// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "../openzeppelin/token/ERC20/ERC20.sol";

/**
 * @title Template contract for social money, to be used by TokenFactory
 */

contract SocialMoney is ERC20 {
	using SafeMath for uint256;

	/**
     * @dev Constructor on SocialMoney
     * @param _name string Name parameter of Token
     * @param _symbol string Symbol parameter of Token
     * @param _decimals uint8 Decimals parameter of Token
     * @param _proportions uint256[3] Parameter that dictates how totalSupply will be divvied up,
                            _proportions[0] = Vesting Beneficiary Initial Supply
                            _proportions[1] = Roll Supply
                            _proportions[2] = Vesting Beneficiary Vesting Supply
							_proportions[3] = Referral
     * @param _vestingBeneficiary address Address of the Vesting Beneficiary
     * @param _platformWallet Address of Roll platform wallet
     * @param _tokenVestingInstance address Address of Token Vesting contract
	 * @param _referral Roll 1.5
     */
	constructor(
		string memory _name,
		string memory _symbol,
		uint8 _decimals,
		uint256[4] memory _proportions,
		address _vestingBeneficiary,
		address _platformWallet,
		address _tokenVestingInstance,
		address _referral
	) ERC20(_name, _symbol) {
		_setupDecimals(_decimals);

		uint256 totalProportions =
			_proportions[0].add(_proportions[1]).add(_proportions[2]).add(
				_proportions[3]
			);

		_mint(_vestingBeneficiary, _proportions[0]);
		_mint(_platformWallet, _proportions[1]);
		_mint(_tokenVestingInstance, _proportions[2]);
		if (_referral != address(0)) {
			_mint(_referral, _proportions[3]);
		}

		//Sanity check that the totalSupply is exactly where we want it to be
		require(totalProportions == totalSupply(), "Error on totalSupply");
	}
}