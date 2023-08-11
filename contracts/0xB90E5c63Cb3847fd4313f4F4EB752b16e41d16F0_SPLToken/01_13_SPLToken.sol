// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {ERC20Capped, ERC20, IERC20} from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Pausable} from '@openzeppelin/contracts/security/Pausable.sol';
import {AggregatorV3Interface} from '../../interfaces/IAggregatorV3Interface.sol';
import {ISPLToken} from '../../interfaces/ISPLToken.sol';

/**
 * @title SPL token for launch
 * @author Splendor Network
 * @notice This contract has a system to collaterized the price
 * to wBTC taking info from Chainlink Price Feeds
 * @notice Check the prices in chainlink with  capacity to remove it
 */

contract SPLToken is ERC20Capped, Ownable, ISPLToken, Pausable {
  using SafeERC20 for IERC20;

  AggregatorV3Interface internal priceFeedWBTC;
  AggregatorV3Interface internal priceFeedCGLD;

  address public WBTC;
  address public CGLD;
  /*/////////////////////////////////
                    ERRORS           
  /////////////////////////////////*/

  error SplendorToken__NotEnoughBalance();
  error SplendorToken__FunctionPaused();

  constructor(
    address _WBTC,
    address _CGLD,
    address _priceFeedWBTC,
    address _priceFeedCGLD
  ) ERC20('SPL', 'Splendor') ERC20Capped(187_500e18) {
    WBTC = _WBTC;
    CGLD = _CGLD;
    priceFeedWBTC = AggregatorV3Interface(_priceFeedWBTC);
    priceFeedCGLD = AggregatorV3Interface(_priceFeedCGLD);
  }

  /**
   * @dev Function to buy SPL
   * @param _amount amount of SPL that the user wants buy
   * @notice We need to have Request Approve from Dapp by The User
   * @return true
   */
  function buySplendorWithWBTC(uint256 _amount) external returns (bool) {
    if (getWBTCUserBalance(_msgSender()) < _amount) {
      revert SplendorToken__NotEnoughBalance();
    }
    IERC20(WBTC).safeTransferFrom(_msgSender(), owner(), _amount);
    _mint(_msgSender(), _amount);
    emit TokenBoughtWithWBTC(_msgSender(), _amount);
    return true;
  }

  /**
   * @dev Function to buy SPL token with CGLD token
   * @param _amount spl with CGLD
   * @return true
   */
  function buySplendorWithCGLD(uint256 _amount) external returns (bool) {
    if (getCGLDUserBalance(_msgSender()) < calculatePrice(_amount)) {
      revert SplendorToken__NotEnoughBalance();
    }
    if (paused()) {
      revert SplendorToken__FunctionPaused();
    }
    IERC20(CGLD).safeTransferFrom(_msgSender(), owner(), calculatePrice(_amount));
    _mint(_msgSender(), _amount);
    emit TokenBoughtWithCGLD(_msgSender(), _amount, calculatePrice(_amount));
    return true;
  }

  /**
   * @return price calculated in CGLD of SPL cost
   * @notice Is a formula:
   * priceOfSPLInUSD(_amount) / priceOfCGLDInIUSD(1)
   */
  function calculatePrice(uint256 _amount) public view returns (uint256) {
    uint256 price = getPriceOfSPLInUSD(_amount) / getPriceOfCGLDInUSD(1);
    return price;
  }

  /*///////////////////////////////////////////////////////////////
                       ADMIN FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Function to pause some functions
   */
  function pause() external onlyOwner {
    _pause();
  }

  /*///////////////////////////////////////////////////////////////
                       CHAINLINK FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /**
   * @return price of WBTC in USD obtained from chainlink price feed
   */
  function getLatestWBTCInUSDPrice() public view returns (int256) {
    (, int256 price,,,) = priceFeedWBTC.latestRoundData();
    return price;
  }

  /**
   * @return price of CGLD in USD obtained from chainlink price feed
   */
  function getLatestCGLDInUSDPrice() public view returns (int256) {
    (, int256 price,,,) = priceFeedCGLD.latestRoundData();
    return price;
  }

  /**
   * @return price of SPL in USD
   */
  function getPriceOfSPLInUSD(uint256 _amount) public view returns (uint256) {
    uint256 price = uint256(getLatestWBTCInUSDPrice() * 10 ** 10);
    uint256 __price = price * _amount;
    return __price;
  }

  /**
   * @return price of SPL in USD
   */
  function getPriceOfCGLDInUSD(uint256 _amount) public view returns (uint256) {
    uint256 price = uint256(getLatestCGLDInUSDPrice() * 10 ** 10);
    uint256 __price = price * _amount;
    return __price;
  }

  /*///////////////////////////////////////////////////////////////
                        GETTER FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /**
   * @return balance of WBTC of _msgSender()
   */
  function getWBTCUserBalance(address _user) internal view returns (uint256) {
    return IERC20(WBTC).balanceOf(_user);
  }

  /**
   * @return balance of CGLD of _msgSender()
   */
  function getCGLDUserBalance(address _user) internal view returns (uint256) {
    return IERC20(CGLD).balanceOf(_user);
  }
}