// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "../interfaces/IMintableBurnableERC20.sol";
import "../interfaces/ITreasury.sol";
import "../interfaces/IPreBluejayToken.sol";

import "./MerkleDistributor.sol";

/// @title PreBluejayToken
/// @author Bluejay Core Team
/// @notice PreBluejayToken is the contract for the pBLU token. The token is a
/// non-transferable token that can be redeemed for underlying BLU tokens. The
/// redemption ratio is proportional to the current total supply of the BLU token
/// against the targeted total supply of BLU tokens. The contract allows a mimimal
/// level of tokens to be redeemed by each account for initial liquidity.
/// ie If the target supply is 50M and the current supply is 10M, users will be
/// able to redeem 1/5 of their pBLU tokens as BLU tokens.
/// @dev The pBLU token is not an ERC20 token
contract PreBluejayToken is Ownable, MerkleDistributor, IPreBluejayToken {
  uint256 constant WAD = 10**18;

  /// @notice The contract address of the treasury, for minting BLU
  ITreasury public immutable treasury;

  /// @notice The contract address of the BLU token
  IMintableBurnableERC20 public immutable BLU;

  /// @notice Target BLU total supply when all pBLU are vested, in WAD
  uint256 public immutable bluSupplyTarget;

  /// @notice Amount claimable that does not require vesting, in WAD
  uint256 public immutable vestingThreshold;

  /// @notice Flag to pause contract
  bool public paused;

  /// @notice Mapping of addresses to allocated pBLU, in WAD
  mapping(address => uint256) public quota;

  /// @notice Mapping of addresses to redeemed pBLU, in WAD
  mapping(address => uint256) public redeemed;

  /// @notice Constructor to initialize the contract
  /// @param _BLU Address of the BLU token
  /// @param _treasury Address of the treasury
  /// @param _merkleRoot Merkle root of the distribution
  /// @param _bluSupplyTarget Target BLU total supply when all pBLU are vested, in WAD
  /// @param _vestingThreshold Amount claimable that does not require vesting, in WAD
  constructor(
    address _BLU,
    address _treasury,
    bytes32 _merkleRoot,
    uint256 _bluSupplyTarget,
    uint256 _vestingThreshold
  ) {
    BLU = IMintableBurnableERC20(_BLU);
    treasury = ITreasury(_treasury);
    _setMerkleRoot(_merkleRoot);
    bluSupplyTarget = _bluSupplyTarget;
    vestingThreshold = _vestingThreshold;
    paused = true;
  }

  // =============================== PUBLIC FUNCTIONS =================================

  /// @notice Claims pBLU tokens
  /// @dev The parameters of the function should come from the merkle distribution file.
  /// @param index Index of the distribution
  /// @param account Account where the distribution is credited to
  /// @param amount Amount of pBLU allocated in the distribution, in WAD
  /// @param merkleProof Array of bytes32s representing the merkle proof of the distribution
  function claimQuota(
    uint256 index,
    address account,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) public override {
    _claim(index, account, amount, merkleProof);
    quota[account] += amount;
  }

  /// @notice Redeem BLU token against pBLU tokens
  /// @dev During redemption, the quota does not change. Instead the redeemed amount is
  /// updated to reflect amount of pBLU redeemed.
  /// @param amount Amount of BLU tokens to redeem
  /// @param recipient Address where the BLU tokens will be sent to
  function redeem(uint256 amount, address recipient) public override {
    require(!paused, "Redemption paused");
    require(
      redeemableTokens(msg.sender) >= amount,
      "Insufficient redeemable balance"
    );
    redeemed[msg.sender] += amount;
    treasury.mint(recipient, amount);
    emit Redeemed(msg.sender, recipient, amount);
  }

  // =============================== VIEW FUNCTIONS =================================

  /// @notice Gets the overall vesting progress
  /// @return progress The vesting progress, in WAD
  function vestingProgress() public view override returns (uint256) {
    uint256 bluSupply = BLU.totalSupply();
    return
      bluSupply < bluSupplyTarget ? (bluSupply * WAD) / bluSupplyTarget : WAD;
  }

  /// @notice Gets the amount of BLU that can be redeemed for a given address
  /// @param account Address to get the redeemable balance for
  /// @return redeemableAmount Amount of BLU that can be redeemed, in WAD
  function redeemableTokens(address account)
    public
    view
    override
    returns (uint256)
  {
    uint256 quotaVested = (quota[account] * vestingProgress()) / WAD;
    if (quotaVested <= vestingThreshold) {
      quotaVested = quota[account] < vestingThreshold
        ? quota[account]
        : vestingThreshold;
    }
    return quotaVested - redeemed[account];
  }

  // =============================== ADMIN FUNCTIONS =================================

  /// @notice Pause and unpause the contract
  /// @param _paused True to pause, false to unpause
  function setPause(bool _paused) public onlyOwner {
    paused = _paused;
  }

  /// @notice Set the merkle root for the distribution
  /// @dev Setting the merkle root after distribution has begun may result in unintended consequences
  /// @param _merkleRoot New merkle root of the distribution
  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    _setMerkleRoot(_merkleRoot);
    emit UpdatedMerkleRoot(_merkleRoot);
  }
}