// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

error TradingAlreadyDisabled();
error IncorrectPayment();
error ArrayLengthMismatch(uint256 length1, uint256 length2);
error LayerNotBoundToTokenId();
error DuplicateActiveLayers();
error MultipleVariationsEnabled();
error InvalidLayer(uint256 layer);
error BadDistributions();
error NotOwner();
error BatchNotRevealed();
error LayerAlreadyBound();
error CannotBindBase();
error OnlyBase();
error InvalidLayerType();
error MaxSupply();
error MaxRandomness();
error OnlyCoordinatorCanFulfill(address have, address want);
error UnsafeReveal();
error NoActiveLayers();
error InvalidInitialization();
error NumRandomBatchesMustBePowerOfTwo();
error NumRandomBatchesMustBeGreaterThanOne();
error NumRandomBatchesMustBeLessThanOrEqualTo16();
error RevealPending();
error NoBatchesToReveal();