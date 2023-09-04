// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./registry/CompaniesRegistry.sol";
import "./registry/RecordsRegistry.sol";
import "./registry/TokensRegistry.sol";

/**
 * @title Registry Contract
 * @notice This contract serves as a registry to store all events, contracts, and proposals of all pools using global sequential numbering.
 * @dev The repository of all user and business entities created by the protocol: companies to be implemented, contracts to be deployed, proposals created by shareholders. The main logic of the registry is implemented in contracts that inherit from Registry.
 */
contract Registry is CompaniesRegistry, RecordsRegistry, TokensRegistry {
    /// @dev This mapping stores the correspondence between the pool address, the local proposal number, and its global number registered in the registry.
    mapping(address => mapping(uint256 => uint256)) public globalProposalIds;
    event Log(address sender, address receiver, uint256 value, bytes data);

    mapping(uint256 => address) public companyAddress;

    /**
     * @notice Contract constructor.
     * @dev This contract uses OpenZeppelin upgrades and has no need for a constructor function.
     * The constructor is replaced with an initializer function.
     * This method disables the initializer feature of the OpenZeppelin upgrades plugin, preventing the initializer methods from being misused.
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Contract initializer
     * @dev This method replaces the constructor for upgradeable contracts.
     */
    function initialize() public initializer {
        __RegistryBase_init();
    }

    // INTERNAL FUNCTIONS

    /**
     * @dev Update global proposal ID
     * @param pool Pool address
     * @param proposalId Local Proposal ID
     * @param globalProposalId Global Proposal ID
     */
    function setGlobalProposalId(
        address pool,
        uint256 proposalId,
        uint256 globalProposalId
    ) internal override {
        globalProposalIds[pool][proposalId] = globalProposalId;
    }

    function _setIndexAddress(uint256 index, address poolAddress) internal override {

        companyAddress[index] = poolAddress;
    }

    // VIEW FUNCTIONS

    function getPoolAddressByIndex(
        uint256 index
    ) public view returns (address) {
        return companyAddress[index];
    }

    /**
     * @dev Return global proposal ID
     * @param pool Pool address
     * @param proposalId Proposal ID
     * @return Global proposal ID
     */
    function getGlobalProposalId(
        address pool,
        uint256 proposalId
    ) public view returns (uint256) {
        return globalProposalIds[pool][proposalId];
    }

    function log(
        address sender,
        address receiver,
        uint256 value,
        bytes memory data
    ) external {
        require(
            msg.sender == address(this) ||
                msg.sender == service ||
                msg.sender == address(IService(service).tgeFactory()) ||
                msg.sender == address(IService(service).invoice()) ||
                msg.sender == address(IService(service).vesting()) ||
                typeOf(msg.sender) == IRecordsRegistry.ContractType.Pool ||
                typeOf(msg.sender) == IRecordsRegistry.ContractType.TGE ||
                typeOf(msg.sender) ==
                IRecordsRegistry.ContractType.GovernanceToken ||
                typeOf(msg.sender) ==
                IRecordsRegistry.ContractType.PreferenceToken,
            ExceptionsLibrary.INVALID_USER
        );
        // Emit event
        emit Log(sender, receiver, value, data);
    }
}