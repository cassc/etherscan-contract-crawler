// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Danksgiving - 42023
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    @@@@@@@@@@@@@@@@@@@%[email protected]@:-%@@@@@@@@@@@@@@@@@@@@%@@[email protected]@@@@@@@@@@@@@@@@@@@@@@#@@@###%@@@@@@    //
//    @@@@@@@@@@@@@@@@@@#:[email protected]:[email protected]@@@@@@@@@@@@@@@@@@+.#*.....=%@@@@@@@@@@@@@@@@@@%:.%#:::::-#@@@@    //
//    @@@@@@@@@@@@@@@@@#[email protected]+::@@@=:%@@@@@@@@@@@@[email protected][email protected]@@@@@@@@@@@@@@@%:[email protected]::::::::[email protected]@@    //
//    *:[email protected]@@@@@@@@@@@@*....%#::@@*::[email protected]@@@@@@@@%+:[email protected]%%#@%@@@@@@@@@@@@:..%%:::::::::*@@    //
//    +...:#@@@@@@@@@*[email protected]+...#@::%@::[email protected]:-=-:.....#@=..*@@[email protected]*[email protected]:*@@@@%:*@#@@:.:@%:::+=::::[email protected]@    //
//    %[email protected]@@@@@@@[email protected]*[email protected]::--:[email protected]@:..:%@@@@%###%@@#[email protected]=---%@%@:[email protected]%=*%=##.%@[email protected]%::*@@====*@@    //
//    @[email protected]@@@@@@#[email protected][email protected]=::=::*@#-..=***+-:..:[email protected]%[email protected]+-.#*:%[email protected]=:+%=#*[email protected]#.:@@::%%===+*%@@    //
//    @*......*@@@%%@@-.-:[email protected]+::@@+::*@%#***#%%%-...#@.:@@@+.#*:#*:@[email protected]**[email protected]::@@::%#=*#-:[email protected]@    //
//    @%[email protected]=..:@@-::-%*.#=...*#::@@@%-:-#@*+#@@@@[email protected]+.:[email protected]#:*@::[email protected]@..*#.--*[email protected]@-:[email protected]@@@-:*@@    //
//    @@..#%...*%::::[email protected][email protected][email protected]::%@@@@+::+#:..::.....:@@...:[email protected]@@@@@@#@@*..+#[email protected]%@+::=##+::%@@    //
//    @@:[email protected]:[email protected]=##::#-:@@[email protected]@%@@@@@@@@%#@@*:.......:@@%*%@@@@@@@@@@@@@#+##..%%:[email protected]#:::::::[email protected]@@    //
//    @@:[email protected]@@@@=:*+.%@@@@@@@@@@@@@@@@@@@@%####%@@@@@*[email protected]@@@@@@@@@@@@@@@*+#@#[email protected]#-:::-*@@@@    //
//    @@=.:@=..:@@@@-:+*.%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@-..:@@@@@@@@@@@@@@@@@@@@@@%@@@@@%@@@@@@@    //
//    @@[email protected]+..:@*::::[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@#+===*@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@=..%[email protected]*:-=:-#%@@@@@@@@@@@@@#***##@@@@@@@@@%:.*:.#@@:[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@+..%*[email protected]*:+#::@@@@@@@@@@@@@+::::::::[email protected]@@@@#.:##.:@@#.......*@#%@@@@@@@@@@@@@@@@@%*[email protected]@    //
//    @@*..##..:@*:=*::@@@@@@@@@@@@%:::..::-..:-%@@#.:%@[email protected]@%.-#@=.*#=*+:@@@@@@@@@@@%*[email protected][email protected]    //
//    @@#..+#..:@*:=*::@@@@@@@@@@@@%::.::.-==:.:[email protected]@:-%@%..%#%@@@@*:%@==#+:@*=-:-=%@#=:::+#=*[email protected]    //
//    @@@[email protected]:@*:-#::@@@@@@@@@@@@@:::-:.:.:::::@=.**=.....%@@@+.%@@%++*@#..::..-%::::::@@@@[email protected]    //
//    @@@[email protected]:@*::%::@@@@@@@@@@@@@#.::==--:::+%%.:--...=#@%%@#[email protected]@@@#@@@+.:@--++::@@@@:#@    //
//    @@@+.:@:[email protected]*:-%::@@@@@@@@@@@@@@+:::[email protected]@@@@@@@[email protected]@%::%#=***+=#@*%@@@@@[email protected]#%@@#:@---:@@    //
//    @@@#.:@[email protected]#:-%::%@@@@@@@@@@@@@*:::::::@@@@@@@@#..*@@@@@@@@@@@@@@#*@@@@@+..#---:@++%:[email protected]    //
//    @@@#.:@=..#%::%::%@@@@@@@@@@@@-:.::::::*@@@@@@@:[email protected]@@@@@@#+=++#@@@@@@@@-..#+*@*[email protected]@@@@@[email protected]    //
//    @@@@[email protected][email protected]:-%::#@@@@@@@@@@@@.::.::::[email protected]@@@@@@[email protected]@@@@+....::::*@@@@#:..#@+::[email protected][email protected]@@@@#[email protected]    //
//    @@@@:[email protected]:[email protected]::*@@@@@@@@@@@*-:::::::#@@@@@@*...#@@@%+.....::.-.%@@#[email protected]@%[email protected]%-+*[email protected]:@    //
//    @@@@=.....:@::@::[email protected]@@@@@@@@@-:==:::.::[email protected]@@@@@*+*%@#+=-==--::--::.%@@:[email protected]=:-=*@[email protected]    //
//    @@@@*[email protected]:@::[email protected]@@@@@@@@@:::==-::::.*@@@@@@@@@@%[email protected]@@:.....-#@@@@@@@@@@%#@@    //
//    @@@@#[email protected]:@=:[email protected]@@@@@@@@@=::-===-::::[email protected]@@@@@@@@@-:+=:=-:=+==+%@@@=...:#@@@@@@@@@@@@@@@@    //
//    @@@@*[email protected]+:%+:[email protected]@@@@@@@@@@::::[email protected]@@@@@@@@@%=:.:=-:. [email protected]@@@%[email protected]@@@%#*%*#%#@@@@@@    //
//    @@@@*[email protected]*:==:[email protected]@@@@@@@@@@+.:::[email protected]@@@@@@@#+-:-=-+======%@@@@@@@@@@@=**+*====+%@@@@    //
//    @@@@*.....:@@[email protected]@@@@@@@@@@@::::::-===:@@@@@@@%::+%+==-====+#@@@@@@@@@@##=+++=++==++*@@@    //
//    @@@@+...:=%@@@@@@@@@@@@@@@@@@@:::.::::-=:@@@@@@@@#@@@====+=+=+*@@@@@@@@@@=+===+*++++=*@@@@    //
//    @@@@*.=#@@@@@@%@@@@@@@@@@@@@@-:.:::.:::::#@@@@@@@@@@@[email protected]@@@@@@@@@++=+=++=+=+**#@@@    //
//    @@@@@@@#@@@@@*@@@@@@@@@@@@@@@=::.:::::::::@@@@@@@@@@@[email protected]@@@@@@@@@#[email protected]@@@    //
//    @@@@@@@@#*%@@[email protected]@@@@@@@@@@@@@#+-::.::::::[email protected]@@@@@@@@@@[email protected]@@@@@@@@@#=+=++++++++%@@@@    //
//    @@@@@@@@@@#*@+%@@@@@@@@@@@+:-=+=::.:::::::@@@@@@@@@@@=+====+==*@@@@@@@@@@+=++++=++++=*@@@@    //
//    @@@@@@@@@@@##@*@@@@@@@@@@++-:-++=:::---::[email protected]@@@@@@@@@@+++=+=+==#@@@@@@@@@@#+==++++++=*@@@@@    //
//    @@@@@@@@@@@@#@[email protected]@@@@@@@*+++=-:=====++*++=+%@@@@@@@@@@*========*@@@@@@@@%@@++=+=+++=+%@@@@@    //
//    @@@@@@@@@@@@@@#@@@@@@@%=+=+==:-===--::---==+++=+=+*#@+======*==+*#*+===+=++++++=+==#@%%@@@    //
//    @@@@@@@@@@@@@@%%@@@@@@+=+==-:::====:::.:-+=====+===+=+===+=+=====+++++++==+++=+++=++++++#@    //
//    @@@@@@@@@@@@%+*-#@***-::---:::::===-:::+%##**++=+====+==+==++=+======+=+===++++++==+++**@@    //
//    @@@@@@@@@@@@**=-+=-:-=:::.::::::-===-**@@@@@@@@@@@#+++=*+====++===+++++==++++++==+++=*%@@@    //
//    @@@@@@@@@@@@@#+=--==:==:::.::::::[email protected]@@@@@@@@@@@@@%++===+=+++=====+==+====++++++++++#@@@@@    //
//    @@@@@@@@@@@@@@@++---:===:::.:::::[email protected]@@@**#%%@@%%@@@++++========*======+=======+=*%%@@@@%#@    //
//    @@@@@@@@@@@@@@::===:::===:::::::::[email protected]@@[email protected]@*+=+=:.     *[email protected]%:[email protected]@#::+    //
//    @@@@@@+%@@@@@@.::===:::-==-:::::::.#@@[email protected]@@++*=*==*++=+=======+==+=+==*@@::@@=::*    //
//    @@@@@+..#@@@@*--:::-=-:::--==---::::%@%*%%:..+#[email protected]@@@+*=++----==-:============#@@@+:%@::[email protected]    //
//    @@@@@=..:%@@#.:-=-:::-----::::======-%@@@@:[email protected]@@@@@@@@-===-::------=+==+====*@@@@@%:@+::%@    //
//    @@@@@[email protected]@@%-..:-=--::::-=-------::#@@@%[email protected]@%-*@@@@*:---:-::::::======*%@@@@@@@@:=::[email protected]@    //
//    @@@@@*[email protected]@@%@%=..:-====-=-::::::::*@@@@#..:@@-..#@@@%::::::-::::[email protected]@@@@+::[email protected]::::@@@    //
//    @@@@@*[email protected]@-.#@@@*:.:[email protected]@@@@*[email protected]%.=:[email protected]@@@*:--:-::----**[email protected]@@%::::[email protected]:::*@@@    //
//    @@@@@[email protected]@..#@@%@@%+::.:--===--*%@@@@@@[email protected][email protected]=.%@@@@%***##%#==*@@[email protected]@@=:::::@-:[email protected]@@@    //
//    @@@@@=...*@#[email protected]@=.-#@@@#+:...:[email protected]%[email protected]@@@@:..#@:[email protected][email protected]*%@@@@@@@@@++%@@@+#@@@@-:::::@-:[email protected]@@@    //
//    @@@@@-..:@@[email protected]@:[email protected]%=+*#%##**@@-:[email protected]@@@@...%@.:=..#@::##=::-%@@#[email protected]@@%+#@@@@::::::@:::#@@@    //
//    @@@@@[email protected]@:[email protected]@[email protected]+::::::::[email protected]%::*@@@@#[email protected]%..:[email protected]@@::::::::[email protected]@@*@@@@%*@@@@:::::[email protected]::::@@@    //
//    @@@@%...#@*..#@#...%@#%=::=+*%@@+::%@@@@*..:@#.#@#=#@::::::[email protected]@@#[email protected]@@[email protected]@@:::::[email protected]:#+:[email protected]@    //
//    @@@@%..:@@:..*@[email protected][email protected]=:#@@*-#@-::@@@@@[email protected]#[email protected]@[email protected]:[email protected]%#%@@@@%*==%@#[email protected]@-::%*#%:#%::[email protected]    //
//    @@@@%[email protected]*...#@:..%@@@@:[email protected]@%::@%::[email protected]@@@@[email protected]*.=%:.*@:%@@@%##*++==*+++=-=#@@-:[email protected]##%:#@=::%    //
//    @@@@#..#%:...**..=%:*@+:*@@+::=:::*@@@@@[email protected]=.....#%:#@@*-====-+===*##%@@@@:::=:-%:[email protected]*::%    //
//    @@@@#..::.+=.::.:@[email protected]@::%@@::-::::@@@@@#[email protected]=.....%%:[email protected]===%@@@#::::%@+-..%@:::::[email protected]:[email protected]@::%    //
//    @@@@[email protected][email protected]::@%::@@+:[email protected]+::[email protected]@@@@=...:@[email protected]#:[email protected]@+::#@+:::+%#:-+:-%%:::::*@::#@+:#    //
//    @@@@:[email protected]@*...:@%[email protected]*:[email protected]@::*@:::*@@@@@:[email protected]=....*@#::@@@%=::::=%@+..+++=#@::::[email protected]@-:#@%:#    //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract DANK is ERC1155Creator {
    constructor() ERC1155Creator("Danksgiving - 42023", "DANK") {}
}