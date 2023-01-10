// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Staking.sol";
import "./StakingStorage.sol";
import "./Converter.sol";
import "./EnergyStorage.sol";
import "./helpers/PermissionControl.sol";
import "./helpers/Util.sol";

/**
 * @dev ASM Genome Mining - Registry contract
 * @notice We use this contract to manage contracts addresses
 * @notice when we need to update some of them.
 */
contract Controller is Util, PermissionControl {
    Staking private _stakingLogic;
    StakingStorage private _astoStorage;
    StakingStorage private _lpStorage;
    Converter private _converterLogic;
    EnergyStorage private _energyStorage;
    EnergyStorage private _lbaEnergyStorage;
    IERC20 private _astoToken;
    IERC20 private _lpToken;
    address private _dao;
    address private _multisig;

    bool private _initialized;

    uint256 public constant ASTO_TOKEN_ID = 0;
    uint256 public constant LP_TOKEN_ID = 1;

    event ContractUpgraded(uint256 timestamp, string contractName, address oldAddress, address newAddress);

    constructor(address multisig) {
        if (!_isContract(multisig)) revert InvalidInput(INVALID_MULTISIG);
        /**
         * MULTISIG_ROLE is ONLY used for:
         * - initalisation controller
         * - setting periods (mining cycles) for the Converter contract
         */
        _grantRole(MULTISIG_ROLE, multisig);
        _grantRole(DAO_ROLE, multisig);
        _multisig = multisig;
    }

    function init(
        address dao,
        address astoToken,
        address astoStorage,
        address lpToken,
        address lpStorage,
        address stakingLogic,
        address converterLogic,
        address energyStorage,
        address lbaEnergyStorage
    ) external onlyRole(MULTISIG_ROLE) {
        if (!_initialized) {
            if (!_isContract(dao)) revert InvalidInput(INVALID_DAO);
            if (!_isContract(astoToken)) revert InvalidInput(INVALID_ASTO_CONTRACT);
            if (!_isContract(astoStorage)) revert InvalidInput(INVALID_STAKING_STORAGE);
            if (!_isContract(lpToken)) revert InvalidInput(INVALID_LP_CONTRACT);
            if (!_isContract(lpStorage)) revert InvalidInput(INVALID_STAKING_STORAGE);
            if (!_isContract(stakingLogic)) revert InvalidInput(INVALID_STAKING_LOGIC);
            if (!_isContract(converterLogic)) revert InvalidInput(INVALID_CONVERTER_LOGIC);
            if (!_isContract(energyStorage)) revert InvalidInput(INVALID_ENERGY_STORAGE);
            if (!_isContract(lbaEnergyStorage)) revert InvalidInput(INVALID_ENERGY_STORAGE);
            _clearRole(DAO_ROLE);
            _grantRole(DAO_ROLE, dao);

            // Saving addresses on init:
            _dao = dao;
            _astoToken = IERC20(astoToken);
            _astoStorage = StakingStorage(astoStorage);
            _lpToken = IERC20(lpToken);
            _lpStorage = StakingStorage(lpStorage);
            _stakingLogic = Staking(stakingLogic);
            _converterLogic = Converter(converterLogic);
            _energyStorage = EnergyStorage(energyStorage);
            _lbaEnergyStorage = EnergyStorage(lbaEnergyStorage);

            // Initializing contracts
            _upgradeContracts(
                astoToken,
                astoStorage,
                lpToken,
                lpStorage,
                stakingLogic,
                converterLogic,
                energyStorage,
                lbaEnergyStorage
            );
            _initialized = true;
        }
    }

    /** ----------------------------------
     * ! Private functions | Setters
     * ----------------------------------- */

    /**
     * @notice Each contract has own params to initialize
     * @notice Contracts with no address specified will be skipped
     * @dev Internal functions, can be called from constructor OR
     * @dev after authentication by the public function `upgradeContracts()`
     */
    function _upgradeContracts(
        address astoToken,
        address astoStorage,
        address lpToken,
        address lpStorage,
        address stakingLogic,
        address converterLogic,
        address energyStorage,
        address lbaEnergyStorage
    ) internal {
        if (_isContract(astoToken)) _setAstoToken(astoToken);
        if (_isContract(astoStorage)) _setAstoStorage(astoStorage);
        if (_isContract(lpToken)) _setLpToken(lpToken);
        if (_isContract(lpStorage)) _setLpStorage(lpStorage);
        if (_isContract(stakingLogic)) _setStakingLogic(stakingLogic);
        if (_isContract(energyStorage)) _setEnergyStorage(energyStorage);
        if (_isContract(lbaEnergyStorage)) _setLBAEnergyStorage(lbaEnergyStorage);
        if (_isContract(converterLogic)) _setConverterLogic(converterLogic);
        _setController(address(this));
    }

    function _setDao(address dao) internal {
        _dao = dao;
        _clearRole(DAO_ROLE);
        _grantRole(DAO_ROLE, dao);
        _grantRole(MULTISIG_ROLE, dao);
        _stakingLogic.setDao(dao);
        _converterLogic.setDao(dao);
    }

    function _setMultisig(address multisig) internal {
        _multisig = multisig;
        _clearRole(MULTISIG_ROLE);
        _grantRole(MULTISIG_ROLE, multisig);
        _grantRole(MULTISIG_ROLE, _dao);
        _converterLogic.setMultisig(multisig, _dao);
    }

    function _setController(address newContract) internal {
        _stakingLogic.setController(newContract);
        _astoStorage.setController(newContract);
        _lpStorage.setController(newContract);
        _converterLogic.setController(newContract);
        _energyStorage.setController(newContract);
        _lbaEnergyStorage.setController(newContract);
        emit ContractUpgraded(block.timestamp, "Controller", address(this), newContract);
    }

    function _setStakingLogic(address newContract) internal {
        // revoke consumer role to old staking storage contract
        if (_isContract(address(_stakingLogic))) {
            _astoStorage.removeConsumer(address(_stakingLogic));
            _lpStorage.removeConsumer(address(_stakingLogic));
        }

        uint256 lockedAsto = _stakingLogic.totalStakedAmount(ASTO_TOKEN_ID);
        uint256 lockedLp = _stakingLogic.totalStakedAmount(LP_TOKEN_ID);

        _stakingLogic = Staking(newContract);
        _stakingLogic.init(
            address(_dao),
            IERC20(_astoToken),
            address(_astoStorage),
            IERC20(_lpToken),
            address(_lpStorage),
            lockedAsto,
            lockedLp
        );
        _astoStorage.addConsumer(newContract);
        _lpStorage.addConsumer(newContract);
        emit ContractUpgraded(block.timestamp, "Staking Logic", address(this), newContract);
    }

    function _setAstoToken(address newContract) internal {
        _astoToken = IERC20(newContract);
        emit ContractUpgraded(block.timestamp, "ASTO Token", address(this), newContract);
    }

    function _setAstoStorage(address newContract) internal {
        _astoStorage = StakingStorage(newContract);
        _astoStorage.init(address(_stakingLogic));
        emit ContractUpgraded(block.timestamp, "ASTO Staking Storage", address(this), newContract);
    }

    function _setLpToken(address newContract) internal {
        _lpToken = IERC20(newContract);
        emit ContractUpgraded(block.timestamp, "LP Token", address(this), newContract);
    }

    function _setLpStorage(address newContract) internal {
        _lpStorage = StakingStorage(newContract);
        _lpStorage.init(address(_stakingLogic));
        emit ContractUpgraded(block.timestamp, "LP Staking Storage", address(this), newContract);
    }

    function _setConverterLogic(address newContract) internal {
        // revoke consumer role to old energy storage contract
        if (_isContract(address(_converterLogic))) {
            _lbaEnergyStorage.removeConsumer(address(_converterLogic));
            _energyStorage.removeConsumer(address(_converterLogic));
        }

        _converterLogic = Converter(newContract);
        _converterLogic.init(
            address(_dao),
            address(_multisig),
            address(_energyStorage),
            address(_lbaEnergyStorage),
            address(_stakingLogic)
        );
        _lbaEnergyStorage.addConsumer(newContract);
        _energyStorage.addConsumer(newContract);
        emit ContractUpgraded(block.timestamp, "Converter Logic", address(this), newContract);
    }

    function _setEnergyStorage(address newContract) internal {
        _energyStorage = EnergyStorage(newContract);
        _energyStorage.init(address(_converterLogic));
        emit ContractUpgraded(block.timestamp, "Energy Storage", address(this), newContract);
    }

    function _setLBAEnergyStorage(address newContract) internal {
        _lbaEnergyStorage = EnergyStorage(newContract);
        _lbaEnergyStorage.init(address(_converterLogic));
        emit ContractUpgraded(block.timestamp, "LBA Energy Storage", address(this), newContract);
    }

    /** ----------------------------------
     * ! External functions | Manager Role
     * ----------------------------------- */

    /**
     * @notice The way to upgrade contracts
     * @notice Only Manager address (_dao wallet) has access to upgrade
     * @notice All parameters are optional
     */
    function upgradeContracts(
        address astoToken,
        address astoStorage,
        address lpToken,
        address lpStorage,
        address stakingLogic,
        address converterLogic,
        address energyStorage,
        address lbaEnergyStorage
    ) external onlyRole(DAO_ROLE) {
        _upgradeContracts(
            astoToken,
            astoStorage,
            lpToken,
            lpStorage,
            stakingLogic,
            converterLogic,
            energyStorage,
            lbaEnergyStorage
        );
    }

    function setDao(address dao) external onlyRole(DAO_ROLE) {
        _setDao(dao);
    }

    function setMultisig(address multisig) external onlyRole(DAO_ROLE) {
        _setMultisig(multisig);
    }

    function setController(address newContract) external onlyRole(DAO_ROLE) {
        _setController(newContract);
    }

    function setStakingLogic(address newContract) external onlyRole(DAO_ROLE) {
        _setStakingLogic(newContract);
    }

    function setAstoStorage(address newContract) external onlyRole(DAO_ROLE) {
        _setAstoStorage(newContract);
    }

    function setLpStorage(address newContract) external onlyRole(DAO_ROLE) {
        _setLpStorage(newContract);
    }

    function setConverterLogic(address newContract) external onlyRole(DAO_ROLE) {
        _setConverterLogic(newContract);
    }

    function setEnergyStorage(address newContract) external onlyRole(DAO_ROLE) {
        _setEnergyStorage(newContract);
    }

    function setLBAEnergyStorage(address newContract) external onlyRole(DAO_ROLE) {
        _setLBAEnergyStorage(newContract);
    }

    // DAO and MULTISIG can call this function
    function pause() external onlyRole(MULTISIG_ROLE) {
        if (!_stakingLogic.paused()) {
            _stakingLogic.pause();
        }

        if (!_converterLogic.paused()) {
            _converterLogic.pause();
        }
    }

    // DAO and MULTISIG can call this function
    function unpause() external onlyRole(MULTISIG_ROLE) {
        if (_stakingLogic.paused()) {
            _stakingLogic.unpause();
        }

        if (_converterLogic.paused()) {
            _converterLogic.unpause();
        }
    }

    /** ----------------------------------
     * ! Public functions | Getters
     * ----------------------------------- */

    function getController() external view returns (address) {
        return address(this);
    }

    function getDao() external view returns (address) {
        return _dao;
    }

    function getMultisig() external view returns (address) {
        return _multisig;
    }

    function getStakingLogic() external view returns (address) {
        return address(_stakingLogic);
    }

    function getAstoStorage() external view returns (address) {
        return address(_astoStorage);
    }

    function getLpStorage() external view returns (address) {
        return address(_lpStorage);
    }

    function getConverterLogic() external view returns (address) {
        return address(_converterLogic);
    }

    function getEnergyStorage() external view returns (address) {
        return address(_energyStorage);
    }

    function getLBAEnergyStorage() external view returns (address) {
        return address(_lbaEnergyStorage);
    }
}