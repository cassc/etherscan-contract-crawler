// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {IRDNRegistry} from "../RDN/interfaces/IRDNRegistry.sol";
import {IAMPERProject} from "./interfaces/IAMPERProject.sol";
import {IAMPEREstimator} from "./interfaces/IAMPEREstimator.sol";

contract AMPEREstimatorV1 is IAMPEREstimator, AccessControlEnumerable {

    IRDNRegistry public immutable registry;
    IAMPERProject public immutable amper;
    uint public startPrice;
    uint public priceMoveStep;
    uint public priceMoveThreshold;

    uint[2][10] public promoBonusConfig = [
        [0, 0],
        [0, 0],
        [0, 0],
        [0, 0],
        [0, 0],
        [0, 0],
        [0, 0],
        [0, 0],
        [0, 0],
        [0, 0]
    ];
    bool public promoBonusActive = false;

    uint public onceBonusBase;
    mapping(uint => uint) public onceBonusValues;
    uint[] public onceBonusTakers;

    bytes32 public constant CONFIG_ROLE = keccak256("CONFIG_ROLE");

    constructor (
        address _registry, 
        address _amper, 
        address _admin, 
        uint _startPrice,
        uint _priceMoveStep,
        uint _priceMoveThreshld,
        uint _onceBonusBase) 
    {
        registry = IRDNRegistry(_registry);
        amper = IAMPERProject(_amper);

        startPrice = _startPrice;
        priceMoveStep = _priceMoveStep;
        priceMoveThreshold = _priceMoveThreshld;

        onceBonusBase = _onceBonusBase;

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(CONFIG_ROLE, _admin);
    }

    function estimateAmountOut(uint _userId, uint _amountIn) public view returns(uint, uint) {
        uint _startPrice = startPrice;
        uint _step = priceMoveStep;
        uint _threshold = priceMoveThreshold;
        uint _distributed = amper.distributed();
        uint remained = _amountIn;
        uint amountOut = 0;
        while (remained > 0) {
            uint currentStage = _distributed / _threshold;
            uint currentPrice = _startPrice + currentStage * _step;
            uint currentPriceAmount = _threshold - _distributed % _threshold;
            uint currentPriceCost = (currentPrice * currentPriceAmount) / (10**18);
            uint spent = (currentPriceCost <= remained) ? currentPriceCost : remained;
            uint bought = (currentPriceCost <= remained) ? currentPriceAmount: ((remained * 10**18)/ currentPrice);
            remained -= spent;
            amountOut += bought;
            _distributed += bought;
        }
        uint bonus = estimatePromoBonus(amountOut) + estimateOnceBonus(_userId, amountOut);
        return (amountOut, bonus);
    }

    function giveOnceBonus(uint _userId, uint _amountOut) public returns(uint) {
        require(msg.sender == address(amper), "Access denied");
        uint bonus = estimateOnceBonus(_userId, _amountOut);
        if (bonus > 0) {
            onceBonusTakers.push(_userId);
            onceBonusValues[_userId] = bonus;
        }
        return bonus;
    }

    function estimateOnceBonus(uint _userId, uint _amountOut) public view returns(uint) {
        uint bonus;
        if (onceBonusValues[_userId] > 0) return 0;
        bonus = (_amountOut * onceBonusBase * registry.getTariff(_userId)) / 10**4;
        return bonus;
    }

    function estimatePromoBonus(uint _amountOut) public view returns(uint) {
        if (promoBonusActive == false) return 0;
        uint bonus;
        uint[2][10] memory _promoBonusConfig = promoBonusConfig;
        for (uint i=0; i < _promoBonusConfig.length; i++) {
            if (_amountOut >= _promoBonusConfig[i][0]) {
                bonus = _promoBonusConfig[i][1];
            }
        }
        return (bonus * _amountOut)/10**4;
    }

    // admin functions

    function configPromoBonus(uint[2][10] memory _promoBonusConfig) public onlyRole(CONFIG_ROLE) {
        promoBonusConfig = _promoBonusConfig;
    }

    function configDistribution(
        uint _startPrice,
        uint _priceMoveStep,
        uint _priceMoveThreshold,
        uint _onceBonusBase,
        bool _promoBonusActive)
        public onlyRole(CONFIG_ROLE) 
    {
        startPrice = _startPrice;
        priceMoveStep = _priceMoveStep;
        priceMoveThreshold = _priceMoveThreshold;
        onceBonusBase = _onceBonusBase;
        promoBonusActive = _promoBonusActive;
    }

}