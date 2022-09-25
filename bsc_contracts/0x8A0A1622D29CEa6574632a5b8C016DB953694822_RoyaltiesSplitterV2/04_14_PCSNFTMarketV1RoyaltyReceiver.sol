// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IPCSNFTMarketV1Royalty.sol";
import "./ViewablePaymentSplitter.sol";

contract PCSNFTMarketV1RoyaltyReceiver is Ownable {

    address internal pcsNftMarketV1;

    constructor(address _pcsNftMarketV1) {
        pcsNftMarketV1 = _pcsNftMarketV1;
    }

    function setPcsNftMarketV1(address _pcsNftMarketV1) external onlyOwner {
        pcsNftMarketV1 = _pcsNftMarketV1;
    }

    function _claimRoyalties() internal {
        if (_pendingRoyalties() > 0) {
            IPCSNFTMarketV1Royalty(pcsNftMarketV1).claimPendingRevenue();
        }
    }

    function _pendingRoyalties() internal view returns (uint256) {
        if (address(pcsNftMarketV1) == address(0)) return 0;
        return IPCSNFTMarketV1Royalty(pcsNftMarketV1).pendingRevenue(address(this));
    }

}