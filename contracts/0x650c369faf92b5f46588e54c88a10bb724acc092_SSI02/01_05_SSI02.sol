// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Celestial Divination Idol
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//       [email protected]@@+   *@@@   [email protected]@@+   *@@@   :@@@+   #@@@.  [email protected]@@*   *@@@   [email protected]@@+   *@@@   [email protected]@@+   *@@@.  [email protected]@@+   *@@@   :@@@*   *@@@    //
//       [email protected]@@+   *@@@.  :@@@+   *@@@.  :@@@*   *@@@.  :@@@*   *@@@.  :@@@+   *@@@   [email protected]@@+   *@@@.  :@@@*   *@@@.  :@@@*   *@@@    //
//    @@@@@@@@@@@-   @@@@@@@@@@@-   @@@@@@@@@@@:   %@@@@@@@@@@-   @@@@@@@@@@@-   @@@@@@@@@@@-   %@@@@@@@@@@-   @@@@@@@@@@@-       //
//    ###%@@@@###=:::###%@@@@###=:::###%@@@@###-:::###%@@@@###=:::###%@@@@###-:::###%@@@@###=:::###%@@@@###-:::###%@@@@###-:::    //
//       [email protected]@@+   *@@@   [email protected]@@+   *@@@   :@@@+   #@@@.  [email protected]@@*   *@@@   [email protected]@@+   *@@@   [email protected]@@+   *@@@.  [email protected]@@+   *@@@   :@@@*   *@@@    //
//        **%#---#@**   .%@@#--:=***   .***-   =***   .***-   =***   .***-   =***    ***-   =***   .%@@#---=***  :[email protected]@@#:  =***    //
//          [email protected]@@@@@      #@@@@@*                                                                    [email protected]@@@@%      #@@@@@*          //
//          [email protected]@@@@@      #@@@@@*                                                                    [email protected]@@@@%      #@@@@@*          //
//    [email protected]@@@@@......*%%%%%*                                                                    =%%%%%#......#@@@@@#......    //
//    @@@@@@@@@@@@@@@@@@@:                -===:=== -=-..==- -. -:-.  = .- =: :: :==- :- -:                [email protected]@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@:                 +#[email protected]++ %+*#:@=#=.%#+ %=  @*#. @#++*=%..*% *%*                 [email protected]@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@:                 =# [email protected]==.%-#=:@:%: -%  %*[email protected]:#[email protected]:[email protected]*:%==%+-%=%-                [email protected]@@@@@@@@@@@@@@@@@@    //
//          [email protected]@@@@@      *@@@@@*                                                 ..                 [email protected]@@@@%      #@@@@@*          //
//          [email protected]@@@@@      #@@@@@*                                                                    [email protected]@@@@%      #@@@@@*          //
//          [email protected]@@@@@      #@@@@@*                                                                    [email protected]@@@@%      #@@@@@*          //
//          .:::::=%%%%%%@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@@@%%%%%%+:::::.          //
//                [email protected]%::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::#@=                //
//     .:      := [email protected]%  --::-=::-.:-: :#+  *#. *#. =#- -#= .#* .#*  +#: +#: -#+ :#+  ##  ##  =#- :=:-:--:::.--. *@=        -#:     //
//     :@%+::+%@* [email protected]%  ====-==-==-+: .==++==  -=++==: :==++=-  ==++==. -=+++=: .==++==  ==++==. -=-==-=-=====  *@= :======*@-     //
//       [email protected]@@@=   [email protected]%  -=+=:-=-=-=+: .+*@@++  =+%@#+: :+#@%+=  [email protected]@*+. -+%@#+- :+*@@++  [email protected]@*+: :-+==:=---=++  *@= =******%@-     //
//     .#@%==%@#= [email protected]%  +=+= :* .=+-- .+*@@++. =+%@#+- -+#@%+= [email protected]@*+. =+%@%+- :+*@@++  [email protected]@#+: -===- +- -===. *@=        [email protected]     //
//     .=.    .=* [email protected]%  **==-...-*-=-   .**      =*:     :*=      **.     -*-     .*+      +*:   -*+-=:...++-+  *@= -++++++++:     //
//      :#@@@@%=  [email protected]%  ==--==--=-++-::=:=:=:-- =.==-:-= .=-:=:+:-:.-----:-=. =----=--:::-------::-=--+-=--++=  *@= #@[email protected]@=#@-     //
//     :@%-. :[email protected]# [email protected]%  =---:-:::--=-:-=----:--=---=-=---:---------=---=-=---:--=-----:=-----=----=:=:::::--=-  *@= #@. %% [email protected]     //
//     [email protected]+     @@ [email protected]%    ==  :=: ==.*:#@%=-#@%-=%@#:[email protected]@*:[email protected]@+:*@@=:#@%--%@#-=%@#:[email protected]@*:[email protected]@+:*@@=+:-=    ==  -=. *@= =+  -- :=.     //
//     [email protected]@+--=%@+ [email protected]%  [email protected]@=-+*- [email protected]@@=.*@%-:#@%:-%@*[email protected]@*[email protected]@=.*@@=:#@%-:#@#:-%@*[email protected]@[email protected]@+.*@:=+  [email protected]@--**. *@= =********:     //
//       =#%%#*:  [email protected]%  ##@@%#=:. [email protected]=:*@%-:#@#:-#@#:=%@*:[email protected]@+:[email protected]%=:*@%-:#@#--%@*:[email protected]@*[email protected]@[email protected]%#:-+ :#%@@##::  *@= [email protected]#=*@-     //
//     .========- [email protected]%    %%. +%= ==.#*@@*-#@@+-%@@==%@%[email protected]@#[email protected]@*-*@@*-#@@+-%@%[email protected]@%[email protected]@#-*@@*:+:-=   .%#  #%: *@= :+%@@#:*@:     //
//     .*****@@@# [email protected]%    ::  .:. -+.*.....--...:--..................................--:..:--...+::=    ::  .:  *@= **-.:*%#=      //
//       .=#@%+:  [email protected]%  [email protected]@:.*%= =:.*    [email protected]@-  %@@                                 :@@+  *@@:  =:-:  .:@@..#%: *@= :========.     //
//     .#@@#=---: [email protected]% [email protected]@@@@@-   +=.* :%%%@@%%%:..                               %%%@@@%%=..   =:=+ :@@@@@@.   *@= =***@%*#@-     //
//     .********+ [email protected]%    @@. *@= +=.* .++#@@#++==-                               ++#@@%++===.  =:=+   [email protected]@  %@: *@=  -+%@* [email protected]     //
//     :=      =* [email protected]%            =-.*    [email protected]@-  %@@        .------.      .------.   :@@+  *@@:  =:==            *@= #%+--%@@*      //
//     .%@+..*@@= [email protected]%    @@. *@= :..*                     [email protected]@@@@@=      [email protected]@@@@@+               =:::   [email protected]@  %@: *@= .      :+-     //
//       -#@@%=   [email protected]% [email protected]@@@@@-   ==.*    [email protected]@-  %@@        [email protected]@@@@@=      [email protected]@@@@@+   :@@+  [email protected]@:  =:-= [email protected]@@@@@.   *@=     :+%@#:     //
//     :###@@###* [email protected]%  [email protected]@-.*%= ==.* .==*@@*==+++        [email protected]@@@@@=      [email protected]@@@@@+ ==*@@#==+++.  =:==  .:@@..#%: *@= #@@@@@#.       //
//      :::::::=- [email protected]%    ::  .:. ==.* :@@@@@@@@.   =######%@@@@@@%######=::::::[email protected]@@@@@@@-     =:-+    ::  .:  *@=     .=#@#:     //
//             @% [email protected]%    #%. +%- ==.*    [email protected]@-  %@@ [email protected]@@@@@@@@@@@@@@@@@@@=          :@@+  *@@:  =:-=   .%#  #%: *@=        .=:     //
//     [email protected]% [email protected]%  ##@@%#=:. =+.*    .--.  :-- [email protected]@@@@@@@@@@@@@@@@@@@=           --.  :--   =:-+ :##@@##-:  *@= *@@@@@@@@-     //
//     .********+ [email protected]%  [email protected]@=-+*- =:.*    :**:  +** -######%@@@@@@%######=::::::.   .**-  -**.  =:-:  [email protected]@--**. *@= #@-......      //
//     :#=.       [email protected]%    --  :-. +=.*  ::[email protected]@+::*##        [email protected]@@@@@=      [email protected]@@@@@+ ::[email protected]@*::+##.  =:=+    --  --. *@= *%.            //
//      =#@#=---: [email protected]%    **. =*- +=.* :@@@@@@@@.          [email protected]@@@@@=      [email protected]@@@@@[email protected]@@@@@@@-     =:=+   .**  +*. *@= =++++++++:     //
//       -*@@%%%* [email protected]%  [email protected]@*+==: +=.*  [email protected]@+..#%#        [email protected]@@@@@=      [email protected]@@@@@+ [email protected]@*..+%%:  =:== .+*@@++==. *@= [email protected]@*++.     //
//     :@@*-      [email protected]%  [email protected]@*+==: -:.*    :**:  +** .=:-:.-=+*+*=+= ::.=.==**=*+.   .**-  =**.  =:-: .+*@@++==. *@=  :*@%#@*:      //
//     .-:-:   .- [email protected]%    +*. =*: -=.*    .::.  :::  # #+-+*++=:* #:*+:*=#=-==*+     ::.  .::   =:-=    *+  +*. *@= *@#-  .*@-     //
//      %@#@#+%@* [email protected]%    ==  -=: -=.*    [email protected]@-  %@@                                 :@@+  *@@:  =:--    ==  -=. *@= -.      ..     //
//     :@= [email protected]*-   [email protected]%  [email protected]@=-+*: =+.* :%%@@@@%%:.                               .%%@@@@%%-..   =:-+ [email protected]@=-+*. *@= *@@@@@@@@-     //
//     :@@@@@@@@# [email protected]%  **@@#*=-. ==.* .++#@@*++===                               ++*@@#++===.  =:== :*#@@#*--  *@=    .=#@%+.     //
//      ..:.....: [email protected]%    ##. +#- -=.*    [email protected]@-  #@%                                 :@@+  [email protected]@:  =::=   .##  *#: *@= .+%@#=.        //
//      *@@@+-*@# [email protected]%    ::  .:. =-.#----------------------------------------------------------*:=-    ::  ::  *@= #@@@@@@@@-     //
//     :@+ [email protected]#+:  [email protected]%  ::@@-:+#- +=.*:#@%--#@#:=%@*:[email protected]@[email protected]@+:*@%-:#@%--%@#:-%@*:[email protected]@+:[email protected]@=:*@%=+:==  :[email protected]@::##: *@=    .::.        //
//     :@%#%@###+ [email protected]% [email protected]@@@@@-   [email protected]@%-:#@%:-%@#:-%@*[email protected]@[email protected]@=:#@%-:#@#:-%@*:[email protected]@[email protected]@+.*@@=.*@:=+ :@@@@@@.   *@=  =%@@@@%-      //
//     .--------- [email protected]%    @@. *@= [email protected]:#@%-:#@#:-%@*:[email protected]@[email protected]@=:*@%=:#@#--%@#:-%@*[email protected]@[email protected]%=:*@%#:-=   [email protected]@  %@: *@= *@*:  :%@-     //
//     :#= +*  %# [email protected]%            -:.#*@@*-#@@+=%@@+=%@%[email protected]@%[email protected]@#-*@@*-#@@+=%@%==%@%[email protected]@#=*@@#-*:=:            *@= @@.    [email protected]+     //
//     :@+ #@  @% [email protected]%  ++-=-+-==:-+=::=:-:=:-: -.-::::- .--:-:=:-:.::-::::-. -:--:-:::::::::::::-+-=-====::++. *@= [email protected]%+-=*@@.     //
//     :@@%@@%%@% [email protected]%  --==-++-+=-*: .:.:.: ...:..:.:.:  .....:...:.:.:.:.:. ........ :.....:...:-====+-=+=+=  *@=  .+*##*=       //
//     .+-::::::. [email protected]%  ==== :=.:=+--   [email protected]@      *@-     [email protected]#      @@.     [email protected]+     :@%      %@-   --+-- =:.-+-=  *@= ##=.  .=#-     //
//     :@+        [email protected]%  *+==..- :===: :%%@@%%. #%@@@%= =%@@@%# .%%@@%%: *%@@@%* -%%@@%%  %%@@@%= -+==- -. =-=-  *@= .=#@%#@%+.     //
//     :@@@@@@@@# [email protected]%  +*+==-.:=====  :[email protected]@::  .:#@+:. .:[email protected]%:.  ::@@-:  .:#@*:.  :[email protected]@::  ::@@=:. -++-==.-:=+=+. *@=  -*@@%@*-      //
//     :@*.....   [email protected]%  ==------=-=+- :#*::*#. *#-:+#- -#+:-#* .#*::*#: +#=:=#+ :#*:-##  ##-:+#- :+-=::----++=  *@= #@*-  :+%-     //
//     .-:        [email protected]%  ...:.::...::. .-:  --  --  :-: :-:  --  --  :-. :-. .-: .-:  --  --  :-. ...:..:::..:.  *@= .              //
//                [email protected]@++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++%@=                //
//          :+++++*++++++%@@@@@%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#@@@@@@++++++*+++++-          //
//          [email protected]@@@@@      #@@@@@*                                                                    [email protected]@@@@%      #@@@@@*          //
//          [email protected]@@@@@      #@@@@@*                                                                    [email protected]@@@@%      #@@@@@*          //
//    ------#@@@@@@------+*****=          :- .- :==: .=  =.-. -.===  :. :- -.-: = ===. ::           -*****+------%@@@@@#------    //
//    @@@@@@@@@@@@@@@@@@@:                 *#%.*#..#+=%#[email protected]#[email protected]@  #+  %*%[email protected][email protected] ==%= +*                 [email protected]@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@:                .#+%-=%==%-=#.%@.-#[email protected] :@.#=#+-%=%=+#[email protected] =+%==##=                [email protected]@@@@@@@@@@@@@@@@@@    //
//    %%%%%%@@@@@@@%%%%%%-.....               .  ..      . .  .   .    .  ..   .. ... ....           .....:%%%%%%@@@@@@@%%%%%%    //
//          [email protected]@@@@@      #@@@@@*                                                                    [email protected]@@@@%      #@@@@@*          //
//          [email protected]@@@@@      #@@@@@*                                                                    [email protected]@@@@%      #@@@@@*          //
//          [email protected]@@@@@      #@@@@@*                                                                    [email protected]@@@@%      #@@@@@*          //
//    @@@%   [email protected]@@-   %@@#   [email protected]@@-   @@@#   [email protected]@@:   %@@%   [email protected]@@-   %@@#   [email protected]@@-   @@@%   [email protected]@@-   %@@#   [email protected]@@-   %@@#   [email protected]@@:       //
//    %%%#[email protected]@@=...%%%#[email protected]@@=...%%%#[email protected]@@-...%%%#[email protected]@@=...%%%#[email protected]@@-...%%%%[email protected]@@=...%%%#[email protected]@@-...%%%#[email protected]@@-...    //
//       [email protected]@@@@@@@@@@   [email protected]@@@@@@@@@@   :@@@@@@@@@@@.  [email protected]@@@@@@@@@@   [email protected]@@@@@@@@@@   [email protected]@@@@@@@@@@.  [email protected]@@@@@@@@@@   :@@@@@@@@@@@    //
//    :::-###%@@@%###:::-###%@@@%###:::-###%@@@%###-::-###%@@@%###:::-###%@@@%###:::-###%@@@%###:::-###%@@@%###:::-###%@@@%###    //
//    @@@%   [email protected]@@-   @@@%   [email protected]@@-   @@@#   [email protected]@@:   %@@%   [email protected]@@-   @@@%   [email protected]@@-   @@@%   [email protected]@@-   %@@%   [email protected]@@-   @@@#   [email protected]@@-       //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SSI02 is ERC721Creator {
    constructor() ERC721Creator("Celestial Divination Idol", "SSI02") {}
}