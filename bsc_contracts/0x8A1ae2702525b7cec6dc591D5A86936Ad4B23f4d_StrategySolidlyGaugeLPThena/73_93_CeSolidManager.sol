// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CeSolidManager is Ownable, Pausable {
    using SafeERC20 for IERC20;

    /**
     * @dev Peanutfi Contracts:
     * {keeper} - Address to manage a few lower risk features of the strat..
     */
    address public keeper;
    address public voter;

    event NewKeeper(address oldKeeper, address newKeeper);
    event NewVoter(address newVoter);

    /**
     * @dev Initializes the base strategy.
     * @param _keeper address to use as alternative owner.
     */
    constructor(
        address _keeper,
        address _voter
    ) {
        keeper = _keeper;
        voter = _voter;
    }

    // Checks that caller is either owner or keeper.
    modifier onlyManager() {
        require(msg.sender == owner() || msg.sender == keeper, "CeSolidManager: MANAGER_ONLY");
        _;
    }

    // Checks that caller is either owner or keeper.
    modifier onlyVoter() {
        require(msg.sender == voter, "CeSolidManager: VOTER_ONLY");
        _;
    }

    /**
     * @dev Updates address of the strat keeper.
     * @param _keeper new keeper address.
     */
    function setKeeper(address _keeper) external onlyManager {
        emit NewKeeper( keeper, _keeper);
        keeper = _keeper;
    }

    function setVoter(address _voter) external onlyManager {
        emit NewVoter(_voter);
        voter = _voter;
    }
}