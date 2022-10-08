// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAuraToken {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Initialised();
    event OperatorChanged(address indexed previousOperator, address indexed newOperator);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function EMISSIONS_MAX_SUPPLY() external view returns (uint256);

    function INIT_MINT_AMOUNT() external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function init(address _to, address _minter) external;

    function mint(address _to, uint256 _amount) external;

    function minter() external view returns (address);

    function minterMint(address _to, uint256 _amount) external;

    function name() external view returns (string memory);

    function operator() external view returns (address);

    function reductionPerCliff() external view returns (uint256);

    function symbol() external view returns (string memory);

    function totalCliffs() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function updateOperator() external;

    function vecrvProxy() external view returns (address);
}