// SPDX-License-Identifier: MIT License
pragma solidity >=0.8.0 <0.9.0;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract PhunkAuctionFlywheelTest is ChainlinkClient {
    using Chainlink for Chainlink.Request;
    
    event EstimateReceived(bytes32 requestId, uint estimate);
    event EstimateRequested(bytes32 requestId);
    
    constructor(
    ) {
        setChainlinkToken(0x514910771AF9Ca656af840dff83E8264EcF986CA);
        setChainlinkOracle(0xc780c666f17F661851ee11a8730B36d0B25219F9);
    }
    
    function getAppraisalFromOracle(uint256 phunkId) internal returns (bytes32 requestId) {
        Chainlink.Request memory req = buildOperatorRequest(
            0x3531323636383165386664633466626638323361383163636135633138623431,
            this.callback.selector
        );

        req.addBytes("assetAddress", abi.encodePacked(0xf07468eAd8cf26c752C676E43C814FEe9c8CF402));
        req.addUint("tokenId", phunkId);
        req.add("pricingAsset", "ETH");

        requestId = sendOperatorRequest(req, 2.5 ether);
        emit EstimateRequested(requestId);
    }
    
    function callback(bytes32 requestId, uint estimate) external recordChainlinkFulfillment(requestId) {
        emit EstimateReceived(requestId, estimate);
    }
}