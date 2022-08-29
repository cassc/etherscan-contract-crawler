// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Errors {
  /* Particles.sol */
  error WithdrawTransfer();
  error UnknownParticle();
  error InvalidMinter();
  error MaxSpawnMinted();
  error ParticlePropertiesMissMatch();
  error ParticleMaxSpawnCannotBeZero();
  error ParticleAlreadyExists();
  error PropertyAlreadyExists();
  error PropertyMinCannotBeBiggerMax();
  error PropertyMaxSpawnCannotBeZero();
  error ParticleValueOutOfRangeOrDoesntExist();
  error CannotBurnWhatYouDontOwn();

  /* MerkleMinter.sol */
  error NotAllowListed();
  error InsufficientFunds();
  error AlreadyMinted();
  error MintNotStarted();
}