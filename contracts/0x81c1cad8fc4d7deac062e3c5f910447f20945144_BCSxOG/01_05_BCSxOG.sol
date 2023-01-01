// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bullish Circuit Sentimentality : Gold Genesis
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


contract BCSxOG is ERC721Creator {
    constructor() ERC721Creator("Bullish Circuit Sentimentality : Gold Genesis", "BCSxOG") {}
}