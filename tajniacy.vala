using Gtk;
using GLib;

class Item : Button {

    public enum Type {
        UNKNOWN,
        NEUTRAL,
        RED,
        BLUE,
        KILLER
    }

    private static string get_color (Type type) {
        switch (type) {
        case Type.UNKNOWN:
            return "white";
        case Type.NEUTRAL:
            return "gray";
        case Type.RED:
            return "red";
        case Type.BLUE:
            return "blue";
        case Type.KILLER:
            return "black";
        default:
            return null;
        }
    }

    private string text;

    private bool black;

    private new Label label;

    void set_color (string color) {
        var rgba = new Gdk.RGBA ();
        rgba.parse (color);
        override_background_color (StateFlags.NORMAL, rgba);
    }

    void update_markup () {
        label.label = "<span size='15000' color='%s'>%s</span>".printf (black ? "black" : "white", text);
    }

    public Item (string text, Type type, bool reveal) {
        this.text = text;
        label = new Label ("");
        label.wrap = true;
        label.use_markup = true;
        add (label);
        clicked.connect (() => { set_color (get_color (type)); black = !black; update_markup (); });
        get_style_context ().add_class ("flat");
        set_color (get_color (reveal ? type : Type.UNKNOWN));
        black = !reveal;
        update_markup ();
    }

}

int[] random_perm (int n) {
    var array = new int[n];
    for (int i = 0; i < n; i++) {
        int k = GLib.Random.int_range (0, i + 1);
        array[i] = array[k];
        array[k] = i + 1;
    }
    return array;
}

string[] load_words (string directory) {
    string[] result = { };
    var path = Path.build_filename (directory, "slownik.txt");
    var file = File.new_for_path (path);
    var stream = new DataInputStream (file.read ());
    string line;
    while ((line = stream.read_line_utf8 (null, null)) != null) {
        result += line;
    }
    return result;
}

void start_game (bool leader, uint64 seed, string directory, Window win) {
    Random.set_seed ((uint32)seed);
    var words = load_words (directory);
    var word_perm = random_perm (words.length);
    var tile_perm = random_perm (25);
    var side1 = Item.Type.RED, side2 = Item.Type.BLUE;
    if (GLib.Random.int_range (0, 2) == 1)
    {
        side1 = Item.Type.BLUE;
        side2 = Item.Type.RED;
    };
    var tile_type = new Item.Type[25];
    for(int i = 0; i < 9; i++)
        tile_type[i] = side1;
    for(int i = 9; i < 17; i++)
        tile_type[i] = side2;
    tile_type[17] = Item.Type.KILLER;
    for(int i = 18; i < 25; i++)
        tile_type[i] = Item.Type.NEUTRAL;
    var grid = new Grid ();
    grid.column_homogeneous = true;
    grid.row_homogeneous = true;
    for (int i = 0; i < 5; i++)
        for (int j = 0; j < 5; j++)
            grid.attach (new Item(words[word_perm[i * 5 + j]], tile_type[tile_perm[i * 5 + j]-1], leader), i, j);
    var vbox = new Box (Orientation.VERTICAL, 2);
    vbox.pack_start (new Label("Zaczyna: %s".printf (side1 == Item.Type.RED ? "Czerwony" : "Niebieski")), false, false);
    vbox.pack_start (grid, true, true);
    if (win.get_child() != null) {
        win.remove (win.get_child());
    }
    win.add (vbox);
    win.show_all ();
    win.set_size_request(800, 600);
}

ListBoxRow createRow (string label, Widget widget) {
    var box = new Box (Orientation.HORIZONTAL, 30);
    box.pack_start (new Label(label), false, false, 20);
    box.pack_end (widget, false, false, 20);
    var row = new ListBoxRow ();
    row.add (box);
    return row;
}

int main (string[] args)
{
    bool leader = "leader" in args;
    uint64 seed = 0;
    bool seed_set = false;
    var directory = Path.get_dirname (args[0]);
    print (directory + "\n");
    foreach(var arg in args) {
        if(uint64.try_parse(arg, out seed)) {
            seed_set = true;
            break;
        }
    }
    init (ref args);
    var win = new Window ();
    win.title = "Tajniacy";
    if (seed_set) {
        start_game (leader, seed, directory, win);
    } else {
        var list = new ListBox ();
        list.selection_mode = SelectionMode.NONE;
        var entry = new Entry ();
        entry.max_length = 10;
        entry.width_chars = 10;
        entry.xalign = 1;
        var check = new CheckButton ();
        list.add (createRow ("Ziarno", entry));
        list.add (createRow ("Lider", check));
        var box = new Box (Orientation.VERTICAL, 5);
        box.pack_start (list, true, false, 5);
        var hbox = new Box (Orientation.HORIZONTAL, 0);
        var start = new Button.with_label ("Start!");
        start.clicked.connect (() => {
            uint64.try_parse (entry.text, out seed);
            start_game (check.active, seed, directory, win);
        });
        hbox.pack_start (start, true, false);
        box.pack_end (hbox, false, false, 10);
        win.set_default_size (400, 300);
        win.add (box);
    }
    win.window_position = WindowPosition.CENTER;
    win.show_all ();
    win.present ();
    win.destroy.connect (main_quit);
    Gtk.main ();
    return 0;
}