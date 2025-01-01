## AUTHORİZATİON SYSTEM

// Birleşik Yetkilendirme Sistemi
module authorization_system(
    input clk,                // Saat sinyali
    input reset,              // Reset sinyali
    input [7:0] username,     // 8-bit kullanıcı adı
    input [7:0] password,     // 8-bit şifre
    output reg authorized_seq, // Durum makinesi tabanlı yetkilendirme
    output authorized_comb     // Kombinasyonel yetkilendirme
);

    // Sabit kullanıcı adı ve şifre tanımları
    parameter [7:0] USERNAME = 8'h55;  // Kullanıcı adı: 0x55
    parameter [7:0] PASSWORD = 8'hAA;  // Şifre: 0xAA

    // Durum makinesi için durum tanımları
    typedef enum logic [1:0] {
        IDLE        = 2'b00,
        CHECK_USER  = 2'b01,
        CHECK_PASS  = 2'b10,
        AUTH_DONE   = 2'b11
    } state_t;

    state_t current_state, next_state;

    // Kombinasyonel yetkilendirme
    assign authorized_comb = (username == USERNAME) && (password == PASSWORD);

    // Durum geçişleri
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // Durumlara göre yetkilendirme işlemleri ve bir sonraki durumun belirlenmesi
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            authorized_seq <= 1'b0;
        end else begin
            case (current_state)
                IDLE: begin
                    authorized_seq <= 1'b0;
                    next_state <= CHECK_USER;
                end

                CHECK_USER: begin
                    if (username == USERNAME) begin
                        next_state <= CHECK_PASS;
                    end else begin
                        next_state <= IDLE;
                    end
                end

                CHECK_PASS: begin
                    if (password == PASSWORD) begin
                        next_state <= AUTH_DONE;
                    end else begin
                        next_state <= IDLE;
                    end
                end

                AUTH_DONE: begin
                    authorized_seq <= 1'b1;
                    next_state <= IDLE; // Döngüsel tekrar
                end

                default: begin
                    next_state <= IDLE;
                end
            endcase
        end
    end

endmodule

// Test Bench of Authorization System
testbench_authorization_system;
    reg clk;
    reg reset;
    reg [7:0] username;
    reg [7:0] password;
    wire authorized_seq;
    wire authorized_comb;

    // Modül örnekleme
    authorization_system uut (
        .clk(clk),
        .reset(reset),
        .username(username),
        .password(password),
        .authorized_seq(authorized_seq),
        .authorized_comb(authorized_comb)
    );

    // Saat sinyali üretilmesi
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 birimlik periyot
    end

    // Test işlemleri
    initial begin
        $monitor($time, " username=%h password=%h authorized_seq=%b authorized_comb=%b", username, password, authorized_seq, authorized_comb);

        // Başlangıç durumu
        reset = 1;
        username = 8'h00;
        password = 8'h00;
        #10 reset = 0;

        // Geçersiz kullanıcı adı ve şifre
        username = 8'h00;
        password = 8'h00;
        #10;

        // Geçerli kullanıcı adı, geçersiz şifre
        username = 8'h55;
        password = 8'h00;
        #10;

        // Geçerli kullanıcı adı ve şifre
        username = 8'h55;
        password = 8'hAA;
        #10;

        // Test bitişi
        $finish;
    end

endmodule

## GENERAL MANAGEMENT SYSTEM

