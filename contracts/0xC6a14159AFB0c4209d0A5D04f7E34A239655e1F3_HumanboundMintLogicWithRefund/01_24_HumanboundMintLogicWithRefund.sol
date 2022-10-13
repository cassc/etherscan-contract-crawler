// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "./HumanboundMintLogic.sol";
import "../refund/IGasRefundLogic.sol";

contract HumanboundMintLogicWithRefund is HumanboundMintLogic {
    function mint(
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 expiry,
        address to,
        uint256 tokenId,
        string calldata tokenURI
    ) public override requiresAuth(v, r, s, expiry) {
        super.mint(v, r, s, expiry, to, tokenId, tokenURI);

        // refund the cost of entire transaction
        // gas steps 253756 includes the minting and the refund execution assuming max uint size
        IGasRefund(address(this)).refundExecution(253756);
    }
}