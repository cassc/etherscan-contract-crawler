// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {WithdrawAnyERC20Token} from "../Utils/WithdrawAnyERC20Token.sol";
import {IRDNRegistry} from "../RDN/interfaces/IRDNRegistry.sol";
import {IRDNDistributor} from "../RDN/interfaces/IRDNDistributor.sol";
import {IAMPEREstimator} from "./interfaces/IAMPEREstimator.sol";
import {IAMPERStaking} from "./interfaces/IAMPERStaking.sol";



contract AMPERProject is AccessControlEnumerable, WithdrawAnyERC20Token {

    IRDNRegistry public immutable registry;
    IAMPEREstimator public estimator;
    IAMPERStaking public staking;
    IERC20 public token;
    uint public distributed;
    uint public distributionLimit;
    uint public reward;

    event Turnover(
        uint indexed userId,
        address indexed token,
        uint turnoverAmount,
        uint normalizedTurnover
    );

    event Participation(
        uint indexed userId,
        address indexed tokensIn,
        uint amountIn,
        uint amountOutTotal,
        uint bonus
    );

    bytes32 public constant CONFIG_ROLE = keccak256("CONFIG_ROLE");

    constructor (address _registry, address _admin) WithdrawAnyERC20Token(_admin, false) {
        registry = IRDNRegistry(_registry);

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(CONFIG_ROLE, _admin);
        
    }

    function estimateAmountOut(uint _userId, uint _amountIn) public view returns(uint, uint) {
        return _estimateAmountOut(_userId, _amountIn);
    }

    function _estimateAmountOut(uint _userId, uint _amountIn) private view returns(uint, uint) {
        require(registry.isRegistered(_userId), "Not registered in RDN");
        (uint amountOut, uint bonus) = estimator.estimateAmountOut(_userId, _amountIn);
        require(amountOut <= (distributionLimit - distributed), "Distribution Limit");
        return (amountOut, bonus);
    }

    function participate(uint _amountIn, uint _amountOutMin) public {
        uint userId = registry.getUserIdByAddress(msg.sender);
        require(userId > 0, "Not registered in RDN");
        
        (uint amountOut, uint bonus) = estimator.estimateAmountOut(userId, _amountIn);
        uint onceBonus = estimator.estimateOnceBonus(userId, _amountIn);
        uint amountOutTotal = amountOut + bonus;
        require(amountOutTotal <= (distributionLimit - distributed), "Distribution limit overflow");
        require(amountOutTotal >= _amountOutMin, "amountOut lt amountOutMin");

        token.transferFrom(msg.sender, address(this), _amountIn);
        uint toReward = (_amountIn * reward) / 10**4;
        if (toReward > 0) {
            IRDNDistributor distributor = IRDNDistributor(registry.getDistributor(address(token)));
            token.approve(address(distributor), toReward);
            distributor.distribute(msg.sender, toReward);
        }

        if (onceBonus > 0) {
            estimator.giveOnceBonus(userId, amountOut);
        }

        distributed += amountOutTotal;

        staking.deposit(userId, amountOutTotal, 0);

        emit Turnover(userId, address(token), _amountIn, _amountIn / 10);
        emit Participation(userId, address(token), _amountIn, amountOutTotal, bonus);
        
    }

    function config(address _staking, address _estimator, uint _distributionLimit, address _token, uint _reward) public onlyRole(CONFIG_ROLE) {
        estimator = IAMPEREstimator(_estimator);
        staking = IAMPERStaking(_staking);
        distributionLimit = _distributionLimit;
        token = IERC20(_token);
        reward = _reward;
    }

    function setDistributed(uint _distributed) public onlyRole(CONFIG_ROLE) {
        distributed = _distributed;
    }

    
}