// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.4;

import "./IERC20Wnft.sol";

/// @title ERC20Wnft
/// @author Hifi
contract ERC20Wnft is IERC20Wnft {
    /// PUBLIC STORAGE ///

    /// @inheritdoc IERC20
    uint256 public override totalSupply;

    /// @inheritdoc IERC20
    mapping(address => uint256) public override balanceOf;

    /// @inheritdoc IERC20
    mapping(address => mapping(address => uint256)) public override allowance;

    /// @inheritdoc IERC20Metadata
    string public override name;

    /// @inheritdoc IERC20Metadata
    string public override symbol;

    /// @inheritdoc IERC20Metadata
    uint8 public constant override decimals = 18;

    /// @dev version
    string public constant version = "1";

    /// @inheritdoc IERC20Permit
    bytes32 public override DOMAIN_SEPARATOR;
    // solhint-disable-previous-line var-name-mixedcase

    /// @inheritdoc IERC20Permit
    mapping(address => uint256) public override nonces;

    /// @dev keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @inheritdoc IERC20Wnft
    address public override asset;

    /// @inheritdoc IERC20Wnft
    address public immutable override factory;

    /// CONSTRUCTOR ///

    constructor() {
        factory = msg.sender;
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IERC20Wnft
    function initialize(
        string memory name_,
        string memory symbol_,
        address asset_
    ) public override {
        if (msg.sender != factory) {
            revert ERC20Wnft__Forbidden();
        }
        name = name_;
        symbol = symbol_;
        asset = asset_;

        uint256 chainId;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                address(this)
            )
        );
        emit Initialize(name, symbol, asset);
    }

    /// @inheritdoc IERC20
    function approve(address spender, uint256 value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /// @inheritdoc IERC20
    function transfer(address to, uint256 value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender] - value;
        }
        _transfer(from, to, value);
        return true;
    }

    /// @inheritdoc IERC20Permit
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override {
        if (deadline < block.timestamp) {
            revert ERC20Wnft__PermitExpired();
        }
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        if (recoveredAddress == address(0) || recoveredAddress != owner) {
            revert ERC20Wnft__InvalidSignature();
        }
        _approve(owner, spender, value);
    }

    /// INTERNAL NON-CONSTANT FUNCTIONS ///

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply + value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from] - value;
        totalSupply = totalSupply - value;
        emit Transfer(from, address(0), value);
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function permitInternal(
        uint256 amount,
        uint256 deadline,
        bytes memory signature
    ) internal {
        if (signature.length > 0) {
            bytes32 r;
            bytes32 s;
            uint8 v;

            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            permit(msg.sender, address(this), amount, deadline, v, r, s);
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] = balanceOf[from] - value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(from, to, value);
    }
}