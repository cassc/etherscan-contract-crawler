// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract StakingStateV2 {
    uint internal constant TIME_STEP = 1 days;
	uint internal constant PERCENT_DIVIDER = 1000;
	uint internal constant ROI = 5;


	uint public initDate;


	mapping(uint => address) public investors;
	uint internal totalUsers;
	uint internal totalInvested;
	uint internal totalWithdrawn;
	uint internal totalDeposits;
	uint internal totalReinvested;
	uint internal totalReinvestCount;



	address public devAddress;

	event Paused(address account);
	event Unpaused(address account);

	// init stopped

	uint internal constant EXPRIRATION_DAYS = 60 days;
	uint internal stopProductionDate;
	uint internal constant MIN_INVEST = 10 ether;
	uint internal constant DAYS_FOR_INVEST = 27 days;
	uint internal stopInvestDate;

	modifier hasStoppedProduction() {
		require(hasStoppedProductionView(), "Production is not stopped");
				_;
	}

	modifier hasNotStoppedProduction() {
		require(!hasStoppedProductionView(), "Production is stopped");
				_;
	}

	modifier hasNotStoppedInvest() {
		require(!investHasStoppedView(), "Invest is stopped");
				_;
	}


	function hasStoppedProductionView() public view returns(bool) {
		return stopProductionDate <= block.timestamp || block.timestamp >= initDate + EXPRIRATION_DAYS;
	}

	function stopProduction() external onlyOwner {
		stopProductionDate = block.timestamp;
		require(stopProductionDate <= initDate + EXPRIRATION_DAYS, "Production is not stopped");
	}

	function stopInSecdons(uint seconds_) external onlyOwner {
		stopProductionDate = block.timestamp + seconds_;
		require(stopProductionDate <= initDate + EXPRIRATION_DAYS, "Production is not stopped");
	}

	function investHasStoppedView() public view returns(bool) {
		return block.timestamp >= stopInvestDate;
	}

	function stopSinvest() external onlyOwner {
		stopInvestDate = block.timestamp;
	}

	function getRemainingTime() public view returns(uint) {
		if(stopProductionDate > block.timestamp) {
			return stopProductionDate - block.timestamp;
		}
		return 0;
	}

	function getRemainInvest() public view returns(uint) {
		if(stopInvestDate > block.timestamp) {
			return stopInvestDate - block.timestamp;
		}
		return 0;
	}

	function getRemainingTimeInDays() external view returns(uint) {
		return getRemainingTime() / TIME_STEP;
	}

	function getRemainInvestInDays() external view returns(uint) {
		return getRemainInvest() / TIME_STEP;
	}
	// end stopped

	modifier onlyOwner() {
		require(devAddress == msg.sender, "Ownable: caller is not the owner");
		_;
	}

	modifier whenNotPaused() {
		require(initDate > 0, "Pausable: paused");
		_;
	}

	modifier whenPaused() {
		require(initDate == 0, "Pausable: not paused");
		_;
	}

	function unpause() external whenPaused onlyOwner{
		initDate = block.timestamp;
        stopProductionDate = initDate + EXPRIRATION_DAYS;
		stopInvestDate = initDate + DAYS_FOR_INVEST;
		emit Unpaused(msg.sender);
	}

	function isPaused() public view returns(bool) {
		return initDate == 0;
	}

	function getDAte() external view returns(uint) {
		return block.timestamp;
	}

	function getPublicData() external view returns(
		uint totalUsers_,
		uint totalInvested_,
		uint totalDeposits_,
		uint totalReinvested_,
		uint totalReinvestCount_,
		uint totalWithdrawn_,
		bool isPaused_
		) {
		totalUsers_=totalUsers;
		totalInvested_=totalInvested;
		totalDeposits_=totalDeposits;
		totalReinvested_=totalReinvested;
		totalReinvestCount_=totalReinvestCount;
		totalWithdrawn_=totalWithdrawn;
		isPaused_=isPaused();		
	}

	function getAllInvestors() external view returns(address[] memory) {
		address[] memory investorsList = new address[](totalUsers);
		for(uint i = 0; i < totalUsers; i++) {
			investorsList[i] = investors[i];
		}
		return investorsList;
	}

	function getInvestorByIndex(uint index) external view returns(address) {
		require(index < totalUsers, "Index out of range");
		return investors[index];
	}

}