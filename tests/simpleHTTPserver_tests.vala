class TestSimpleHTTPServer : Gee.TestCase {
/*
print("RES---------------------------------------------\n|%s|\n", printable_uint(res));
print("ROOT_RES---------------------------------------------\n|%s|\n---------------------------------------------------------\n", printable_uint(root_res));
print_bytes(res);print_bytes(root_res);
*/

    SimpleHTTPServer server;

    public TestSimpleHTTPServer() {
        // assign a name for this class
        base("TestSimpleHTTPServer");
        // add test methods
        add_test(" * Test default server directory is current path (test_default_dir)", test_default_dir);
        add_test(" * Test default server port is in 8080 (test_default_port)", test_default_port);
        add_test(" * Test directory request in root (test_root_directory_ok)", test_root_directory_ok);
        add_test(" * Test directory request subfolder level 1 (test_subfolder_lv1_ok)", test_subfolder_lv1_ok);
        add_test(" * Test directory request subfolder level 2 (test_subfolder_lv2_ok)", test_subfolder_lv2_ok);
        add_test(" * Test directory request with index (test_directory_index_ok)", test_directory_index_ok);
        add_test(" * Test text file request (test_text_file_ok)", test_text_file_ok);
        add_test(" * Test image file request (test_image_file_ok)", test_image_file_ok);
        add_test(" * Test audio file request (test_audio_file_ok)", test_audio_file_ok);
        add_test(" * Test video file request (test_video_file_ok)", test_video_file_ok);
        add_test(" * Test error request (test_error_ok)", test_error_ok);
    }

    public override void set_up () {
        server = new SimpleHTTPServer.with_port_and_path(9999, Environment.get_current_dir()+"/fixtures/test_directory_requests");
        //server.run_async ();
        //PRINT// stdout.printf("\n");
    }

    private uint8[] make_get_request(string url) {
        MainLoop loop = new MainLoop ();
        // Create a session:
        Soup.Session session = new Soup.Session ();
        // Send a request:
        uint8[] res = "NONE".data;
        Soup.Message msg = new Soup.Message ("GET", url);
        session.queue_message (msg, (sess, mess) => {
            res = mess.response_body.data;
            // Process the result:
            //PRINT// print ("Status Code: %u\n", mess.status_code);
            //PRINT// print ("Message length: %lld\n", mess.response_body.length);
            //PRINT// print ("Data: \n%s\n", res);
            loop.quit ();
        });
        loop.run ();
        return res;
    }

    private uint8[]  get_fixture_content(string path) {
        string abs_path = Environment.get_current_dir()+"/fixtures/" + path;
        File file = File.new_for_path (abs_path);
        var file_stream = file.read ();
        var data_stream = new DataInputStream (file_stream);
        /*data_stream.set_byte_order (DataStreamByteOrder.LITTLE_ENDIAN);
        uint8[]  contents = new uint8[8];
        int readed = 0;
        try {
            while (true) {
                if (contents.length <= readed) contents.resize(readed*2);
                contents[readed] = data_stream.read_byte();
                readed += 1;
            }
        } catch (Error e) {}
        contents = contents[0:readed-1];*/
        uint8[]  contents;
        try {
            try {
                string etag_out;
                file.load_contents (null, out contents, out etag_out);
            }catch (Error e){
                error("%s", e.message);
            }
        }catch (Error e){
            error("%s", e.message);
        }
        return contents;
    }

    public string printable_uint(uint8[] bytes) {
        string res = "";
        foreach (uint8 b in bytes) {
            res += ((char)b).to_string();
        }
        return res;
    }

    public void print_bytes(uint8[] bytes) {
        print("BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB\n");
        int i = 0;
        foreach (uint8 b in bytes) {
            print("*%d-|%d|".printf(i, b));
            i+=1;
        }
        print("\nBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB\n");
    }

    public void assert_bytes(uint8[] res1, uint8[] res2) {
        assert (res1.length == res2.length);
        for (int i=0; i<res1.length;i++) {
            assert (res1[i] == res2[i]);
        }
    }

    public void assert_strings(uint8[] res1, uint8[] res2) {
        string s1 = (string)res1;
        string s2 = (string)res2;
        if (s1 == null) s1 = " ";
        if (s2 == null) s2 = " ";
        s1 = s1.strip();
        s2 = s2.strip();
        assert (s1 == s2);
    }

    public void test_default_dir() {
        server = new SimpleHTTPServer.with_port(9999);
        string current = Environment.get_current_dir()+"/";
        //PRINT// stdout.printf("    - server.basedir -> %s == %s\n", current, server.basedir);
        assert(current == server.basedir);
    }

    public void test_default_port() {
        server = new SimpleHTTPServer.with_path(Environment.get_current_dir()+"/fixtures");
        server.run_async ();
        //PRINT// stdout.printf("    - server.port -> %s == %s\n", "8080", server.port.to_string());
        assert (8080 == server.port);
        var listeners = server.get_uris();
        uint uport = listeners.nth_data(0).get_port();
        //PRINT// stdout.printf("    - listeners.nth_data(0).get_port() -> %s == %s\n", "8080", uport.to_string());
        assert (8080 == uport);
    }

    public void test_root_directory_ok() {
        //PRINT// stdout.printf("    - request '/' -> %s", "http://localhost:%d\n".printf((int)server.port));
        server.run_async();
        uint8[] res = make_get_request("http://localhost:%d\n".printf((int)server.port));
        uint8[] root_res = get_fixture_content("test_directory_requests.html");
        assert_strings (res, root_res);
    }

    public void test_subfolder_lv1_ok() {
        //PRINT// stdout.printf("    - request '/' -> %s", "http://localhost:%d/carpeta_1\n".printf((int)server.port));
        server.run_async();
        uint8[] res = make_get_request("http://localhost:%d/carpeta_1\n".printf((int)server.port));
        uint8[] root_res = get_fixture_content("carpeta_1.html");
        assert_strings (res, root_res);
    }

    public void test_subfolder_lv2_ok() {
        //PRINT// stdout.printf("    - request '/' -> %s", "http://localhost:%d/carpeta_1/carpeta_2\n".printf((int)server.port));
        server.run_async();
        uint8[] res = make_get_request("http://localhost:%d/carpeta_1/carpeta_2\n".printf((int)server.port));
        uint8[] root_res = get_fixture_content("carpeta_2.html");
        assert_strings (res, root_res);
    }

    public void test_directory_index_ok() {
        //PRINT// stdout.printf("    - request '/' -> %s", "http://localhost:%d/carpeta_amb_index\n".printf((int)server.port));
        server.run_async();
        uint8[] res = make_get_request("http://localhost:%d/carpeta_amb_index\n".printf((int)server.port));
        uint8[] root_res = get_fixture_content("test_directory_requests/carpeta_amb_index/index.html");
        assert_bytes (res, root_res);
    }

    public void test_text_file_ok() {
        server.run_async();
        uint8[] res = make_get_request("http://localhost:%d/carpeta_amb_fitxers_test/text_test.txt\n".printf((int)server.port));
        uint8[] root_res = get_fixture_content("test_directory_requests/carpeta_amb_fitxers_test/text_test.txt");
        assert_bytes (res, root_res);
    }

    public void test_image_file_ok() {
        server.run_async();
        uint8[] res = make_get_request("http://localhost:%d/carpeta_amb_fitxers_test/img_test.jpg\n".printf((int)server.port));
        uint8[] root_res = get_fixture_content("test_directory_requests/carpeta_amb_fitxers_test/img_test.jpg");
        assert_bytes (res, root_res);
    }

    public void test_audio_file_ok() {
        server.run_async();
        uint8[] res = make_get_request("http://localhost:%d/carpeta_amb_fitxers_test/demo.mp3\n".printf((int)server.port));
        uint8[] root_res = get_fixture_content("test_directory_requests/carpeta_amb_fitxers_test/demo.mp3");
        assert_bytes (res, root_res);
    }

    public void test_video_file_ok() {
        server.run_async();
        uint8[] res = make_get_request("http://localhost:%d/carpeta_amb_fitxers_test/demo.mp4\n".printf((int)server.port));
        uint8[] root_res = get_fixture_content("test_directory_requests/carpeta_amb_fitxers_test/demo.mp4");
        assert_bytes (res, root_res);
    }

    public void test_error_ok() {
        server.run_async();
        uint8[] res = make_get_request("http://localhost:%d/carpeta_inventada\n".printf((int)server.port));
        uint8[] root_res = get_fixture_content("error.html");
        assert_strings (res, root_res);
    }

    public override void tear_down () {
        if (server != null) {
            server.disconnect();
            server = null;
        }
    }
}

