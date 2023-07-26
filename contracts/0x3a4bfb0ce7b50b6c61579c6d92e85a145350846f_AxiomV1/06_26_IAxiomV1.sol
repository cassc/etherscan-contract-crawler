// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./core/IAxiomV1Verifier.sol";
import "./core/IAxiomV1Update.sol";
import "./core/IAxiomV1State.sol";
import "./core/IAxiomV1Events.sol";

/// @title The interface for the core Axiom V1 contract
/// @notice The Axiom V1 contract stores a continually updated cache of all historical block hashes
/// @dev The interface is broken up into many smaller pieces
interface IAxiomV1 is IAxiomV1Events, IAxiomV1State, IAxiomV1Update, IAxiomV1Verifier {}