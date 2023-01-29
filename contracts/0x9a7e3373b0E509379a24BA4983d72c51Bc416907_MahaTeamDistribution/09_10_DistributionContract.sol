// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";

/**
 * @title DistributionContract
 * @dev A simple contract that distributes tokens across investors
 */
contract DistributionContract is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event InvestorAdded(address indexed investor, uint256 allocation);
  event InvestorBlacklisted(address indexed investor);
  event WithdrawnTokens(address indexed investor, uint256 value);
  event RecoverToken(address indexed token, uint256 indexed amount);

  IERC20 public token;
  uint256 public totalAllocatedAmount;
  uint256 public initialTimestamp;
  uint256 public noOfRemaingDays;
  address[] public investors;

  struct Investor {
    bool exists;
    uint256 withdrawnTokens;
    uint256 tokensAllotment;
  }

  mapping(address => Investor) public investorsInfo;
  mapping(address => bool) public isBlacklisted;

  modifier onlyInvestor() {
    require(investorsInfo[_msgSender()].exists, "Only investors allowed");
    _;
  }

  constructor(
    address _token,
    uint256 _timestamp,
    uint256 _noOfRemaingDays,
    address _owner
  ) {
    token = IERC20(_token);
    initialTimestamp = _timestamp;
    noOfRemaingDays = _noOfRemaingDays;

    _transferOwnership(_owner);
  }

  /// @dev Adds investors. This function doesn't limit max gas consumption,
  /// so adding too many investors can cause it to reach the out-of-gas error.
  /// @param _investors The addresses of new investors.
  /// @param _tokenAllocations The amounts of the tokens that belong to each investor.
  function addInvestors(
    address[] calldata _investors,
    uint256[] calldata _tokenAllocations,
    uint256[] calldata _tokenClaimed
  ) external onlyOwner {
    require(
      _investors.length == _tokenAllocations.length,
      "different arrays sizes"
    );
    for (uint256 i = 0; i < _investors.length; i++) {
      _addInvestor(_investors[i], _tokenAllocations[i], _tokenClaimed[i]);
    }
  }

  function blacklistInvestor(address _investor) external onlyOwner {
    isBlacklisted[_investor] = true;
    emit InvestorBlacklisted(_investor);
  }

  /// @dev Adds investor. This function doesn't limit max gas consumption,
  /// so adding too many investors can cause it to reach the out-of-gas error.
  /// @param _investor The addresses of new investors.
  /// @param _tokensAllotment The amounts of the tokens that belong to each investor.
  function _addInvestor(
    address _investor,
    uint256 _tokensAllotment,
    uint256 _tokensClaimed
  ) internal onlyOwner {
    require(_investor != address(0), "invalid address");
    require(
      _tokensAllotment > 0,
      "the investor allocation must be more than 0"
    );
    Investor storage investor = investorsInfo[_investor];

    require(investor.tokensAllotment == 0, "investor already added");

    investor.tokensAllotment = _tokensAllotment;
    investor.exists = true;
    investor.withdrawnTokens = _tokensClaimed;
    investors.push(_investor);
    totalAllocatedAmount = totalAllocatedAmount.add(_tokensAllotment);
    emit InvestorAdded(_investor, _tokensAllotment);
  }

  function withdrawTokens() external onlyInvestor {
    Investor storage investor = investorsInfo[_msgSender()];
    uint256 tokensAvailable = withdrawableTokens(_msgSender());

    require(tokensAvailable > 0, "no tokens available for withdrawl");

    investor.withdrawnTokens = investor.withdrawnTokens.add(tokensAvailable);
    token.safeTransfer(_msgSender(), tokensAvailable);
    emit WithdrawnTokens(_msgSender(), tokensAvailable);
  }

  function withdrawableTokens(
    address _investor
  ) public view returns (uint256 tokens) {
    require(!isBlacklisted[_investor], "investor blacklisted");

    Investor storage investor = investorsInfo[_investor];
    uint256 availablePercentage = _calculateAvailablePercentage();
    uint256 noOfTokens = _calculatePercentage(
      investor.tokensAllotment,
      availablePercentage
    );
    uint256 tokensAvailable = noOfTokens.sub(investor.withdrawnTokens);

    return tokensAvailable;
  }

  function _calculatePercentage(
    uint256 _amount,
    uint256 _percentage
  ) private pure returns (uint256 percentage) {
    return _amount.mul(_percentage).div(100).div(1e18);
  }

  function _calculateAvailablePercentage()
    private
    view
    returns (uint256 availablePercentage)
  {
    uint256 distroDuration = initialTimestamp + (noOfRemaingDays * 1 days);
    uint256 remainingDistroPercentage = 100;
    uint256 everyDayReleasePercentage = remainingDistroPercentage.mul(1e18).div(
      noOfRemaingDays
    );

    // console.log("Every Day Release %: %s", everyDayReleasePercentage);
    uint256 currentTimeStamp = block.timestamp;

    if (currentTimeStamp > initialTimestamp) {
      if (currentTimeStamp < distroDuration) {
        uint256 _noOfDays = BokkyPooBahsDateTimeLibrary.diffDays(
          initialTimestamp,
          currentTimeStamp
        );
        // console.log("Number of days: %s", noOfRemaingDays);
        uint256 currentUnlockedPercentage = _noOfDays.mul(
          everyDayReleasePercentage
        );
        // console.log("Current Unlock %: %s", currentUnlockedPercentage);
        return currentUnlockedPercentage;
      } else {
        return uint256(100).mul(1e18);
      }
    } else {
      return uint256(0);
    }
  }

  function recoverToken(address _token, uint256 _amount) external onlyOwner {
    IERC20(_token).safeTransfer(owner(), _amount);
    emit RecoverToken(_token, _amount);
  }
}