// Birleşik Genel Yönetim Sistemi
module general_management_system(
    input clk,                     // Saat sinyali
    input reset,                   // Reset sinyali
    input [7:0] user_id,           // 8-bit kullanıcı kimliği
    input [1:0] role,              // 2-bit rol (00: User, 01: Admin, 10: Supervisor)
    input [1:0] operation,         // 2-bit işlem türü (00: Read, 01: Write, 10: Delete)
    output reg access_granted_seq, // Durum makinesi tabanlı erişim izni
    output reg operation_success_seq, // Durum makinesi tabanlı işlem başarısı
    output access_granted_comb,    // Kombinasyonel erişim izni
    output operation_success_comb  // Kombinasyonel işlem başarısı
);

    // Önceden tanımlanmış sabitler
    parameter [7:0] VALID_USER_ID = 8'hA5; // Sabit kullanıcı kimliği
    parameter [1:0] READ = 2'b00;          // Okuma işlemi
    parameter [1:0] WRITE = 2'b01;         // Yazma işlemi
    parameter [1:0] DELETE = 2'b10;        // Silme işlemi

    // Durum makinesi için durum tanımları
    typedef enum logic [1:0] {
        IDLE        = 2'b00,
        CHECK_USER  = 2'b01,
        CHECK_ROLE  = 2'b10,
        DONE        = 2'b11
    } state_t;

    state_t current_state, next_state;

    // Kombinasyonel erişim kontrolü: Kullanıcı kimliği doğruysa erişim verilir
    assign access_granted_comb = (user_id == VALID_USER_ID);

    // Kombinasyonel işlem kontrolü: Rol ve işlem türüne göre işlem başarı durumu
    assign operation_success_comb = access_granted_comb && (
        (role == 2'b00 && operation == READ) ||                    // USER: Sadece okuma
        (role == 2'b01 && (operation == READ || operation == WRITE)) ||  // ADMIN: Okuma ve yazma
        (role == 2'b10)                                            // SUPERVISOR: Tüm işlemler
    );

    // Durum geçişleri
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // Durumlara göre işlemler ve bir sonraki durumun belirlenmesi
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            access_granted_seq <= 1'b0;
            operation_success_seq <= 1'b0;
        end else begin
            case (current_state)
                IDLE: begin
                    access_granted_seq <= 1'b0;
                    operation_success_seq <= 1'b0;
                    next_state <= CHECK_USER;
                end

                CHECK_USER: begin
                    if (user_id == VALID_USER_ID) begin
                        access_granted_seq <= 1'b1;
                        next_state <= CHECK_ROLE;
                    end else begin
                        access_granted_seq <= 1'b0;
                        next_state <= IDLE;
                    end
                end

                CHECK_ROLE: begin
                    if (access_granted_seq) begin
                        case (role)
                            2'b00: operation_success_seq <= (operation == READ); // USER: Sadece okuma
                            2'b01: operation_success_seq <= (operation == READ || operation == WRITE); // ADMIN: Okuma ve yazma
                            2'b10: operation_success_seq <= 1'b1; // SUPERVISOR: Tüm işlemler
                            default: operation_success_seq <= 1'b0;
                        endcase
                        next_state <= DONE;
                    end else begin
                        next_state <= IDLE;
                    end
                end

                DONE: begin
                    next_state <= IDLE; // Döngüsel tekrar için
                end

                default: begin
                    next_state <= IDLE;
                end
            endcase
        end
    end

endmodule

// Test Bench of General Management System
testbench_general_management_system;
    reg clk;
    reg reset;
    reg [7:0] user_id;
    reg [1:0] role;
    reg [1:0] operation;
    wire access_granted_seq;
    wire operation_success_seq;
    wire access_granted_comb;
    wire operation_success_comb;

    // Modül örnekleme
    general_management_system uut (
        .clk(clk),
        .reset(reset),
        .user_id(user_id),
        .role(role),
        .operation(operation),
        .access_granted_seq(access_granted_seq),
        .operation_success_seq(operation_success_seq),
        .access_granted_comb(access_granted_comb),
        .operation_success_comb(operation_success_comb)
    );

    // Saat sinyali üretilmesi
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 birimlik periyot
    end

    // Test işlemleri
    initial begin
        $monitor($time, " user_id=%h role=%b operation=%b access_granted_seq=%b operation_success_seq=%b access_granted_comb=%b operation_success_comb=%b", 
                 user_id, role, operation, access_granted_seq, operation_success_seq, access_granted_comb, operation_success_comb);

        // Başlangıç durumu
        reset = 1;
        user_id = 8'h00;
        role = 2'b00;
        operation = 2'b00;
        #10 reset = 0;

        // Geçersiz kullanıcı kimliği
        user_id = 8'h00;
        role = 2'b00;
        operation = 2'b00;
        #10;

        // Geçerli kullanıcı kimliği, USER rolü, okuma işlemi
        user_id = 8'hA5;
        role = 2'b00;
        operation = 2'b00;
        #10;

        // Geçerli kullanıcı kimliği, ADMIN rolü, yazma işlemi
        user_id = 8'hA5;
        role = 2'b01;
        operation = 2'b01;
        #10;

        // Geçerli kullanıcı kimliği, SUPERVISOR rolü, silme işlemi
        user_id = 8'hA5;
        role = 2'b10;
        operation = 2'b10;
        #10;

        // Test bitişi
        $finish;
    end

endmodule

## SMART LİGHTİNG SYSTEM

// Birleşik Genel Yönetim ve Akıllı Aydınlatma Sistemi

module smart_lighting_system (
    input clk,                     // Saat sinyali
    input reset,                   // Reset sinyali
    input light_sensor,            // Ortam ışık sensörü (1: karanlık, 0: aydınlık)
    input motion_sensor,           // Hareket sensörü (1: hareket var, 0: hareket yok)
    input manual_switch,           // Manuel açma-kapama düğmesi (1: açık, 0: kapalı)
    input [3:0] hour,              // Saat bilgisi (0-23 arası)
    output reg light_seq,          // Durum makinesi tabanlı ışık durumu
    output light_comb              // Kombinasyonel ışık durumu
);

    // Belirli saatler için zamanlayıcı sınırları
    parameter NIGHT_START = 4'd18; // Akşam 18:00
    parameter NIGHT_END = 4'd6;    // Sabah 6:00

    // Durum makinesi için durum tanımları
    typedef enum logic [1:0] {
        IDLE        = 2'b00,
        CHECK_LIGHT = 2'b01,
        CHECK_MOTION = 2'b10,
        DONE        = 2'b11
    } state_t;

    state_t current_state, next_state;

    // Kombinasyonel ışık kontrolü
    assign light_comb = manual_switch || // Manuel düğme ışığı açar
                        (light_sensor && (motion_sensor || (hour >= NIGHT_START || hour < NIGHT_END)));

    // Durum geçişleri
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // Durumlara göre işlemler ve bir sonraki durumun belirlenmesi
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            light_seq <= 1'b0;
        end else begin
            case (current_state)
                IDLE: begin
                    light_seq <= 1'b0;
                    next_state <= CHECK_LIGHT;
                end

                CHECK_LIGHT: begin
                    if (manual_switch) begin
                        light_seq <= 1'b1;
                        next_state <= DONE;
                    end else if (light_sensor) begin
                        next_state <= CHECK_MOTION;
                    end else begin
                        next_state <= IDLE;
                    end
                end

                CHECK_MOTION: begin
                    if (motion_sensor || (hour >= NIGHT_START || hour < NIGHT_END)) begin
                        light_seq <= 1'b1;
                    end else begin
                        light_seq <= 1'b0;
                    end
                    next_state <= DONE;
                end

                DONE: begin
                    next_state <= IDLE; // Döngüsel tekrar için
                end

                default: begin
                    next_state <= IDLE;
                end
            endcase
        end
    end

endmodule

// Test Bench Of Smart Lighting 
testbench_smart_lighting_system;
    reg clk;
    reg reset;
    reg light_sensor;
    reg motion_sensor;
    reg manual_switch;
    reg [3:0] hour;
    wire light_seq;
    wire light_comb;

    // Modül örnekleme
    smart_lighting_system uut (
        .clk(clk),
        .reset(reset),
        .light_sensor(light_sensor),
        .motion_sensor(motion_sensor),
        .manual_switch(manual_switch),
        .hour(hour),
        .light_seq(light_seq),
        .light_comb(light_comb)
    );

    // Saat sinyali üretilmesi
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 birimlik periyot
    end

    // Test işlemleri
    initial begin
        $monitor($time, " light_sensor=%b motion_sensor=%b manual_switch=%b hour=%d light_seq=%b light_comb=%b", 
                 light_sensor, motion_sensor, manual_switch, hour, light_seq, light_comb);

        // Başlangıç durumu
        reset = 1;
        light_sensor = 0;
        motion_sensor = 0;
        manual_switch = 0;
        hour = 4'd0;
        #10 reset = 0;

        // Manuel düğme açık
        manual_switch = 1;
        #10;

        // Karanlık, hareket var
        manual_switch = 0;
        light_sensor = 1;
        motion_sensor = 1;
        #10;

        // Karanlık, hareket yok, gece saatleri
        motion_sensor = 0;
        hour = 4'd20;
        #10;

        // Aydınlık, gece saatleri
        light_sensor = 0;
        hour = 4'd5;
        #10;

        // Test bitişi
        $finish;
    end

endmodule

## WHİTE GOODS CONTROL SYSTEM

// Birleşik Beyaz Eşya ve Akıllı Aydınlatma Kontrol Sistemi

module white_goods_control (
    input clk,                     // Saat sinyali
    input reset,                   // Reset sinyali
    input manual_laundry,          // Çamaşır makinesi manuel açma (1: açık, 0: kapalı)
    input manual_dishwasher,       // Bulaşık makinesi manuel açma (1: açık, 0: kapalı)
    input manual_oven,             // Fırın manuel açma (1: açık, 0: kapalı)
    input [3:0] hour,              // Günün saat bilgisi (0-23)
    output reg laundry_on_seq,     // Çamaşır makinesi durumu (durum makinesi tabanlı)
    output reg dishwasher_on_seq,  // Bulaşık makinesi durumu (durum makinesi tabanlı)
    output reg oven_on_seq,        // Fırın durumu (durum makinesi tabanlı)
    output laundry_on_comb,        // Çamaşır makinesi durumu (kombinasyonel)
    output dishwasher_on_comb,     // Bulaşık makinesi durumu (kombinasyonel)
    output oven_on_comb            // Fırın durumu (kombinasyonel)
);

    // Otomatik başlatma saatleri
    parameter LAUNDRY_AUTO_START = 4'd7;     // Çamaşır makinesi için otomatik başlatma saati (7:00)
    parameter DISHWASHER_AUTO_START = 4'd22; // Bulaşık makinesi için otomatik başlatma saati (22:00)
    parameter OVEN_AUTO_START = 4'd18;       // Fırın için otomatik başlatma saati (18:00)

    // Durum makinesi için durum tanımları
    typedef enum logic [1:0] {
        IDLE             = 2'b00,
        CHECK_LAUNDRY    = 2'b01,
        CHECK_DISHWASHER = 2'b10,
        CHECK_OVEN       = 2'b11
    } state_t;

    state_t current_state, next_state;

    // Kombinasyonel cihaz kontrolü
    assign laundry_on_comb = manual_laundry || (hour == LAUNDRY_AUTO_START);
    assign dishwasher_on_comb = manual_dishwasher || (hour == DISHWASHER_AUTO_START);
    assign oven_on_comb = manual_oven || (hour == OVEN_AUTO_START);

    // Durum geçişleri
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // Durumlara göre işlemler ve bir sonraki durumun belirlenmesi
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            laundry_on_seq <= 1'b0;
            dishwasher_on_seq <= 1'b0;
            oven_on_seq <= 1'b0;
        end else begin
            case (current_state)
                IDLE: begin
                    laundry_on_seq <= 1'b0;
                    dishwasher_on_seq <= 1'b0;
                    oven_on_seq <= 1'b0;
                    next_state <= CHECK_LAUNDRY;
                end

                CHECK_LAUNDRY: begin
                    if (manual_laundry || (hour == LAUNDRY_AUTO_START)) begin
                        laundry_on_seq <= 1'b1;
                    end
                    next_state <= CHECK_DISHWASHER;
                end

                CHECK_DISHWASHER: begin
                    if (manual_dishwasher || (hour == DISHWASHER_AUTO_START)) begin
                        dishwasher_on_seq <= 1'b1;
                    end
                    next_state <= CHECK_OVEN;
                end

                CHECK_OVEN: begin
                    if (manual_oven || (hour == OVEN_AUTO_START)) begin
                        oven_on_seq <= 1'b1;
                    end
                    next_state <= IDLE; // Döngüsel tekrar için
                end

                default: begin
                    next_state <= IDLE;
                end
            endcase
        end
    end

endmodule

// Test Bench
testbench_white_goods_control;
    reg clk;
    reg reset;
    reg manual_laundry;
    reg manual_dishwasher;
    reg manual_oven;
    reg [3:0] hour;
    wire laundry_on_seq;
    wire dishwasher_on_seq;
    wire oven_on_seq;
    wire laundry_on_comb;
    wire dishwasher_on_comb;
    wire oven_on_comb;

    // Modül örnekleme
    white_goods_control uut (
        .clk(clk),
        .reset(reset),
        .manual_laundry(manual_laundry),
        .manual_dishwasher(manual_dishwasher),
        .manual_oven(manual_oven),
        .hour(hour),
        .laundry_on_seq(laundry_on_seq),
        .dishwasher_on_seq(dishwasher_on_seq),
        .oven_on_seq(oven_on_seq),
        .laundry_on_comb(laundry_on_comb),
        .dishwasher_on_comb(dishwasher_on_comb),
        .oven_on_comb(oven_on_comb)
    );

    // Saat sinyali üretilmesi
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 birimlik periyot
    end

    // Test işlemleri
    initial begin
        $monitor($time, " manual_laundry=%b manual_dishwasher=%b manual_oven=%b hour=%d laundry_on_seq=%b dishwasher_on_seq=%b oven_on_seq=%b laundry_on_comb=%b dishwasher_on_comb=%b oven_on_comb=%b", 
                 manual_laundry, manual_dishwasher, manual_oven, hour, laundry_on_seq, dishwasher_on_seq, oven_on_seq, laundry_on_comb, dishwasher_on_comb, oven_on_comb);

        // Başlangıç durumu
        reset = 1;
        manual_laundry = 0;
        manual_dishwasher = 0;
        manual_oven = 0;
        hour = 4'd0;
        #10 reset = 0;

        // Çamaşır makinesi manuel açma
        manual_laundry = 1;
        #10;

        // Bulaşık makinesi manuel açma
        manual_laundry = 0;
        manual_dishwasher = 1;
        #10;

        // Fırın manuel açma
        manual_dishwasher = 0;
        manual_oven = 1;
        #10;

        // Otomatik başlatma saatleri testi
        manual_oven = 0;
        hour = 4'd7;
        #10;
        hour = 4'd22;
        #10;
        hour = 4'd18;
        #10;

        // Test bitişi
        $finish;
    end

endmodule

## SMART HOME CONTROL SYSTEM 

// Birleşik Beyaz Eşya, Akıllı Aydınlatma ve Akıllı Ev Kontrol Sistemi

module smart_home_control (
    input clk,                     // Saat sinyali
    input reset,                   // Reset sinyali
    input sunlight_sensor,         // Güneş ışığı sensörü (1: güneş var, 0: güneş yok)
    input temp_sensor,             // Sıcaklık sensörü (1: sıcak, 0: soğuk)
    input air_quality_sensor,      // Hava kalitesi sensörü (1: iyi, 0: kötü)
    input manual_curtain,          // Perde manuel açma-kapama (1: açık, 0: kapalı)
    input manual_window,           // Pencere manuel açma-kapama (1: açık, 0: kapalı)
    input manual_door_lock,        // Kapı manuel kilitleme (1: kilitle, 0: aç)
    output reg curtain_open_seq,   // Perde durumu (1: açık, 0: kapalı - durum makinesi)
    output reg window_open_seq,    // Pencere durumu (1: açık, 0: kapalı - durum makinesi)
    output reg door_locked_seq,    // Kapı durumu (1: kilitli, 0: açık - durum makinesi)
    output curtain_open_comb,      // Kombinasyonel perde kontrolü
    output window_open_comb,       // Kombinasyonel pencere kontrolü
    output door_locked_comb        // Kombinasyonel kapı kontrolü
);

    // Durum makinesi için durum tanımları
    typedef enum logic [1:0] {
        IDLE          = 2'b00,
        CHECK_CURTAIN = 2'b01,
        CHECK_WINDOW  = 2'b10,
        CHECK_DOOR    = 2'b11
    } state_t;

    state_t current_state, next_state;

    // Kombinasyonel kontroller
    assign curtain_open_comb = manual_curtain || (!sunlight_sensor);
    assign window_open_comb = manual_window || (temp_sensor && air_quality_sensor);
    assign door_locked_comb = manual_door_lock;

    // Durum geçişleri
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // Durumlara göre işlemler ve bir sonraki durumun belirlenmesi
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            curtain_open_seq <= 1'b0;
            window_open_seq <= 1'b0;
            door_locked_seq <= 1'b0;
        end else begin
            case (current_state)
                IDLE: begin
                    curtain_open_seq <= 1'b0;
                    window_open_seq <= 1'b0;
                    door_locked_seq <= 1'b0;
                    next_state <= CHECK_CURTAIN;
                end

                CHECK_CURTAIN: begin
                    if (manual_curtain || (!sunlight_sensor)) begin
                        curtain_open_seq <= 1'b1;
                    end
                    next_state <= CHECK_WINDOW;
                end

                CHECK_WINDOW: begin
                    if (manual_window || (temp_sensor && air_quality_sensor)) begin
                        window_open_seq <= 1'b1;
                    end
                    next_state <= CHECK_DOOR;
                end

                CHECK_DOOR: begin
                    if (manual_door_lock) begin
                        door_locked_seq <= 1'b1;
                    end
                    next_state <= IDLE;
                end

                default: begin
                    next_state <= IDLE;
                end
            endcase
        end
    end

endmodule

// Test Bench
testbench_smart_home_control;
    reg clk;
    reg reset;
    reg sunlight_sensor;
    reg temp_sensor;
    reg air_quality_sensor;
    reg manual_curtain;
    reg manual_window;
    reg manual_door_lock;
    wire curtain_open_seq;
    wire window_open_seq;
    wire door_locked_seq;
    wire curtain_open_comb;
    wire window_open_comb;
    wire door_locked_comb;

    // Modül örnekleme
    smart_home_control uut (
        .clk(clk),
        .reset(reset),
        .sunlight_sensor(sunlight_sensor),
        .temp_sensor(temp_sensor),
        .air_quality_sensor(air_quality_sensor),
        .manual_curtain(manual_curtain),
        .manual_window(manual_window),
        .manual_door_lock(manual_door_lock),
        .curtain_open_seq(curtain_open_seq),
        .window_open_seq(window_open_seq),
        .door_locked_seq(door_locked_seq),
        .curtain_open_comb(curtain_open_comb),
        .window_open_comb(window_open_comb),
        .door_locked_comb(door_locked_comb)
    );

    // Saat sinyali üretilmesi
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 birimlik periyot
    end

    // Test işlemleri
    initial begin
        $monitor($time, " sunlight_sensor=%b temp_sensor=%b air_quality_sensor=%b manual_curtain=%b manual_window=%b manual_door_lock=%b curtain_open_seq=%b window_open_seq=%b door_locked_seq=%b curtain_open_comb=%b window_open_comb=%b door_locked_comb=%b", 
                 sunlight_sensor, temp_sensor, air_quality_sensor, manual_curtain, manual_window, manual_door_lock, curtain_open_seq, window_open_seq, door_locked_seq, curtain_open_comb, window_open_comb, door_locked_comb);

        // Başlangıç durumu
        reset = 1;
        sunlight_sensor = 0;
        temp_sensor = 0;
        air_quality_sensor = 0;
        manual_curtain = 0;
        manual_window = 0;
        manual_door_lock = 0;
        #10 reset = 0;

        // Manuel perde açma
        manual_curtain = 1;
        #10;

        // Manuel pencere açma
        manual_curtain = 0;
        manual_window = 1;
        #10;

        // Manuel kapı kilitleme
        manual_window = 0;
        manual_door_lock = 1;
        #10;

        // Güneş ışığı yok, sıcak, hava iyi
        manual_door_lock = 0;
        sunlight_sensor = 0;
        temp_sensor = 1;
        air_quality_sensor = 1;
        #10;

        // Güneş var, soğuk, hava kötü
        sunlight_sensor = 1;
        temp_sensor = 0;
        air_quality_sensor = 0;
        #10;

        // Test bitişi
        $finish;
    end

endmodule

## CLİMATE CONTROL SYSTEM

// Birleşik İklim Kontrol Sistemi

module climate_control_system (
    input clk,                     // Saat sinyali
    input reset,                   // Reset sinyali
    input [7:0] temp,              // Sıcaklık değeri (8-bit, örneğin 0-255 arasında)
    input [7:0] humidity,          // Nem değeri (8-bit, örneğin 0-255 arasında)
    input manual_heater,           // Manuel ısıtıcı kontrolü (1: açık, 0: kapalı)
    input manual_ac,               // Manuel klima kontrolü (1: açık, 0: kapalı)
    input manual_humidifier,       // Manuel nemlendirici kontrolü (1: açık, 0: kapalı)
    input manual_dehumidifier,     // Manuel nem giderici kontrolü (1: açık, 0: kapalı)
    output reg heater_on_seq,      // Isıtıcı durumu (1: açık, 0: kapalı - durum makinesi)
    output reg ac_on_seq,          // Klima durumu (1: açık, 0: kapalı - durum makinesi)
    output reg humidifier_on_seq,  // Nemlendirici durumu (1: açık, 0: kapalı - durum makinesi)
    output reg dehumidifier_on_seq,// Nem giderici durumu (1: açık, 0: kapalı - durum makinesi)
    output heater_on_comb,         // Kombinasyonel ısıtıcı kontrolü
    output ac_on_comb,             // Kombinasyonel klima kontrolü
    output humidifier_on_comb,     // Kombinasyonel nemlendirici kontrolü
    output dehumidifier_on_comb    // Kombinasyonel nem giderici kontrolü
);

    // Sıcaklık ve nem için ideal aralıklar
    parameter [7:0] TEMP_LOW_THRESHOLD = 8'd18;      // Minimum sıcaklık (örn: 18°C)
    parameter [7:0] TEMP_HIGH_THRESHOLD = 8'd26;     // Maksimum sıcaklık (örn: 26°C)
    parameter [7:0] HUMIDITY_LOW_THRESHOLD = 8'd30;  // Minimum nem (%30)
    parameter [7:0] HUMIDITY_HIGH_THRESHOLD = 8'd70; // Maksimum nem (%70)

    // Kombinasyonel kontroller
    assign heater_on_comb = manual_heater || (temp < TEMP_LOW_THRESHOLD);
    assign ac_on_comb = manual_ac || (temp > TEMP_HIGH_THRESHOLD);
    assign humidifier_on_comb = manual_humidifier || (humidity < HUMIDITY_LOW_THRESHOLD);
    assign dehumidifier_on_comb = manual_dehumidifier || (humidity > HUMIDITY_HIGH_THRESHOLD);

    // Durum makinesi için durum tanımları
    typedef enum logic [2:0] {
        IDLE               = 3'b000,
        CHECK_HEATER       = 3'b001,
        CHECK_AC           = 3'b010,
        CHECK_HUMIDIFIER   = 3'b011,
        CHECK_DEHUMIDIFIER = 3'b100
    } state_t;

    state_t current_state, next_state;

    // Durum geçişleri
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // Durumlara göre işlemler ve bir sonraki durumun belirlenmesi
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            heater_on_seq <= 1'b0;
            ac_on_seq <= 1'b0;
            humidifier_on_seq <= 1'b0;
            dehumidifier_on_seq <= 1'b0;
        end else begin
            case (current_state)
                IDLE: begin
                    heater_on_seq <= 1'b0;
                    ac_on_seq <= 1'b0;
                    humidifier_on_seq <= 1'b0;
                    dehumidifier_on_seq <= 1'b0;
                    next_state <= CHECK_HEATER;
                end

                CHECK_HEATER: begin
                    if (manual_heater || (temp < TEMP_LOW_THRESHOLD)) begin
                        heater_on_seq <= 1'b1;
                    end else begin
                        heater_on_seq <= 1'b0;
                    end
                    next_state <= CHECK_AC;
                end

                CHECK_AC: begin
                    if (manual_ac || (temp > TEMP_HIGH_THRESHOLD)) begin
                        ac_on_seq <= 1'b1;
                    end else begin
                        ac_on_seq <= 1'b0;
                    end
                    next_state <= CHECK_HUMIDIFIER;
                end

                CHECK_HUMIDIFIER: begin
                    if (manual_humidifier || (humidity < HUMIDITY_LOW_THRESHOLD)) begin
                        humidifier_on_seq <= 1'b1;
                    end else begin
                        humidifier_on_seq <= 1'b0;
                    end
                    next_state <= CHECK_DEHUMIDIFIER;
                end

                CHECK_DEHUMIDIFIER: begin
                    if (manual_dehumidifier || (humidity > HUMIDITY_HIGH_THRESHOLD)) begin
                        dehumidifier_on_seq <= 1'b1;
                    end else begin
                        dehumidifier_on_seq <= 1'b0;
                    end
                    next_state <= IDLE; // Döngüsel tekrar için
                end

                default: begin
                    next_state <= IDLE;
                end
            endcase
        end
    end

endmodule

// Test Bench
testbench_climate_control_system;
    reg clk;
    reg reset;
    reg [7:0] temp;
    reg [7:0] humidity;
    reg manual_heater;
    reg manual_ac;
    reg manual_humidifier;
    reg manual_dehumidifier;
    wire heater_on_seq;
    wire ac_on_seq;
    wire humidifier_on_seq;
    wire dehumidifier_on_seq;
    wire heater_on_comb;
    wire ac_on_comb;
    wire humidifier_on_comb;
    wire dehumidifier_on_comb;

    // Modül örnekleme
    climate_control_system uut (
        .clk(clk),
        .reset(reset),
        .temp(temp),
        .humidity(humidity),
        .manual_heater(manual_heater),
        .manual_ac(manual_ac),
        .manual_humidifier(manual_humidifier),
        .manual_dehumidifier(manual_dehumidifier),
        .heater_on_seq(heater_on_seq),
        .ac_on_seq(ac_on_seq),
        .humidifier_on_seq(humidifier_on_seq),
        .dehumidifier_on_seq(dehumidifier_on_seq),
        .heater_on_comb(heater_on_comb),
        .ac_on_comb(ac_on_comb),
        .humidifier_on_comb(humidifier_on_comb),
        .dehumidifier_on_comb(dehumidifier_on_comb)
    );

    // Saat sinyali üretilmesi
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 birimlik periyot
    end

    // Test işlemleri
    initial begin
        $monitor($time, " temp=%d humidity=%d manual_heater=%b manual_ac=%b manual_humidifier=%b manual_dehumidifier=%b heater_on_seq=%b ac_on_seq=%b humidifier_on_seq=%b dehumidifier_on_seq=%b heater_on_comb=%b ac_on_comb=%b humidifier_on_comb=%b dehumidifier_on_comb=%b", 
                 temp, humidity, manual_heater, manual_ac, manual_humidifier, manual_dehumidifier, heater_on_seq, ac_on_seq, humidifier_on_seq, dehumidifier_on_seq, heater_on_comb, ac_on_comb, humidifier_on_comb, dehumidifier_on_comb);

        // Başlangıç durumu
        reset = 1;
        temp = 8'd20;
        humidity = 8'd50;
        manual_heater = 0;
        manual_ac = 0;
        manual_humidifier = 0;
        manual_dehumidifier = 0;
        #10 reset = 0;

        // Manuel ısıtıcı açma
        manual_heater = 1;
        #10;

        // Manuel klima açma
        manual_heater = 0;
        manual_ac = 1;
        #10;

        // Manuel nemlendirici açma
        manual_ac = 0;
        manual_humidifier = 1;
        #10;

        // Manuel nem giderici açma
        manual_humidifier = 0;
        manual_dehumidifier = 1;
        #10;

        // Sıcaklık düşük, nem yüksek
        manual_dehumidifier = 0;
        temp = 8'd15;
        humidity = 8'd80;
        #10;

        // Sıcaklık yüksek, nem düşük
        temp = 8'd30;
        humidity = 8'd20;
        #10;

        // Test bitişi
        $finish;
    end

endmodule

## AC CONTROL SYSTEM

// Birleşik Klima Kontrol Sistemi

module ac_control (
    input clk,                     // Saat sinyali
    input reset,                   // Reset sinyali
    input [7:0] temp,              // Sıcaklık değeri (8-bit, örneğin 0-255 arasında)
    input [7:0] target_temp_low,   // Hedef sıcaklık alt sınırı
    input [7:0] target_temp_high,  // Hedef sıcaklık üst sınırı
    input manual_ac,               // Manuel klima kontrolü (1: açık, 0: kapalı)
    output reg ac_on_seq,          // Klima durumu (1: açık, 0: kapalı - durum makinesi)
    output ac_on_comb              // Kombinasyonel klima kontrolü
);

    // Kombinasyonel kontrol
    assign ac_on_comb = manual_ac || (temp > target_temp_high);

    // Durum makinesi için durum tanımları
    typedef enum logic [1:0] {
        IDLE          = 2'b00,
        CHECK_TEMP    = 2'b01,
        DONE          = 2'b10
    } state_t;

    state_t current_state, next_state;

    // Durum geçişleri
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // Durumlara göre işlemler ve bir sonraki durumun belirlenmesi
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ac_on_seq <= 1'b0;
        end else begin
            case (current_state)
                IDLE: begin
                    ac_on_seq <= 1'b0;
                    next_state <= CHECK_TEMP;
                end

                CHECK_TEMP: begin
                    if (manual_ac || (temp > target_temp_high)) begin
                        ac_on_seq <= 1'b1;
                    end else begin
                        ac_on_seq <= 1'b0;
                    end
                    next_state <= DONE;
                end

                DONE: begin
                    next_state <= IDLE; // Döngüsel tekrar için
                end

                default: begin
                    next_state <= IDLE;
                end
            endcase
        end
    end

endmodule

// Test Bench
testbench_ac_control;
    reg clk;
    reg reset;
    reg [7:0] temp;
    reg [7:0] target_temp_low;
    reg [7:0] target_temp_high;
    reg manual_ac;
    wire ac_on_seq;
    wire ac_on_comb;

    // Modül örnekleme
    ac_control uut (
        .clk(clk),
        .reset(reset),
        .temp(temp),
        .target_temp_low(target_temp_low),
        .target_temp_high(target_temp_high),
        .manual_ac(manual_ac),
        .ac_on_seq(ac_on_seq),
        .ac_on_comb(ac_on_comb)
    );

    // Saat sinyali üretilmesi
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 birimlik periyot
    end

    // Test işlemleri
    initial begin
        $monitor($time, " temp=%d target_temp_low=%d target_temp_high=%d manual_ac=%b ac_on_seq=%b ac_on_comb=%b", 
                 temp, target_temp_low, target_temp_high, manual_ac, ac_on_seq, ac_on_comb);

        // Başlangıç durumu
        reset = 1;
        temp = 8'd20;
        target_temp_low = 8'd18;
        target_temp_high = 8'd25;
        manual_ac = 0;
        #10 reset = 0;

        // Manuel klima açma
        manual_ac = 1;
        #10;

        // Sıcaklık hedefin üstünde
        manual_ac = 0;
        temp = 8'd30;
        #10;

        // Sıcaklık hedefin altında
        temp = 8'd20;
        #10;

        // Test bitişi
        $finish;
    end

endmodule

## HEATİNG SYSTEM CONTROL

// Birleşik Isıtıcı ve Klima Kontrol Sistemi

module heating_system_control (
    input clk,                     // Saat sinyali
    input reset,                   // Reset sinyali
    input [7:0] temp,              // Mevcut sıcaklık (8-bit)
    input [7:0] target_temp_low,   // Hedef sıcaklık alt sınırı
    input [7:0] target_temp_high,  // Hedef sıcaklık üst sınırı
    input manual_heater,           // Manuel ısıtıcı kontrolü (1: aç, 0: kapat)
    output reg heater_on_seq,      // Isıtıcı durumu (1: açık, 0: kapalı - durum makinesi)
    output heater_on_comb          // Kombinasyonel ısıtıcı kontrolü
);

    // Kombinasyonel kontrol
    assign heater_on_comb = manual_heater || (temp < target_temp_low);

    // Durum makinesi için durum tanımları
    typedef enum logic [1:0] {
        IDLE          = 2'b00,
        CHECK_TEMP    = 2'b01,
        DONE          = 2'b10
    } state_t;

    state_t current_state, next_state;

    // Durum geçişleri
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // Durumlara göre işlemler ve bir sonraki durumun belirlenmesi
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            heater_on_seq <= 1'b0;
        end else begin
            case (current_state)
                IDLE: begin
                    heater_on_seq <= 1'b0;
                    next_state <= CHECK_TEMP;
                end

                CHECK_TEMP: begin
                    if (manual_heater || (temp < target_temp_low)) begin
                        heater_on_seq <= 1'b1;
                    end else begin
                        heater_on_seq <= 1'b0;
                    end
                    next_state <= DONE;
                end

                DONE: begin
                    next_state <= IDLE; // Döngüsel tekrar için
                end

                default: begin
                    next_state <= IDLE;
                end
            endcase
        end
    end

endmodule

// Test Bench
testbench_heating_system_control;
    reg clk;
    reg reset;
    reg [7:0] temp;
    reg [7:0] target_temp_low;
    reg [7:0] target_temp_high;
    reg manual_heater;
    wire heater_on_seq;
    wire heater_on_comb;

    // Modül örnekleme
    heating_system_control uut (
        .clk(clk),
        .reset(reset),
        .temp(temp),
        .target_temp_low(target_temp_low),
        .target_temp_high(target_temp_high),
        .manual_heater(manual_heater),
        .heater_on_seq(heater_on_seq),
        .heater_on_comb(heater_on_comb)
    );

    // Saat sinyali üretilmesi
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 birimlik periyot
    end

    // Test işlemleri
    initial begin
        $monitor($time, " temp=%d target_temp_low=%d target_temp_high=%d manual_heater=%b heater_on_seq=%b heater_on_comb=%b", 
                 temp, target_temp_low, target_temp_high, manual_heater, heater_on_seq, heater_on_comb);

        // Başlangıç durumu
        reset = 1;
        temp = 8'd20;
        target_temp_low = 8'd18;
        target_temp_high = 8'd25;
        manual_heater = 0;
        #10 reset = 0;

        // Manuel ısıtıcı açma
        manual_heater = 1;
        #10;

        // Sıcaklık hedefin altında
        manual_heater = 0;
        temp = 8'd15;
        #10;

        // Sıcaklık hedefin üstünde
        temp = 8'd30;
        #10;

        // Test bitişi
        $finish;
    end

endmodule

## SAFETY SYSTEM

// Birleşik Güvenlik Sistemi

module SafetySystem (
    input clk,                     // Saat sinyali
    input reset,                   // Reset sinyali
    input wire motion_sensor,      // Hareket algılayıcı sinyali (1: hareket var, 0: hareket yok)
    input wire arm_system,         // Güvenlik sistemi aktiflik sinyali (1: aktif, 0: pasif)
    output reg alarm_seq,          // Alarm sinyali (1: alarm çalıyor, 0: alarm kapalı - durum makinesi)
    output alarm_comb              // Kombinasyonel alarm kontrolü
);

    // Kombinasyonel kontrol
    assign alarm_comb = arm_system && motion_sensor;

    // Durum makinesi için durum tanımları
    typedef enum logic [1:0] {
        IDLE         = 2'b00,
        CHECK_ALARM  = 2'b01,
        DONE         = 2'b10
    } state_t;

    state_t current_state, next_state;

    // Durum geçişleri
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // Durumlara göre işlemler ve bir sonraki durumun belirlenmesi
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            alarm_seq <= 1'b0;
        end else begin
            case (current_state)
                IDLE: begin
                    alarm_seq <= 1'b0;
                    next_state <= CHECK_ALARM;
                end

                CHECK_ALARM: begin
                    if (arm_system && motion_sensor) begin
                        alarm_seq <= 1'b1;
                    end else begin
                        alarm_seq <= 1'b0;
                    end
                    next_state <= DONE;
                end

                DONE: begin
                    next_state <= IDLE; // Döngüsel tekrar için
                end

                default: begin
                    next_state <= IDLE;
                end
            endcase
        end
    end

endmodule

// Test Bench
testbench_SafetySystem;
    reg clk;
    reg reset;
    reg motion_sensor;
    reg arm_system;
    wire alarm_seq;
    wire alarm_comb;

    // Modül örnekleme
    SafetySystem uut (
        .clk(clk),
        .reset(reset),
        .motion_sensor(motion_sensor),
        .arm_system(arm_system),
        .alarm_seq(alarm_seq),
        .alarm_comb(alarm_comb)
    );

    // Saat sinyali üretilmesi
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 birimlik periyot
    end

    // Test işlemleri
    initial begin
        $monitor($time, " motion_sensor=%b arm_system=%b alarm_seq=%b alarm_comb=%b", 
                 motion_sensor, arm_system, alarm_seq, alarm_comb);

        // Başlangıç durumu
        reset = 1;
        motion_sensor = 0;
        arm_system = 0;
        #10 reset = 0;

        // Hareket algılandığında sistem aktif
        arm_system = 1;
        motion_sensor = 1;
        #10;

        // Hareket yok, sistem aktif
        motion_sensor = 0;
        #10;

        // Hareket var, sistem pasif
        arm_system = 0;
        motion_sensor = 1;
        #10;

        // Test bitişi
        $finish;
    end

endmodule



