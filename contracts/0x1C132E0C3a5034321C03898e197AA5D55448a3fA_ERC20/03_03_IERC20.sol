// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IERC20Events {
    /// @notice EIP-20 transfer event
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /// @notice EIP-20 approval event
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    /// @notice Mint event
    event Mint(address indexed _to, uint256 _value);
}

interface IERC20 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external view returns (bytes32);

    function initialize(
        address operator_,
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_
    ) external returns (address);

    function setBurnable(bool canBurn) external;

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;
}