// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IterableMapping} from "./IterableMapping.sol";

contract Staking is Pausable, Ownable , ReentrancyGuard{

    using IterableMapping for IterableMapping.InvestorMap;

    IterableMapping.InvestorMap private investorMap;

    uint256 public startDate;
    uint256 public endDate;

    struct AllInvestment {
        address investor;
        uint256[] amounts;
    }

    using SafeERC20 for IERC20;

    event SetStakingStartDate(uint256 date);
    event SetStakingEndDate(uint256 date);
    event LockWithdrawal(uint256 date);
    event UnlockWithdraw(uint256 date);
    event WithdrawFundsRaised(address to, address token, uint256 amount);

    event Stake(address _investor, uint _tokenId, uint256 _amount);


    address public JCHF;
    address public BUSD;
    address public USDT;
    address public USDC;
    address public DAI;

    bool private _isWithdrawalLocked;

    address[] public tokenAddress;

    constructor(
        uint256 _startDate,
        uint256 _endDate,
        address _JCHF,
        address _BUSD,
        address _USDT,
        address _USDC,
        address _DAI
    ) {
        JCHF = address(_JCHF);
        BUSD = address(_BUSD);
        USDT = address(_USDT);
        USDC = address(_USDC);
        DAI = address(_DAI);
        tokenAddress.push(JCHF);
        tokenAddress.push(BUSD);
        tokenAddress.push(USDT);
        tokenAddress.push(USDC);
        tokenAddress.push(DAI);
        _isWithdrawalLocked = false;
        startDate = _startDate;
        endDate = _endDate;
    }


    function stake(uint _tokenId, uint256 _amount) external whenNotPaused {
        require(startDate < block.timestamp, "Staking hasn't started yet.");
        require(endDate > block.timestamp, "Staking is finished.");
        require(!investorMap.cannotInvest(msg.sender), "You cannot invest if you have already withdrawn all funds.");
        require(_amount > 0, "Cannot stake 0.");
        IERC20(tokenAddress[_tokenId]).safeTransferFrom(msg.sender, address(this), _amount);
        investorMap.addInvestment(msg.sender, _tokenId, _amount);
        emit Stake(msg.sender, _tokenId, _amount);
    }

    function withdraw() external whenNotPaused nonReentrant() {
        require(!_isWithdrawalLocked, "Withdrawals are locked.");
        require(endDate > block.timestamp, "Staking is finished.");
        for (uint i = 0 ; i<= 4; i++) {
            if (investorMap.getAmountInvestedByTokenId(msg.sender, i) > 0) {
                IERC20(tokenAddress[i]).safeTransfer(msg.sender, investorMap.getAmountInvestedByTokenId(msg.sender, i));
            }
        }
        investorMap.updateBalance(msg.sender);
    }


    // Setters
    function setStakingStartDate(uint256 _date) external onlyOwner {
        require(_date < endDate, "StartDate is after EndDate.");
        startDate = _date;
        emit SetStakingStartDate(_date);
    }
    function setStakingEndDate(uint256 _date) external onlyOwner {
        require(startDate < _date, "EndDate is before StartDate.");
        endDate = _date;
        emit SetStakingEndDate(_date);
    }

    function pause() external onlyOwner {
        super._pause();
    }

    function unpause() external onlyOwner {
        super._unpause();
    }
    
    function lockWithdraw() external onlyOwner {
        _isWithdrawalLocked = true;
        emit LockWithdrawal(block.timestamp);
    }

    function unlockWithdraw() external onlyOwner {
        _isWithdrawalLocked = false;
        emit UnlockWithdraw(block.timestamp);
    }

    // Getters
    function getAllInvestmentForAllInvestors(uint _startIndex, uint32 _endIndex) external view returns(AllInvestment[] memory) {
        uint256 size = _endIndex - _startIndex;
        AllInvestment[] memory investmentsStruct = new AllInvestment[](size);
        for(uint i = _startIndex; i < _endIndex; i++) {
            address key = investorMap.getKeyAtIndex(i);
            investmentsStruct[i] = AllInvestment(key, investorMap.getAllInvestmentsForOneAddress(key));
        }
        return investmentsStruct;
    }

    function getInvestmentByTokenId(address key, uint tokenId) public view returns(uint) {
        return investorMap.getAmountInvestedByTokenId(key,tokenId);
    }

    function getInvestmentForAnAddress(address _investor) external view returns(uint256[] memory) {
        return investorMap.getAllInvestmentsForOneAddress(_investor);
    }

    function investorCannotInvest(address _investor) external view returns(bool) {
        return investorMap.cannotInvest(_investor);
    }
    function getStakingStartDate() external view returns(uint256) {
        return startDate;
    }
    function getStakingEndDate() external view returns(uint256)  {
        return endDate;
    }


    function withdrawFundsRaised(address _to, address _token, uint256 _amount) external onlyOwner {
        require(_isWithdrawalLocked, "Withdrawal is not locked.");
        require(endDate > block.timestamp, "Withdrawal is not locked.");
        require(getContractBalanceFor(_token) > 0, "There are no tokens in the contract.");
        IERC20(_token).safeTransfer(_to, _amount);
        emit WithdrawFundsRaised(_to, _token, _amount);
    }

    function getContractBalanceFor(address _token) public onlyOwner view returns(uint256) {
        return IERC20(_token).balanceOf(address(this));
    }
}