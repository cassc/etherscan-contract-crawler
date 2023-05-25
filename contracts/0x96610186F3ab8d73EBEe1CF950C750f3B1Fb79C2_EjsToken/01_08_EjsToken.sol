// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";
import "./interfaces/IEjsToken.sol";

/**
 * @title EjsToken
 * @author Enjinstarter
 */
contract EjsToken is ERC20Capped, IEjsToken {
    using SafeMath for uint256;

    address public governanceAccount;
    address public minterAccount;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 tokenCap
    ) ERC20(tokenName, tokenSymbol) ERC20Capped(tokenCap) {
        governanceAccount = msg.sender;
        minterAccount = msg.sender;
    }

    modifier onlyBy(address account) {
        require(msg.sender == account, "EjsToken: sender unauthorized");
        _;
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     */
    function burn(uint256 amount) external override {
        require(amount > 0, "EjsToken: zero amount");
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external override {
        require(amount > 0, "EjsToken: zero amount");

        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(
            amount,
            "EjsToken: burn amount exceeds allowance"
        );

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }

    function mint(address account, uint256 amount)
        external
        override
        onlyBy(minterAccount)
    {
        require(amount > 0, "EjsToken: zero amount");
        _mint(account, amount);
    }

    function setGovernanceAccount(address account)
        external
        override
        onlyBy(governanceAccount)
    {
        require(account != address(0), "EjsToken: zero governance account");

        governanceAccount = account;
    }

    function setMinterAccount(address account)
        external
        override
        onlyBy(governanceAccount)
    {
        require(account != address(0), "EjsToken: zero minter account");
        minterAccount = account;
    }
}