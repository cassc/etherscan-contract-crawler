// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Honourable Vindictive Idol
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


contract SSI04 is ERC721Creator {
    constructor() ERC721Creator("Honourable Vindictive Idol", "SSI04") {}
}