// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/mixins/nftMarket/NFTMarketAuction.sol";

contract $NFTMarketAuction is NFTMarketAuction {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event $_getNextAndIncrementAuctionId_Returned(uint256 arg0);

    constructor() {}

    function $_initializeNFTMarketAuction() external {
        return super._initializeNFTMarketAuction();
    }

    function $_getNextAndIncrementAuctionId() external returns (uint256) {
        (uint256 ret0) = super._getNextAndIncrementAuctionId();
        emit $_getNextAndIncrementAuctionId_Returned(ret0);
        return (ret0);
    }

    function $_disableInitializers() external {
        return super._disableInitializers();
    }

    function $_getInitializedVersion() external view returns (uint8) {
        return super._getInitializedVersion();
    }

    function $_isInitializing() external view returns (bool) {
        return super._isInitializing();
    }

    receive() external payable {}
}