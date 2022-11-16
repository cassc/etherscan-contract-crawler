// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ReservoirOracle} from "oracle/ReservoirOracle.sol";

// In order to enforce the proper payout of royalties, we need an oracle
// attesting the price of the token for which royalties are paid. It can
// be the floor price or the appraised price (or even something else).
contract PriceOracle is ReservoirOracle {
    // Constructor

    constructor(address reservoirSigner) ReservoirOracle(reservoirSigner) {}

    // Public methods

    function getPrice(
        // On-chain data
        address token,
        uint256 tokenId,
        uint256 maxAge,
        // Off-chain data
        bytes calldata offChainData
    ) external view returns (uint256) {
        // Decode the off-chain data
        ReservoirOracle.Message memory message = abi.decode(
            offChainData,
            (ReservoirOracle.Message)
        );

        // Construct the wanted message id
        bytes32 id = keccak256(
            abi.encode(
                // keccak256("CollectionPriceByToken(uint8 kind,uint256 twapSeconds,address token,uint256 tokenId)")
                0x4163bce510ba405523529cf23054a8ff50e064fa158d7a8a76df334bfcfad6ef,
                uint8(0), // PriceKind.SPOT
                uint256(0),
                token,
                tokenId
            )
        );

        // Validate the message
        if (!_verifyMessage(id, maxAge, message)) {
            revert InvalidMessage();
        }

        // Decode the message's payload
        (address currency, uint256 price) = abi.decode(
            message.payload,
            (address, uint256)
        );

        // The currency should be ETH
        if (currency != address(0)) {
            revert InvalidMessage();
        }

        return price;
    }
}