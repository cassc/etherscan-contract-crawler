//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Enums.sol";

library Rarities {
    function accessory() internal pure returns (uint16[] memory ret) {
        ret = new uint16[](7);
        ret[0] = 1200;
        ret[1] = 800;
        ret[2] = 800;
        ret[3] = 400;
        ret[4] = 400;
        ret[5] = 400;
        ret[6] = 6000;
    }

    function backaccessory() internal pure returns (uint16[] memory ret) {
        ret = new uint16[](8);
        ret[0] = 200;
        ret[1] = 1300;
        ret[2] = 800;
        ret[3] = 400;
        ret[4] = 1100;
        ret[5] = 700;
        ret[6] = 500;
        ret[7] = 5000;
    }

    function background() internal pure returns (uint16[] memory ret) {
        ret = new uint16[](23);
        ret[0] = 600;
        ret[1] = 600;
        ret[2] = 600;
        ret[3] = 600;
        ret[4] = 500;
        ret[5] = 500;
        ret[6] = 500;
        ret[7] = 500;
        ret[8] = 500;
        ret[9] = 500;
        ret[10] = 100;
        ret[11] = 100;
        ret[12] = 100;
        ret[13] = 600;
        ret[14] = 600;
        ret[15] = 600;
        ret[16] = 100;
        ret[17] = 100;
        ret[18] = 400;
        ret[19] = 400;
        ret[20] = 500;
        ret[21] = 500;
        ret[22] = 500;
    }

    function clothing() internal pure returns (uint16[] memory ret) {
        ret = new uint16[](24);
        ret[0] = 500;
        ret[1] = 500;
        ret[2] = 300;
        ret[3] = 300;
        ret[4] = 500;
        ret[5] = 400;
        ret[6] = 300;
        ret[7] = 250;
        ret[8] = 250;
        ret[9] = 500;
        ret[10] = 100;
        ret[11] = 500;
        ret[12] = 300;
        ret[13] = 500;
        ret[14] = 500;
        ret[15] = 500;
        ret[16] = 100;
        ret[17] = 400;
        ret[18] = 400;
        ret[19] = 250;
        ret[20] = 250;
        ret[21] = 250;
        ret[22] = 150;
        ret[23] = 2000;
    }

    function eyes() internal pure returns (uint16[] memory ret) {
        ret = new uint16[](32);
        ret[0] = 250;
        ret[1] = 700;
        ret[2] = 225;
        ret[3] = 350;
        ret[4] = 125;
        ret[5] = 450;
        ret[6] = 700;
        ret[7] = 700;
        ret[8] = 350;
        ret[9] = 350;
        ret[10] = 600;
        ret[11] = 450;
        ret[12] = 250;
        ret[13] = 350;
        ret[14] = 350;
        ret[15] = 225;
        ret[16] = 125;
        ret[17] = 350;
        ret[18] = 200;
        ret[19] = 200;
        ret[20] = 200;
        ret[21] = 200;
        ret[22] = 200;
        ret[23] = 200;
        ret[24] = 50;
        ret[25] = 50;
        ret[26] = 450;
        ret[27] = 450;
        ret[28] = 400;
        ret[29] = 450;
        ret[30] = 25;
        ret[31] = 25;
    }

    function fur() internal pure returns (uint16[] memory ret) {
        ret = new uint16[](16);
        ret[0] = 1100;
        ret[1] = 1100;
        ret[2] = 1100;
        ret[3] = 525;
        ret[4] = 350;
        ret[5] = 1100;
        ret[6] = 350;
        ret[7] = 1100;
        ret[8] = 1000;
        ret[9] = 525;
        ret[10] = 525;
        ret[11] = 500;
        ret[12] = 525;
        ret[13] = 100;
        ret[14] = 50;
        ret[15] = 50;
    }

    function head() internal pure returns (uint16[] memory ret) {
        ret = new uint16[](21);
        ret[0] = 200;
        ret[1] = 200;
        ret[2] = 350;
        ret[3] = 350;
        ret[4] = 350;
        ret[5] = 150;
        ret[6] = 600;
        ret[7] = 350;
        ret[8] = 350;
        ret[9] = 350;
        ret[10] = 600;
        ret[11] = 600;
        ret[12] = 600;
        ret[13] = 200;
        ret[14] = 350;
        ret[15] = 600;
        ret[16] = 600;
        ret[17] = 50;
        ret[18] = 50;
        ret[19] = 100;
        ret[20] = 3000;
    }

    function mouth() internal pure returns (uint16[] memory ret) {
        ret = new uint16[](21);
        ret[0] = 1000;
        ret[1] = 1000;
        ret[2] = 1000;
        ret[3] = 650;
        ret[4] = 1000;
        ret[5] = 900;
        ret[6] = 750;
        ret[7] = 650;
        ret[8] = 100;
        ret[9] = 50;
        ret[10] = 100;
        ret[11] = 100;
        ret[12] = 100;
        ret[13] = 100;
        ret[14] = 50;
        ret[15] = 100;
        ret[16] = 100;
        ret[17] = 600;
        ret[18] = 600;
        ret[19] = 50;
        ret[20] = 1000;
    }
}