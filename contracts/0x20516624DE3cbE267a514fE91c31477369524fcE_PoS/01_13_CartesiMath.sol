// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title CartesiMath
/// @author Felipe Argento
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

abstract contract CartesiMath {
    using SafeMath for uint256;
    mapping(uint256 => uint256) log2tableTimes1M;

    constructor() {
        log2tableTimes1M[1] = 0;
        log2tableTimes1M[2] = 1000000;
        log2tableTimes1M[3] = 1584962;
        log2tableTimes1M[4] = 2000000;
        log2tableTimes1M[5] = 2321928;
        log2tableTimes1M[6] = 2584962;
        log2tableTimes1M[7] = 2807354;
        log2tableTimes1M[8] = 3000000;
        log2tableTimes1M[9] = 3169925;
        log2tableTimes1M[10] = 3321928;
        log2tableTimes1M[11] = 3459431;
        log2tableTimes1M[12] = 3584962;
        log2tableTimes1M[13] = 3700439;
        log2tableTimes1M[14] = 3807354;
        log2tableTimes1M[15] = 3906890;
        log2tableTimes1M[16] = 4000000;
        log2tableTimes1M[17] = 4087462;
        log2tableTimes1M[18] = 4169925;
        log2tableTimes1M[19] = 4247927;
        log2tableTimes1M[20] = 4321928;
        log2tableTimes1M[21] = 4392317;
        log2tableTimes1M[22] = 4459431;
        log2tableTimes1M[23] = 4523561;
        log2tableTimes1M[24] = 4584962;
        log2tableTimes1M[25] = 4643856;
        log2tableTimes1M[26] = 4700439;
        log2tableTimes1M[27] = 4754887;
        log2tableTimes1M[28] = 4807354;
        log2tableTimes1M[29] = 4857980;
        log2tableTimes1M[30] = 4906890;
        log2tableTimes1M[31] = 4954196;
        log2tableTimes1M[32] = 5000000;
        log2tableTimes1M[33] = 5044394;
        log2tableTimes1M[34] = 5087462;
        log2tableTimes1M[35] = 5129283;
        log2tableTimes1M[36] = 5169925;
        log2tableTimes1M[37] = 5209453;
        log2tableTimes1M[38] = 5247927;
        log2tableTimes1M[39] = 5285402;
        log2tableTimes1M[40] = 5321928;
        log2tableTimes1M[41] = 5357552;
        log2tableTimes1M[42] = 5392317;
        log2tableTimes1M[43] = 5426264;
        log2tableTimes1M[44] = 5459431;
        log2tableTimes1M[45] = 5491853;
        log2tableTimes1M[46] = 5523561;
        log2tableTimes1M[47] = 5554588;
        log2tableTimes1M[48] = 5584962;
        log2tableTimes1M[49] = 5614709;
        log2tableTimes1M[50] = 5643856;
        log2tableTimes1M[51] = 5672425;
        log2tableTimes1M[52] = 5700439;
        log2tableTimes1M[53] = 5727920;
        log2tableTimes1M[54] = 5754887;
        log2tableTimes1M[55] = 5781359;
        log2tableTimes1M[56] = 5807354;
        log2tableTimes1M[57] = 5832890;
        log2tableTimes1M[58] = 5857980;
        log2tableTimes1M[59] = 5882643;
        log2tableTimes1M[60] = 5906890;
        log2tableTimes1M[61] = 5930737;
        log2tableTimes1M[62] = 5954196;
        log2tableTimes1M[63] = 5977279;
        log2tableTimes1M[64] = 6000000;
        log2tableTimes1M[65] = 6022367;
        log2tableTimes1M[66] = 6044394;
        log2tableTimes1M[67] = 6066089;
        log2tableTimes1M[68] = 6087462;
        log2tableTimes1M[69] = 6108524;
        log2tableTimes1M[70] = 6129283;
        log2tableTimes1M[71] = 6149747;
        log2tableTimes1M[72] = 6169925;
        log2tableTimes1M[73] = 6189824;
        log2tableTimes1M[74] = 6209453;
        log2tableTimes1M[75] = 6228818;
        log2tableTimes1M[76] = 6247927;
        log2tableTimes1M[77] = 6266786;
        log2tableTimes1M[78] = 6285402;
        log2tableTimes1M[79] = 6303780;
        log2tableTimes1M[80] = 6321928;
        log2tableTimes1M[81] = 6339850;
        log2tableTimes1M[82] = 6357552;
        log2tableTimes1M[83] = 6375039;
        log2tableTimes1M[84] = 6392317;
        log2tableTimes1M[85] = 6409390;
        log2tableTimes1M[86] = 6426264;
        log2tableTimes1M[87] = 6442943;
        log2tableTimes1M[88] = 6459431;
        log2tableTimes1M[89] = 6475733;
        log2tableTimes1M[90] = 6491853;
        log2tableTimes1M[91] = 6507794;
        log2tableTimes1M[92] = 6523561;
        log2tableTimes1M[93] = 6539158;
        log2tableTimes1M[94] = 6554588;
        log2tableTimes1M[95] = 6569855;
        log2tableTimes1M[96] = 6584962;
        log2tableTimes1M[97] = 6599912;
        log2tableTimes1M[98] = 6614709;
        log2tableTimes1M[99] = 6629356;
        log2tableTimes1M[100] = 6643856;
        log2tableTimes1M[101] = 6658211;
        log2tableTimes1M[102] = 6672425;
        log2tableTimes1M[103] = 6686500;
        log2tableTimes1M[104] = 6700439;
        log2tableTimes1M[105] = 6714245;
        log2tableTimes1M[106] = 6727920;
        log2tableTimes1M[107] = 6741466;
        log2tableTimes1M[108] = 6754887;
        log2tableTimes1M[109] = 6768184;
        log2tableTimes1M[110] = 6781359;
        log2tableTimes1M[111] = 6794415;
        log2tableTimes1M[112] = 6807354;
        log2tableTimes1M[113] = 6820178;
        log2tableTimes1M[114] = 6832890;
        log2tableTimes1M[115] = 6845490;
        log2tableTimes1M[116] = 6857980;
        log2tableTimes1M[117] = 6870364;
        log2tableTimes1M[118] = 6882643;
        log2tableTimes1M[119] = 6894817;
        log2tableTimes1M[120] = 6906890;
        log2tableTimes1M[121] = 6918863;
        log2tableTimes1M[122] = 6930737;
        log2tableTimes1M[123] = 6942514;
        log2tableTimes1M[124] = 6954196;
        log2tableTimes1M[125] = 6965784;
        log2tableTimes1M[126] = 6977279;
        log2tableTimes1M[127] = 6988684;
        log2tableTimes1M[128] = 7000000;
    }

    /// @notice Approximates log2 * 1M
    /// @param _num number to take log2 * 1M of
    function log2ApproxTimes1M(uint256 _num) public view returns (uint256) {
        require (_num > 0, "Number cannot be zero");
        uint256 leading = 0;

        if (_num == 1) return 0;

        while (_num > 128) {
           _num = _num >> 1;
           leading += 1;
       }
       return (leading.mul(uint256(1000000))).add(log2tableTimes1M[_num]);
    }
}