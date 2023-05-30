// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IOpenseaSeaportConduitController } from "./Interfaces.sol";

library Constants {
	string public constant NAME = "The Saudis Soulbound";
	string public constant SYMBOL = "SASB";
	uint256 public constant MATURITY_TIMESTAMP = 1657825200 + 40 days;
	IERC721 public constant SAUD_CONTRACT = IERC721(0xe21EBCD28d37A67757B9Bc7b290f4C4928A430b1);
	IOpenseaSeaportConduitController public constant OPENSEA_SEAPORT_CONDUIT_CONTROLLER = IOpenseaSeaportConduitController(0x00000000F9490004C11Cef243f5400493c00Ad63);
    address public constant OPENSEA_SEAPORT = 0x00000000006c3852cbEf3e08E8dF289169EdE581;
	address public constant ROYALTY_WALLET_ADDRESS = 0xbfE5D10F8DeDed4706C212399D74289f860ac289;
	uint96 public constant ROYALTY_BASIS_POINTS = 750;
}