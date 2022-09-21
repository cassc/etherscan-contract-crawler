// SPDX-License-Identifier: MIT
// AppBase.sol : CryptoStacks(tm) Stacks721 by j0zf at ApogeeINVENT 2021-02-28

pragma solidity >=0.6.0 <0.8.0;
import "./SafeMath.sol"; 
import "./Strings.sol"; 
import "./Market.sol";
import "./Holdings.sol";

abstract contract AppBase { 
	using SafeMath for uint256;
	using Strings for uint256;
	using Market for Market.TokenContract;
	using Market for Market.Listing;
	using Holdings for Holdings.HoldingsTable;

	//	from Library Holdings.sol
	event AccountCredited(uint32 indexed accountType, address indexed account, uint256 amount, uint256 balance);
	event AccountDebited(uint32 indexed accountType, address indexed account, uint256 amount, uint256 balance);
	event PoolCredited(uint32 poolType, uint256 amount, uint256 balance);
	event PoolDebited(uint32 indexed poolType, uint256 amount, uint256 balance);

	bool internal _paused;
	uint32 internal _networkId;
	mapping(string => string) internal _values; // version, banner, whatever, etc..
	Market.TokenContract[] internal _tokenContracts;
	Market.Listing[] internal _listings; // indexed by listingId
	mapping(address => uint256[]) internal _activeListingIds; // address(0) is ALL active listings
	mapping(address => mapping(uint256 => uint256)) internal _activeListingIdIndexes; // address(0) is ALL active listings, Maintains Index into _activeListingIds 
	mapping(uint256 => mapping(string => mapping(uint256 => uint256))) internal _contractListingIds; // __[contractId]["token"|"series"][id] => listingId

	Holdings.HoldingsTable internal _holdingsTable;

	mapping(uint32 => uint256) internal _conversionTable;
	// ^^ _conversionTable[peg] => conversion multiplier so Value * Multiplier = Approx Value in Wei
	// ^^ peg is the index for the container of the conversion multiplier: 0:Wei 1:USD

	mapping(uint32 => mapping(address => bool)) internal _roles; 
	// ^^ _roles[roleType][address] => true : "Has Role"
	// ^^ roleType 0:Null 1:Admin 2:Manager 3:Publisher
	uint32 constant _Admin_Role_ = 1;
	uint32 constant _Manager_Role_ = 2;
	uint32 constant _Publisher_Role_ = 3;
	uint32 constant _Banker_Role_ = 4;

	mapping(bytes4 => address) internal _logicFunctionContracts; // for mapping specific functions to contract addresses

	// Generalized Storage Containers for Proxy Logic expansions
	mapping(string => uint256) internal uint256Db;
	mapping(string => mapping(uint256 => uint256)) internal uint256MapDb;
	mapping(string => string) internal stringDb;
	mapping(string => mapping(uint256 => string)) internal stringMapDb;
	mapping(string => address) internal addressDb;
	mapping(string => mapping(uint256 => address)) internal addressMapDb;
	mapping(string => bytes) internal bytesDb;
	mapping(string => mapping(uint256 => bytes)) internal bytesMapDb;

	mapping(uint256 => mapping(string => uint32)) internal _listingDataInt; // listingId => "name" => uint32
	mapping(uint256 => mapping(string => uint256)) internal _listingDataNumber;
	mapping(uint256 => mapping(string => string)) internal _listingDataString;

	function installLogic(address logicContract, bool allowOverride) external {
		require(_roles[_Admin_Role_][msg.sender], "DENIED"); // 1:Admin
		(bool success, ) = logicContract.delegatecall(abi.encodeWithSignature("installProxy(address,bool)", logicContract, allowOverride));
		if (!success) {
			revert("FAILED_INSTALL");
		}
	}

	bool internal reentrancyLock = false;
	modifier nonReentrant() {
		require(!reentrancyLock);
		reentrancyLock = true;
		_;
		reentrancyLock = false;
	}

	function _setLogicFunction(string memory functionSignature, address functionContract, bool allowOverride) internal {
		require(_roles[_Admin_Role_][msg.sender], "DENIED"); // 1:Admin
		bytes4 sig = bytes4(keccak256(bytes(functionSignature)));
		require(sig != bytes4(keccak256(bytes("installLogic(address)"))), "CRASH!");
		require(sig != bytes4(keccak256(bytes("installProxy(address)"))), "BOOM!");
		require(allowOverride || _logicFunctionContracts[sig] == address(0), "OVERRIDE");
		_logicFunctionContracts[sig] = functionContract;
		emit LogicFunctionSet(functionSignature, sig, functionContract, allowOverride);
	}
	event LogicFunctionSet(string functionSignature, bytes4 indexed sig, address functionContract, bool allowOverride);

	function _delegateLogic() internal {
		address _delegateContract = _logicFunctionContracts[msg.sig];
		require(_delegateContract != address(0), "NO_LOGIC"); // No Logic Function found in the lookup table
		require(!_paused || _roles[_Admin_Role_][msg.sender], "PAUSED");  // 1:Admin
		assembly {
			let ptr := mload(0x40)
			calldatacopy(ptr, 0, calldatasize())
			let result := delegatecall(gas(), _delegateContract, ptr, calldatasize(), 0, 0)
			let size := returndatasize()
			returndatacopy(ptr, 0, size)
			switch result
				case 0 { revert(ptr, size) }
				default { return(ptr, size) }
		}
	}

	function _setConversion(uint32 peg, uint256 multiplier) internal {
		// ENFORCE EXTERNALLY
		// Currency Value X multiplier = nativePrice in Wei
		// peg 0 is native Wei, peg 1 is USD, etc.
		_conversionTable[peg] = multiplier;
	}

	function _getConversion(uint32 peg, uint256 value) internal view returns (uint256) {
		// @returns the nativePrice. A value in Wei converted by using a multiplier in a currency conversion-table
		// if the peg is not set. 0 will be returned
		// 	^ (note the "0" nativePrice or askingPrice should be "not for sale")
		// peg 0 is always native Wei peg 1 is USD and so on
		return ( peg == 0 ? value : value.mul(_conversionTable[peg]) );
	}

	function _percentOf(uint256 percent, uint256 x) internal pure returns (uint256) {
		// get truncated percentage of x, discards remainder. (percent is a whole number percent)
		return x.mul(percent).div(100);
	}

	function _removeActiveListing(address owner, uint256 listingId) internal returns (bool) {
		// @param address(0) for ALL active listings
		if (listingId < 1 || _activeListingIds[owner].length < 1) return false;
		uint256 endListingIndex = _activeListingIds[owner].length - 1;
		if (_activeListingIds[owner][endListingIndex] == listingId) { // it's on the end so pop it off
			_activeListingIdIndexes[owner][listingId] = uint256(-1); // Max uint256 is Non-Indexed
			_activeListingIds[owner].pop();
			return true;
		}
		uint256 index = _getActiveListingIdIndex(owner, listingId);
		if (index != uint256(-1)) { // replace it with the one on the end
			uint256 endListingId = _activeListingIds[owner][endListingIndex]; 
			_activeListingIds[owner][index] = endListingId;
			_activeListingIdIndexes[owner][listingId] = uint256(-1);  // Max uint256 is Non-Indexed
			_activeListingIdIndexes[owner][endListingId] = index; 
			_activeListingIds[owner].pop();
			return true;
		}
		return false;
	}

	function _addActiveListing(address owner, uint256 listingId) internal returns (bool) {
		// @param address(0) for ALL active listings
		if (_getActiveListingIdIndex(owner, listingId) == uint256(-1)) {
			_activeListingIdIndexes[owner][listingId] = _activeListingIds[owner].length; // track index into the _activeListingIds
			_activeListingIds[owner].push(listingId);
			return true;
		}
		return false;
	}

	function _getActiveListingIdIndex(address owner, uint256 listingId) internal view returns (uint256) {
		uint256 index = _activeListingIdIndexes[owner][listingId];
		if ( index < _activeListingIds[owner].length && _activeListingIds[owner][index] == listingId ) {
			return index;
		}
		return uint256(-1); // Max value means not found
	}

}
