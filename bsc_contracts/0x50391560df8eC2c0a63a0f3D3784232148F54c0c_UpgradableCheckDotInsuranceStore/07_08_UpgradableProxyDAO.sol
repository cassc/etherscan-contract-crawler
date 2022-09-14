// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./utils/ProxyUpgrades.sol";
import "./utils/ProxyAddresses.sol";
import "./utils/ProxyBool.sol";
import "./utils/ProxyVoteDurations.sol";
import "./interfaces/IERC20BalanceAndDecimals.sol";

/**
 * @title UpgradableProxyDAO
 * @author Jeremy Guyet (@jguyet)
 * @dev Smart contract to implement on a contract proxy.
 * This contract allows the management of the important memory of a proxy.
 * The memory spaces are extremely far from the beginning of the memory
 * which allows a high security against collisions.
 * This contract allows updates using a DAO program governed by an
 * ERC20 governance token. A voting session is mandatory for each update.
 * All holders of at least one whole token are eligible to vote.
 * There are several memory locations dedicated to the proper functioning
 * of the proxy (Implementation, admin, governance, upgrades).
 * For more information about the security of these locations please refer
 * to the discussions around the EIP-1967 standard we have been inspired by.
 */
contract UpgradableProxyDAO {
    using ProxyAddresses for ProxyAddresses.AddressSlot;
    using ProxyBool for ProxyBool.BoolSlot;
    using ProxyVoteDurations for ProxyVoteDurations.VoteDurationSlot;
    using ProxyUpgrades for ProxyUpgrades.Upgrades;
    using ProxyUpgrades for ProxyUpgrades.Upgrade;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1
     */
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Storage slot with the address of the gorvenance token of the contract.
     * This is the keccak-256 hash of "checkdot.io.proxy.governance-token" subtracted by 1
     */
    bytes32 private constant _GOVERNANCE_SLOT = 0x6dad0f23c7599fe058f6d945cb006fc2efdeec546a7309619015b2fe6aafe749;

    /**
     * @dev Storage slot with the upgrades of the contract.
     * This is the keccak-256 hash of "checkdot.io.proxy.upgrades" subtracted by 1
     */
    bytes32 private constant _UPGRADES_SLOT = 0x6190170739ac7613eca8f8497702a38493865185ee4d45c91d18b0973eef39a8;

    /**
     * @dev Storage slot with the upgrades of the contract.
     * This is the keccak-256 hash of "checkdot.io.proxy.vote.duration" subtracted by 1
     */
    bytes32 private constant _VOTE_DURATION_SLOT = 0x3dbc3e8463648688016ac4674e4344b3e465f24bb2b8d250193e1371f4fe1b31;

    /**
     * @dev Storage slot with the upgrades of the contract.
     * This is the keccak-256 hash of "checkdot.io.proxy.production" subtracted by 1
     */
    bytes32 private constant _IS_PRODUCTION_SLOT = 0xdb4027e5ac6ab1244eeafe40a76baa5f57763046d91d31b60a29e63885da6ed3;

    /**
     * @dev Storage slot with the graal mode of the contract.
     * This is the keccak-256 hash of "checkdot.io.proxy.graal" subtracted by 1
     */
    bytes32 private constant _THE_GRAAL_SLOT = 0xc11b5cd5592b4c028201fe20d869d004ea2f18eecb6daa132a73e7a1039a3d7c;

    constructor(address _cdtGouvernanceAddress) {
        _setOwner(msg.sender);
        _setGovernance(_cdtGouvernanceAddress);
        _setInProduction(false);
        _setVoteDuration(86400); // 1 day
        _setTheGraal(false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    /**
     * @dev Returns the current Owner address.
     */
    function getOwner() external view returns (address) {
        return _getOwner();
    }

    /**
     * @dev Returns the current Governance address.
     */
    function getGovernance() external view returns (address) {
        return _getGovernance();
    }

    /**
     * @dev Returns the current vote duration.
     */
    function getVoteDuration() external view returns (uint256) {
        return _getVoteDuration();
    }

    /**
     * @dev Returns if the proxy is in production. (Irreversible)
     */
    function isInProduction() external view returns (bool) {
        return _isInProduction();
    }

    /**
     * @dev Enable the production Mode when is in production all upgrades need DAO vote.
     */
    function setInProduction() external payable {
        require(_getOwner() == msg.sender, "Proxy: FORBIDDEN");
        _setInProduction(true);
    }

    /**
     * @dev Returns if the protocol do have the graal. (Irreversible)
     */
    function doHaveTheGraal() external view returns (bool) {
        return _doHaveTheGraal();
    }

    /**
     * @dev Enable the Full Decentralized Mode when is in production.
     */
    function setTheGraal() external payable {
        require(_getOwner() == msg.sender, "Proxy: FORBIDDEN");
        require(_isInProduction() == true, "Proxy: FORBIDDEN_ONLY_IN_PROD");
        _setTheGraal(true);
    }

    /**
     * @dev Set the Vote Duration minimum of 1 day.
     */
    function setVoteDuration(uint256 _newVoteDuration) external payable {
        require(_getOwner() == msg.sender, "Proxy: FORBIDDEN");
        _setVoteDuration(_newVoteDuration);
    }

    /**
     * @dev Transfer the ownership onlyOwner can call this function.
     */
    function transferOwnership(address _newOwner) external payable {
        require(_getOwner() == msg.sender, "Proxy: FORBIDDEN");
        _setOwner(_newOwner);
    }

    /**
     * @dev Creation and update function of the proxified implementation,
     * the entry of a start date and an end date of the voting period by
     * the governance is necessary. The start date of the period must be
     * greater or equals than the `block.timestamp`.
     * The start date and end date of the voting period must be at least
     * 86400 seconds apart.
     */
    function upgrade(address _newAddress, bytes memory _initializationData) external payable {
        require(_getOwner() == msg.sender, "Proxy: FORBIDDEN");
        require(_doHaveTheGraal() == false, "Proxy: THE_GRAAL");
        if (_isInProduction() == false) {
            _upgrade(_newAddress, _initializationData);
        } else {
            ProxyUpgrades.Upgrades storage _proxyUpgrades = ProxyUpgrades.getUpgradesSlot(_UPGRADES_SLOT).value;

            require(_proxyUpgrades.isEmpty() || _proxyUpgrades.current().isFinished, "Proxy: UPGRADE_ALREADY_INPROGRESS");
            _proxyUpgrades.add(_newAddress, _initializationData, block.timestamp, block.timestamp + _getVoteDuration());
        }
    }

    /**
     * @dev Function to check the result of the vote of the implementation
     * update.
     * Only called by the owner and if the vote is favorable the
     * implementation is changed and a call to the initialize function of
     * the new implementation will be made.
     */
    function voteUpgradeCounting() external payable {
        require(_getOwner() == msg.sender, "Proxy: FORBIDDEN");
        require(_doHaveTheGraal() == false, "Proxy: THE_GRAAL");
        ProxyUpgrades.Upgrades storage _proxyUpgrades = ProxyUpgrades.getUpgradesSlot(_UPGRADES_SLOT).value;

        require(!_proxyUpgrades.isEmpty(), "Proxy: EMPTY");
        require(_proxyUpgrades.current().voteFinished(), "Proxy: VOTE_ALREADY_INPROGRESS");
        require(!_proxyUpgrades.current().isFinished, "Proxy: UPGRADE_ALREADY_FINISHED");

        _proxyUpgrades.current().setFinished(true);
        if (_proxyUpgrades.current().totalApproved > _proxyUpgrades.current().totalUnapproved) {
            _upgrade(_proxyUpgrades.current().submitedNewFunctionalAddress, _proxyUpgrades.current().initializationData);
        }
    }

    /**
     * @dev Function callable by the holder of at least one unit of the
     * governance token.
     * A voter can only vote once per update.
     */
    function voteUpgrade(bool approve) external payable {
        ProxyUpgrades.Upgrades storage _proxyUpgrades = ProxyUpgrades.getUpgradesSlot(_UPGRADES_SLOT).value;

        require(!_proxyUpgrades.isEmpty(), "Proxy: EMPTY");
        require(!_proxyUpgrades.current().isFinished, "Proxy: VOTE_FINISHED");
        require(_proxyUpgrades.current().voteInProgress(), "Proxy: VOTE_NOT_STARTED");
        require(!_proxyUpgrades.current().hasVoted(_proxyUpgrades, msg.sender), "Proxy: ALREADY_VOTED");
        IERC20BalanceAndDecimals token = IERC20BalanceAndDecimals(_getGovernance());
        uint256 votes = token.balanceOf(msg.sender) / (10 ** token.decimals());
        require(votes >= 1, "Proxy: INSUFFISANT_POWER");

        _proxyUpgrades.current().vote(_proxyUpgrades, msg.sender, votes, approve);
    }

    /**
     * @dev Returns the array of all upgrades.
     */
    function getAllUpgrades() external view returns (ProxyUpgrades.Upgrade[] memory) {
        return ProxyUpgrades.getUpgradesSlot(_UPGRADES_SLOT).value.all();
    }

    /**
     * @dev Returns the last upgrade.
     */
    function getLastUpgrade() external view returns (ProxyUpgrades.Upgrade memory) {
        return ProxyUpgrades.getUpgradesSlot(_UPGRADES_SLOT).value.getLastUpgrade();
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return ProxyAddresses.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address _newImplementation) private {
        ProxyAddresses.getAddressSlot(_IMPLEMENTATION_SLOT).value = _newImplementation;
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _getOwner() internal view returns (address) {
        return ProxyAddresses.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setOwner(address _owner) private {
        ProxyAddresses.getAddressSlot(_ADMIN_SLOT).value = _owner;
    }

    /**
     * @dev Returns the governance address.
     */
    function _getGovernance() internal view returns (address) {
        return ProxyAddresses.getAddressSlot(_GOVERNANCE_SLOT).value;
    }

    /**
     * @dev Stores a new address in the governance slot.
     */
    function _setGovernance(address _newGovernance) private {
        ProxyAddresses.getAddressSlot(_GOVERNANCE_SLOT).value = _newGovernance;
    }

    /**
     * @dev Returns boolean DAO is enabled.
     */
    function _isInProduction() internal view returns (bool) {
        return ProxyBool.getBoolSlot(_IS_PRODUCTION_SLOT).value;
    }

    /**
     * @dev Application of the production mode, irreversible change.
     */
    function _setInProduction(bool enabled) private {
        ProxyBool.getBoolSlot(_IS_PRODUCTION_SLOT).value = enabled;
    }

    /**
     * @dev Returns boolean Full decentralization is enabled.
     */
    function _doHaveTheGraal() internal view returns (bool) {
        return ProxyBool.getBoolSlot(_THE_GRAAL_SLOT).value;
    }

    /**
     * @dev Application of the production Full decentralization, irreversible change.
     */
    function _setTheGraal(bool enabled) private {
        ProxyBool.getBoolSlot(_THE_GRAAL_SLOT).value = enabled;
    }

    /**
     * @dev Returns the vote duration.
     */
    function _getVoteDuration() internal view returns (uint256) {
        return ProxyVoteDurations.getVoteDurationSlot(_VOTE_DURATION_SLOT).value;
    }

    /**
     * @dev Stores the vote duration
     */
    function _setVoteDuration(uint256 _newVoteDuration) private {
        require(_newVoteDuration >= 86400, "Proxy: Minimum of one day");
        ProxyVoteDurations.getVoteDurationSlot(_VOTE_DURATION_SLOT).value = _newVoteDuration;
    }

    /**
     * @dev Stores the new implementation address in the implementation slot
     * and call the internal _afterUpgrade function used for calling functions
     * on the new implementation just after the set in the same nonce block.
     */
    function _upgrade(address _newFunctionalAddress, bytes memory _initializationData) internal {
        _setImplementation(_newFunctionalAddress);
        _afterUpgrade(_newFunctionalAddress, _initializationData);
    }

    /**
     * @dev internal virtual function implemented in the Proxy contract.
     * This is called just after all upgrades of the proxy implementation.
     */
    function _afterUpgrade(address _newFunctionalAddress, bytes memory _initializationData) internal virtual { }

}