// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../utils/Constants.sol";
import "../interfaces/IFeeManager.sol";
import "./LibVault.sol";
import "./LibBrokerManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library LibFeeManager {

    using SafeERC20 for IERC20;

    bytes32 constant FEE_MANAGER_STORAGE_POSITION = keccak256("apollox.fee.manager.storage");

    struct FeeConfig {
        string name;
        uint16 index;
        uint16 openFeeP;     // 1e4
        uint16 closeFeeP;    // 1e4
        bool enable;
    }

    struct FeeManagerStorage {
        // 0/1/2/3/.../ => FeeConfig
        mapping(uint16 => FeeConfig) feeConfigs;
        // feeConfig index => pair.base[]
        mapping(uint16 => address[]) feeConfigPairs;
        // USDT/BUSD/.../ => FeeDetail
        mapping(address => IFeeManager.FeeDetail) feeDetails;
        address daoRepurchase;
        uint16 daoShareP;       // 1e4
    }

    function feeManagerStorage() internal pure returns (FeeManagerStorage storage fms) {
        bytes32 position = FEE_MANAGER_STORAGE_POSITION;
        assembly {
            fms.slot := position
        }
    }

    event AddFeeConfig(uint16 indexed index, uint16 openFeeP, uint16 closeFeeP, string name);
    event RemoveFeeConfig(uint16 indexed index);
    event UpdateFeeConfig(uint16 indexed index,
        uint16 oldOpenFeeP, uint16 oldCloseFeeP,
        uint16 openFeeP, uint16 closeFeeP
    );
    event SetDaoRepurchase(address indexed oldDaoRepurchase, address daoRepurchase);
    event SetDaoShareP(uint16 oldDaoShareP, uint16 daoShareP);
    event OpenFee(address indexed token, uint256 totalFee, uint256 daoAmount, uint24 brokerId, uint256 brokerAmount);
    event CloseFee(address indexed token, uint256 totalFee, uint256 daoAmount, uint24 brokerId, uint256 brokerAmount);

    function initialize(address daoRepurchase, uint16 daoShareP) internal {
        FeeManagerStorage storage fms = feeManagerStorage();
        require(fms.daoRepurchase == address(0), "LibFeeManager: Already initialized");
        setDaoRepurchase(daoRepurchase);
        setDaoShareP(daoShareP);
        // default fee config
        fms.feeConfigs[0] = FeeConfig("Default Fee Rate", 0, 8, 8, true);
        emit AddFeeConfig(0, 8, 8, "Default Fee Rate");
    }

    function addFeeConfig(uint16 index, string calldata name, uint16 openFeeP, uint16 closeFeeP) internal {
        FeeManagerStorage storage fms = feeManagerStorage();
        FeeConfig storage config = fms.feeConfigs[index];
        require(!config.enable, "LibFeeManager: Configuration already exists");
        config.index = index;
        config.name = name;
        config.openFeeP = openFeeP;
        config.closeFeeP = closeFeeP;
        config.enable = true;
        emit AddFeeConfig(index, openFeeP, closeFeeP, name);
    }

    function removeFeeConfig(uint16 index) internal {
        FeeManagerStorage storage fms = feeManagerStorage();
        FeeConfig storage config = fms.feeConfigs[index];
        require(config.enable, "LibFeeManager: Configuration not enabled");
        require(fms.feeConfigPairs[index].length == 0, "LibFeeManager: Cannot remove a configuration that is still in use");
        delete fms.feeConfigs[index];
        emit RemoveFeeConfig(index);
    }

    function updateFeeConfig(uint16 index, uint16 openFeeP, uint16 closeFeeP) internal {
        FeeManagerStorage storage fms = feeManagerStorage();
        FeeConfig storage config = fms.feeConfigs[index];
        require(config.enable, "LibFeeManager: Configuration not enabled");
        (uint16 oldOpenFeeP, uint16 oldCloseFeeP) = (config.openFeeP, config.closeFeeP);
        config.openFeeP = openFeeP;
        config.closeFeeP = closeFeeP;
        emit UpdateFeeConfig(index, oldOpenFeeP, oldCloseFeeP, openFeeP, closeFeeP);
    }

    function setDaoRepurchase(address daoRepurchase) internal {
        FeeManagerStorage storage fms = feeManagerStorage();
        address oldDaoRepurchase = fms.daoRepurchase;
        fms.daoRepurchase = daoRepurchase;
        emit SetDaoRepurchase(oldDaoRepurchase, daoRepurchase);
    }

    function setDaoShareP(uint16 daoShareP) internal {
        FeeManagerStorage storage fms = feeManagerStorage();
        require(daoShareP <= Constants.MAX_DAO_SHARE_P, "LibFeeManager: Invalid allocation ratio");
        uint16 oldDaoShareP = fms.daoShareP;
        fms.daoShareP = daoShareP;
        emit SetDaoShareP(oldDaoShareP, daoShareP);
    }

    function getFeeConfigByIndex(uint16 index) internal view returns (FeeConfig memory, address[] storage) {
        FeeManagerStorage storage fms = feeManagerStorage();
        return (fms.feeConfigs[index], fms.feeConfigPairs[index]);
    }

    function chargeOpenFee(address token, uint256 feeAmount, uint24 broker) internal returns (uint24){
        FeeManagerStorage storage fms = feeManagerStorage();
        IFeeManager.FeeDetail storage detail = fms.feeDetails[token];

        uint256 daoShare = feeAmount * fms.daoShareP / 1e4;
        if (daoShare > 0) {
            IERC20(token).safeTransfer(fms.daoRepurchase, daoShare);
            detail.total += feeAmount;
            detail.daoAmount += daoShare;
        }
        (uint256 commission, uint24 brokerId) = LibBrokerManager.updateBrokerCommission(token, feeAmount, broker);
        detail.brokerAmount += commission;

        uint256 lpAmount = feeAmount - daoShare - commission;
        LibVault.deposit(token, lpAmount);
        emit OpenFee(token, feeAmount, daoShare, brokerId, commission);
        return brokerId;
    }

    function chargeCloseFee(address token, uint256 feeAmount, uint24 broker) internal {
        FeeManagerStorage storage fms = feeManagerStorage();
        IFeeManager.FeeDetail storage detail = fms.feeDetails[token];

        uint256 daoShare = feeAmount * fms.daoShareP / 1e4;
        if (daoShare > 0) {
            IERC20(token).safeTransfer(fms.daoRepurchase, daoShare);
            detail.total += feeAmount;
            detail.daoAmount += daoShare;
        }
        (uint256 commission, uint24 brokerId) = LibBrokerManager.updateBrokerCommission(token, feeAmount, broker);
        detail.brokerAmount += commission;

        uint256 lpAmount = feeAmount - daoShare - commission;
        LibVault.deposit(token, lpAmount);
        emit CloseFee(token, feeAmount, daoShare, brokerId, commission);
    }
}