// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {ReentrancyGuard} from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {MerkleProof} from '@openzeppelin/contracts/cryptography/MerkleProof.sol';
import {Utils} from '@kyber.network/utils-sc/contracts/Utils.sol';
import {PermissionAdmin} from '@kyber.network/utils-sc/contracts/PermissionAdmin.sol';
import {IPool} from '../interfaces/liquidation/IPool.sol';
import {IERC20Ext, IRewardsDistributor} from '../interfaces/rewardDistribution/IRewardsDistributor.sol';


/**
 * @title Rewards Distributor contract for Kyber 3.0
 * - For users to claim allocated rewards for various KyberDAO program initiatives
 * (Eg. liquidity mining, staking rewards etc) in multiple tokens
 * Reward amounts for each user are generated off-chain and merklized by the Kyber team.
 * The admin (presumably the daoOperator) updates the reward amounts by submitting
 * the merkle root of a new cycle.
 **/
contract RewardsDistributor is IRewardsDistributor, PermissionAdmin, ReentrancyGuard, Utils {
  using SafeERC20 for IERC20Ext;
  using SafeMath for uint256;

  struct MerkleData {
    uint256 cycle;
    bytes32 root;
    string contentHash;
  }

  MerkleData private merkleData;
  // wallet => token => claimedAmount
  mapping(address => mapping(IERC20Ext => uint256)) public claimedAmounts;

  event RootUpdated(uint256 indexed cycle, bytes32 root, string contentHash);

  constructor(address admin) PermissionAdmin(admin) {}

  receive() external payable {}

  function getMerkleData() external view returns (MerkleData memory) {
    return merkleData;
  }

  /** 
   * @dev Claim accumulated rewards for a set of tokens at a given cycle number
   * @param cycle cycle number
   * @param index user reward info index in the array of reward info
   * during merkle tree generation
   * @param user wallet address of reward beneficiary
   * @param tokens array of tokens claimable by reward beneficiary
   * @param cumulativeAmounts cumulative token amounts claimable by reward beneficiary
   * @param merkleProof merkle proof of claim
   * @return claimAmounts actual claimed token amounts sent to the reward beneficiary
   **/
  function claim(
    uint256 cycle,
    uint256 index,
    address user,
    IERC20Ext[] calldata tokens,
    uint256[] calldata cumulativeAmounts,
    bytes32[] calldata merkleProof
  ) external override nonReentrant returns (uint256[] memory claimAmounts) {
    // verify if can claim
    require(
      isValidClaim(cycle, index, user, tokens, cumulativeAmounts, merkleProof),
      'invalid claim data'
    );


    claimAmounts = new uint256[](tokens.length);

    // claim each token
    for (uint256 i = 0; i < tokens.length; i++) {
      // if none claimable, skip
      if (cumulativeAmounts[i] == 0) continue;

      uint256 claimable = cumulativeAmounts[i].sub(claimedAmounts[user][tokens[i]]);
      if (claimable == 0) continue;

      claimedAmounts[user][tokens[i]] = cumulativeAmounts[i];
      claimAmounts[i] = claimable;
      if (tokens[i] == ETH_TOKEN_ADDRESS) {
        (bool success, ) = user.call{value: claimable}('');
        require(success, 'eth transfer failed');
      } else {
        tokens[i].safeTransfer(user, claimable);
      }
    }
    emit Claimed(cycle, user, tokens, claimAmounts);
  }

  /// @notice Propose a new root and content hash, only by admin
  function proposeRoot(
    uint256 cycle,
    bytes32 root,
    string calldata contentHash
  ) external onlyAdmin {
    require(cycle == merkleData.cycle.add(1), 'incorrect cycle');

    merkleData.cycle = cycle;
    merkleData.root = root;
    merkleData.contentHash = contentHash;

    emit RootUpdated(cycle, root, contentHash);
  }

  function pullFundsFromTreasury(
    IPool treasuryPool,
    IERC20Ext[] calldata tokens,
    uint256[] calldata amounts
  )
    external
    onlyAdmin
  {
    treasuryPool.withdrawFunds(tokens, amounts, payable(address(this)));
  }

   /**
   * @dev Checks whether a claim is valid or not
   * @param cycle cycle number
   * @param index user reward info index in the array of reward info
   * during merkle tree generation
   * @param user wallet address of reward beneficiary
   * @param tokens array of tokens claimable by reward beneficiary
   * @param cumulativeAmounts cumulative token amounts claimable by reward beneficiary
   * @param merkleProof merkle proof of claim
   * @return true if valid claim, false otherwise
   **/
  function isValidClaim(
    uint256 cycle,
    uint256 index,
    address user,
    IERC20Ext[] calldata tokens,
    uint256[] calldata cumulativeAmounts,
    bytes32[] calldata merkleProof
  ) public view override returns (bool) {
    if (cycle != merkleData.cycle) return false;
    if (tokens.length != cumulativeAmounts.length) return false;
    bytes32 node = keccak256(abi.encode(cycle, index, user, tokens, cumulativeAmounts));
    return MerkleProof.verify(merkleProof, merkleData.root, node);
  }

  /** 
   * @dev Fetch accumulated claimed rewards for a set of tokens since the first cycle
   * @param user wallet address of reward beneficiary
   * @param tokens array of tokens claimed by reward beneficiary
   * @return userClaimedAmounts claimed token amounts by reward beneficiary since the first cycle
   **/
  function getClaimedAmounts(address user, IERC20Ext[] calldata tokens)
    public
    view
    override
    returns (uint256[] memory userClaimedAmounts)
  {
    userClaimedAmounts = new uint256[](tokens.length);
    for (uint256 i = 0; i < tokens.length; i++) {
      userClaimedAmounts[i] = claimedAmounts[user][tokens[i]];
    }
  }

  function encodeClaim(
    uint256 cycle,
    uint256 index,
    address account,
    IERC20Ext[] calldata tokens,
    uint256[] calldata cumulativeAmounts
  ) external pure returns (bytes memory encodedData, bytes32 encodedDataHash) {
    require(tokens.length == cumulativeAmounts.length, 'bad tokens and amounts length');
    encodedData = abi.encode(cycle, index, account, tokens, cumulativeAmounts);
    encodedDataHash = keccak256(encodedData);
  }
}