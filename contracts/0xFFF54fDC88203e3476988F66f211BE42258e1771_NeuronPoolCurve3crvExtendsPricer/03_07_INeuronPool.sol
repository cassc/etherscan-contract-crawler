// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface INeuronPool {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function available() external view returns (uint256);

    function balance() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function controller() external view returns (address);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function deposit(address _enterToken, uint256 _amount) external payable returns (uint256);

    function depositAll(address _enterToken) external payable returns (uint256);

    function earn() external;

    function getSupportedTokens() external view returns (address[] memory tokens);

    function governance() external view returns (address);

    function harvest(address reserve, uint256 amount) external;

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function masterchef() external view returns (address);

    function max() external view returns (uint256);

    function min() external view returns (uint256);

    function name() external view returns (string memory);

    function pricePerShare() external view returns (uint256);

    function setController(address _controller) external;

    function setGovernance(address _governance) external;

    function setMin(uint256 _min) external;

    function setTimelock(address _timelock) external;

    function symbol() external view returns (string memory);

    function timelock() external view returns (address);

    function token() external view returns (address);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function withdraw(address _withdrawableToken, uint256 _shares) external;

    function withdrawAll(address _withdrawableToken) external;
}