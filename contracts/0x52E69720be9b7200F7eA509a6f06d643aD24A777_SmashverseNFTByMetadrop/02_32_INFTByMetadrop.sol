// SPDX-License-Identifier: MIT
// Metadrop Contracts (v0.0.1)

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface INFTByMetadrop {
  // The current status of the mint:
  //   - notEnabled: This type of mint is not part of this drop
  //   - notYetOpen: This type of mint is part of the drop, but it hasn't started yet
  //   - open: it's ready for ya, get in there.
  //   - finished: been and gone.
  //   - unknown: theoretically impossible.
  enum MintStatus {
    notEnabled,
    notYetOpen,
    open,
    finished,
    unknown
  }

  enum AllocationCheck {
    invalidListType,
    hasAllocation,
    invalidProof,
    allocationExhausted
  }

  enum BeneficiaryType {
    owner,
    epsDelegate,
    stakedOwner,
    vestedOwner,
    offChainOwner
  }

  // ============================
  // EVENTS
  // ============================
  event EPSComposeThisUpdated(address epsComposeThisAddress);
  event EPSDelegateRegisterUpdated(address epsDelegateRegisterAddress);
  event EPS_CTTurnedOn();
  event EPS_CTTurnedOff();
  event Revealed();
  event BaseContractSet(address baseContract);
  event VestingAddressSet(address vestingAddress);
  event MaxStakingDurationSet(uint16 maxStakingDurationInDays);
  event MerkleRootSet(bytes32 merkleRoot);

  // ============================
  // ERRORS
  // ============================
  error ThisIsTheBaseContract();
  error MintingIsClosedForever();
  error ThisMintIsClosed();
  error IncorrectETHPayment();
  error TransferFailed();
  error VestingAddressIsLocked();
  error MetadataIsLocked();
  error StakingDurationExceedsMaximum(
    uint256 requestedStakingDuration,
    uint256 maxStakingDuration
  );
  error MaxPublicMintAllowanceExceeded(
    uint256 requested,
    uint256 alreadyMinted,
    uint256 maxAllowance
  );
  error ProofInvalid();
  error RequestingMoreThanRemainingAllocation(
    uint256 requested,
    uint256 remainingAllocation
  );
  error baseChainOnly();
  error InvalidAddress();

  // ============================
  // FUNCTIONS
  // ============================

  function setURIs(
    string memory placeholderURI_,
    string memory arweaveURI_,
    string memory ipfsURI_
  ) external;

  function lockURIs() external;

  function switchImageSource(bool useArweave_) external;

  function setDefaultRoyalty(address recipient, uint96 fraction) external;

  function deleteDefaultRoyalty() external;

  function mint(
    uint256 quantityToMint_,
    address to_,
    uint256 vestingInDays_
  ) external;
}