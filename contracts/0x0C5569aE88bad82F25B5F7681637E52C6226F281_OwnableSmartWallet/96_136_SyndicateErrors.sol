pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

error ZeroAddress();
error EmptyArray();
error InconsistentArrayLengths();
error InvalidBLSPubKey();
error InvalidNumberOfCollateralizedOwners();
error KnotSlashed();
error FreeFloatingStakeAmountTooSmall();
error KnotIsNotRegisteredWithSyndicate();
error NotPriorityStaker();
error KnotIsFullyStakedWithFreeFloatingSlotTokens();
error InvalidStakeAmount();
error KnotIsNotAssociatedWithAStakeHouse();
error UnableToStakeFreeFloatingSlot();
error NothingStaked();
error TransferFailed();
error NotCollateralizedOwnerAtIndex();
error InactiveKnot();
error DuplicateArrayElements();
error KnotIsAlreadyRegistered();
error KnotHasAlreadyBeenDeRegistered();
error NotKickedFromBeaconChain();