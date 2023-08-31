//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝


pragma solidity 0.8.16;
//SPDX-License-Identifier: BUSL-1.1

import "../utils/Owner.sol";
import {Errors} from "../utils/Errors.sol";

/** @title Dullahan Registry contract
 *  @author Paladin
 *  @notice Registry, for all Aave related addresses & some Dullahan addresses
 */
contract DullahanRegistry is Owner {

    // Storage

    /** @notice Address of the stkAAVE token */
    address public immutable STK_AAVE;
    /** @notice Address of the AAVE token */
    address public immutable AAVE;

    /** @notice Address of the GHO token */
    address public immutable GHO;
    /** @notice Address of the GHO debt token */
    address public immutable DEBT_GHO;

    /** @notice Address of the Aave v3 Pool */
    address public immutable AAVE_POOL_V3;

    /** @notice Address of the Aave rewards controller */
    address public immutable AAVE_REWARD_COONTROLLER;

    /** @notice Address of the Dullahan Vault */
    address public dullahanVault;

    /** @notice Address of Dullahan Pod Managers */
    address[] public dullahanPodManagers;

    // Events

    /** @notice Event emitted when the Vault is set */
    event SetVault(address indexed vault);
    /** @notice Event emitted when a Manager is added */
    event AddPodManager(address indexed newManager);


    // Constructor
    constructor(
        address _aave,
        address _stkAave,
        address _gho,
        address _ghoDebt,
        address _aavePool,
        address _aaveRewardController
    ) {
        if(
            _aave == address(0)
            || _stkAave == address(0)
            || _gho == address(0)
            || _ghoDebt == address(0)
            || _aavePool == address(0)
            || _aaveRewardController == address(0)
        ) revert Errors.AddressZero();

        STK_AAVE = _stkAave;
        AAVE = _aave;

        GHO = _gho;
        DEBT_GHO = _ghoDebt;

        AAVE_POOL_V3 = _aavePool;

        AAVE_REWARD_COONTROLLER = _aaveRewardController;
    }

    /**
    * @notice Set the Dullahan Vault
    * @param vault address of the vault
    */
    function setVault(address vault) external onlyOwner {
        if(vault == address(0)) revert Errors.AddressZero();
        if(dullahanVault != address(0)) revert Errors.VaultAlreadySet();

        dullahanVault = vault;

        emit SetVault(vault);
    }

    /**
    * @notice Add a Pod Manager
    * @param manager Address of the new manager
    */
    function addPodManager(address manager) external onlyOwner {
        if(manager == address(0)) revert Errors.AddressZero();

        // Check in the Manager list that it's not already present
        address[] memory _managers = dullahanPodManagers;
        uint256 length = _managers.length;
        for(uint256 i; i < length;){
            if(_managers[i] == manager) revert Errors.AlreadyListedManager();
            unchecked { ++i; }
        }

        dullahanPodManagers.push(manager);

        emit AddPodManager(manager);
    }

    /**
    * @notice Get the list of Pod Managers
    * @return address[] : List of Pod Managers
    */
    function getPodManagers() external view returns(address[] memory) {
        return dullahanPodManagers;
    }

}