// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title Pixelmon Interface
/// @author LiquidX
/// @notice This smart contract is the interface of Pixelmon NFT to support the evolution

interface IPixelmon is IERC721 {

    /// @notice Mints an evolved Pixelmon
    /// @param receiver Receiver of the evolved Pixelmon
    /// @param evolutionStage The evolution (2-4) that the Pixelmon is undergoing
    function mintEvolvedPixelmon(address receiver, uint evolutionStage) external;
}