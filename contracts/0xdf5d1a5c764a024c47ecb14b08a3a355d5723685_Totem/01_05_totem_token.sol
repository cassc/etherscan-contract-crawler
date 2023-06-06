// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract Totem is ERC20{
    address private constant _DEV_WALLET = address(0xa0270756B3a3E18AfA74dB7812367aF9E5e79BF3);
    // This is the Totemheads Coin address, but the allocation of tokens has now been recorded on the blockchain
	address private constant _MARKETING = address(0x9055C61eAF42757bC8D2D0c413F26e9F75E1b7E8);
	// This is the Totemheads Coin address, but the allocation of tokens has now been recorded on the blockchain
	address private constant _GAME_REWARD = address(0x9055C61eAF42757bC8D2D0c413F26e9F75E1b7E8);
	// This is the Totemheads Coin address, but the allocation of tokens has now been recorded on the blockchain
	address private constant _NFT_HOLDER_CLAIM = address(0x9055C61eAF42757bC8D2D0c413F26e9F75E1b7E8);

    constructor() ERC20("TotemHeads Coin", "$TOTEM") {
        _mint(msg.sender, 666_000_000_000_000 * 10 ** 18);
        _mint(_DEV_WALLET, 13_811_450_000_000 * 10 ** 18);
		_mint(_MARKETING, 7_200_000_000_000 * 10 ** 18);
		_mint(_GAME_REWARD, 3_718_750_000_000 * 10 ** 18);
		_mint(_NFT_HOLDER_CLAIM, 29_269_800_000_000 * 10 ** 18);
    }

}