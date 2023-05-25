// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IVeCRV.sol";
/// @title sdToken
/// @author StakeDAO
/// @notice A token that represents the Token deposited by a user into the Depositor
/// @dev Minting & Burning was modified to be used by the operator
contract sdCRV is ERC20 {
	address public operator;
    address public constant SD_VE_CRV = 0x478bBC744811eE8310B461514BDc29D03739084D;
	address public constant VE_CRV = 0x5f3b5DfEb7B28CDbD7FAba78963EE202a494e2A2;
	address public constant DAO = 0xF930EBBd05eF8b25B1797b9b2109DDC9B0d43063;

	constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
		operator = msg.sender;

		// It will mint sdCrv token to the DAO address (around 600K)
    	// It is the difference between the number of CRV locked by the locker and the sdVeCrv total supply
    	// The sdveCrv minting will be disabled before deploying this contract so the sdVeCrv total suppply won't change
        uint256 lockerBalance = ERC20(SD_VE_CRV).totalSupply();
		IVeCRV.LockedBalance memory lockedBalance = IVeCRV(VE_CRV).locked(0x52f541764E6e90eeBc5c21Ff570De0e2D63766B6);
		uint256 toMint = uint256(uint128(lockedBalance.amount)) - lockerBalance;
		_mint(DAO, toMint);
	}

	/// @notice Set a new operator that can mint and burn sdToken
	/// @param _operator new operator address
	function setOperator(address _operator) external {
		require(msg.sender == operator, "!authorized");
		operator = _operator;
	}

	/// @notice mint new sdToken, callable only by the operator
	/// @param _to recipient to mint for 
	/// @param _amount amount to mint
	function mint(address _to, uint256 _amount) external {
		require(msg.sender == operator, "!authorized");
		_mint(_to, _amount);
	}

	/// @notice burn sdToken, callable only by the operator
	/// @param _from sdToken holder
	/// @param _amount amount to burn
	function burn(address _from, uint256 _amount) external {
		require(msg.sender == operator, "!authorized");
		_burn(_from, _amount);
	}
}