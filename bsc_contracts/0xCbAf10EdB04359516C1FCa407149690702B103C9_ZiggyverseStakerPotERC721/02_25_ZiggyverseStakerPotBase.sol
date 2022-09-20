// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./token/IControlledToken.sol";
import "./token/ITokenController.sol";
import "./prize-strategy/IPeriodicPrizeStrategy.sol";

/**
 * @title Base contract for a Ziggyverse Staker Pot
 * 
 * Controls the chances to win the pot by entering the pot with a given weight.
 * Chance to win is relative to the weight the user owns.
 * Weight is tracked as a ERC20 token in {controlledToken}, the ticket.
 *
 * Unstaking can be disabled until a given timestamp is reached.
 */
abstract contract ZiggyverseStakerPotBase is Ownable, Pausable, ReentrancyGuard, ITokenController {
    using ERC165Checker for address;


    event PrizeStrategySet(address indexed prizeStrategy);
    event UnstakeableAfterSet(uint256 indexed timestamp);


    // Ticket tracking the chances to win a drawing
    IControlledToken public controlledToken;

    // Price strategy handling the drawing and prize distribution
    IPeriodicPrizeStrategy public prizeStrategy;

    // Time users can unstake
    uint256 public unstakeableAfter;


    // --- Admin methods ---
    
    /**
     * @dev Set after constructor since we need to set this contract as controller in the Ticket constructor
     * Callable by owner.
     */
    function setTicket(IControlledToken _ticket) external onlyOwner {
        require(address(controlledToken) == address(0), "Already set");
        controlledToken = _ticket;
    }

    /**
     * @dev Sets the timestamp from when to allow unstaking
     * Callable by owner.
     */
    function setUnstakeableAfter(uint256 _unstakeableAfter) external onlyOwner {
        unstakeableAfter = _unstakeableAfter;
        emit UnstakeableAfterSet(_unstakeableAfter);
    }

    /**
     * @dev Sets the prize strategy of the pot.
     * Callable by owner.
     */
    function setPrizeStrategy(IPeriodicPrizeStrategy _prizeStrategy) external onlyOwner {
        _setPrizeStrategy(_prizeStrategy);
    }


    // --- Internal methods ---

    /**
     * @dev Enter the pot for `user` with given `weight`.
     */
    function _enterPot(address user, uint256 weight) internal virtual {
        controlledToken.controllerMint(user, weight);
    }

    /**
     * @dev Leave the pot for `user` with given `weight`.
     */
    function _leavePot(
        address user,
        uint256 weight
    ) internal virtual {
        require(block.timestamp >= unstakeableAfter, "Can not unstake yet");
        controlledToken.controllerBurnFrom(_msgSender(), user, weight);
    }
    
    /**
     * @dev Sets the prize strategy of the pot.
     */
    function _setPrizeStrategy(IPeriodicPrizeStrategy _prizeStrategy) internal {
        require(
            address(_prizeStrategy) != address(0),
            "prizeStrategy-not-zero"
        );
        require(
            address(_prizeStrategy).supportsInterface(
                type(IPeriodicPrizeStrategy).interfaceId
            ),
            "prizeStrategy-invalid"
        );
        prizeStrategy = _prizeStrategy;

        emit PrizeStrategySet(address(_prizeStrategy));
    }


    // --- ITokenController interface ---

    /**
     * @dev Hook of {controlledTicket} to avoid buying and selling tickets when award is in progress.
     */
    function beforeTokenTransfer(
        address,
        address,
        uint256
    ) external view override {
        require(
            address(prizeStrategy) == address(0) ||
                prizeStrategy.awardNotInProgress(),
            "Award in progress"
        );
    }
}