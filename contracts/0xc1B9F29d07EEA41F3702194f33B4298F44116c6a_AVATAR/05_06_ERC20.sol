// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import {IERC20} from "./interfaces/IERC20.sol";

/*
    ███████╗██████╗  ██████╗    ██████╗  ██████╗
    ██╔════╝██╔══██╗██╔════╝    ╚════██╗██╔═████╗
    █████╗  ██████╔╝██║          █████╔╝██║██╔██║
    ██╔══╝  ██╔══██╗██║         ██╔═══╝ ████╔╝██║
    ███████╗██║  ██║╚██████╗    ███████╗╚██████╔╝
    ╚══════╝╚═╝  ╚═╝ ╚═════╝    ╚══════╝ ╚═════╝
*/

/**
 *  @title Modern ERC-20 implementation.
 *  @dev   Acknowledgements to Solmate, OpenZeppelin, and DSS for inspiring this code.
 */
contract ERC20 is IERC20 {
    /**************/
    /*** ERC-20 ***/
    /**************/

    string public override name;
    string public override symbol;

    uint8 public immutable override decimals;

    uint256 public override totalSupply;

    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;

    /**
     *  @param name_     The name of the token.
     *  @param symbol_   The symbol of the token.
     *  @param decimals_ The decimal precision used by the token.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    /**************************/
    /*** External Functions ***/
    /**************************/

    function approve(address spender_, uint256 amount_) public virtual override returns (bool success_) {
        _approve(msg.sender, spender_, amount_);
        return true;
    }

    function decreaseAllowance(address spender_, uint256 subtractedAmount_)
        public
        virtual
        override
        returns (bool success_)
    {
        _decreaseAllowance(msg.sender, spender_, subtractedAmount_);
        return true;
    }

    function increaseAllowance(address spender_, uint256 addedAmount_) public virtual override returns (bool success_) {
        _approve(msg.sender, spender_, allowance[msg.sender][spender_] + addedAmount_);
        return true;
    }

    function transfer(address recipient_, uint256 amount_) public virtual override returns (bool success_) {
        _transfer(msg.sender, recipient_, amount_);
        return true;
    }

    function transferFrom(
        address owner_,
        address recipient_,
        uint256 amount_
    ) public virtual override returns (bool success_) {
        _decreaseAllowance(owner_, msg.sender, amount_);
        _transfer(owner_, recipient_, amount_);
        return true;
    }

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    function _approve(
        address owner_,
        address spender_,
        uint256 amount_
    ) internal {
        emit Approval(owner_, spender_, allowance[owner_][spender_] = amount_);
    }

    function _burn(address owner_, uint256 amount_) internal {
        balanceOf[owner_] -= amount_;

        // Cannot underflow because a user's balance will never be larger than the total supply.
        unchecked {
            totalSupply -= amount_;
        }

        emit Transfer(owner_, address(0), amount_);
    }

    function _decreaseAllowance(
        address owner_,
        address spender_,
        uint256 subtractedAmount_
    ) internal {
        uint256 spenderAllowance = allowance[owner_][spender_]; // Cache to memory.

        if (spenderAllowance != type(uint256).max) {
            _approve(owner_, spender_, spenderAllowance - subtractedAmount_);
        }
    }

    function _mint(address recipient_, uint256 amount_) internal {
        totalSupply += amount_;

        // Cannot overflow because totalSupply would first overflow in the statement above.
        unchecked {
            balanceOf[recipient_] += amount_;
        }

        emit Transfer(address(0), recipient_, amount_);
    }

    function _transfer(
        address owner_,
        address recipient_,
        uint256 amount_
    ) internal virtual {
        balanceOf[owner_] -= amount_;

        // Cannot overflow because minting prevents overflow of totalSupply, and sum of user balances == totalSupply.
        unchecked {
            balanceOf[recipient_] += amount_;
        }

        emit Transfer(owner_, recipient_, amount_);
    }
}