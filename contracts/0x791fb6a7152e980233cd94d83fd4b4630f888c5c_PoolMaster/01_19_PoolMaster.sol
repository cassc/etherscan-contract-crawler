// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

import '@openzeppelin/contracts/math/SafeMath.sol';
import {IERC20Ext} from '@kyber.network/utils-sc/contracts/IERC20Ext.sol';
import {ERC20, ERC20Burnable} from '@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import {
  PermissionAdmin,
  PermissionOperators
} from '@kyber.network/utils-sc/contracts/PermissionOperators.sol';
import {IKyberStaking} from '../interfaces/staking/IKyberStaking.sol';
import {IRewardsDistributor} from '../interfaces/rewardDistribution/IRewardsDistributor.sol';
import {IKyberGovernance} from '../interfaces/governance/IKyberGovernance.sol';

interface INewKNC {
  function mintWithOldKnc(uint256 amount) external;

  function oldKNC() external view returns (address);
}

interface IKyberNetworkProxy {
  function swapEtherToToken(IERC20Ext token, uint256 minConversionRate)
    external
    payable
    returns (uint256 destAmount);

  function swapTokenToToken(
    IERC20Ext src,
    uint256 srcAmount,
    IERC20Ext dest,
    uint256 minConversionRate
  ) external returns (uint256 destAmount);
}

