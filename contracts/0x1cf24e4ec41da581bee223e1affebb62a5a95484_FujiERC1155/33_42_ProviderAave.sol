// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.7.0;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { UniERC20 } from "../Libraries/LibUniERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IProvider } from "./IProvider.sol";

interface ITokenInterface {
  function approve(address, uint256) external;

  function transfer(address, uint256) external;

  function transferFrom(
    address,
    address,
    uint256
  ) external;

  function deposit() external payable;

  function withdraw(uint256) external;

  function balanceOf(address) external view returns (uint256);

  function decimals() external view returns (uint256);
}

interface IAaveInterface {
  function deposit(
    address _asset,
    uint256 _amount,
    address _onBehalfOf,
    uint16 _referralCode
  ) external;

  function withdraw(
    address _asset,
    uint256 _amount,
    address _to
  ) external;

  function borrow(
    address _asset,
    uint256 _amount,
    uint256 _interestRateMode,
    uint16 _referralCode,
    address _onBehalfOf
  ) external;

  function repay(
    address _asset,
    uint256 _amount,
    uint256 _rateMode,
    address _onBehalfOf
  ) external;

  function setUserUseReserveAsCollateral(address _asset, bool _useAsCollateral) external;
}

interface AaveLendingPoolProviderInterface {
  function getLendingPool() external view returns (address);
}

interface AaveDataProviderInterface {
  function getReserveTokensAddresses(address _asset)
    external
    view
    returns (
      address aTokenAddress,
      address stableDebtTokenAddress,
      address variableDebtTokenAddress
    );

  function getUserReserveData(address _asset, address _user)
    external
    view
    returns (
      uint256 currentATokenBalance,
      uint256 currentStableDebt,
      uint256 currentVariableDebt,
      uint256 principalStableDebt,
      uint256 scaledVariableDebt,
      uint256 stableBorrowRate,
      uint256 liquidityRate,
      uint40 stableRateLastUpdated,
      bool usageAsCollateralEnabled
    );

  function getReserveData(address _asset)
    external
    view
    returns (
      uint256 availableLiquidity,
      uint256 totalStableDebt,
      uint256 totalVariableDebt,
      uint256 liquidityRate,
      uint256 variableBorrowRate,
      uint256 stableBorrowRate,
      uint256 averageStableBorrowRate,
      uint256 liquidityIndex,
      uint256 variableBorrowIndex,
      uint40 lastUpdateTimestamp
    );
}

interface AaveAddressProviderRegistryInterface {
  function getAddressesProvidersList() external view returns (address[] memory);
}

