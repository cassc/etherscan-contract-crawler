pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ZapBase.sol";
import "./libs/Swap.sol";
import "./interfaces/ITempleStableRouter.sol";
import "./interfaces/IGenericZaps.sol";
import "./interfaces/IVault.sol";


contract TempleZaps is ZapBase {
  using SafeERC20 for IERC20;

  address public immutable temple;
  ITempleStableRouter public templeRouter;
  IGenericZaps public zaps;

  mapping(address => bool) public supportedStables;

  struct TempleLiquidityParams {
    uint256 amountAMin;
    uint256 amountBMin;
    uint256 lpSwapMinAmountOut;
    address stableToken;
    bool transferResidual;
  }

  event SetZaps(address zaps);
  event SetTempleRouter(address router);
  event ZappedTemplePlusFaithInVault(address indexed sender, address fromToken, uint256 fromAmount, uint112 faithAmount, uint256 boostedAmount);
  event ZappedTempleInVault(address indexed sender, address fromToken, uint256 fromAmount, uint256 templeAmount);
  event TokenRecovered(address token, address to, uint256 amount);
  event ZappedInTempleLP(address indexed recipient, address fromAddress, uint256 fromAmount, uint256 amountA, uint256 amountB);

  constructor(
    address _temple,
    address _templeRouter,
    address _zaps
  ) {
    temple = _temple;
    templeRouter = ITempleStableRouter(_templeRouter);
    zaps = IGenericZaps(_zaps);
  }

  /**
   * set generic zaps contract
   * @param _zaps zaps contract
   */
  function setZaps(address _zaps) external onlyOwner {
    zaps = IGenericZaps(_zaps);

    emit SetZaps(_zaps);
  }

  /**
   * set temple stable router
   * @param _router temple router
   */
  function setTempleRouter(address _router) external onlyOwner {
    templeRouter = ITempleStableRouter(_router);

    emit SetTempleRouter(_router);
  }

  /**
   * set supported stables. by default these are the stable amm supported stable tokens
   * @param _stables stable tokens to permit
   * @param _supported to support or not
   */
  function setSupportedStables(
    address[] calldata _stables,
    bool[] calldata _supported
  ) external onlyOwner {
    uint _length = _stables.length;
    require(_supported.length == _length, "TempleZaps: Invalid Input length");
    for (uint i=0; i<_length; i++) {
      supportedStables[_stables[i]] = _supported[i];
    }
  }

  /**
   * @notice recover token or ETH
   * @param _token token to recover
   * @param _to receiver of recovered token
   * @param _amount amount to recover
   */
  function recoverToken(address _token, address _to, uint256 _amount) external onlyOwner {
    require(_to != address(0), "TempleZaps: Invalid receiver");
    if (_token == address(0)) {
      // this is effectively how OpenZeppelin transfers eth
      require(address(this).balance >= _amount, "TempleZaps: insufficient eth balance");
      (bool success,) = _to.call{value: _amount}(""); 
      require(success, "TempleZaps: unable to send value");
    } else {
      _transferToken(IERC20(_token), _to, _amount);
    }
    
    emit TokenRecovered(_token, _to, _amount);
  }

  /**
   * @notice This function zaps ETH or an ERC20 token to TEMPLE ERC20 token
   * @param _fromToken The token used for entry (address(0) if ether)
   * @param _fromAmount The amount of fromToken to zap
   * @param _minTempleReceived Minimum temple to receive
   * @param _stableToken Supported temple pair stable token
   * @param _minStableReceived Minimum temple pair stable token to receive
   * @param _swapTarget Execution target for the swap
   * @param _swapData DEX data
   */
  function zapInTemple(
    address _fromToken,
    uint256 _fromAmount,
    uint256 _minTempleReceived,
    address _stableToken,
    uint256 _minStableReceived,
    address _swapTarget,
    bytes memory _swapData
  ) external payable whenNotPaused {
    zapInTempleFor(_fromToken, _fromAmount, _minTempleReceived, _stableToken, _minStableReceived, msg.sender, _swapTarget, _swapData);
  }

  /**
   * @notice This function zaps ETH or an ERC20 token to TEMPLE LP token
   * @param _fromAddress The token used for entry (address(0) if ether)
   * @param _fromAmount The amount of fromToken to zap
   * @param _minAmountOut Minimum tokens out after first DEX swap
   * @param _swapTarget Execution target for the swap
   * @param _params Parameters for liquidity addition
   * @param _swapData DEX data
   */
  function zapInTempleLP(
    address _fromAddress,
    uint256 _fromAmount,
    uint256 _minAmountOut,
    address _swapTarget,
    TempleLiquidityParams memory _params,
    bytes memory _swapData
  ) external payable whenNotPaused {
    zapInTempleLPFor(_fromAddress, _fromAmount, _minAmountOut, msg.sender, _swapTarget, _params, _swapData);
  }

  /**
   * @notice This function zaps ETH or an ERC20 token to TEMPLE and stakes in core vault
   * @param _fromToken The token used for entry (address(0) if ether)
   * @param _fromAmount The amount of fromToken to zap
   * @param _minTempleReceived Minimum tokens out after first DEX swap
   * @param _stableToken Supported temple pair stable token
   * @param _minStableReceived Minimum stable token to receive
   * @param _vault Target core vault
   * @param _swapTarget Execution target for the swap
   * @param _swapData DEX data
   */
  function zapInVault(
    address _fromToken,
    uint256 _fromAmount,
    uint256 _minTempleReceived,
    address _stableToken,
    uint256 _minStableReceived,
    address _vault,
    address _swapTarget,
    bytes memory _swapData
  ) external payable whenNotPaused {
    zapInVaultFor(_fromToken, _fromAmount, _minTempleReceived, _stableToken, _minStableReceived, _vault, msg.sender, _swapTarget, _swapData);
  }
  
  /**
   * @notice This function zaps ETH or an ERC20 token to TEMPLE ERC20 token
   * @param _fromToken The token used for entry (address(0) if ether)
   * @param _fromAmount The amount of fromToken to zap
   * @param _minTempleReceived Minimum temple to receive
   * @param _stableToken Supported temple pair stable token
   * @param _minStableReceived Minimum of stable token to receive
   * @param _recipient Recipient of exit tokens
   * @param _swapTarget Execution target for the swap
   * @param _swapData DEX data
   */
  function zapInTempleFor(
    address _fromToken,
    uint256 _fromAmount,
    uint256 _minTempleReceived,
    address _stableToken,
    uint256 _minStableReceived,
    address _recipient,
    address _swapTarget,
    bytes memory _swapData
  ) public payable whenNotPaused {
    require(supportedStables[_stableToken] == true, "TempleZaps: Unsupported stable token");

    uint256 amountOut;
    if (_fromToken != address(0)) {
      SafeERC20.safeTransferFrom(IERC20(_fromToken), msg.sender, address(this), _fromAmount);
      SafeERC20.safeIncreaseAllowance(IERC20(_fromToken), address(zaps), _fromAmount);
      amountOut = zaps.zapIn(_fromToken, _fromAmount, _stableToken, _minStableReceived, _swapTarget, _swapData);
    } else {
      amountOut = Swap.fillQuote(_fromToken, _fromAmount, _stableToken, _swapTarget, _swapData);
      require(amountOut >= _minStableReceived, "TempleZaps: Not enough stable tokens out");
    }

     _enterTemple(_stableToken, _recipient, amountOut, _minTempleReceived);
  }

  /**
   * @notice This function zaps ETH or an ERC20 token to TEMPLE LP token
   * @param _fromAddress The token used for entry (address(0) if ether)
   * @param _fromAmount The amount of fromToken to zap
   * @param _minAmountOut Minimum tokens out after first DEX swap
   * @param _for Recipient of exit LP tokens
   * @param _swapTarget Execution target for the swap
   * @param _params Parameters for liquidity addition
   * @param _swapData DEX data
   */
  function zapInTempleLPFor(
    address _fromAddress,
    uint256 _fromAmount,
    uint256 _minAmountOut,
    address _for,
    address _swapTarget,
    TempleLiquidityParams memory _params,
    bytes memory _swapData
  ) public payable {
    require(supportedStables[_params.stableToken] == true, "TempleZaps: Unsupported stable token");

    _pullTokens(_fromAddress, _fromAmount);

    // get pair tokens supporting stable coin
    address pair = templeRouter.tokenPair(_params.stableToken);
    address token0 = IUniswapV2Pair(pair).token0();
    address token1 = IUniswapV2Pair(pair).token1();

    if (_fromAddress != token0 && _fromAddress != token1) {

      _fromAmount = Swap.fillQuote(
        _fromAddress,
        _fromAmount,
        _params.stableToken,
        _swapTarget,
        _swapData
      );
      require(_fromAmount >= _minAmountOut, "TempleZaps: Insufficient tokens out");

      // After we've swapped from user provided token to stable token
      // The stable token is now the intermediate token.
      // reuse variable
      _fromAddress = _params.stableToken;
    }
    (uint256 amountA, uint256 amountB) = _swapAMMTokens(pair, _params.stableToken, _fromAddress, _fromAmount, _params.lpSwapMinAmountOut);

    // approve tokens and add liquidity
    {
      SafeERC20.safeIncreaseAllowance(IERC20(token0), address(templeRouter), amountA);
      SafeERC20.safeIncreaseAllowance(IERC20(token1), address(templeRouter), amountB);
    }
  
    _addLiquidity(pair, _for, amountA, amountB, _params);

    emit ZappedInTempleLP(_for, _fromAddress, _fromAmount, amountA, amountB);
  }

  /**
   * @notice This function zaps ETH or an ERC20 token to TEMPLE and stakes in core vault
   * @param _fromToken The token used for entry (address(0) if ether)
   * @param _fromAmount The amount of fromToken to zap
   * @param _minTempleReceived Minimum tokens out after first DEX swap
   * @param _stableToken Supported temple pair stable token
   * @param _minStableReceived Minimum stable token to receive
   * @param _vault Target core vault
   * @param _for Staked for
   * @param _swapTarget Execution target for the swap
   * @param _swapData DEX data
   */
  function zapInVaultFor(
    address _fromToken,
    uint256 _fromAmount,
    uint256 _minTempleReceived,
    address _stableToken,
    uint256 _minStableReceived,
    address _vault,
    address _for,
    address _swapTarget,
    bytes memory _swapData
  ) public payable whenNotPaused {
    require(supportedStables[_stableToken] == true, "TempleZaps: Unsupported stable token");

    _pullTokens(_fromToken, _fromAmount);
    
    uint256 receivedTempleAmount;
    if (_fromToken == temple) {
      receivedTempleAmount = _fromAmount;
    } else if (supportedStables[_fromToken]) {
      // if fromToken is supported stable, enter temple directly
      receivedTempleAmount = _enterTemple(_stableToken, address(this), _fromAmount, _minTempleReceived);
    } else {
      if (_fromToken != address(0)) {
        IERC20(_fromToken).safeIncreaseAllowance(address(zaps), _fromAmount);
      }
      
      // after zap in, enter temple from stable token
      uint256 receivedStableAmount = zaps.zapIn{value: msg.value}(
        _fromToken,
        _fromAmount,
        _stableToken,
        _minStableReceived,
        _swapTarget,
        _swapData
      );
      
      receivedTempleAmount = _enterTemple(_stableToken, address(this), receivedStableAmount, _minTempleReceived);
    }

    // approve and deposit for user
    if (receivedTempleAmount > 0) {
      IERC20(temple).safeIncreaseAllowance(_vault, receivedTempleAmount);
      IVault(_vault).depositFor(_for, receivedTempleAmount);
      emit ZappedTempleInVault(_for, _fromToken, _fromAmount, receivedTempleAmount);
    }
  }

  /**
   * @dev Helper function to calculate swap in amount of a token before adding liquidit to uniswap v2 pair
   * @param _token Token to swap in
   * @param _pair Uniswap V2 Pair token
   * @param _amount Amount of token
   * @return uint256 Amount to swap
   */
  function getAmountToSwap(
    address _token,
    address _pair,
    uint256 _amount
  ) public view returns (uint256) {
    return Swap.getAmountToSwap(_token, _pair, _amount);
  }

  function _addLiquidity(
    address _pair,
    address _for,
    uint256 _amountA,
    uint256 _amountB,
    TempleLiquidityParams memory _params
  ) internal {
    (uint256 amountAActual, uint256 amountBActual,) = templeRouter.addLiquidity(
      _amountA,
      _amountB,
      _params.amountAMin,
      _params.amountBMin,
      _params.stableToken,
      _for,
      DEADLINE
    );

    if (_params.transferResidual) {
      if (amountAActual < _amountA) {
        _transferToken(IERC20(IUniswapV2Pair(_pair).token0()), _for, _amountA - amountAActual);
      }

      if(amountBActual < _amountB) {
        _transferToken(IERC20(IUniswapV2Pair(_pair).token1()), _for, _amountB - amountBActual);
      }
    }
  }

  function _swapAMMTokens(
    address _pair,
    address _stableToken,
    address _intermediateToken,
    uint256 _intermediateAmount,
    uint256 _lpSwapMinAmountOut
  ) internal returns (uint256 amountA, uint256 amountB) {
    address token0 = IUniswapV2Pair(_pair).token0();
    uint256 amountToSwap = getAmountToSwap(_intermediateToken, _pair, _intermediateAmount);
    uint256 remainder = _intermediateAmount - amountToSwap;

    uint256 amountOut;
    if (_intermediateToken == temple) {
      SafeERC20.safeIncreaseAllowance(IERC20(temple), address(templeRouter), amountToSwap);

      amountOut = templeRouter.swapExactTempleForStable(amountToSwap, _lpSwapMinAmountOut, _stableToken, address(this), type(uint128).max);
      amountA = token0 == _stableToken ? amountOut : remainder;
      amountB = token0 == _stableToken ? remainder : amountOut;
    } else if (_intermediateToken == _stableToken) {
      SafeERC20.safeIncreaseAllowance(IERC20(_stableToken), address(templeRouter), amountToSwap);

      // There's currently a shadowed declaration in the AMM Router causing amountOut to always be zero.
      // So have to resort to getting the balance before/after.
      uint256 balBefore = IERC20(temple).balanceOf(address(this));
      /*amountOut = */ templeRouter.swapExactStableForTemple(amountToSwap, _lpSwapMinAmountOut, _stableToken, address(this), type(uint128).max);
      amountOut = IERC20(temple).balanceOf(address(this)) - balBefore;

      amountA = token0 == _stableToken ? remainder : amountOut;
      amountB = token0 == _stableToken ? amountOut : remainder;
    } else {
      revert("Unsupported token of liquidity pool");
    }
  }

  /**
   * @notice This function swaps stables for TEMPLE
   * @param _stableToken stable token 
   * @param _amountStable The amount of stable to swap
   * @param _minTempleReceived The minimum acceptable quantity of TEMPLE to receive
   * @return templeAmountReceived Quantity of TEMPLE received
   */
  function _enterTemple(
    address _stableToken,
    address _templeReceiver,
    uint256 _amountStable,
    uint256 _minTempleReceived
  ) internal returns (uint256 templeAmountReceived) {
    uint256 templeBefore = IERC20(temple).balanceOf(address(this));
    SafeERC20.safeIncreaseAllowance(IERC20(_stableToken), address(templeRouter), _amountStable);

    templeRouter
      .swapExactStableForTemple(
        _amountStable,
        _minTempleReceived,
        _stableToken,
        _templeReceiver,
        DEADLINE
      );
    // stableswap amm router has a shadowed declaration and so no value is returned after swapExactStableForTemple
    // using calculation below instead
    if (_templeReceiver == address(this)) {
      templeAmountReceived = IERC20(temple).balanceOf(address(this)) - templeBefore;
      require(templeAmountReceived >= _minTempleReceived, "TempleZaps: Not enough temple tokens received");
    }
  }
}