// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./finance/UnwrappingRoyaltiesSplitter.sol";
import "./finance/NFTKeyRoyaltyReceiver.sol";
import "./finance/PCSNFTMarketV1RoyaltyReceiver.sol";

/// @dev Royalty splitter handling Unwrapping WBNB, NFTKey royalties and PCS claiming royalties.
contract RoyaltiesSplitterV2 is UnwrappingRoyaltiesSplitter, NFTKeyRoyaltyReceiver, PCSNFTMarketV1RoyaltyReceiver {

    constructor(
        address[] memory payees, 
        uint256[] memory shares_,
        address _wbnb,
        address _pcsNftMarketV1
    )
        UnwrappingRoyaltiesSplitter(payees, shares_, _wbnb)
        PCSNFTMarketV1RoyaltyReceiver(_pcsNftMarketV1)
    {}

    function release(address payable account) public virtual override {
        _claimRoyalties();
        super.release(account);
    }

    function releaseAll() public virtual override {
        _claimRoyalties();
        super.releaseAll();
    }

    function totalReceived() public view override returns (uint256) {
        return super.totalReceived() + _pendingRoyalties();
    }

    function pending(address account) public view override returns (uint256) {
        return ((_pendingRoyalties() * shares(account)) / totalShares()) + super.pending(account);
    }
}