//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {Ownable} from "../lib/Ownable.sol";
import {ICabinToken} from "./interface/ICabinToken.sol";

/**
 * @title ₡ABIN
 *
 * 🏡 a community of cabins for web3 workers
 * 🌐 a DAO retreat & residency program
 * 🌆 an experiment in decentralized cities
 */
contract CabinToken is Ownable, ICabinToken {
    // ============ Constants ============

    // There is an initial supply of 1m tokens, each with 18 decimals,
    // that are minted to the owner upon deploy.
    uint256 private constant initialSupply = 1_000_000 * 1 ether;

    // ============ Immutable ERC20 Attributes ============

    string public constant override symbol = unicode"₡ABIN";
    string public constant override name = unicode"₡ABIN";
    uint8 public constant override decimals = 18;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    bytes32 public immutable override DOMAIN_SEPARATOR;

    // ============ Mutable ERC20 Attributes ============

    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;
    mapping(address => uint256) public override nonces;

    // ============ Constructor ============

    constructor(address owner_) Ownable(owner_) {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

        // The initial supply is minted to the owner.
        _mint(owner_, initialSupply);
    }

    // ============ Minting ============

    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    // ============ ERC20 Spec ============

    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        require(
            allowance[from][msg.sender] >= value,
            "CabinToken: transfer amount exceeds spender allowance"
        );

        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= value;
        }

        _transfer(from, to, value);
        return true;
    }

    function permit(
        address owner_,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(deadline >= block.timestamp, "CabinToken: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner_,
                        spender,
                        value,
                        nonces[owner_]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner_,
            "CabinToken: INVALID_SIGNATURE"
        );
        _approve(owner_, spender, value);
    }

    // ============ Internal Functions ============

    function _mint(address to, uint256 value) internal {
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
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
        require(
            balanceOf[from] >= value,
            "CabinToken: transfer amount exceeds balance"
        );

        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }
}