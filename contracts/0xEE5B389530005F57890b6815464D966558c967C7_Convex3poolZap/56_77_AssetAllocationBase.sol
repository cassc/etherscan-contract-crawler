// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IAssetAllocation} from "contracts/common/Imports.sol";

abstract contract AssetAllocationBase is IAssetAllocation {
    function numberOfTokens() external view override returns (uint256) {
        return tokens().length;
    }

    function symbolOf(uint8 tokenIndex)
        public
        view
        override
        returns (string memory)
    {
        return tokens()[tokenIndex].symbol;
    }

    function decimalsOf(uint8 tokenIndex) public view override returns (uint8) {
        return tokens()[tokenIndex].decimals;
    }

    function addressOf(uint8 tokenIndex) public view returns (address) {
        return tokens()[tokenIndex].token;
    }

    function tokens() public view virtual override returns (TokenData[] memory);
}