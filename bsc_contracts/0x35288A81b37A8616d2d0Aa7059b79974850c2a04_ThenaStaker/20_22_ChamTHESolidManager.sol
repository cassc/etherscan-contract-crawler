// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ChamTHESolidManager is Ownable, Pausable {
    using SafeERC20 for IERC20;

    /**
     * @dev Peanutfi Contracts:
     * {keeper} - Address to manage a few lower risk features of the strat..
     */
    address public keeper;
    address public voter;
    address public taxWallet;

    event NewKeeper(address oldKeeper, address newKeeper);
    event NewVoter(address oldVoter, address newVoter);
    event NewTaxWallet(address oldTaxWallet, address newTaxWallet);

    /**
     * @dev Initializes the base strategy.
     * @param _keeper address to use as alternative owner.
     */
    constructor(
        address _keeper,
        address _voter,
        address _taxWallet
    ) {
        keeper = _keeper;
        voter = _voter;
        taxWallet = _taxWallet;
    }

    // Checks that caller is either owner or keeper.
    modifier onlyManager() {
        require(msg.sender == owner() || msg.sender == keeper, "ChamTHESolidManager: MANAGER_ONLY");
        _;
    }

    // Checks that caller is either owner or keeper.
    modifier onlyVoter() {
        require(msg.sender == voter, "ChamTHESolidManager: VOTER_ONLY");
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
        emit NewVoter(voter, _voter);
        voter = _voter;
    }

    function setTaxWallet(address _taxWallet) external onlyManager {
        emit NewTaxWallet(taxWallet, _taxWallet);
        taxWallet = _taxWallet;
    }
}