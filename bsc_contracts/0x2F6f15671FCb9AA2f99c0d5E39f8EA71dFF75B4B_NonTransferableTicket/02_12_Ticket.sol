// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../external/SortitionSumTreeFactory.sol";
import "../external/libs/UniformRandomNumber.sol";

import "./ControlledToken.sol";
import "./ITicket.sol";

contract Ticket is ControlledToken, ITicket {
    using SortitionSumTreeFactory for SortitionSumTreeFactory.SortitionSumTrees;

    bytes32 private constant TREE_KEY = keccak256("Ziggyverses/Ticket");
    uint256 private constant MAX_TREE_LEAVES = 5;
    uint8 private constant DECIMALS = 0;

    // Ticket-weighted odds
    SortitionSumTreeFactory.SortitionSumTrees internal sortitionSumTrees;


    /// @notice Initializes the Controlled Token with Token Details and the Controller
    /// @param _name The name of the Token
    /// @param _symbol The symbol for the Token
    /// @param _controller Address of the Controller contract for minting & burning
    constructor(string memory _name, string memory _symbol, ITokenController _controller)
        ControlledToken(_name, _symbol, DECIMALS, _controller) 
    {
        sortitionSumTrees.createTree(TREE_KEY, MAX_TREE_LEAVES);
    }

    /// @notice Returns the user's chance of winning.
    function chanceOf(address user) external view returns (uint256) {
        return sortitionSumTrees.stakeOf(TREE_KEY, bytes32(uint256(uint160(user))));
    }

    /// @notice Selects a user using a random number.  The random number will be uniformly bounded to the ticket totalSupply.
    /// @param randomNumber The random number to use to select a user.
    /// @return The winner
    function draw(uint256 randomNumber)
        external
        view
        override
        returns (address)
    {
        uint256 bound = totalSupply();
        address selected;
        if (bound == 0) {
            selected = address(0);
        } else {
            uint256 token = UniformRandomNumber.uniform(randomNumber, bound);
            selected = address(
                uint160(uint256(sortitionSumTrees.draw(TREE_KEY, token)))
            );
        }
        return selected;
    }

    /// @dev Controller hook to provide notifications & rule validations on token transfers to the controller.
    /// This includes minting and burning.
    /// May be overridden to provide more granular control over operator-burning
    /// @param from Address of the account sending the tokens (address(0x0) on minting)
    /// @param to Address of the account receiving the tokens (address(0x0) on burning)
    /// @param amount Amount of tokens being transferred
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        // optimize: ignore transfers to self
        if (from == to) {
            return;
        }

        if (from != address(0)) {
            uint256 fromBalance = balanceOf(from) - amount;
            sortitionSumTrees.set(
                TREE_KEY,
                fromBalance,
                bytes32(uint256(uint160(from)))
            );
        }

        if (to != address(0)) {
            uint256 toBalance = balanceOf(to) + amount;
            sortitionSumTrees.set(TREE_KEY, toBalance, bytes32(uint256(uint160(to))));
        }
    }
}