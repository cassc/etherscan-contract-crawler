// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import './interfaces/IConditional.sol';
import './interfaces/IMultiplier.sol';
import './OKLGWithdrawable.sol';

contract OKLGDividendDistributor is OKLGWithdrawable {
  using SafeMath for uint256;

  struct Dividend {
    uint256 totalExcluded; // excluded dividend
    uint256 totalRealised;
    uint256 lastClaim; // used for boosting logic
  }

  address public shareholderToken;
  uint256 public totalSharesDeposited; // will only be actual deposited tokens without handling any reflections or otherwise
  address wrappedNative;
  IUniswapV2Router02 router;

  // used to fetch in a frontend to get full list
  // of tokens that dividends can be claimed
  address[] public tokens;
  mapping(address => bool) tokenAwareness;

  mapping(address => uint256) shareholderClaims;

  // amount of shares a user has
  mapping(address => uint256) public shares;
  // dividend information per user
  mapping(address => mapping(address => Dividend)) public dividends;

  address public boostContract;
  address public boostMultiplierContract;
  uint256 public floorBoostClaimTimeSeconds = 60 * 60 * 12;
  uint256 public ceilBoostClaimTimeSeconds = 60 * 60 * 24;

  // per token dividends
  mapping(address => uint256) public totalDividends;
  mapping(address => uint256) public totalDistributed; // to be shown in UI
  mapping(address => uint256) public dividendsPerShare;

  uint256 public constant ACC_FACTOR = 10**36;
  address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

  constructor(
    address _dexRouter,
    address _shareholderToken,
    address _wrappedNative
  ) {
    router = IUniswapV2Router02(_dexRouter);
    shareholderToken = _shareholderToken;
    wrappedNative = _wrappedNative;
  }

  function stake(address token, uint256 amount) external {
    _stake(msg.sender, token, amount, false);
  }

  function _stake(
    address shareholder,
    address token,
    uint256 amount,
    bool contractOverride
  ) private {
    if (shares[shareholder] > 0 && !contractOverride) {
      distributeDividend(token, shareholder, false);
    }

    IERC20 shareContract = IERC20(shareholderToken);
    uint256 stakeAmount = amount == 0
      ? shareContract.balanceOf(shareholder)
      : amount;

    // for compounding we will pass in this contract override flag and assume the tokens
    // received by the contract during the compounding process are already here, therefore
    // whatever the amount is passed in is what we care about and leave it at that. If a normal
    // staking though by a user, transfer tokens from the user to the contract.
    uint256 finalAmount = amount;
    if (!contractOverride) {
      uint256 shareBalanceBefore = shareContract.balanceOf(address(this));
      shareContract.transferFrom(shareholder, address(this), stakeAmount);
      finalAmount = shareContract.balanceOf(address(this)).sub(
        shareBalanceBefore
      );
    }

    totalSharesDeposited = totalSharesDeposited.add(finalAmount);
    shares[shareholder] += finalAmount;
    dividends[shareholder][token].totalExcluded = getCumulativeDividends(
      token,
      shares[shareholder]
    );
  }

  function unstake(address token, uint256 amount) external {
    require(
      shares[msg.sender] > 0 && (amount == 0 || shares[msg.sender] <= amount),
      'you can only unstake if you have some staked'
    );
    distributeDividend(token, msg.sender, false);

    IERC20 shareContract = IERC20(shareholderToken);

    // handle reflections tokens
    uint256 baseWithdrawAmount = amount == 0 ? shares[msg.sender] : amount;
    uint256 totalSharesBalance = shareContract.balanceOf(address(this)).sub(
      totalDividends[shareholderToken].sub(totalDistributed[shareholderToken])
    );
    uint256 appreciationRatio18 = totalSharesBalance.mul(10**18).div(
      totalSharesDeposited
    );
    uint256 finalWithdrawAmount = baseWithdrawAmount
      .mul(appreciationRatio18)
      .div(10**18);

    shareContract.transfer(msg.sender, finalWithdrawAmount);
    totalSharesDeposited = totalSharesDeposited.sub(baseWithdrawAmount);
    shares[msg.sender] -= baseWithdrawAmount;
    dividends[msg.sender][token].totalExcluded = getCumulativeDividends(
      token,
      shares[msg.sender]
    );
  }

  // tokenAddress == address(0) means native token
  // any other token should be ERC20 listed on DEX router provided in constructor
  //
  // NOTE: Using this function will add tokens to the core rewards/dividends to be
  // distributed to all shareholders. However, to implement boosting, the token
  // should be directly transferred to this contract. Anything above and
  // beyond the totalDividends[tokenAddress] amount will be used for boosting.
  function depositDividends(address tokenAddress, uint256 erc20DirectAmount)
    external
    payable
  {
    require(
      erc20DirectAmount > 0 || msg.value > 0,
      'value must be greater than 0'
    );
    require(
      totalSharesDeposited > 0,
      'must be shares deposited to be rewarded dividends'
    );

    if (!tokenAwareness[tokenAddress]) {
      tokenAwareness[tokenAddress] = true;
      tokens.push(tokenAddress);
    }

    IERC20 token;
    uint256 amount;
    if (tokenAddress == address(0)) {
      payable(address(this)).call{ value: msg.value }('');
      amount = msg.value;
    } else if (erc20DirectAmount > 0) {
      token = IERC20(tokenAddress);
      uint256 balanceBefore = token.balanceOf(address(this));

      token.transferFrom(msg.sender, address(this), erc20DirectAmount);

      amount = token.balanceOf(address(this)).sub(balanceBefore);
    } else {
      token = IERC20(tokenAddress);
      uint256 balanceBefore = token.balanceOf(address(this));

      address[] memory path = new address[](2);
      path[0] = wrappedNative;
      path[1] = tokenAddress;

      router.swapExactETHForTokensSupportingFeeOnTransferTokens{
        value: msg.value
      }(0, path, address(this), block.timestamp);

      amount = token.balanceOf(address(this)).sub(balanceBefore);
    }

    totalDividends[tokenAddress] = totalDividends[tokenAddress].add(amount);
    dividendsPerShare[tokenAddress] = dividendsPerShare[tokenAddress].add(
      ACC_FACTOR.mul(amount).div(totalSharesDeposited)
    );
  }

  function distributeDividend(
    address token,
    address shareholder,
    bool compound
  ) internal {
    if (shares[shareholder] == 0) {
      return;
    }

    uint256 amount = getUnpaidEarnings(token, shareholder);
    if (amount > 0) {
      totalDistributed[token] = totalDistributed[token].add(amount);
      // native transfer
      if (token == address(0)) {
        if (compound) {
          IERC20 shareToken = IERC20(shareholderToken);
          uint256 balBefore = shareToken.balanceOf(address(this));
          address[] memory path = new address[](2);
          path[0] = wrappedNative;
          path[1] = shareholderToken;
          router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
          }(0, path, address(this), block.timestamp);
          uint256 amountReceived = shareToken.balanceOf(address(this)).sub(
            balBefore
          );
          if (amountReceived > 0) {
            _stake(shareholder, token, amountReceived, true);
          }
        } else {
          payable(shareholder).call{ value: amount }('');
        }
      } else {
        IERC20(token).transfer(shareholder, amount);
      }

      _payBoostedRewards(token, shareholder);

      shareholderClaims[shareholder] = block.timestamp;
      dividends[shareholder][token].totalRealised = dividends[shareholder][
        token
      ].totalRealised.add(amount);
      dividends[shareholder][token].totalExcluded = getCumulativeDividends(
        token,
        shares[shareholder]
      );
      dividends[shareholder][token].lastClaim = block.timestamp;
    }
  }

  function _payBoostedRewards(address token, address shareholder) internal {
    bool canCurrentlyClaim = canClaimBoostedRewards(token, shareholder) &&
      eligibleForRewardBooster(shareholder);
    if (!canCurrentlyClaim) {
      return;
    }

    uint256 amount = calculateBoostRewards(token, shareholder);
    if (amount > 0) {
      if (token == address(0)) {
        payable(shareholder).call{ value: amount }('');
      } else {
        IERC20(token).transfer(shareholder, amount);
      }
    }
  }

  function claimDividend(address token, bool compound) external {
    distributeDividend(token, msg.sender, compound);
  }

  function canClaimBoostedRewards(address token, address shareholder)
    public
    view
    returns (bool)
  {
    return
      dividends[shareholder][token].lastClaim == 0 ||
      (block.timestamp >
        dividends[shareholder][token].lastClaim.add(
          floorBoostClaimTimeSeconds
        ) &&
        block.timestamp <=
        dividends[shareholder][token].lastClaim.add(ceilBoostClaimTimeSeconds));
  }

  function getDividendTokens() external view returns (address[] memory) {
    return tokens;
  }

  function getBoostMultiplier(address wallet) public view returns (uint256) {
    return
      boostMultiplierContract == address(0)
        ? 0
        : IMultiplier(boostMultiplierContract).getMultiplier(wallet);
  }

  function calculateBoostRewards(address token, address shareholder)
    public
    view
    returns (uint256)
  {
    // use the token circulating supply for boosting rewards since that's
    // how the calculation has been done thus far and we want the boosted
    // rewards to have some longevity.
    IERC20 shareToken = IERC20(shareholderToken);
    uint256 totalCirculatingShareTokens = shareToken.totalSupply() -
      shareToken.balanceOf(DEAD);
    uint256 availableBoostRewards = address(this).balance;
    if (token != address(0)) {
      availableBoostRewards = IERC20(token).balanceOf(address(this));
    }
    uint256 excluded = totalDividends[token].sub(totalDistributed[token]);
    uint256 finalAvailableBoostRewards = availableBoostRewards.sub(excluded);
    uint256 userShareBoostRewards = finalAvailableBoostRewards
      .mul(shares[shareholder])
      .div(totalCirculatingShareTokens);

    uint256 rewardsWithBooster = eligibleForRewardBooster(shareholder)
      ? userShareBoostRewards.add(
        userShareBoostRewards.mul(getBoostMultiplier(shareholder)).div(10**2)
      )
      : userShareBoostRewards;
    return
      rewardsWithBooster > finalAvailableBoostRewards
        ? finalAvailableBoostRewards
        : rewardsWithBooster;
  }

  function eligibleForRewardBooster(address shareholder)
    public
    view
    returns (bool)
  {
    return
      boostContract != address(0) &&
      IConditional(boostContract).passesTest(shareholder);
  }

  // returns the unpaid earnings
  function getUnpaidEarnings(address token, address shareholder)
    public
    view
    returns (uint256)
  {
    if (shares[shareholder] == 0) {
      return 0;
    }

    uint256 earnedDividends = getCumulativeDividends(
      token,
      shares[shareholder]
    );
    uint256 dividendsExcluded = dividends[shareholder][token].totalExcluded;
    if (earnedDividends <= dividendsExcluded) {
      return 0;
    }

    return earnedDividends.sub(dividendsExcluded);
  }

  function getCumulativeDividends(address token, uint256 share)
    internal
    view
    returns (uint256)
  {
    return share.mul(dividendsPerShare[token]).div(ACC_FACTOR);
  }

  function setShareholderToken(address _token) external onlyOwner {
    shareholderToken = _token;
  }

  function setBoostClaimTimeInfo(uint256 floor, uint256 ceil)
    external
    onlyOwner
  {
    floorBoostClaimTimeSeconds = floor;
    ceilBoostClaimTimeSeconds = ceil;
  }

  function setBoostContract(address _contract) external onlyOwner {
    if (_contract != address(0)) {
      IConditional _contCheck = IConditional(_contract);
      // allow setting to zero address to effectively turn off check logic
      require(
        _contCheck.passesTest(address(0)) == true ||
          _contCheck.passesTest(address(0)) == false,
        'contract does not implement interface'
      );
    }
    boostContract = _contract;
  }

  function setBoostMultiplierContract(address _contract) external onlyOwner {
    if (_contract != address(0)) {
      IMultiplier _contCheck = IMultiplier(_contract);
      // allow setting to zero address to effectively turn off check logic
      require(
        _contCheck.getMultiplier(address(0)) >= 0,
        'contract does not implement interface'
      );
    }
    boostMultiplierContract = _contract;
  }

  receive() external payable {}
}