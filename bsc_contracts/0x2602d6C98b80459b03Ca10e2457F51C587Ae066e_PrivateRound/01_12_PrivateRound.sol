// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Roles.sol";


contract PrivateRound is Roles
{


using SafeERC20 for IERC20;


struct Member
{
	uint busdPaid;
	uint fcgRemain;
	uint fcgBuyed;
	uint periodsPaid;
	uint rewardMillis;
	address referrer;
	bool registered;
	bool initialPartWithdrawed;
	uint referralsCount;
	uint busdReward;
}


mapping (address => Member) public members;
uint public constant rateDenominator = 10000; // e-4
uint public constant minSummaryBusdLimit = 50000 ether; // $50000

// Stage control
bool public sellStageStarted;
bool public sellStageFinished;
uint public constant sellStageDuration = 90 days; // 90 days
uint public sellStageExpireAt;
uint public withdrawStageStartedAt;

uint public constant fcgCap = 50000000 ether; // 50M FCG
uint public busdReserved;
uint public fcgReserved;
IERC20 public immutable BUSD;
IERC20 public immutable FCG;

uint private constant PERIOD_SECONDS = 1 days; // 24 * 3600
uint private constant PERIODS_COUNT = 425; // 14 months * 30.4 days

address public immutable receiverAddress; // For BUSD income
address public immutable remnantAddress; // For FCG remnant


event MemberRegistered(address indexed member);
event MemberRemoved(address indexed member);
event SellStageStarted(uint expireAt);
event Purchase(address indexed member, uint busdAmount, uint fcgAmount);
event SellStageFinished();
event WithdrawStageStarted();
event RewardWithdrawed(address indexed referrer, uint fcgAmount);
event TakedFCG(address indexed member, uint amount);


constructor(
	address defaultOwner_,
	address defaultAdmin_,
	address receiverAddress_,
	address remnantAddress_,
	address busdAddress_,
	address fcgAddress_
) Roles(defaultOwner_, defaultAdmin_)
{
	require(receiverAddress_ != address(0) && remnantAddress_ != address(0), "PR: invalid addresses");

	receiverAddress = receiverAddress_;
	remnantAddress = remnantAddress_;

	require(busdAddress_ != address(0) && fcgAddress_ != address(0)
		&& busdAddress_ != fcgAddress_, "PR: invalid tokens addresses");

	BUSD = IERC20(busdAddress_);
	FCG = IERC20(fcgAddress_);
}

// Dynamic sell rate by BUSD volume
function getRateByVolume(uint busdVolume) public pure returns(uint)
{
	if (busdVolume > 1000000 ether) return 500; // 0.05/$FCG
	if (busdVolume > 500000 ether) return 535; // 0.0535/$FCG
	if (busdVolume > 250000 ether) return 565; // 0.0565/$FCG
	return 600; // 0.06/$FCG
}

// Registration opened until sell stage finished
function isRegistrationOpened() public view returns(bool)
{ return !sellStageStarted || isSellOpened(); }

function isSellOpened() public view returns(bool)
{
	return sellStageStarted && block.timestamp < sellStageExpireAt
		&& !sellStageFinished && getAvailableFCG() > 0;
}

function registerMember(address account, address referrer) external onlyAdmin
{ _registerMember(account, referrer); }

function registerMembers(address[] calldata accounts, address[] calldata referrers)
	public onlyAdmin
{
	require(accounts.length > 0 && accounts.length == referrers.length,
		"PR: invalid input arrays");

	for (uint i = 0; i < accounts.length; i++)
		_registerMember(accounts[i], referrers[i]);
}

function _registerMember(address account, address referrer) private
{
	require(isRegistrationOpened(), "PR: sell stage finished");
	require(account != address(0), "PR: invalid address");
	require(account != referrer, "PR: invalid referrer");

	Member storage member = members[account];
	require(!member.registered, "PR: member already exist");

	if (referrer != address(0))
	{
		Member storage refMember = members[referrer];
		if (refMember.registered)
		{
			member.referrer = referrer;
			refMember.referralsCount++;
		}
	}

	member.registered = true;
	emit MemberRegistered(account);
}

function removeMember(address account) external onlyAdmin
{
	require(!sellStageStarted, "PR: sell stage already started");

	Member storage member = members[account];
	require(member.registered, "PR: is unregistered user");

	member.registered = false;
	emit MemberRemoved(account);
}

function setReferralReward(address account, uint rewardMillis) external onlyAdmin
{
	Member storage member = members[account];

	require(member.registered, "PR: account isn't registered");
	require(rewardMillis > 0 && rewardMillis <= 200, "PR: reward limit"); // 20% max
	require(rewardMillis > member.rewardMillis, "PR: is less than member has");

	member.rewardMillis = rewardMillis;
}

function getAvailableFCG() public view returns(uint)
{ return fcgCap - fcgReserved; }

function startSellStage() external onlyOwner
{
	require(!sellStageStarted, "PR: sell stage alredy started");
	require(FCG.balanceOf(address(this)) >= fcgCap,
		"PR: not enough FCG on this contract balance");

	sellStageStarted = true;
	sellStageExpireAt = block.timestamp + sellStageDuration;

	emit SellStageStarted(sellStageExpireAt);
}

// Registered user call this to pay required BUSD and start participating in seed program
function sendBusdToBuyFcg(uint busdAmount) external
{
	require(isSellOpened(), "PR: sell stage is closed");

	address memberAddress = msg.sender;
	Member storage member = members[memberAddress];

	require(member.registered, "PR: you aren't registered yet");
	require(busdAmount > 0, "PR: invalid BUSD amount");


	uint rate = getRateByVolume(member.busdPaid + busdAmount);
	uint fcgAmount = busdAmount * rateDenominator / rate;
	uint fcgAvailable = getAvailableFCG();

	// If cap too small, recalculate amounts to get remnant of cap
	if (fcgAmount > fcgAvailable)
	{
		fcgAmount = fcgAvailable;

		uint initialBusdAmount = busdAmount;
		busdAmount = fcgAmount * rate / rateDenominator;

		// Recalculate discount
		uint newRate = getRateByVolume(member.busdPaid + busdAmount);
		if (newRate != rate) busdAmount = fcgAmount * newRate / rateDenominator;

		require(busdAmount > 0 && busdAmount <= initialBusdAmount, "PR: invalid recalculated BUSD amount");
	}

	require(member.busdPaid + busdAmount >= minSummaryBusdLimit, "PR: minimal summary BUSD limit");

	// All checks passed
	BUSD.safeTransferFrom(memberAddress, address(this), busdAmount);
	emit Purchase(memberAddress, busdAmount, fcgAmount);

	// Calc reward for referrer
	if (member.referrer != address(0))
	{
		Member storage referrer = members[member.referrer];

		if (referrer.registered && referrer.rewardMillis > 0)
		{
			uint busdReward = busdAmount * referrer.rewardMillis / 1000;
			busdReserved += busdReward;
			referrer.busdReward += busdReward;
		}
	}

	// Apply changes
	member.busdPaid += busdAmount;
	member.fcgBuyed += fcgAmount;
	fcgReserved += fcgAmount;
	member.fcgRemain += fcgAmount;

	// Finish sell stage if whole cap sold
	if (getAvailableFCG() == 0)
	{
		sellStageFinished = true;
		emit SellStageFinished();
	}
}

function closeSellStage() external onlyOwner
{
	require(isSellOpened(), "PR: sell stage is closed");

	sellStageFinished = true;
	emit SellStageFinished();
}

function withdrawDevFunds() external onlyOwner
{
	require(sellStageStarted && !isSellOpened(), "PR: sell stage isn't finished");

	// Officially finish sell stage if it isn't
	if (!sellStageFinished)
	{
		sellStageFinished = true;
		emit SellStageFinished();
	}

	uint busdBalance = BUSD.balanceOf(address(this));
	if (busdBalance > busdReserved) BUSD.safeTransfer(receiverAddress, busdBalance - busdReserved);

	uint fcgBalance = FCG.balanceOf(address(this));
	if (fcgBalance > fcgReserved) FCG.safeTransfer(remnantAddress, fcgBalance - fcgReserved);
}

function withdrawReward() external
{
	// After sell stage finished
	require(sellStageStarted && !isSellOpened(), "PR: withdraw isn't permitted yet");

	Member storage member = members[msg.sender];
	require(member.registered, "PR: you aren't registered");

	uint amount = member.busdReward;
	require(amount > 0, "PR: you haven't reward");
	require(amount <= busdReserved && amount <= BUSD.balanceOf(address(this)),
		"PR: incorrect reward amount");

	member.busdReward = 0;
	busdReserved -= amount;

	BUSD.safeTransfer(msg.sender, amount);
	emit RewardWithdrawed(msg.sender, amount);
}

function startWithdrawStage() external onlyOwner
{
	require(sellStageFinished, "PR: sell stage isn't finished");
	require(withdrawStageStartedAt == 0, "PR: stage already started");

	withdrawStageStartedAt = block.timestamp;
	emit WithdrawStageStarted();
}

function takeAvailableFcg() external
{
	require(withdrawStageStartedAt > 0, "PR: stage isn't started");

	address memberAddress = msg.sender;
	Member storage member = members[memberAddress];

	require(member.registered, "PR: you aren't registered");
	require(member.fcgRemain > 0 && member.periodsPaid < PERIODS_COUNT, "PR: you taked all FCG");

	uint fcgToWithdraw;
	if (!member.initialPartWithdrawed)
	{
		fcgToWithdraw = member.fcgBuyed * 15 / 100;
		member.initialPartWithdrawed = true;
	}

	uint timePassed = block.timestamp - withdrawStageStartedAt;
	uint periodsPassed = timePassed > 2626560 ? 
		(timePassed - 2626560) / PERIOD_SECONDS : 0; // After "death" month

	if (periodsPassed > member.periodsPaid)
	{
		uint periodsToPay;
		if (periodsPassed >= PERIODS_COUNT)
		{
			periodsToPay = PERIODS_COUNT - member.periodsPaid;
			fcgToWithdraw = member.fcgRemain;
		}
		else
		{
			uint amountPerPeriod = (member.fcgBuyed * 85 / 100) / PERIODS_COUNT;
			periodsToPay = periodsPassed - member.periodsPaid;
			fcgToWithdraw += amountPerPeriod * periodsToPay;
		}

		member.periodsPaid += periodsToPay;
	}

	require(fcgToWithdraw > 0, 'PR: nothing to withdraw');

	member.fcgRemain -= fcgToWithdraw;
	fcgReserved -= fcgToWithdraw;
	FCG.safeTransfer(memberAddress, fcgToWithdraw);

	emit TakedFCG(memberAddress, fcgToWithdraw);
}


}