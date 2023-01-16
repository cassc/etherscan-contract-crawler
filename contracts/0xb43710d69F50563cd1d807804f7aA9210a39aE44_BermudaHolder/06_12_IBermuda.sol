// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./UniswapV2Interfaces.sol";

interface IBermuda {
  function allowance ( address owner, address spender ) external view returns ( uint256 );
  function approve ( address spender, uint256 amount ) external returns ( bool );
  function balanceOf ( address account ) external view returns ( uint256 );
  function botBlacklist ( address ) external view returns ( bool );
  function burn ( uint256 amount ) external;
  function burnFrom ( address account, uint256 amount ) external;
  function burnTax (  ) external view returns ( uint256 );
  function decimals (  ) external view returns ( uint8 );
  function decreaseAllowance ( address spender, uint256 subtractedValue ) external returns ( bool );
  function devTax (  ) external view returns ( uint256 );
  function devWallet (  ) external view returns ( address );
  function disableBotKiller (  ) external view returns ( bool );
  function enableTrading (  ) external;
  function excludeFromTax ( address ) external view returns ( bool );
  function feelessAddLiquidity ( uint256 amountBMDADesired, uint256 amountWETHDesired, uint256 amountBMDAMin, uint256 amountWETHMin, address to, uint256 deadline ) external returns ( uint256 amountBMDA, uint256 amountWETH, uint256 liquidity );
  function feelessAddLiquidityETH ( uint256 amountBMDADesired, uint256 amountBMDAMin, uint256 amountETHMin, address to, uint256 deadline ) external returns ( uint256 amountBMDA, uint256 amountETH, uint256 liquidity );
  function holderLimit (  ) external view returns ( uint256 );
  function increaseAllowance ( address spender, uint256 addedValue ) external returns ( bool );
  function marketingTax (  ) external view returns ( uint256 );
  function marketingWallet (  ) external view returns ( address );
  function name (  ) external view returns ( string memory );
  function owner (  ) external view returns ( address );
  function recoverLostTokens ( address _token, uint256 _amount, address _to ) external;
  function renounceOwnership (  ) external;
  function sellerLimit (  ) external view returns ( uint256 );
  function setBotBlacklist ( address bot, bool blacklist ) external;
  function setDisableBotKiller ( bool disabled ) external;
  function setExcludeFromTax ( address wallet, bool exclude ) external;
  function setPercentages ( uint256 dev, uint256 marketing, uint256 burn, uint256 holder, uint256 seller ) external;
  function setWallets ( address dev, address marketing ) external;
  function symbol (  ) external view returns ( string memory );
  function totalSupply (  ) external view returns ( uint256 );
  function tradingEnabled (  ) external view returns ( bool );
  function transfer ( address to, uint256 amount ) external returns ( bool );
  function transferFrom ( address from, address to, uint256 amount ) external returns ( bool );
  function transferOwnership ( address newOwner ) external;
  function uniswapV2Pair (  ) external view returns ( IUniswapV2Pair );
  function uniswapV2Router (  ) external view returns ( IUniswapV2Router02 );
}