contract ProviderAave is IProvider {
  using SafeMath for uint256;
  using UniERC20 for IERC20;

  function _getAaveProvider() internal pure returns (AaveLendingPoolProviderInterface) {
    return AaveLendingPoolProviderInterface(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5); //mainnet
  }

  function _getAaveDataProvider() internal pure returns (AaveDataProviderInterface) {
    return AaveDataProviderInterface(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d); //mainnet
  }

  function _getWethAddr() internal pure returns (address) {
    return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // Mainnet WETH Address
  }

  function _getEthAddr() internal pure returns (address) {
    return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // ETH Address
  }

  function _getIsColl(
    AaveDataProviderInterface _aaveData,
    address _token,
    address _user
  ) internal view returns (bool isCol) {
    (, , , , , , , , isCol) = _aaveData.getUserReserveData(_token, _user);
  }

  function _convertEthToWeth(
    bool _isEth,
    ITokenInterface _token,
    uint256 _amount
  ) internal {
    if (_isEth) _token.deposit{ value: _amount }();
  }

  function _convertWethToEth(
    bool _isEth,
    ITokenInterface _token,
    uint256 _amount
  ) internal {
    if (_isEth) {
      _token.approve(address(_token), _amount);
      _token.withdraw(_amount);
    }
  }

  /**
   * @dev Return the borrowing rate of ETH/ERC20_Token.
   * @param _asset to query the borrowing rate.
   */
  function getBorrowRateFor(address _asset) external view override returns (uint256) {
    AaveDataProviderInterface aaveData = _getAaveDataProvider();

    (, , , , uint256 variableBorrowRate, , , , , ) =
      AaveDataProviderInterface(aaveData).getReserveData(
        _asset == _getEthAddr() ? _getWethAddr() : _asset
      );

    return variableBorrowRate;
  }

  /**
   * @dev Return borrow balance of ETH/ERC20_Token.
   * @param _asset token address to query the balance.
   */
  function getBorrowBalance(address _asset) external view override returns (uint256) {
    AaveDataProviderInterface aaveData = _getAaveDataProvider();

    bool isEth = _asset == _getEthAddr();
    address _token = isEth ? _getWethAddr() : _asset;

    (, , uint256 variableDebt, , , , , , ) = aaveData.getUserReserveData(_token, msg.sender);

    return variableDebt;
  }

  /**
   * @dev Return deposit balance of ETH/ERC20_Token.
   * @param _asset token address to query the balance.
   */
  function getDepositBalance(address _asset) external view override returns (uint256) {
    AaveDataProviderInterface aaveData = _getAaveDataProvider();

    bool isEth = _asset == _getEthAddr();
    address _token = isEth ? _getWethAddr() : _asset;

    (uint256 atokenBal, , , , , , , , ) = aaveData.getUserReserveData(_token, msg.sender);

    return atokenBal;
  }

  /**
   * @dev Deposit ETH/ERC20_Token.
   * @param _asset token address to deposit.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
   * @param _amount token amount to deposit.
   */
  function deposit(address _asset, uint256 _amount) external payable override {
    IAaveInterface aave = IAaveInterface(_getAaveProvider().getLendingPool());
    AaveDataProviderInterface aaveData = _getAaveDataProvider();

    bool isEth = _asset == _getEthAddr();
    address _token = isEth ? _getWethAddr() : _asset;

    ITokenInterface tokenContract = ITokenInterface(_token);

    if (isEth) {
      _amount = _amount == uint256(-1) ? address(this).balance : _amount;
      _convertEthToWeth(isEth, tokenContract, _amount);
    } else {
      _amount = _amount == uint256(-1) ? tokenContract.balanceOf(address(this)) : _amount;
    }

    tokenContract.approve(address(aave), _amount);

    aave.deposit(_token, _amount, address(this), 0);

    if (!_getIsColl(aaveData, _token, address(this))) {
      aave.setUserUseReserveAsCollateral(_token, true);
    }
  }

  /**
   * @dev Borrow ETH/ERC20_Token.
   * @param _asset token address to borrow.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
   * @param _amount token amount to borrow.
   */
  function borrow(address _asset, uint256 _amount) external payable override {
    IAaveInterface aave = IAaveInterface(_getAaveProvider().getLendingPool());

    bool isEth = _asset == _getEthAddr();
    address _token = isEth ? _getWethAddr() : _asset;

    aave.borrow(_token, _amount, 2, 0, address(this));
    _convertWethToEth(isEth, ITokenInterface(_token), _amount);
  }

  /**
   * @dev Withdraw ETH/ERC20_Token.
   * @param _asset token address to withdraw.
   * @param _amount token amount to withdraw.
   */
  function withdraw(address _asset, uint256 _amount) external payable override {
    IAaveInterface aave = IAaveInterface(_getAaveProvider().getLendingPool());

    bool isEth = _asset == _getEthAddr();
    address _token = isEth ? _getWethAddr() : _asset;

    ITokenInterface tokenContract = ITokenInterface(_token);
    uint256 initialBal = tokenContract.balanceOf(address(this));

    aave.withdraw(_token, _amount, address(this));
    uint256 finalBal = tokenContract.balanceOf(address(this));
    _amount = finalBal.sub(initialBal);

    _convertWethToEth(isEth, tokenContract, _amount);
  }

  /**
   * @dev Payback borrowed ETH/ERC20_Token.
   * @param _asset token address to payback.
   * @param _amount token amount to payback.
   */

  function payback(address _asset, uint256 _amount) external payable override {
    IAaveInterface aave = IAaveInterface(_getAaveProvider().getLendingPool());
    AaveDataProviderInterface aaveData = _getAaveDataProvider();

    bool isEth = _asset == _getEthAddr();
    address _token = isEth ? _getWethAddr() : _asset;

    ITokenInterface tokenContract = ITokenInterface(_token);

    (, , uint256 variableDebt, , , , , , ) = aaveData.getUserReserveData(_token, address(this));
    _amount = _amount == uint256(-1) ? variableDebt : _amount;

    if (isEth) _convertEthToWeth(isEth, tokenContract, _amount);

    tokenContract.approve(address(aave), _amount);

    aave.repay(_token, _amount, 2, address(this));
  }
}