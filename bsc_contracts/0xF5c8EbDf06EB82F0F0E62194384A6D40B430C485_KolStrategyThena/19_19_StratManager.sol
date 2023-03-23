// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./AuthUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract StratManager is AuthUpgradeable, PausableUpgradeable {
    function _authorizeUpgrade(address) internal override onlyOwner {}
    /**
     * @dev Initializes the base strategy.
     * @param keeper address to use as alternative owner.
     * @param strategist address where strategist fees go.
     * @param uniRouter router to use for swaps
     * @param vault address of parent vault.
     * @param coFeeRecipient address where to send ChampionOptimizer's fees.
     */
    struct CommonAddresses {
        address keeper;
        address strategist;
        address uniRouter;
        address vault;
        address coFeeRecipient;
    }

    /**
     * @dev Champion Optimizer Contracts:
     * {keeper} - Address to manage a few lower risk features of the strat
     * {strategist} - Address of the strategy author/deployer where strategist fee will go.
     * {vault} - Address of the vault that controls the strategy's funds.
     * {uniRouter} - Address of exchange to execute swaps.
     */
    address public keeper;
    address public strategist;
    address public uniRouter;
    address public vault;
    address public coFeeRecipient;
    bool public hadVault;
    /*
        constructor(CommonAddresses memory _commonAddresses) {
            keeper = _commonAddresses.keeper;
            strategist = _commonAddresses.strategist;
            uniRouter = _commonAddresses.uniRouter;
            vault = _commonAddresses.vault;
            coFeeRecipient = _commonAddresses.coFeeRecipient;
        }
    */
    // checks that caller is either owner or keeper.
    modifier onlyManager() {
        require(msg.sender == owner || msg.sender == keeper, "StratManager: MANAGER_ONLY");
        _;
    }

    // verifies that the caller is not a contract.
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "StratManager: EOA_ONLY");
        _;
    }

    /**
     * @dev Updates address of the strat keeper.
     * @param _keeper new keeper address.
     */
    function setKeeper(address _keeper) external onlyManager {
        keeper = _keeper;
    }

    /**
     * @dev Updates address where strategist fee earnings will go.
     * @param _strategist new strategist address.
     */
    function setStrategist(address _strategist) external {
        require(msg.sender == strategist, "StratManager: STRATEGIST_ONLY");
        strategist = _strategist;
    }

    /**
     * @dev Updates parent vault.
     * @param _vault new vault address.
     */
    function setVault(address _vault) public onlyOwner {
        require(!hadVault, "StratManager: vault had been set up");
        vault = _vault;
        hadVault = true;
    }

    /**
     * @dev Updates CO fee recipient.
     * @param _coFeeRecipient new CO fee recipient address.
     */
    function setCoFeeRecipient(address _coFeeRecipient) external onlyOwner {
        coFeeRecipient = _coFeeRecipient;
    }

    /**
     * @dev Function to synchronize balances before new user deposit.
     * Can be overridden in the strategy.
     */
    function beforeDeposit() external virtual {}
}