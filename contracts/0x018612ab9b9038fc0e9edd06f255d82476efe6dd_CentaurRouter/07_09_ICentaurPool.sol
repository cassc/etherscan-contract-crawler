// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ICentaurPool {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    event Mint(address indexed sender, uint amount);
    event Burn(address indexed sender, uint amount, address indexed to);
    event AmountIn(address indexed sender, uint amount);
    event AmountOut(address indexed sender, uint amount, address indexed to);
    event EmergencyWithdraw(uint256 _timestamp, address indexed _token, uint256 _amount, address indexed _to);

    function factory() external view returns (address);
    function settlement() external view returns (address);
    function baseToken() external view returns (address);
    function baseTokenDecimals() external view returns (uint);
    function oracle() external view returns (address);
    function oracleDecimals() external view returns (uint);
    function baseTokenTargetAmount() external view returns (uint);
    function baseTokenBalance() external view returns (uint);
    function liquidityParameter() external view returns (uint);

    function init(address, address, address, uint) external;

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount);

    function swapTo(address _sender, address _fromToken, uint _amountIn, uint _value, address _receiver) external returns (uint maxAmount);
    function swapFrom(address _sender) external returns (uint amount, uint value);
    function swapSettle(address _sender) external returns (uint, address);

    function getOraclePrice() external view returns (uint price);
    function getAmountOutFromValue(uint _value) external view returns (uint amount);
    function getValueFromAmountIn(uint _amount) external view returns (uint value);
    function getAmountInFromValue(uint _value) external view returns (uint amount);
    function getValueFromAmountOut(uint _amount) external view returns (uint value);

    function setFactory(address) external;
    function setTradeEnabled(bool) external;
    function setDepositEnabled(bool) external;
    function setWithdrawEnabled(bool) external;
    function setLiquidityParameter(uint) external;
    function emergencyWithdraw(address, uint, address) external;
}