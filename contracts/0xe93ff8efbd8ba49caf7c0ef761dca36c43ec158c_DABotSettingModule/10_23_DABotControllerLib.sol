// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../../common/Errors.sol";
import "../interfaces/IBotTemplateController.sol";
import "../interfaces/IDABotGovernToken.sol";
import "../interfaces/IDABotManager.sol";
import "../DABotCommon.sol";

struct BotTemplateController {
    mapping(bytes4 => bytes32) selectors;
    mapping(bytes32 => address) moduleAddresses;
    bytes32[] modules;
}

struct BotCoreData {
    BotTemplateController controller;
    BotMetaData metadata;
    BotSetting setting;
}

library DABotTemplateControllerLib {

    using DABotTemplateControllerLib for BotTemplateController;

    bytes32 constant CORE_STORAGE_POSITION = keccak256("core.dabot.storage");

    function coredata() internal pure returns(BotCoreData storage ds) {
        bytes32 position = CORE_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function controller() internal view returns (BotTemplateController storage) {
        return coredata().controller;
    }

    function requireNewModule(bytes32 moduleId) internal view {
        BotTemplateController storage ds = controller();
        require(ds.module(moduleId) == address(0), Errors.BCL_DUPLICATED_MODULE);
    }

    function module(BotTemplateController storage ds, bytes32 moduleId) internal view returns(address) {
        return ds.moduleAddresses[moduleId];
    }

    function moduleOfSelector(BotTemplateController storage ds, bytes4 selector) internal view returns(address) {
        bytes32 moduleId = ds.selectors[selector];
        return ds.moduleAddresses[moduleId];
    }

    function registerModule(BotTemplateController storage ds, bytes32 moduleId, address moduleAddress) internal returns(address oldModuleAddress) {
        oldModuleAddress = ds.moduleAddresses[moduleId];
        ds.moduleAddresses[moduleId] = moduleAddress;
    }

    function registerSelectors(BotTemplateController storage ds, bytes32 moduleId, bytes4[] memory selectors) internal {
        for(uint i = 0; i < selectors.length; i++)
            ds.selectors[selectors[i]] = moduleId;
    }

    
}

library DABotMetaLib {

    using DABotMetaLib for BotMetaData;
    using DABotTemplateControllerLib for BotTemplateController;

    bytes32 constant CORE_STORAGE_POSITION = keccak256("core.dabot.storage");

    function coredata() internal pure returns(BotCoreData storage ds) {
        bytes32 position = CORE_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function metadata() internal view returns (BotMetaData storage) {
        return coredata().metadata;
    }

    function manager(BotMetaData storage ds) internal view returns(IDABotManager _manager) {
        _manager = IDABotManager(ds.botManager);
        require(address(_manager) != address(0), Errors.BCL_BOT_MANAGER_IS_NOT_CONFIGURED);
    }

    function configurator(BotMetaData storage ds) internal view returns(IConfigurator _config) {
        _config = ds.manager().configurator();
    }

    function factory(BotMetaData storage ds) internal view returns(IRoboFiFactory _factory) {
        IConfigurator config = ds.configurator();
        _factory = IRoboFiFactory(config.addressOf(AddressBook.ADDR_FACTORY));
        require(address(_factory) != address(0), Errors.CM_FACTORY_ADDRESS_IS_NOT_CONFIGURED);
    }

    function governToken(BotMetaData storage ds) internal view returns(IDABotGovernToken) {
        address gToken = ds.gToken;
        require(gToken != address(0), Errors.BCL_GOVERN_TOKEN_IS_NOT_DEPLOYED);
        return IDABotGovernToken(gToken);
    }

    function module(BotMetaData storage ds, bytes32 moduleId) internal view returns(address) {
        if (ds.botTemplate == address(0)) {
            return DABotTemplateControllerLib.controller().module(moduleId);
        }
        return IBotTemplateController(ds.botTemplate).module(moduleId);
    }

    function deployCertToken(BotMetaData storage ds, address asset) internal returns(address) {
        address certTokenMaster = ds.module(BOT_CERT_TOKEN_TEMPLATE_ID);
        if (certTokenMaster == address(0)) {
            revert(string(abi.encodePacked(
                Errors.BCL_CERT_TOKEN_IS_NOT_CONFIGURED, 
                '. template: ', 
                Strings.toHexString(uint160(ds.botTemplate), 20)
                )));
        }
        require(certTokenMaster != address(0), Errors.BCL_CERT_TOKEN_IS_NOT_CONFIGURED);

        return ds.factory().deploy(
            certTokenMaster,
            abi.encode(address(this), asset),
            false
        );
    }

    function deployGovernanceToken(BotMetaData storage ds) internal returns(address) {
        address governTokenMaster = ds.module(BOT_GOV_TOKEN_TEMPLATE_ID);
        require(governTokenMaster != address(0), Errors.BCL_GOVERN_TOKEN_IS_NOT_CONFIGURED);

        return ds.factory().deploy(
            governTokenMaster,
            abi.encode(address(this)),
            false
        );
    }

    function deployLocker(BotMetaData storage ds, bytes32 lockerType, LockerData memory data) internal returns(address) {
        address lockerMaster = ds.module(lockerType);
        if (lockerMaster == address(0)) {
            if (lockerType == BOT_CERT_TOKEN_COOLDOWN_HANDLER_ID) 
                revert(Errors.BCL_COOLDOWN_LOCKER_IS_NOT_CONFIGURED);
            revert(Errors.BCL_UKNOWN_MODULE_ID);
        }
        return ds.factory().deploy(
            lockerMaster,
            abi.encode(data),
            false
        );
    }
}