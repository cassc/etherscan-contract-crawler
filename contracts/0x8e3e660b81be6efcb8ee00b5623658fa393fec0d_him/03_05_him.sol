//Website : https://dokwon.icu/
//Telegram : https://t.me/dokwonhim

pragma solidity ^0.8.0;


import "./ERC20.sol";

contract him is Context, ERC20 {

	constructor(uint256 _supply) ERC20("DOKWON", "HIM") {
		_mint(msg.sender, _supply);
	}

	function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}