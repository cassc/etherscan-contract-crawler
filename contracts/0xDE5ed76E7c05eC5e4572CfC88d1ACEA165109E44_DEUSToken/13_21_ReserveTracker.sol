// Be name Khoda
// Bime Abolfazl

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.7;

// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     | 
// =================================================================================================================
// ====================================================================
// =========================== ReserveTracker =========================
// ====================================================================
// Deus Finance: https://github.com/DeusFinance

// Primary Author(s)
// Jason Huan: https://github.com/jasonhuan
// Sam Kazemian: https://github.com/samkazemian
// Vahid: https://github.com/vahid-dev
// SAYaghoubnejad: https://github.com/SAYaghoubnejad

// Reviewer(s) / Contributor(s)
// Travis Moore: https://github.com/FortisFortuna

import "../Math/SafeMath.sol";
import "../Math/Math.sol";
import "../Uniswap/Interfaces/IUniswapV2Pair.sol";
import "../Governance/AccessControl.sol";

contract ReserveTracker is AccessControl {

	// Roles
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

	// Various precisions
	uint256 private PRICE_PRECISION = 1e6;

	// Contract addresses
	address private dei_contract_address;
	address private deus_contract_address;

	// Array of pairs for DEUS
	address[] public deus_pairs_array;

	// Mapping is also used for faster verification
	mapping(address => bool) public deus_pairs;

	uint256 public deus_reserves;

	// ========== MODIFIERS ==========

	modifier onlyByOwnerOrGovernance() {
		require(hasRole(OWNER_ROLE, msg.sender), "Caller is not owner");
		_;
	}

	// ========== CONSTRUCTOR ==========

	constructor(
		address _dei_contract_address,
		address _deus_contract_address
	) {
		dei_contract_address = _dei_contract_address;
		deus_contract_address = _deus_contract_address;
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_setupRole(OWNER_ROLE, msg.sender);
	}

	// ========== VIEWS ==========

	function getDEUSReserves() public view returns (uint256) {
		uint256 total_deus_reserves = 0;

		for (uint i = 0; i < deus_pairs_array.length; i++){ 
			// Exclude null addresses
			if (deus_pairs_array[i] != address(0)){
				if(IUniswapV2Pair(deus_pairs_array[i]).token0() == deus_contract_address) {
					(uint reserves0, , ) = IUniswapV2Pair(deus_pairs_array[i]).getReserves();
					total_deus_reserves = total_deus_reserves + reserves0;
				} else if (IUniswapV2Pair(deus_pairs_array[i]).token1() == deus_contract_address) {
					( , uint reserves1, ) = IUniswapV2Pair(deus_pairs_array[i]).getReserves();
					total_deus_reserves = total_deus_reserves + reserves1;
				}
			}
		}

		return total_deus_reserves;
	}

	// Adds collateral addresses supported, such as tether and busd, must be ERC20 
	function addDEUSPair(address pair_address) public onlyByOwnerOrGovernance {
		require(deus_pairs[pair_address] == false, "Address already exists");
		deus_pairs[pair_address] = true; 
		deus_pairs_array.push(pair_address);
	}

	// Remove a pool 
	function removeDEUSPair(address pair_address) public onlyByOwnerOrGovernance {
		require(deus_pairs[pair_address] == true, "Address nonexistant");
		
		// Delete from the mapping
		delete deus_pairs[pair_address];

		// 'Delete' from the array by setting the address to 0x0
		for (uint i = 0; i < deus_pairs_array.length; i++){ 
			if (deus_pairs_array[i] == pair_address) {
				deus_pairs_array[i] = address(0); // This will leave a null in the array and keep the indices the same
				break;
			}
		}
	}
}

//Dar panah khoda