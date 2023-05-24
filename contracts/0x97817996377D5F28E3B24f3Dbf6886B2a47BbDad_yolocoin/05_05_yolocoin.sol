// NOT JUST ANY MEME!
// YOLO Token represent a willingness to embrace the volatile and often unpredictable nature of cryptocurrencies.
// Website : https://yoloeth.xyz/


pragma solidity ^0.8.0;


import "./ERC20.sol";

contract yolocoin is Context, ERC20 {

	constructor(uint256 _supply) ERC20("Yolo Coin", "YOLO") {
		_mint(msg.sender, _supply);
	}

	function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}