// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma abicoder v2;

import "./interfaces.sol";

contract ConstantVariables {
    AaveInterface internal immutable aave;

    AavePoolProviderInterface internal immutable aavePoolAddressProvider;

    ListInterface internal immutable instaList;

    constructor(address aavePoolAddressesProvider_, address instaList_) {
        aavePoolAddressProvider = AavePoolProviderInterface(
            aavePoolAddressesProvider_
        );

        aave = AaveInterface(
            AavePoolProviderInterface(aavePoolAddressesProvider_)
                .getLendingPool()
        );

        instaList = ListInterface(instaList_);
    }
}

contract Structs {
    enum Status {
        NOT_INITIATED, // no automation enabled for user
        AUTOMATED, // User enabled automation
        DROPPED, // Automation dropped by system
        CANCELLED // user cancelled the automation
    }

    struct Spell {
        string[] _targets;
        bytes[] _datas;
    }

    struct Swap {
        address buyToken;
        address sellToken;
        uint256 sellAmt;
        uint256 unitAmt;
        bytes callData;
    }

    struct Automation {
        address user;
        Status status;
        uint32 nonce;
        uint128 safeHF;
        uint128 thresholdHF;
    }

    struct ExecutionParams {
        address collateralToken;
        address debtToken;
        uint256 collateralAmount;
        uint256 debtAmount;
        uint256 collateralAmountWithTotalFee;
        Swap swap;
        uint256 route;
        uint256 rateMode;
    }
}

contract Variables is ConstantVariables, Structs {
    address public _owner; // The owner of address(this)

    uint8 public _status; // initialise status check
    uint16 public _automationFee; // Automation fees in BPS
    uint32 public _id; // user automation id
    uint128 public _minimumThresholdHf; // minimum threshold Health required for enabled automation
    uint128 public _bufferHf; // buffer health factor for next automaion check

    mapping(uint32 => Automation) public _userAutomationConfigs; // user automation config

    mapping(address => uint32) public _userLatestId; // user latest automation id

    mapping(address => bool) public _executors; // executors enabled by _owner

    constructor(address aavePoolAddressesProvider_, address instaList_)
        ConstantVariables(aavePoolAddressesProvider_, instaList_)
    {}
}