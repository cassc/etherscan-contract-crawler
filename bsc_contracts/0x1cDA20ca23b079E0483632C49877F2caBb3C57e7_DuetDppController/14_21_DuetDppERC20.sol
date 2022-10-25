// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { DecimalMath } from "./lib/DecimalMath.sol";
import { DuetDppStorage } from "./DuetDppStorage.sol";

/// @title DppLp
/// @author So. Lu
/// @notice lp token's method, the same with erc20 tokens
contract DuetDppERC20 is DuetDppStorage {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ============ Events ============

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Mint(address indexed user, uint256 value);

    event Burn(address indexed user, uint256 value);

    // ============ Shares (ERC20) ============

    /**
     * @dev transfer token for a specified address
     * @param to The address to transfer to.
     * @param amount The amount to be transferred.
     */
    function transfer(address to, uint256 amount) public returns (bool) {
        require(amount <= _SHARES_[msg.sender], "BALANCE_NOT_ENOUGH");

        _SHARES_[msg.sender] = _SHARES_[msg.sender].sub(amount);
        _SHARES_[to] = _SHARES_[to].add(amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the the balance of.
     * @return balance An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) external view returns (uint256 balance) {
        return _SHARES_[owner];
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param amount uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        require(amount <= _SHARES_[from], "BALANCE_NOT_ENOUGH");
        require(amount <= _ALLOWED_[from][msg.sender], "ALLOWANCE_NOT_ENOUGH");

        _SHARES_[from] = _SHARES_[from].sub(amount);
        _SHARES_[to] = _SHARES_[to].add(amount);
        _ALLOWED_[from][msg.sender] = _ALLOWED_[from][msg.sender].sub(amount);
        emit Transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param spender The address which will spend the funds.
     * @param amount The amount of tokens to be spent.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "Duet_ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        _ALLOWED_[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Function to check the amount of tokens that an owner _ALLOWED_ to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _ALLOWED_[owner][spender];
    }

    function _mint(address user, uint256 value) internal {
        require(value > 1000, "MINT_INVALID");
        _SHARES_[user] = _SHARES_[user].add(value);
        totalSupply = totalSupply.add(value);
        emit Mint(user, value);
        emit Transfer(address(0), user, value);
    }

    function _burn(address user, uint256 value) internal {
        _SHARES_[user] = _SHARES_[user].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Burn(user, value);
        emit Transfer(user, address(0), value);
    }

    // ============================ Permit ======================================

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "Duet_LP: EXPIRED");
        bytes32 _DOMAIN_SEPARATOR = _domainSeparatorV4();

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "Duet_LP: INVALID_SIGNATURE");
        _approve(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            bytes32 _DOMAIN_SEPARATOR = keccak256(
                abi.encode(
                    // keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                    0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
                    keccak256(bytes(name)),
                    keccak256(bytes("1")),
                    block.chainid,
                    address(this)
                )
            );
            return _DOMAIN_SEPARATOR;
        }
    }
}