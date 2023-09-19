// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "../../common/IConfigurator.sol";
import "../interfaces/IDABotSettingModule.sol";
import "../DABotModule.sol";
import "./DABotSettingLib.sol";

contract DABotSettingModule is DABotModule, IDABotSettingModuleEvent {

    using DABotSettingLib for BotSetting;
    using DABotSettingLib for SettingStorage;
    using DABotTemplateControllerLib for BotTemplateController;

    /**
    @dev Ensure the modification of bot settings to comply with the following rule:

    Before the IBO time, bot owner could freely change the bot setting.
    After the IBO has started, bot settings must be changed via the voting protocol.
     */
    modifier SettingGuard() {
        DABotSettingLib.requireSettingChangable(msg.sender);
        _;
    }

    function _onRegister(address moduleAddress) internal override {
        BotTemplateController storage ds = DABotTemplateControllerLib.controller();
        ds.registerModule(IDABotSettingModuleID, moduleAddress);
        bytes4[15] memory selectors =  [
            IDABotSettingModule.status.selector,
            IDABotSettingModule.iboTime.selector,
            IDABotSettingModule.stakingTime.selector,
            IDABotSettingModule.pricePolicy.selector,
            IDABotSettingModule.profitSharing.selector,
            IDABotSettingModule.setIBOTime.selector,
            IDABotSettingModule.setStakingTime.selector,
            IDABotSettingModule.setPricePolicy.selector,
            IDABotSettingModule.setProfitSharing.selector,

            IDABotSettingModule.readAddress.selector,
            IDABotSettingModule.readUint.selector,
            IDABotSettingModule.readBytes.selector,
            IDABotSettingModule.writeAddress.selector,
            IDABotSettingModule.writeUint.selector,
            IDABotSettingModule.writeBytes.selector
        ];
        for (uint i = 0; i < selectors.length; i++)
            ds.selectors[selectors[i]] = IDABotSettingModuleID;

        emit ModuleRegistered("IDABotSettingModule", IDABotSettingModuleID, moduleAddress);
    }

    function _initialize(bytes calldata data) internal override {
        BotCoreData storage ds = DABotSettingLib.coredata();
        BotSetting memory setting = abi.decode(data, (BotSetting));
        IConfigurator config = configurator();

        require(setting.iboEndTime() > setting.iboStartTime(), Errors.BSMOD_IBO_ENDTIME_IS_SOONER_THAN_IBO_STARTTIME);
        require(setting.initDeposit >= config.configOf(Config.CREATOR_DEPOSIT), Errors.BSMOD_INIT_DEPOSIT_IS_LESS_THAN_CONFIGURED_THRESHOLD);
        require(setting.initFounderShare > 0, Errors.BSMOD_FOUNDER_SHARE_IS_ZERO);
        require(setting.maxShare >= setting.iboShare + setting.initFounderShare, Errors.BSMOD_INSUFFICIENT_MAX_SHARE);
        // require(setting.initFounderShare <= setting.iboShare, Errors.BSMOD_FOUNDER_SHARE_IS_GREATER_THAN_IBO_SHARE);

        ds.setting = setting;

        emit SettingChanged(0, setting);
    }

    function moduleInfo() external pure override returns(string memory name, string memory version, bytes32 moduleId) {
        name = "DABotSettingModule";
        version = "v0.1.211201";
        moduleId = IDABotSettingModuleID;
    }

    function status() external view returns(BotStatus) {
        return DABotSettingLib.setting().status();
    }

    function iboTime() external view returns(uint startTime, uint endTime) {
        BotSetting storage _setting = DABotSettingLib.setting();
        startTime = _setting.iboStartTime();
        endTime = _setting.iboEndTime();
    }

    /**
    @dev Retrieves the staking settings of this bot, including the warm-up and cool-down time.
     */
    function stakingTime() external view returns(uint warmup, uint cooldown, uint unit) {
        BotSetting storage _setting = DABotSettingLib.setting();
        warmup = _setting.warmupTime();
        cooldown = _setting.cooldownTime();
        unit = _setting.stakingTimeUnit();
    }

    /**
    @dev Retrieves the pricing policy of this bot, including the after-IBO price multiplier and commission.
     */
    function pricePolicy() external view returns(uint priceMul, uint commission) {
        BotSetting storage _setting = DABotSettingLib.setting();
        priceMul = _setting.priceMultiplier();
        commission = _setting.commission();
    }

    /**
    @dev Retrieves the profit sharing scheme of this bot.
     */
    function profitSharing() external view returns(uint144) {
        BotSetting storage _setting = DABotSettingLib.setting();
        return _setting.profitSharing;
    }

    function setIBOTime(uint startTime, uint endTime) external SettingGuard {
        BotSetting storage _setting = DABotSettingLib.setting();
        _setting.setIboTime(startTime, endTime);
        emit SettingChanged(0, _setting);
    }
    
    function setStakingTime(uint warmup, uint cooldown, uint unit) external SettingGuard {
        BotSetting storage _setting = DABotSettingLib.setting();
        _setting.setStakingTime(warmup, cooldown, unit);
        emit SettingChanged(1, _setting);
    }

    function setPricePolicy(uint priceMul, uint commission) external SettingGuard {
        BotSetting storage _setting = DABotSettingLib.setting();
        _setting.setPricePolicy(priceMul, commission);
        emit SettingChanged(2, _setting);
    }

    function setProfitSharing(uint sharingScheme) external SettingGuard {
        BotSetting storage _setting = DABotSettingLib.setting();
        _setting.setProfitShare(sharingScheme);
        emit SettingChanged(3, _setting);
    }

    function readAddress(bytes32 itemId, address defaultAddress) external view returns(address) {
        return DABotSettingLib.settingStorage().readAddress(itemId, defaultAddress);
    }

    function readUint(bytes32 itemId, uint defaultValue) external view returns(uint) {
        return DABotSettingLib.settingStorage().readUint(itemId, defaultValue);
    }

    function readBytes(bytes32 itemId, bytes calldata defaultValue) external view returns(bytes memory) {
        return DABotSettingLib.settingStorage().readBytes(itemId, defaultValue);
    }

    function writeAddress(bytes32 itemId, address value) external SettingGuard {
        DABotSettingLib.settingStorage().writeAddress(itemId, value);
        emit AddressWritten(itemId, value);
    }

    function writeUint(bytes32 itemId, uint value) external SettingGuard {
        DABotSettingLib.settingStorage().writeUint(itemId, value);
        emit UintWritten(itemId, value);
    }

    function writeBytes(bytes32 itemId, bytes calldata value) external SettingGuard {
        DABotSettingLib.settingStorage().writeBytes(itemId, value);
        emit BytesWritten(itemId, value);
    }
}