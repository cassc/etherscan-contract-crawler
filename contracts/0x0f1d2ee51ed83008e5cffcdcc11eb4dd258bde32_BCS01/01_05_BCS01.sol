// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bullish Circuit Sentimentality
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


contract BCS01 is ERC721Creator {
    constructor() ERC721Creator("Bullish Circuit Sentimentality", "BCS01") {}
}