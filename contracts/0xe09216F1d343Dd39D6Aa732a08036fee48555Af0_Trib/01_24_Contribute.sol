// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.7.0;

import './Trib.sol';
import './Genesis.sol';
import './interfaces/IVault.sol';
import './utils/MathUtils.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';

/// @title Contribute
/// @notice A capital coordination tool.
/// @author Kento Sadim
contract Contribute is ReentrancyGuard {
  using SafeMath for uint256;
  using MathUtils for uint256;
  using SafeERC20 for IERC20;

  event TokensBought(address indexed from, uint256 amountInvested, uint256 tokensMinted);
  event TokensSold(address indexed from, uint256 tokensSold, uint256 amountReceived);
  event MintAndBurn(uint256 reserveAmount, uint256 tokensBurned);
  event InterestClaimed(address indexed from, uint256 initerestAmount);

  /// @notice A 10% tax is applied to every purchase or sale of tokens.
  uint256 public constant TAX = 10;

  /// @notice The slope of the bonding curve.
  uint256 public constant DIVIDER = 1000000; // 1 / multiplier 0.000001 (so that we don't deal with decimals)

  /// @notice Address in which tokens are sent to be burned.
  /// These tokens can't be redeemed by the reserve.
  address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

  /// @notice Trib token instance.
  Trib public token;

  /// @notice Genesis Mint Event contract instance.
  Genesis public genesis;

  /// @notice Token price at the Genesis Mint Event.
  uint256 public genesisAveragePrice;

  /// @notice Total funds invested in the Genesis Mint Event.
  uint256 public genesisReserve;

  /// @notice Total interests earned since the contract deployment.
  uint256 public totalInterestClaimed;

  /// @notice Total reserve value that backs all tokens in circulation.
  /// @dev Area below the bonding curve.
  uint256 public totalReserve;

  /// @notice mUSD reserve instance.
  /// ropsten - 0x4E1000616990D83e56f4b5fC6CC8602DcfD20459
  /// mainnet - 0xe2f2a5C287993345a840Db3B0845fbC70f5935a5
  address public reserve;

  /// @notice Interface for integration with lending platform.
  address public vault;

  /// @notice Current state of the application.
  /// GME is either open (true) or finished (false).
  bool public GME = true;

  modifier onlyGenesis() {
    require(msg.sender == address(genesis), 'Genesis contract only');
    _;
  }

  modifier GMEOpen() {
    require(GME, 'Genesis Mint Event is over');
    _;
  }

  modifier GMEOver() {
    require(!GME, 'Genesis Mint Event is not over');
    _;
  }

  constructor(address _vault, uint256 _endTime) public {
    vault = _vault;
    reserve = IVault(vault).reserve();
    token = new Trib(address(this));
    genesis = new Genesis(reserve, address(this), _endTime);
    _approveMax(reserve, vault);
  }

  /// @notice Invests funds contributed in the Genesis Mint Event.
  /// @dev Updates average price on each investment.
  /// @param contributedAmount Total value in reserve to exchange for tokens.
  function genesisInvest(uint256 contributedAmount) external onlyGenesis GMEOpen {
    genesisReserve = genesisReserve.add(contributedAmount);
    _invest(contributedAmount);
    genesisAveragePrice = genesisReserve.mul(1e18).div(genesis.totalTokenBalance());
  }

  /// @notice Concludes the Genesis Mint Event.
  /// @dev Can only be called by the Genesis Contract after the GME is over.
  function concludeGME() external onlyGenesis GMEOpen {
    GME = false;
  }

  /// @notice Exchanges reserve to tokens according to the bonding curve formula.
  /// @dev Amount to be invested needs to be approved first.
  /// @param reserveAmount Value in wei that will be exchanged to tokens.
  function invest(uint256 reserveAmount) external GMEOver {
    _invest(reserveAmount);
  }

  /// @notice Exchanges token for reserve according to the bonding curve formula.
  /// @param tokenAmount Token value in wei that will be exchanged to reserve
  function sell(uint256 tokenAmount) external GMEOver {
    _sell(tokenAmount);
  }

  /// @notice Sells the maximum amount of tokens required to claim the most interest.
  function claimInterest() external GMEOver {
    uint256 totalToClaim = token.balanceOf(msg.sender) < totalClaimRequired()
      ? token.balanceOf(msg.sender)
      : totalClaimRequired();
    _sell(totalToClaim);
  }

  /// @notice Calculates the amount of tokens required to claim the outstanding interest.
  /// @return Amount of tokens required to claim all the outstanding interest.
  function totalClaimRequired() public view returns (uint256) {
    return _calculateClaimRequired(getInterest());
  }

  /// @notice Calculates the amount of tokens required to claim a specific interest amount.
  /// @param amountToClaim Interest amount to be claimed.
  /// @return Amount of tokens required to claim all specified interest.
  function claimRequired(uint256 amountToClaim) public view returns (uint256) {
    return _calculateClaimRequired(amountToClaim);
  }

  /// @notice Total amount that has been paid in Taxes
  /// and is now forever locked in the protocol.
  function totalContributed() external view returns (uint256) {
    return _calculateReserveFromSupply(getBurnedTokensAmount());
  }

  /// @notice Total outstanding interest accumulated.
  /// @return Interest in reserve accumulated in lending protocol.
  function getInterest() public view returns (uint256) {
    uint256 vaultBalance = IVault(vault).getBalance();
    // Sometimes mStable returns a value lower than the
    // deposit because their exchange rate gets updated after the deposit.
    if (vaultBalance < totalReserve) {
      vaultBalance = totalReserve;
    }
    return vaultBalance.sub(totalReserve);
  }

  /// @notice Total supply of tokens. This includes burned tokens.
  /// @return Total supply of token in wei.
  function getTotalSupply() public view returns (uint256) {
    return token.totalSupply();
  }

  /// @notice Total tokens that have been burned.
  /// @dev These tokens are still in circulation therefore they
  /// are still considered on the bonding curve formula.
  /// @return Total burned token amount in wei.
  function getBurnedTokensAmount() public view returns (uint256) {
    return token.balanceOf(BURN_ADDRESS);
  }

  /// @notice Token's price in wei according to the bonding curve formula.
  /// @return Current token price in wei.
  function getCurrentTokenPrice() external view returns (uint256) {
    // price = supply * multiplier
    return getTotalSupply().roundedDiv(DIVIDER);
  }

  /// @notice Calculates the amount of tokens in exchange for reserve after applying the 10% tax.
  /// @param reserveAmount Reserve value in wei to use in the conversion.
  /// @return Token amount in wei after the 10% tax has been applied.
  function getReserveToTokensTaxed(uint256 reserveAmount) external view returns (uint256) {
    if (reserveAmount == 0) {
      return 0;
    }
    uint256 fee = SafeMath.div(reserveAmount, TAX);
    uint256 totalTokens = getReserveToTokens(reserveAmount);
    uint256 taxedTokens = getReserveToTokens(fee);
    return totalTokens.sub(taxedTokens);
  }

  /// @notice Calculates the amount of reserve in exchange for tokens after applying the 10% tax.
  /// @param tokenAmount Token value in wei to use in the conversion.
  /// @return Reserve amount in wei after the 10% tax has been applied.
  function getTokensToReserveTaxed(uint256 tokenAmount) external view returns (uint256) {
    if (tokenAmount == 0) {
      return 0;
    }
    uint256 reserveAmount = getTokensToReserve(tokenAmount);
    uint256 fee = SafeMath.div(reserveAmount, TAX);
    return SafeMath.sub(reserveAmount, fee);
  }

  /// @notice Calculates the amount of tokens in exchange for reserve.
  /// @param reserveAmount Reserve value in wei to use in the conversion.
  /// @return Token amount in wei.
  function getReserveToTokens(uint256 reserveAmount) public view returns (uint256) {
    return _calculateReserveToTokens(reserveAmount, totalReserve, getTotalSupply());
  }

  /// @notice Calculates the amount of reserve in exchange for tokens.
  /// @param tokenAmount Token value in wei to use in the conversion.
  /// @return Reserve amount in wei.
  function getTokensToReserve(uint256 tokenAmount) public view returns (uint256) {
    return _calculateTokensToReserve(tokenAmount, getTotalSupply(), totalReserve);
  }

  /// @notice Worker function that exchanges reserve to tokens.
  /// Extracts 10% fee from the reserve supplied and exchanges the rest to tokens.
  /// Total amount is then sent to the lending protocol so it can start earning interest.
  /// @dev User must approve the reserve to be spent before investing.
  /// @param _reserveAmount Total reserve value in wei to be exchanged to tokens.
  function _invest(uint256 _reserveAmount) internal nonReentrant {
    uint256 fee = SafeMath.div(_reserveAmount, TAX);
    require(fee >= 1, 'Transaction amount not sufficient to pay fee');

    uint256 totalTokens = getReserveToTokens(_reserveAmount);
    uint256 taxedTokens = getReserveToTokens(fee);
    uint256 userTokens = totalTokens.sub(taxedTokens);

    require(taxedTokens > 0, 'This is not enough to buy a token');

    IERC20(reserve).safeTransferFrom(msg.sender, address(this), _reserveAmount);

    if (IERC20(reserve).allowance(address(this), vault) < _reserveAmount) {
      _approveMax(reserve, vault);
    }

    IVault(vault).deposit(_reserveAmount);

    totalReserve = SafeMath.add(totalReserve, _reserveAmount);

    token.mint(BURN_ADDRESS, taxedTokens);
    token.mint(msg.sender, userTokens);

    emit TokensBought(msg.sender, _reserveAmount, userTokens);
    emit MintAndBurn(fee, taxedTokens);
  }

  /// @notice Worker function that exchanges token for reserve.
  /// Tokens are decreased from the total supply according to the bonding curve formula.
  /// A 10% tax is applied to the reserve amount. 90% is retrieved
  /// from the lending protocol and sent to the user and 10% is used to mint and burn tokens.
  /// @param _tokenAmount Token value in wei that will be exchanged to reserve.
  function _sell(uint256 _tokenAmount) internal nonReentrant {
    require(_tokenAmount <= token.balanceOf(msg.sender), 'Insuficcient balance');
    require(_tokenAmount > 0, 'Must sell something');

    uint256 reserveAmount = getTokensToReserve(_tokenAmount);
    uint256 fee = SafeMath.div(reserveAmount, TAX);

    require(fee >= 1, 'Must pay minimum fee');

    uint256 net = SafeMath.sub(reserveAmount, fee);
    uint256 taxedTokens = _calculateReserveToTokens(
      fee,
      totalReserve.sub(reserveAmount),
      getTotalSupply().sub(_tokenAmount)
    );
    uint256 claimable = _calculateClaimableAmount(reserveAmount);
    uint256 totalClaim = net.add(claimable);

    totalReserve = SafeMath.sub(totalReserve, net);
    totalInterestClaimed = SafeMath.add(totalInterestClaimed, claimable);

    token.decreaseSupply(msg.sender, _tokenAmount);
    token.mint(BURN_ADDRESS, taxedTokens);

    IVault(vault).redeem(totalClaim);
    IERC20(reserve).safeTransfer(msg.sender, totalClaim);

    emit TokensSold(msg.sender, _tokenAmount, net);
    emit MintAndBurn(fee, taxedTokens);
    emit InterestClaimed(msg.sender, claimable);
  }

  function _approveMax(address tkn, address spender) internal {
    uint256 max = uint256(-1);
    IERC20(tkn).safeApprove(spender, max);
  }

  /// @notice Calculates the tokens required to claim a specific amount of interest.
  /// @param _amount The interest to be claimed.
  /// @return The amount of tokens in wei that are required to claim the interest.
  function _calculateClaimRequired(uint256 _amount) internal view returns (uint256) {
    uint256 newReserve = totalReserve.sub(_amount);
    uint256 newReserveSupply = _calculateReserveToTokens(newReserve, 0, 0);
    return getTotalSupply().sub(newReserveSupply);
  }

  /// @notice Calculates the maximum amount of interest that can be claimed
  /// given a certain value.
  /// @param _amount Value to be used in the calculation.
  /// @return The interest amount in wei that can be claimed for the given value.
  function _calculateClaimableAmount(uint256 _amount) internal view returns (uint256) {
    uint256 interest = getInterest();
    uint256 claimable = _amount > interest ? interest : _amount;
    return claimable == 0 ? 0 : claimable;
  }

  /**
   * Supply (s), reserve (r) and token price (p) are in a relationship defined by the bonding curve:
   *      p = m * s
   * The reserve equals to the area below the bonding curve
   *      r = s^2 / 2
   * The formula for the supply becomes
   *      s = sqrt(2 * r / m)
   *
   * In solidity computations, we are using divider instead of multiplier (because its an integer).
   * All values are decimals with 18 decimals (represented as uints), which needs to be compensated for in
   * multiplications and divisions
   */

  /// @notice Computes the increased supply given an amount of reserve.
  /// @param _reserveDelta The amount of reserve in wei to be used in the calculation.
  /// @param _totalReserve The current reserve state to be used in the calculation.
  /// @param _supply The current supply state to be used in the calculation.
  /// @return token amount in wei.
  function _calculateReserveToTokens(
    uint256 _reserveDelta,
    uint256 _totalReserve,
    uint256 _supply
  ) internal pure returns (uint256) {
    uint256 _reserve = _totalReserve;
    uint256 _newReserve = _reserve.add(_reserveDelta);
    // s = sqrt(2 * r / m)
    uint256 _newSupply = MathUtils.sqrt(
      _newReserve
        .mul(2)
        .mul(DIVIDER) // inverse the operation (Divider instead of multiplier)
        .mul(1e18) // compensation for the squared unit
    );

    uint256 _supplyDelta = _newSupply.sub(_supply);
    return _supplyDelta;
  }

  /// @notice Computes the decrease in reserve given an amount of tokens.
  /// @param _supplyDelta The amount of tokens in wei to be used in the calculation.
  /// @param _supply The current supply state to be used in the calculation.
  /// @param _totalReserve The current reserve state to be used in the calculation.
  /// @return Reserve amount in wei.
  function _calculateTokensToReserve(
    uint256 _supplyDelta,
    uint256 _supply,
    uint256 _totalReserve
  ) internal pure returns (uint256) {
    require(_supplyDelta <= _supply, 'Token amount must be less than the supply');

    uint256 _newSupply = _supply.sub(_supplyDelta);

    uint256 _newReserve = _calculateReserveFromSupply(_newSupply);

    uint256 _reserveDelta = _totalReserve.sub(_newReserve);

    return _reserveDelta;
  }

  /// @notice Calculates reserve given a specific supply.
  /// @param _supply The token supply in wei to be used in the calculation.
  /// @return Reserve amount in wei.
  function _calculateReserveFromSupply(uint256 _supply) internal pure returns (uint256) {
    // r = s^2 * m / 2
    uint256 _reserve = _supply
      .mul(_supply)
      .div(DIVIDER) // inverse the operation (Divider instead of multiplier)
      .div(2);

    return _reserve.roundedDiv(1e18); // correction of the squared unit
  }
}