// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "contracts/OndoRegistryClient.sol";
import "contracts/interfaces/IOndoCoinlistDistributor.sol";
import "contracts/interfaces/IOndo.sol";
import "contracts/libraries/OndoLibrary.sol";
import "contracts/vendor/chainalysis/ISanctionsList.sol";

/**
 * @dev OndoCoinlistDistributor
 *
 * Distributes Ondo token to a timelocked contract
 * Users can claim drops by providing correct proofs.
 *
 * @notice Ondo governance must approve this contract to transfer tokens
 */
contract OndoCoinlistDistributor is
  IOndoCoinlistDistributor,
  OndoRegistryClient
{
  /// @notice use SafeERC20
  using SafeERC20 for IERC20;

  /// @dev Ondo token contract
  address public immutable override ondo;
  /// @dev Token multisig with Ondo to claim
  address public ondoMultisig;
  /// @dev The merkle root which will be used to verify claims
  bytes32 public override merkleRoot;
  /// @dev The investorType that claims from this contract
  IOndo.InvestorType public immutable investorType;
  /// @dev Chainalysis sanctions list
  ISanctionsList public immutable sanctionsList;
  /// @dev This is a packed array of booleans.
  mapping(uint256 => uint256) private claimedBitMap;

  constructor(
    address _ondo,
    address _ondoMultisig,
    address _registry,
    bytes32 _merkleRoot,
    IOndo.InvestorType _investorType,
    address _sanctionsList
  ) OndoRegistryClient(_registry) {
    ondo = _ondo;
    ondoMultisig = _ondoMultisig;
    merkleRoot = _merkleRoot;
    investorType = _investorType;
    sanctionsList = ISanctionsList(_sanctionsList);
  }

  /**
   * @dev Check if the user of the merkle index has claimed drops already.
   * @param index - The merkle index
   * @return true if it's claimed, otherwise false
   */
  function isClaimed(uint256 index) public view override returns (bool) {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    uint256 claimedWord = claimedBitMap[claimedWordIndex];
    uint256 mask = (1 << claimedBitIndex);
    return claimedWord & mask == mask;
  }

  /**
   * @dev Marks that the user of the merkle index has claimed drops.
   * @param index - The merkle index
   */
  function _setClaimed(uint256 index) private {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    claimedBitMap[claimedWordIndex] =
      claimedBitMap[claimedWordIndex] |
      (1 << claimedBitIndex);
  }

  /**
   * @notice Marks that the user of the merkle index has claimed drops.
   * @param _newMultisig - Address that holds Ondo to transfer to the user
   */
  function updateMultisig(address _newMultisig)
    external
    isAuthorized(OLib.GOVERNANCE_ROLE)
  {
    ondoMultisig = _newMultisig;
    emit MultiSigUpdated(_newMultisig);
  }

  /**
   * @dev Allows users to claim tokens.
   * It reverts when the user has already claimed or after terminated.
   * index, account, amount, merkleProof - all these data has been used
   * to contribute merkle tree, hence users must keep it securely and provide correct data
   * or it will fail to claim.
   *
   * @param index       - The merkle index
   * @param account     - The address of the user
   * @param amount      - The amount to be distributed to the user
   * @param merkleProof - The merkle proof
   */
  function claim(
    uint256 index,
    address account,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) external whenNotPaused override {
    require(msg.sender == account, "Can't claim another user's tokens");
    require(!isClaimed(index), "Ondo: Drop already claimed.");
    require(
      !sanctionsList.isSanctioned(msg.sender),
      "Ondo: Account is sanctioned"
    );

    // Verify the merkle proof.
    bytes32 node = keccak256(abi.encodePacked(index, account, amount));
    require(
      MerkleProof.verify(merkleProof, merkleRoot, node),
      "Ondo: Invalid proof."
    );

    // Mark address as claimed
    _setClaimed(index);

    // Set tranche balances for user
    IOndo(ondo).updateTrancheBalance(account, amount, investorType);

    IERC20(ondo).safeTransferFrom(ondoMultisig, account, amount);

    emit Claimed(index, account, amount);
  }
}