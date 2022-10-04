// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "@violetprotocol/erc721extendable/contracts/extensions/metadata/setTokenURI/ISetTokenURILogic.sol";
import "../EAT/AccessTokenConsumerExtension.sol";
import "./IHumanboundMintLogic.sol";
import "../refund/IGasRefundLogic.sol";

contract HumanboundMintLogic is HumanboundMintExtension, Mint, AccessTokenConsumerExtension {
    function mint(
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 expiry,
        address to,
        uint256 tokenId,
        string calldata tokenURI
    ) public override requiresAuth(v, r, s, expiry) {
        _mint(to, tokenId);
        if (bytes(tokenURI).length > 0) ISetTokenURILogic(address(this))._setTokenURI(tokenId, tokenURI);

        emit Minted(to, tokenId);

        // refund the cost of entire transaction
        // gas steps 228306 includes the minting and the refund execution
        IGasRefund(address(this)).refundExecution(228306);
    }
}