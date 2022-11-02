// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC721AQueryable} from "erc721a/contracts/extensions/IERC721AQueryable.sol";
import {IERC721ABurnable} from "erc721a/contracts/extensions/IERC721ABurnable.sol";

interface IVoiceMaskAlpha is IERC721ABurnable{
    event AlphaCreated(uint256 indexed tokenId, address to);

    event AlphaBurned(uint256 indexed tokenId);

    event MinterUpdated(address minter);

    function mintAuction() external returns (uint256);

    function mintTeam(address to, uint256 quantity) external returns (uint256);

    function burn(uint256 alphaId) external;

    function setMinter(address _minter) external;

    function setAuctionSupply(uint256 _maxMint) external;

    function setTeamSupply(uint256 _maxMint) external;

    function setBaseURI(string memory uri) external;

}