contract PoolMaster is PermissionAdmin, PermissionOperators, ReentrancyGuard, ERC20Burnable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20Ext;
  struct Fees {
    uint256 mintFeeBps;
    uint256 claimFeeBps;
    uint256 burnFeeBps;
  }
  event FeesSet(uint256 mintFeeBps, uint256 burnFeeBps, uint256 claimFeeBps);
  enum FeeTypes {MINT, CLAIM, BURN}
  IERC20Ext internal constant ETH_ADDRESS = IERC20Ext(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
  uint256 internal constant PRECISION = (10**18);
  uint256 internal constant BPS = 10000;
  uint256 internal constant MAX_FEE_BPS = 1000; // 10%
  uint256 internal constant INITIAL_SUPPLY_MULTIPLIER = 10;
  Fees public adminFees;
  uint256 public withdrawableAdminFees;
  IKyberNetworkProxy public kyberProxy;
  IKyberStaking public immutable kyberStaking;
  IRewardsDistributor public rewardsDistributor;
  IKyberGovernance public kyberGovernance;
  IERC20Ext public immutable newKnc;
  IERC20Ext private immutable oldKnc;

  receive() external payable {}

  constructor(
    string memory _name,
    string memory _symbol,
    IKyberNetworkProxy _kyberProxy,
    IKyberStaking _kyberStaking,
    IKyberGovernance _kyberGovernance,
    IRewardsDistributor _rewardsDistributor,
    uint256 _mintFeeBps,
    uint256 _claimFeeBps,
    uint256 _burnFeeBps
  ) ERC20(_name, _symbol) PermissionAdmin(msg.sender) {
    kyberProxy = _kyberProxy;
    kyberStaking = _kyberStaking;
    kyberGovernance = _kyberGovernance;
    rewardsDistributor = _rewardsDistributor;
    address _newKnc = address(_kyberStaking.kncToken());
    newKnc = IERC20Ext(_newKnc);
    IERC20Ext _oldKnc = IERC20Ext(INewKNC(_newKnc).oldKNC());
    oldKnc = _oldKnc;
    _oldKnc.safeApprove(_newKnc, type(uint256).max);
    IERC20Ext(_newKnc).safeApprove(address(_kyberStaking), type(uint256).max);
    _changeFees(_mintFeeBps, _claimFeeBps, _burnFeeBps);
  }

  function changeKyberProxy(IKyberNetworkProxy _kyberProxy) external onlyAdmin {
    kyberProxy = _kyberProxy;
  }

  function changeRewardsDistributor(IRewardsDistributor _rewardsDistributor) external onlyAdmin {
    rewardsDistributor = _rewardsDistributor;
  }

  function changeGovernance(IKyberGovernance _kyberGovernance) external onlyAdmin {
    kyberGovernance = _kyberGovernance;
  }

  function changeFees(
    uint256 _mintFeeBps,
    uint256 _claimFeeBps,
    uint256 _burnFeeBps
  ) external onlyAdmin {
    _changeFees(_mintFeeBps, _claimFeeBps, _burnFeeBps);
  }

  function depositWithOldKnc(uint256 tokenWei) external {
    oldKnc.safeTransferFrom(msg.sender, address(this), tokenWei);
    INewKNC(address(newKnc)).mintWithOldKnc(tokenWei);
    _deposit(tokenWei, msg.sender);
  }

  function depositWithNewKnc(uint256 tokenWei) external {
    newKnc.safeTransferFrom(msg.sender, address(this), tokenWei);
    _deposit(tokenWei, msg.sender);
  }

  /*
   * @notice Called by users burning their token
   * @dev Calculates pro rata KNC and redeems from staking contract
   * @param tokensToRedeem
   */
  function withdraw(uint256 tokensToRedeemTwei) external nonReentrant {
    require(balanceOf(msg.sender) >= tokensToRedeemTwei, 'insufficient balance');
    uint256 proRataKnc = getLatestStake().mul(tokensToRedeemTwei).div(totalSupply());
    _unstake(proRataKnc);
    proRataKnc = _administerAdminFee(FeeTypes.BURN, proRataKnc);
    super._burn(msg.sender, tokensToRedeemTwei);
    newKnc.safeTransfer(msg.sender, proRataKnc);
  }

  /*
   * @notice Vote on KyberDAO campaigns
   * @dev Admin calls with relevant params for each campaign in an epoch
   * @param proposalIds: DAO proposalIds
   * @param optionBitMasks: corresponding voting options
   */
  function vote(uint256[] calldata proposalIds, uint256[] calldata optionBitMasks)
    external
    onlyOperator
  {
    require(proposalIds.length == optionBitMasks.length, 'invalid length');
    for (uint256 i = 0; i < proposalIds.length; i++) {
      kyberGovernance.submitVote(proposalIds[i], optionBitMasks[i]);
    }
  }

  /*
   * @notice Claim accumulated reward thus far
   * @notice Will apply admin fee to KNC token.
   * Admin fee for other tokens applied after liquidation to KNC
   * @dev Admin or operator calls with relevant params
   * @param cycle - sourced from Kyber API
   * @param index - sourced from Kyber API
   * @param tokens - ERC20 fee tokens
   * @param merkleProof - sourced from Kyber API
   */
  function claimReward(
    uint256 cycle,
    uint256 index,
    IERC20Ext[] calldata tokens,
    uint256[] calldata cumulativeAmounts,
    bytes32[] calldata merkleProof
  ) external onlyOperator {
    rewardsDistributor.claim(cycle, index, address(this), tokens, cumulativeAmounts, merkleProof);
    uint256 availableKnc = _administerAdminFee(FeeTypes.CLAIM, getAvailableNewKncBalanceTwei());
    _stake(availableKnc);
  }

  /*
   * @notice Will liquidate ETH or ERC20 tokens to KNC
   * @notice Will apply admin fee after liquidations
   * @notice Token allowance should have been given to proxy for liquidation
   * @dev Admin or operator calls with relevant params
   * @param tokens - ETH / ERC20 tokens to be liquidated to KNC
   * @param minRates - kyberProxy.getExpectedRate(eth/token => knc)
   */
  function liquidateTokensToKnc(IERC20Ext[] calldata tokens, uint256[] calldata minRates)
    external
    onlyOperator
  {
    require(tokens.length == minRates.length, 'unequal lengths');
    for (uint256 i = 0; i < tokens.length; i++) {
      if (tokens[i] == ETH_ADDRESS) {
        // leave 1 wei for gas optimizations
        kyberProxy.swapEtherToToken{value: address(this).balance.sub(1)}(newKnc, minRates[i]);
      } else if (tokens[i] != newKnc) {
        // token allowance should have been given
        // leave 1 twei for gas optimizations
        kyberProxy.swapTokenToToken(
          tokens[i],
          tokens[i].balanceOf(address(this)).sub(1),
          newKnc,
          minRates[i]
        );
      }
    }
    uint256 availableKnc = _administerAdminFee(FeeTypes.CLAIM, getAvailableNewKncBalanceTwei());
    _stake(availableKnc);
  }

  /*
   * @notice Called by admin on deployment for KNC
   * @dev Approves Kyber Proxy contract to trade KNC
   * @param Token to approve on proxy contract
   * @param Pass _giveAllowance as true to give max allowance, otherwise resets to zero
   */
  function approveKyberProxyContract(IERC20Ext token, bool giveAllowance) external onlyOperator {
    require(token != newKnc, 'knc not allowed');
    uint256 amount = giveAllowance ? type(uint256).max : 0;
    token.safeApprove(address(kyberProxy), amount);
  }

  function withdrawAdminFee() external onlyOperator {
    uint256 fee = withdrawableAdminFees.sub(1);
    withdrawableAdminFees = 1;
    newKnc.safeTransfer(admin, fee);
  }

  function stakeAdminFee() external onlyOperator {
    uint256 fee = withdrawableAdminFees.sub(1);
    withdrawableAdminFees = 1;
    _deposit(fee, admin);
  }

  /*
   * @notice Returns KNC balance staked to the DAO
   */
  function getLatestStake() public view returns (uint256 latestStake) {
    (latestStake, , ) = kyberStaking.getLatestStakerData(address(this));
  }

  /*
   * @notice Returns KNC balance available to stake
   */
  function getAvailableNewKncBalanceTwei() public view returns (uint256) {
    return newKnc.balanceOf(address(this)).sub(withdrawableAdminFees);
  }

  /*
   * @notice Returns fee (in basis points) depending on fee type
   */
  function getFeeRate(FeeTypes _type) public view returns (uint256) {
    if (_type == FeeTypes.MINT) return adminFees.mintFeeBps;
    else if (_type == FeeTypes.CLAIM) return adminFees.claimFeeBps;
    return adminFees.burnFeeBps;
  }

  /*
   * @notice For APY calculation, returns rate of 1 pool master token to KNC
   */
  function getProRataKnc() public view returns (uint256) {
    if (totalSupply() == 0) return 0;
    return getLatestStake().mul(PRECISION).div(totalSupply());
  }

  function _changeFees(
    uint256 _mintFeeBps,
    uint256 _claimFeeBps,
    uint256 _burnFeeBps
  ) internal {
    require(_mintFeeBps <= MAX_FEE_BPS, 'bad mint bps');
    require(_claimFeeBps <= MAX_FEE_BPS, 'bad claim bps');
    require(_burnFeeBps >= 10 && _burnFeeBps <= MAX_FEE_BPS, 'bad burn bps');
    adminFees = Fees({
      mintFeeBps: _mintFeeBps,
      claimFeeBps: _claimFeeBps,
      burnFeeBps: _burnFeeBps
    });
    emit FeesSet(_mintFeeBps, _claimFeeBps, _burnFeeBps);
  }

  /*
   * @notice returns the amount after fee deduction
   */
  function _administerAdminFee(FeeTypes _feeType, uint256 rewardAmount)
    internal
    returns (uint256)
  {
    uint256 adminFeeToDeduct = rewardAmount.mul(getFeeRate(_feeType)).div(BPS);
    withdrawableAdminFees = withdrawableAdminFees.add(adminFeeToDeduct);
    return rewardAmount.sub(adminFeeToDeduct);
  }

  /*
   * @notice Calculate and stake new KNC to staking contract
   * then mints appropriate amount to user
   */
  function _deposit(uint256 tokenWei, address user) internal {
    uint256 balanceBefore = getLatestStake();
    if (user != admin) _administerAdminFee(FeeTypes.MINT, tokenWei);
    uint256 depositAmount = getAvailableNewKncBalanceTwei();
    _stake(depositAmount);
    uint256 mintAmount = _calculateMintAmount(balanceBefore, depositAmount);
    return super._mint(user, mintAmount);
  }

  /*
   * @notice KyberDAO deposit
   */
  function _stake(uint256 amount) private {
    if (amount > 0) kyberStaking.deposit(amount);
  }

  /*
   * @notice KyberDAO withdraw
   */
  function _unstake(uint256 amount) private {
    kyberStaking.withdraw(amount);
  }

  /*
   * @notice Calculates proportional issuance according to KNC contribution
   * @notice Fund starts at ratio of INITIAL_SUPPLY_MULTIPLIER/1 == token supply/ KNC balance
   * and approaches 1/1 as rewards accrue in KNC
   * @param kncBalanceBefore used to determine ratio of incremental to current KNC
   */
  function _calculateMintAmount(uint256 kncBalanceBefore, uint256 depositAmount)
    private
    view
    returns (uint256 mintAmount)
  {
    uint256 totalSupply = totalSupply();
    if (totalSupply == 0)
      return (kncBalanceBefore.add(depositAmount)).mul(INITIAL_SUPPLY_MULTIPLIER);
    mintAmount = depositAmount.mul(totalSupply).div(kncBalanceBefore);
  }
}