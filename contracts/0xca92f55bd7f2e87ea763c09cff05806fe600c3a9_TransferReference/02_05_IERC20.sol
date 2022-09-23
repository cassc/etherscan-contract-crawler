// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for ERC-20 token contract
interface IERC20 {
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 amount);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function allowance(address, address) external view returns (uint256);

    function approve(address _spender, uint256 _amount) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function nonces(address) external view returns (uint256);

    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address _to, uint256 _amount) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool);
}