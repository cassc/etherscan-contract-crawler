// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./Address.sol";
import "./TakingFee.sol";

// layout of dynamic suffix is as follows:
// 0x00 - 0x19: totalFee
// 0x20 - 0x39: resolver
// 0x40 - 0x59: token
// 0x60 - 0x79: rateBump
// 0x80 - 0x99: takingFee
// 0xa0 - 0x..: tokensAndAmounts bytes
// 0x.. - 0x..: tokensAndAmounts length in bytes
library DynamicSuffix {
    struct Data {
        uint256 totalFee;
        Address resolver;
        Address token;
        uint256 rateBump;
        TakingFee.Data takingFee;
    }

    uint256 internal constant _STATIC_DATA_SIZE = 0xa0;

    function decodeSuffix(bytes calldata cd) internal pure returns(Data calldata suffix, bytes calldata tokensAndAmounts, bytes calldata interaction) {
        assembly {
            let lengthOffset := sub(add(cd.offset, cd.length), 0x20)
            tokensAndAmounts.length := calldataload(lengthOffset)
            tokensAndAmounts.offset := sub(lengthOffset, tokensAndAmounts.length)
            suffix := sub(tokensAndAmounts.offset, _STATIC_DATA_SIZE)
            interaction.offset := add(cd.offset, 1)
            interaction.length := sub(suffix, interaction.offset)
        }
    }
}