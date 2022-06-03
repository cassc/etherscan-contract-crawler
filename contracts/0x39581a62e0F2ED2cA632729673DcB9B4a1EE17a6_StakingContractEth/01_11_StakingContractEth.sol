// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";

interface IERC20Extended {
    function decimals() external view returns (uint8);
}

contract StakingContractEth is AccessControl, Multicall {

    using SafeERC20 for IERC20;
    
    IERC20 public shardToken;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    
    address public treasury;
    uint256 public maxDebtModifier; // maximum lending period
    uint256 public reductionRate; // generation modifier for non stablecoin asset
    mapping(IERC20 => uint256) public totalTokensDeposited;
    mapping(address => mapping(IERC20 => uint256)) public deposited;
    mapping(address => mapping(IERC20 => uint256)) public debt;
    mapping(address => mapping(IERC20 => uint256)) public surplus;
    mapping(address => mapping(IERC20 => uint256)) public lastDebtInteraction;
    mapping(IERC20 => bool) public whitelistedTokens; // tokens && aTokens supported by contract

    modifier sync(IERC20 toSync) {
        require(whitelistedTokens[toSync] == true, "token not supported by protocol");

        uint8 decimalsUtoken = IERC20Extended(address(toSync)).decimals();

        if (toSync.balanceOf(address(this)) > totalTokensDeposited[toSync]) {
            uint256 _surplus = toSync.balanceOf(address(this)) - totalTokensDeposited[toSync];
            deposited[treasury][toSync] += _surplus;
            emit status(toSync,_surplus, totalTokensDeposited[toSync]);
            totalTokensDeposited[toSync] += _surplus;
        }
        _;        
    }
    
    modifier updateDebt(IERC20 toSync, address toUpdate) {
        require(whitelistedTokens[toSync] == true, "token not supported by protocol");
        
        if (deposited[toUpdate][toSync] > 0) {
            uint256 reduction = (deposited[toUpdate][toSync] * (block.timestamp - lastDebtInteraction[toUpdate][toSync])) * reductionRate / 86400;
            if (reduction <= debt[toUpdate][toSync]) {
                debt[toUpdate][toSync] -= reduction;
            } 
            else {
                surplus[toUpdate][toSync] += reduction - debt[toUpdate][toSync];
                debt[toUpdate][toSync] = 0;
            }
        }
        lastDebtInteraction[toUpdate][toSync] = block.timestamp;
        _;
    }

    constructor(IERC20 _shardToken, uint256 _mdm) {
        shardToken = _shardToken;
        _setupRole(ADMIN_ROLE, _msgSender());
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        maxDebtModifier = _mdm;
        reductionRate = 1;
        treasury = address(0xa7C212DA5881eA88c9472F83dB94049f95B5472F);
    }

    function deposit(IERC20 toDeposit, uint256 amount) external sync(toDeposit) updateDebt(toDeposit, _msgSender()) {
        toDeposit.safeTransferFrom(_msgSender(), address(this), amount);
        
        deposited[_msgSender()][toDeposit] += amount;
        totalTokensDeposited[toDeposit] += amount;
        emit inflow(_msgSender(),amount, toDeposit);
    }

    function withdraw(IERC20 toWithdraw, uint256 amount) external updateDebt(toWithdraw, _msgSender()) {
        IERC20 bookkeeping = toWithdraw;
        require(deposited[_msgSender()][bookkeeping] >= amount, "insufficient respawn.finance balance");
        require(debt[_msgSender()][bookkeeping] <= normalisedDebt(toWithdraw, deposited[_msgSender()][bookkeeping] - amount), "remaining collateral yield would be insufficient to repay loan");
        totalTokensDeposited[bookkeeping] -= amount;
        deposited[_msgSender()][bookkeeping] -= amount;
        toWithdraw.safeTransfer(_msgSender(), amount);
        emit withdrawals(_msgSender(),amount, toWithdraw);
    }

    function lockPartlyAndReceive(IERC20 tokenToLock, uint256 shardsToCredit) external updateDebt(tokenToLock, _msgSender()) {
        uint256 max = normalisedDebt(tokenToLock, deposited[_msgSender()][tokenToLock]);
        require(shardsToCredit + debt[_msgSender()][tokenToLock] <= (max) + surplus[_msgSender()][tokenToLock], "insufficient collateral");
        if (surplus[_msgSender()][tokenToLock] == 0) {
            debt[_msgSender()][tokenToLock] += shardsToCredit;
        }
        else {
            if (shardsToCredit >= surplus[_msgSender()][tokenToLock]) {
                debt[_msgSender()][tokenToLock] = shardsToCredit - surplus[_msgSender()][tokenToLock];
                surplus[_msgSender()][tokenToLock] = 0;
            }
            else {
                surplus[_msgSender()][tokenToLock] -= shardsToCredit;
            }
        }
        shardToken.safeTransfer(_msgSender(), shardsToCredit);
        emit minted(_msgSender(),shardsToCredit,tokenToLock);
    }

    function lockFullyAndReceive(IERC20 tokenToLock) external updateDebt(tokenToLock, _msgSender()) {

        uint256 max = normalisedDebt(tokenToLock, deposited[_msgSender()][tokenToLock]);
        require(max + surplus[_msgSender()][tokenToLock] > debt[_msgSender()][tokenToLock], "insufficient collateral");
        uint256 amount = (max - debt[_msgSender()][tokenToLock]) + surplus[_msgSender()][tokenToLock];
        surplus[_msgSender()][tokenToLock] = 0;
        debt[_msgSender()][tokenToLock] = max;
        shardToken.safeTransfer(_msgSender(), amount);
        emit minted(_msgSender(),amount,tokenToLock);
    }

    function harvestSurplus(IERC20 lockedToken) external updateDebt(lockedToken, _msgSender()) {
        require(surplus[_msgSender()][lockedToken] > 0, "no rewards left");
        uint256 _surplus = surplus[_msgSender()][lockedToken];
        surplus[_msgSender()][lockedToken] = 0;
        shardToken.safeTransfer(_msgSender(), _surplus);
        emit minted(_msgSender(),_surplus,lockedToken);
    }

    function repayPartlyAndUnlock(IERC20 tokenToUnlock, uint256 amount) external updateDebt(tokenToUnlock, _msgSender()) {
        shardToken.safeTransferFrom(_msgSender(), address(this), amount);
        if (amount >= debt[_msgSender()][tokenToUnlock]) {
            surplus[_msgSender()][tokenToUnlock] += amount - debt[_msgSender()][tokenToUnlock];
            debt[_msgSender()][tokenToUnlock] = 0;
        }
        else {
            debt[_msgSender()][tokenToUnlock] -= amount;
        }
        emit repayment(_msgSender(),amount,tokenToUnlock);
    }

    function repayFullyAndUnlock(IERC20 tokenToUnlock) external updateDebt(tokenToUnlock, _msgSender()) {
        require(debt[_msgSender()][tokenToUnlock] > 0, "debt should be > 0");
        shardToken.safeTransferFrom(_msgSender(), address(this), debt[_msgSender()][tokenToUnlock]);
        emit repayment(_msgSender(),debt[_msgSender()][tokenToUnlock],tokenToUnlock);
        debt[_msgSender()][tokenToUnlock] = 0;
    }

    function normalisedDebt(IERC20 tokenToNormalise, uint256 amountToNormalise) internal view returns(uint256) {
        IERC20Extended _iERC20Extended = IERC20Extended(address(tokenToNormalise));
        uint256 decimals = _iERC20Extended.decimals();
        return (amountToNormalise * 10**18 * maxDebtModifier) / 10**decimals;
    }

    function alterMaxDebtModifier(uint256 rate) onlyRole(ADMIN_ROLE) external {
        maxDebtModifier = rate;
    }

    function alterReductionRate(uint256 rate) onlyRole(ADMIN_ROLE) external {
        reductionRate = rate;
    }

    function whitelistToken(IERC20 rebasingToken) onlyRole(ADMIN_ROLE) external {
        whitelistedTokens[rebasingToken] = true;
    }

    // view functionallity
    function getCDPinfo(address user , IERC20 coin) public view returns(
        uint256 _maxPossCredit, 
        uint256 _deposited, 
        uint256 _outstandingCredit, 
        uint256 _surplus){
            _maxPossCredit = normalisedDebt(coin, deposited[user][coin]);
            _deposited = deposited[user][coin];
            _outstandingCredit = debt[user][coin];
            _surplus = surplus[user][coin];

          return (_maxPossCredit,_deposited,_outstandingCredit,_surplus);
        }

    // events
    event withdrawals(address indexed user , uint256 indexed amount, IERC20 indexed token);
    event inflow(address indexed user , uint256 indexed amount, IERC20 indexed token);
    event repayment(address indexed user , uint256 indexed amount, IERC20 indexed token);
    event minted(address indexed user , uint256 indexed amount, IERC20 indexed token);
    event status(IERC20 indexed token , uint256 indexed surpluss, uint256 indexed total);

}