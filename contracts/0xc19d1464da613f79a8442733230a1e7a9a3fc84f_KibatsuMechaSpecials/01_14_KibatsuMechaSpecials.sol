// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/*
                          .-=*#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#*+=:
                      :+#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*-
                   :+%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#=
                .+%@@@@@@@@@@@@%#*++==================================++*#%@@@@@@@@@@@@@#-
               [email protected]@@@@@@@@@@*=:                                              :=*@@@@@@@@@@@%.
             :%@@@@@@@@@*:                                                      :*@@@@@@@@@@+
            [email protected]@@@@@@@@+                                                           .*@@@@@@@@@%.
           *@@@@@@@@+.                                                              [email protected]@@@@@@@@-
          #@@@@@@@#.                                                                  .#@@@@@@@@-
         [email protected]@@@@@@*                                                                      *@@@@@@@@
        [email protected]@@@@@@*                                                                        *@@@@@@@=
        [email protected]@@@@@%                                                                          %@@@@@@#
        %@@@@@@=                                                                          [email protected]@@@@@@
        @@@@@@@:                                                                          :@@@@@@@
        @@@@@@@.              :#####.                                .#####.              [email protected]@@@@@@
        @@@@@@@.              :@@@@@.                                :@@@@@:              [email protected]@@@@@@
        @@@@@@@.              :%%%%@#***:                        :***#@%%%%:              [email protected]@@@@@@
        @@@@@@@.                   #@@@@-                        [email protected]@@@#                   [email protected]@@@@@@
        @@@@@@@.                   #@@@@*====                ====*@@@@#                   [email protected]@@@@@@
        @@@@@@@.                       [email protected]@@@@                @@@@@+                       [email protected]@@@@@@
        @@@@@@@.                       [email protected]@@@@                @@@@@+                       [email protected]@@@@@@
        @@@@@@@.                       .:::::                :::::.                       [email protected]@@@@@@
        @@@@@@@.                                                                          [email protected]@@@@@@
        @@@@@@@.                                                                          [email protected]@@@@@@
        @@@@@@@.                           -##################                            [email protected]@@@@@@
        @@@@@@@.                           [email protected]@@@@@@@@@@@@@@@@@                            [email protected]@@@@@@
        @@@@@@@.                       ++++#@%%%%%%%%%%%%%%%%@++++-                       [email protected]@@@@@@
        @@@@@@@.                      [email protected]@@@@+                @@@@@*                       [email protected]@@@@@@
        @@@@@@@.                  [email protected]@@@@+                @@@@@#---:                   [email protected]@@@@@@
        @@@@@@@.                  [email protected]@@@%....                 [email protected]@@@@                   [email protected]@@@@@@
        @@@@@@@.                  [email protected]@@@#                         :@@@@@                   [email protected]@@@@@@
        @@@@@@@:                   ::::.                          ::::.                   :@@@@@@@
        %@@@@@@=                                                                          [email protected]@@@@@@
        *@@@@@@%                                                                          %@@@@@@#
        :@@@@@@@*                                                                        *@@@@@@@=
         *@@@@@@@*                                                                      *@@@@@@@@.
          @@@@@@@@#.                                                                  .#@@@@@@@@=
          .%@@@@@@@@+.                                                              [email protected]@@@@@@@@=
            #@@@@@@@@@+                                                           .*@@@@@@@@@@-
             [email protected]@@@@@@@@@*:                                                      :*@@@@@@@@@@#.
              .#@@@@@@@@@@@*=:                                              :=*@@@@@@@@@@@@=
                -#@@@@@@@@@@@@@%#*++==================================++*#%@@@@@@@@@@@@@@+.
                  .=%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*:
                     .=%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%+:
                         .-=+*#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#*+=:.

*/

import "@mikker/contracts/contracts/GenericCollection.sol";

contract KibatsuMechaSpecials is GenericCollection {
  constructor(string memory contractURI, address royalties)
    GenericCollection(
      "Kibatsu Mecha Specials",
      "KIBATSUSPECIALS",
      contractURI,
      royalties,
      750
    )
  {}
}