pragma solidity >=0.4.25 <0.7.0;

import "ERC20Mintable.sol";


contract CBERC20Token is ERC20Mintable {
	  string public constant name = "CAPTAIN";
		string public constant symbol = "CAPT";
		uint8 public constant decimals = 18;

		/**
		* @dev Constructor that gives _initialBeneficiar all of existing tokens.
		*/
		constructor(address _initialBeneficiar) public {
				uint256 INITIAL_SUPPLY = 2100000 * (10 ** uint256(decimals));
				_mint(_initialBeneficiar, INITIAL_SUPPLY);
		}
}
