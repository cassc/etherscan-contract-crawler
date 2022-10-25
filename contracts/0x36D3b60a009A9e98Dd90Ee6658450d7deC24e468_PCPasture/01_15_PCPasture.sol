// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";

import "./PocketCow.sol";

/// @title An epoch-based proportional eth distributor.
/// @author Ethan Pendergraft
/// @notice Allows a user to withdraw a proportional amount based off of how many tokens they have burnt.
contract PCPasture is Ownable {

	event ValueAdded(uint256 unIncreaseAmount);
	event PasturePayout(address Receiver, uint256 Amount);
	event OwnerWithdrawal(address Receiver, uint256 Amount);

	/// @dev The target contract we use to derive an addresses' burn count.
	PocketCow m_pcHolderContract;

	/// @dev An address that is allowed to withdraw from the owner's share.
	address m_adrWithdrawProxy;

	/// @dev The previouly measured balance, used to detect deposits.
	uint256 m_unPrevContractBalance = 0;

	struct MasterEpoch {
		uint256 TokenCount;
		uint256 Value;
	}

	/// @dev The id of the most recent master epoch. It will increase by 1 the first a cow is burn after each deposit.
	uint256 m_unCurrMasterEpochID = 0;
	
	/// @dev Maps epoch IDs to master epochs, no epoch is ever destroyed.
	mapping(uint256 => MasterEpoch) m_mapIDToMasterEpoch;

	/// @dev The id of the last epoch that the owner withdrew from.
	uint256 m_unOwnerEpochID = 0;

	/// @dev The raw, unscaled amount of eth that the owner has withdrawn. The actual amount is lower.
	uint256 m_unOwnerCurrEpochWidthdrawAmount = 0;

	struct HolderEpoch {
		uint256 TokenCount;	// Number of burned tokens held by address
		uint256 EpochID;		// ID of Epoch, used to get total token count
		uint256 ValueWitnessed;	// Unscaled value consumed
	}

	/// @dev Maps each address to its list of epochs. Older epochs will be destryoed once a token holder has withdrawn all of their proportional value.
	mapping(address => HolderEpoch[]) m_mapAddressToHolderEpochs;

	///
	constructor(address payable adrHolderCon) {
		setHolderContract(adrHolderCon);
		startNewMasterEpoch();
	}

	// @notice Will receive any eth sent to the contract
	// https://docs.soliditylang.org/en/v0.8.14/contracts.html#receive-ether-function
	receive () external payable {

	}

	// Admin Functions ===========================================================
	/// @notice Sets the token contract that contains burnt token information.
	/// @param adrHolderCon The address of the contract managing burnt tokens.
	function setHolderContract(address payable adrHolderCon) public onlyOwner {
		m_pcHolderContract = PocketCow(adrHolderCon);
	}

	/// @notice Provides the address of the contract being referenced for burnt token information.
	/// @return Address of reference contract.
	function getHolderContract() external view returns(address) {
		return address(m_pcHolderContract);
	}

	/// @notice Sets who can withdraw from the owner's share other than the owner. Only 1 at a time.
	/// @param adrTarget The address to allow to withdraw from the owner's share
	function setWithdrawProxy(address adrTarget) external onlyOwner {
		m_adrWithdrawProxy = adrTarget;
	}

	/// @return The current address that is allowed to withdraw from the owner's share
	function getWithdrawProxy() external view onlyOwner returns(address) {
		return m_adrWithdrawProxy;
	}

	// General Information Access ================================================

	/// @return The number of burnt tokens there were during the last update
	function getLatestTokenCountInMasterEpoch() public view returns (uint256){
		return m_mapIDToMasterEpoch[m_unCurrMasterEpochID].TokenCount;
	}

	/// @param adrTarget The address to get the epoch count for
	/// @return The number of epochs that an address has
	function getEpochCountOf(address adrTarget) public view returns(uint256) {
		return m_mapAddressToHolderEpochs[adrTarget].length;
	}

	/// @param adrTarget The address to get the value from
	/// @param unIndex The epoch index to get the value from
	/// @return The value that has been marked as consumed for a given address in a given epoch
	function getValueWitnessedInEpochOf(address adrTarget, uint256 unIndex) external view returns(uint256) {
		return m_mapAddressToHolderEpochs[adrTarget][unIndex].ValueWitnessed;
	}

	/// @param adrTarget The address to get the token count from
	/// @param unIndex The epoch index to get the token count from
	/// @return The number of tokens that the target address owned during the epoch at unIndex
	function getTokenCountInEpochOf(address adrTarget, uint256 unIndex) public view returns(uint256) {
		return m_mapAddressToHolderEpochs[adrTarget][unIndex].TokenCount;
	}

	/// @param adrHolder The address to get the token count from
	/// @return The number of tokens that the target address owned during the last update
	function getLatestTokenCountOf(address adrHolder) external view returns(uint256) {
		
		HolderEpoch[] storage liHeCurr = m_mapAddressToHolderEpochs[adrHolder];
		if(liHeCurr.length < 1)
			return 0;

		return getTokenCountInEpochOf(adrHolder, liHeCurr.length - 1);
	}

	/// @dev This caps balance change so that its never negative, and never underflows.
	/// @return The amount that the value stored in the contract has increased since the last update.
	function getBalanceIncrease() public view returns(uint256) {

		if(address(this).balance <= m_unPrevContractBalance)
			return 0;

		return address(this).balance - m_unPrevContractBalance;
	}

	// Internal Structure Functions ==============================================

	function updatePrevValue(uint256 unDiff) private {
		m_unPrevContractBalance = address(this).balance - unDiff;
	}

	function getLastBalance() external view returns(uint256) {
		return m_unPrevContractBalance;
	}

	function startNewMasterEpoch() private {
		m_unCurrMasterEpochID++;
		updateMasterEpoch();
	}

	function updateMasterEpoch() private {
		m_mapIDToMasterEpoch[m_unCurrMasterEpochID].TokenCount = m_pcHolderContract.BurntTokenTotal();
	}

	function addValueToMasterEpoch(uint256 unNewValue) private {
		m_mapIDToMasterEpoch[m_unCurrMasterEpochID].Value += unNewValue;
	}

	function getValueOfMasterEpoch() private view returns(uint256) {
		return m_mapIDToMasterEpoch[m_unCurrMasterEpochID].Value;
	}

	function startNewHolderEpoch(address adrHolder, uint256 unValue) private {
		m_mapAddressToHolderEpochs[adrHolder].push(HolderEpoch(
			m_pcHolderContract.burnBalanceOf(adrHolder),
			m_unCurrMasterEpochID,
			unValue
		));
	}

	//============================================================================

	function updateValue() public {

		uint256 unValInc = getBalanceIncrease();
		if(unValInc > 0) {
			addValueToMasterEpoch(unValInc);
			updatePrevValue(0);

			emit ValueAdded(unValInc);
		}
	}

	function processPayout() private returns(uint256) {

		HolderEpoch[] storage arrCurrHoldEpochs = m_mapAddressToHolderEpochs[msg.sender];

		require(arrCurrHoldEpochs.length > 0, "Address has no epochs.");

		uint256 unPayoutTotal = 0;
		uint256 unMasterEpochCountTotal = 0;
		uint256 unHoldEpochIdx = 0;
		HolderEpoch storage currHoldEpoch = arrCurrHoldEpochs[0];

		for(uint256 unMEID = arrCurrHoldEpochs[0].EpochID; unMEID <= m_unCurrMasterEpochID; ++unMEID) {

			MasterEpoch storage currMastEpoch = m_mapIDToMasterEpoch[unMEID];

			uint256 unNextHoldEpochIdx = unHoldEpochIdx + 1;
			if(unNextHoldEpochIdx < arrCurrHoldEpochs.length) {

				if(unMEID == arrCurrHoldEpochs[unNextHoldEpochIdx].EpochID) {
					currHoldEpoch = arrCurrHoldEpochs[unNextHoldEpochIdx];
					unHoldEpochIdx = unNextHoldEpochIdx;

					unMasterEpochCountTotal = 0;
				}
			}

			unMasterEpochCountTotal += currMastEpoch.Value;

			if(currHoldEpoch.ValueWitnessed >= unMasterEpochCountTotal)
				continue;

			uint256 unDelta = unMasterEpochCountTotal - currHoldEpoch.ValueWitnessed;
			currHoldEpoch.ValueWitnessed += unDelta;
			
			uint256 unScaledUp = unDelta * currHoldEpoch.TokenCount;
			unPayoutTotal += unScaledUp / 10.0 / currMastEpoch.TokenCount;
		}

		return unPayoutTotal;
	}

	function getBalance() external view returns(uint256) {

		HolderEpoch[] storage arrCurrHoldEpochs = m_mapAddressToHolderEpochs[msg.sender];

		require(arrCurrHoldEpochs.length > 0, "Address has no epochs.");

		uint256 unPayoutTotal = 0;
		uint256 unMasterEpochCountTotal = 0;
		uint256 unHoldEpochIdx = 0;

		HolderEpoch storage currHoldEpoch = arrCurrHoldEpochs[0];
		uint256 unCurrEpochValueWitnessed = currHoldEpoch.ValueWitnessed;

		for(uint256 unMEID = arrCurrHoldEpochs[0].EpochID; unMEID <= m_unCurrMasterEpochID; ++unMEID) {

			MasterEpoch storage currMastEpoch = m_mapIDToMasterEpoch[unMEID];

			uint256 unNextHoldEpochIdx = unHoldEpochIdx + 1;
			if(unNextHoldEpochIdx < arrCurrHoldEpochs.length) {

				if(unMEID == arrCurrHoldEpochs[unNextHoldEpochIdx].EpochID) {
					currHoldEpoch = arrCurrHoldEpochs[unNextHoldEpochIdx];
					unCurrEpochValueWitnessed = currHoldEpoch.ValueWitnessed;
					unHoldEpochIdx = unNextHoldEpochIdx;
					unMasterEpochCountTotal = 0;
				}
			}

			unMasterEpochCountTotal += currMastEpoch.Value;

			if(unCurrEpochValueWitnessed >= unMasterEpochCountTotal)
				continue;

			uint256 unDelta = unMasterEpochCountTotal - unCurrEpochValueWitnessed;
			unCurrEpochValueWitnessed += unDelta;
			
			uint256 unScaledUp = unDelta * currHoldEpoch.TokenCount;
			unPayoutTotal += unScaledUp / 10.0 / currMastEpoch.TokenCount;
		}

		return unPayoutTotal;
	}
	
	function withdrawBalance() external {

		require(getLatestTokenCountInMasterEpoch() == m_pcHolderContract.BurntTokenTotal(),
			"onTokenBurnt() needs to be called for each address not registered.");

		updateValue();

		uint256 un256Payout = processPayout();
		require(un256Payout > 0, "Nothing to collect.");

		HolderEpoch[] storage arrCurrHoldEpochs = m_mapAddressToHolderEpochs[msg.sender];
		HolderEpoch memory epHoldMostRecent = arrCurrHoldEpochs[arrCurrHoldEpochs.length - 1];
		delete m_mapAddressToHolderEpochs[msg.sender];
		m_mapAddressToHolderEpochs[msg.sender].push(epHoldMostRecent);

		emit PasturePayout(msg.sender, un256Payout);
		updatePrevValue(un256Payout);

		(bool bSuccess, ) = msg.sender.call{value: un256Payout}("");
		require(bSuccess, "Transfer to pasture holder failed.");

	}

	// Called when it is discovered that a token has burnt.
	function onTokenBurnt(address adrHolder) external {

		uint32 unBurnBalance = m_pcHolderContract.burnBalanceOf(adrHolder);
		require(unBurnBalance > 0, "Address has not burnt any tokens.");

		updateValue();

		if(getValueOfMasterEpoch() > 0) startNewMasterEpoch();
		else updateMasterEpoch();

		uint256 unEpochCount = getEpochCountOf(adrHolder);

		if(unEpochCount < 1) {
			startNewHolderEpoch(adrHolder, 0);
			return;
		}

		HolderEpoch storage currHoldEpoch = m_mapAddressToHolderEpochs[adrHolder][unEpochCount - 1];
		require(unBurnBalance > currHoldEpoch.TokenCount, "No new burnt tokens to process.");

		if(currHoldEpoch.EpochID != m_unCurrMasterEpochID) {
			startNewHolderEpoch(adrHolder, 0);
			return;
		}

		// Update the token count if it still points to the current epoch.
		currHoldEpoch.TokenCount = unBurnBalance;
	}

	function getOwnerBalance() public view returns (uint256) {

		require(owner() == _msgSender() || m_adrWithdrawProxy == _msgSender(), 
			"Caller must be owner or proxy");

		uint256 unRootWithdrawTotal = 0;

		for(uint256 unMEID = m_unOwnerEpochID; unMEID <= m_unCurrMasterEpochID; ++unMEID) {

			MasterEpoch storage currMastEpoch = m_mapIDToMasterEpoch[unMEID];

			// Special case for withdrawing eth deposited in an epoch after last withdrawal.
			if(unMEID == m_unOwnerEpochID 
					&& currMastEpoch.Value > m_unOwnerCurrEpochWidthdrawAmount) {

				uint256 unDiff = currMastEpoch.Value - m_unOwnerCurrEpochWidthdrawAmount;
				unRootWithdrawTotal += unDiff;
				continue;
			}

			unRootWithdrawTotal += currMastEpoch.Value;
		}

		return unRootWithdrawTotal * 9 / 10;
	}

	function ownerWithdraw() external onlyOwner {

		require(owner() == _msgSender() || m_adrWithdrawProxy == _msgSender(), 
			"Caller must be owner or proxy");
			
		require(getLatestTokenCountInMasterEpoch() == m_pcHolderContract.BurntTokenTotal(),
			"onTokenBurnt() needs to be called for each address not registered.");

		updateValue();
		
		uint256 currOwnerBalance = getOwnerBalance();

		// Consume all change up to leading epoch.
		m_unOwnerEpochID = m_unCurrMasterEpochID;
		m_unOwnerCurrEpochWidthdrawAmount = getValueOfMasterEpoch();

		emit OwnerWithdrawal(msg.sender, currOwnerBalance);

		updatePrevValue(currOwnerBalance);

		(bool bSuccess, ) = msg.sender.call{value: currOwnerBalance}("");
		require(bSuccess, "Transfer to owner failed.");

	}
}