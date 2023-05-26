pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CosmosERC20 is ERC20 {
	uint256 MAX_UINT = type(uint256).max;

    uint8 private _decimals;

	constructor(
		address _gravityAddress,
		string memory _name,
		string memory _symbol,
		uint8 decimals_
	) public ERC20(_name, _symbol) {
		_decimals = decimals_;
		_mint(_gravityAddress, MAX_UINT);
	}

	function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

}