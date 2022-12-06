// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@thirdweb-dev/contracts/extension/Multicall.sol";
import "@thirdweb-dev/contracts/extension/PrimarySale.sol";
import "@thirdweb-dev/contracts/lib/CurrencyTransferLib.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./Phaseable.sol";

abstract contract Droppable is Multicall, PrimarySale, Phaseable {
    /// @dev Emitted when tokens are claimed via `claim`.
    event TokensClaimed(
        address indexed claimer,
        address indexed recipient,
        uint256 startTokenId,
        uint256 quantityClaimed
    );

    constructor() {
        _setupPrimarySaleRecipient(msg.sender);
    }

    function claim(
        address _recipient,
        uint32 _quantity,
        bytes32[] calldata _proof
    ) public payable {
        require(msg.sender == tx.origin, "BOT");

        (MintPhase memory mintPhase, uint256 mintPhaseId) = verifyClaim(
            _recipient,
            _quantity,
            _proof
        );

        _beforeClaim(_recipient, _quantity, mintPhase.pricePerToken);

        uint256 totalPrice = mintPhase.pricePerToken * _quantity;
        if (totalPrice > 0) {
            require(totalPrice == msg.value, "Value sent is not correct");
        }

        // Register the claim
        _registerClaim(mintPhaseId, _recipient, _quantity);

        // Process the claim with inheriting contracts
        uint256 startTokenId = transferTokensOnClaim(_recipient, _quantity);

        CurrencyTransferLib.transferCurrency(
            CurrencyTransferLib.NATIVE_TOKEN,
            msg.sender,
            primarySaleRecipient(),
            totalPrice
        );

        emit TokensClaimed(msg.sender, _recipient, startTokenId, _quantity);

        _afterClaim(_recipient, _quantity, mintPhase.pricePerToken);
    }

    /// @dev Runs before every `claim` function call.
    function _beforeClaim(address, uint256, uint256) internal virtual {}

    /// @dev Runs after every `claim` function call.
    function _afterClaim(address, uint256, uint256) internal virtual {}

    /// @dev Function to be ovveridden by contracts to transfer or mint the tokens
    function transferTokensOnClaim(
        address _recipient,
        uint32 _quantity
    ) internal virtual returns (uint256 startTokenId);
}