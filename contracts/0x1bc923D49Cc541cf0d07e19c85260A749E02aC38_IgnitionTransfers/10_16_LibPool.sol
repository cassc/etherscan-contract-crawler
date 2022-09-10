// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./Data.sol";
import "./Math.sol";

/**
* @title Pool Library
* @author Luis Sanchez / Alfredo Lopez: PAID Network 2021.4
* @notice This contract include Struc and Matematics Method
*/
library LibPool {
	/**
	* Interface Struct for ERC20 Decimals
	*
	* @param {boolean active} Exist or not
	* @param {uint256 decimals} number of decimals that ERC20 have
	* @param {uint256} Amount rewarded based on the tier assign in th e Lottery of Ignition for this Pool of the IDO
	*/
	struct ERC20Decimals {
		bool active;
		uint256 decimals;
	}

	/**
	pools mapping
	IDO (Token Address)
		----> Pool Galaxy (uint256)
		----> Pool Moon (uint256)
		----> Pool .... (uint256)
		----> Pool n+1 (uint256)
	*/

	/**
	* Storage Strucs Data in a too efficiente way based on:
	* @notice https://medium.com/@novablitz/storing-structs-is-costing-you-gas-774da988895e
	* @dev Package Data Field (Details):
	* @param {address}: Base Asset of the project owner of the IDO
	* @param {uint32}: Start Date of the pool IDO
	* @param {uint32}: End Date of the IDO
	* @param {uint8}: Id the pool
	* @param {boolean}: withdrawed or not the Crown Sale (is when the Project Owner can withdraw the total coin raised in the Pool of the IDO)
	* @param {boolean}: finalized and Removed or not Rest of the Token (is when the Project Owner can withdraw or transfer Rest Amount of the Token to another address or pool)
	* @param {boolean}: paused/unpaused pool
	* @param {boolean}: Private Pool active/inactive
	* @param {boolean}: Auto Transfer Active / Inactive in the Pool
	* ================================================================================
	* @dev   Struct Pool Token Model
	* @param {bool active} Status Value, indicate if the Pool is Enable or Disable
	* @param {address quoteAsset} Address of address(0) for ETH, or Address of ERC20 for Stablecoin (eg. USDT, USDC, DAI, BUSD, etc) or Inclusive Wrapper ETH (WETH)
	* @param {uint256 packageData} Package Data Field, details above!
	* @param {uint256 rate} Rate of the BaseAsset according with the QuoteAsset selected for the Pool of the IDO
	* @param {uint256 baseTier} Base Value of the Tiers, and based on generete the all allocation in the Pool of the IDO, as multiples of this value
	* @param {uint256 paidAmount} Base Value for participate in the Pool of the IDO (Standard Value for Galaxy: 75K and Moon: 2K)
	* @param {uint256 soldAmount} Total Amount Sold in the Pool of the IDO
	* @param {uint256 tokenTotalAmount} Total Amount of Token enable in the Pool of the IDO
	* @param {uint256 totalRaise} Total Amount raised in the CrownSale in the Pool of the IDO, according the QuoteAsset
	* @param {uint256 maxRaiseAmount} Max Total Amount permitted (this value apply for Private Pool)
	*/
	struct PoolTokenModel {
		bool valid;
		address quoteAsset; // if the value is address(0) is ETH for}
		address pplSuppAsset; // Adddres of Main support asset of Pool
		address sndSuppAsset; // Adddres of secondary support asset of Pool\
		// packageData:
		// 0-159: Pool token address
		// 160-191: Start date timestamp (no miliseconds)
		// 192-223: End date timestamp (no miliseconds)
		// 224-231: uint8 of pool
		// 232: withdraw bit
		// 233: removed remaining amount of token bit
		// 234: paused pool bit
		// 235: private pool bit
		// 236: auto transfer pool bit
		uint256 packageData;
		uint256 rate; // rate pair comparison on ERC20 and pool token
		uint256 baseTier; // tier 1
		uint256 pplAmount; // Main Support Project Amount Limit for Participate in the Pool
		uint256 sndAmount; // Secondary Support Project Amount Limit for Participate in the Pool
		uint256 soldAmount; // Tokens Sold
		uint256 tokenTotalAmount; // Total of Token in the pool
		uint256 totalRaise; // Total of (ETH/USDT/USDC, etc) Raised
		uint256 maxRaiseAmount; // Max Amount of (ETH/USDT/USDC) to Raise
	}

	struct FallBackModel {
		uint256 fbck_finalize; // fallback finalize amount
		uint256 fbck_endDate; // fallback endDate timestamp
		address fbck_account; // fallback address account
	}

	/**
	* @notice generate package for libpool model
	* @dev Error IGN23 - Must be set Max Raised Amount more than Zero to enable Private Pool
    * @dev Error IGN24 - Private Pool Parameter only accept 1 or 0
    * @dev Error IGN25 - Auto Transfer Parameter only accept 1 or 0
	* @param _baseAddress baseToken address
	* @param _args pool args array
	*/
	function generatePackage(address _baseAddress, uint256[15] calldata _args)
	internal pure returns (uint256) {
		uint256 _packageData = uint256(uint160(_baseAddress));
		// startDate
		_packageData |= _args[0]<<160;
		// endDate
		_packageData |= _args[1]<<192;
		// Pool
		_packageData |= _args[2]<<224;
		// withdrawed = false
		_packageData = Data.setPkgDtBoolean(_packageData, false, 232);
		// removed Rest Amount of Token (AKA finalized) = false
		_packageData = Data.setPkgDtBoolean(_packageData, false, 233);
		// paused = false
		_packageData = Data.setPkgDtBoolean(_packageData, false, 234);
		// Private Pool, true or false
		if (_args[9] == 1) {
			require(_args[8] > 0, "IGN23");
			_packageData = Data.setPkgDtBoolean(_packageData, true, 235);
		} else if (_args[9] == 0) {
			_packageData = Data.setPkgDtBoolean(_packageData, false, 235);
		} else {
			revert("IGN24");
		}
		// Auto Transfer, true or false
		if (_args[10] == 1) {
			_packageData = Data.setPkgDtBoolean(_packageData, true, 236);
		} else if (_args[10] == 0){
			_packageData = Data.setPkgDtBoolean(_packageData, false, 236);
		} else {
			revert("IGN25");
		}

		return _packageData;
	}

    /**
	* @dev Checks tokens decimal setting
	* @dev IGN47: Decimals is out ERC20 Standard
	* @return decimal correction
	*/
	function getDecimals(uint256 _decimals) internal pure returns (uint256) {
		if (_decimals == uint256(18)) {
			return uint256(1);
		} else if (_decimals < uint256(18)) {
			return 10**(uint256(18) - (_decimals - (uint(1))));
		} else {
			revert("IGN47");
		}
	}

	/**
	* @dev sets private pool flag in package data
	* @param self pool package data
	* @param value bool value to set
	*/
	function setPrivatePool(PoolTokenModel storage self, bool value) internal{
		self.packageData = Data.setPkgDtBoolean(
			self.packageData,
			value,
			235
		);
	}

	/**
	* @dev sets auto fix flag in package data
	* @param self pool package data
	* @param value bool value to set
	*/
	function setAutoFix(PoolTokenModel storage self, bool value) internal{
		self.packageData = Data.setPkgDtBoolean(
			self.packageData,
			value,
			236
		);
	}

	/**
	* @dev sets end date value in package data
	* @param self pool package data
	* @param _newEndDate date to set
	* @param _status_boolean counter to all status to set
	*/
	function setEndDate(
		PoolTokenModel storage self,
		uint256 _newEndDate,
		uint _status_boolean
	) internal {
		//address
		uint256 _packageData = uint256(uint160(self.packageData));
		//start date
		_packageData |= uint256(uint32(self.packageData>>160))<<160;
		//end date
		_packageData |= _newEndDate<<192;
		//pool
		_packageData |= uint256(uint8(self.packageData>>224))<<224;

		for (uint256 i = 0; i < _status_boolean; i++) {
			bool flag = Data.getPkgDtBoolean(self.packageData, 232+i);
            _packageData = Data.setPkgDtBoolean(_packageData, flag, 232+i);
        }

		self.packageData = _packageData;
	}

	/**
	* @dev sets end date value in package data
	* @param self pool package data
	* @param _newStartDate date to set
	* @param _status_boolean counter to all status to set
	*/
	function setStartDate(
		PoolTokenModel storage self,
		uint256 _newStartDate,
		uint _status_boolean
	) internal {

		//address
		uint256 _packageData = uint256(uint160(self.packageData));
		// startDate
		_packageData |= _newStartDate<<160;
		// endDate
		_packageData |= uint256(uint32(self.packageData>>192))<<192;
		// Pool
		_packageData |= uint256(uint8(self.packageData>>224))<<224;
        // for include all Status pool
        for (uint256 i = 0; i <= _status_boolean; i++) {
            bool flag = Data.getPkgDtBoolean(self.packageData, 232+i);
            _packageData = Data.setPkgDtBoolean(_packageData, flag, 232+i);
        }

		self.packageData = _packageData;
	}

	function setFinalized(PoolTokenModel storage self) internal {
		self.packageData = Data.setPkgDtBoolean(self.packageData,true,233);
	}

	/**
	* @notice check if pool is valid
	* @dev Error IGN38 - Invalid Pool
	* @param self pool package data
	*/
    function poolIsValid(PoolTokenModel storage self) internal view {
		require(self.valid, "IGN38");
    }

	/**
	* @notice isStatusPool for Pool Token Model Struct
	* @dev Boolen method to verify Several Status in this pool
	* @param self pool package data
	* @param _statusNumber Position of Boolean in the PackageData, isWithdrawed(232), isFinalized(233), isPaused(234), isPrivPool(235), isAutoTransfer(236)
	* @return a boolean value according to the value in the storage
	*/
	function _isStatusPool (PoolTokenModel storage self, uint _statusNumber)
	private view returns (bool) {
		poolIsValid(self);
		return Data.getPkgDtBoolean(self.packageData,_statusNumber);
	}

	/**
	* @param self pool package data
	* @return a boolean indicating if raised was withdrawed
	*/
	function isWithdrawed(PoolTokenModel storage self) internal view returns (bool) {
		return _isStatusPool(self, 232);
	}

	/**
	* @param self pool package data
	* @return a boolean indicating if pool is finalized
	*/
	function isFinalized(PoolTokenModel storage self) internal view returns (bool) {
		return _isStatusPool(self, 233);
	}

	/**
	* @param self pool package data
	* @return a boolean indicating if pool is paused
	*/
	function isPaused(PoolTokenModel storage self) internal view returns (bool) {
		return _isStatusPool(self, 234);
	}

	/**
	* @param self pool package data
	* @return a boolean indicating if pool is private
	*/
	function isPrivPool(PoolTokenModel storage self) internal view returns (bool) {
		return _isStatusPool(self, 235);
	}

	/**
	* @param self pool package data
	* @return a boolean indicating if pool has autotransfer
	*/
	function isAutoTransfer(PoolTokenModel storage self) internal view returns (bool) {
		return _isStatusPool(self, 236);
	}

	/**
	* @notice Get the Start Date of the Pool, in Unix Format (Epoch based on Block Timestamp of the blockchain)
	* @param self pool package data
	* @return Start Date of the Pool in Epoch Format
	*/
	function getStartDate(PoolTokenModel storage self) internal view returns (uint256) {
		poolIsValid(self);
		return uint256(uint32(self.packageData>>160));
	}

	/**
	* @notice Get the End Date of the Pool, in Unix Format (Epoch based on Block Timestamp of the blockchain)
	* @param self pool package data
	* @return End Date of the Pool in Epoch Format
	*/
	function getEndDate(PoolTokenModel storage self) internal view returns (uint256) {
		poolIsValid(self);
		return uint256(uint32(self.packageData>>192));
	}

	/**
	* @notice Is Crowd Sale Started
	* @notice This method allows to determine if the Crowd Sale has already been started or not
	* @param self pool package data
	* @return a boolean value according to the state of the Crowd Sale
	*/
	function isActive(PoolTokenModel storage self) internal view returns (bool) {
		return block.timestamp > getStartDate(self) &&
		block.timestamp < getEndDate(self);
	}
}