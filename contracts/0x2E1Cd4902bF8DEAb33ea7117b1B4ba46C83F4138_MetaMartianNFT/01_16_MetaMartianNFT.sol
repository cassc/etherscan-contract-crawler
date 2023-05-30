// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MRC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MetaMartianNFT is MRC721, Ownable {

	uint256 public maxSupply = 400;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

	constructor(
    ) MRC721(
    	"Meta Martian NFT",
    	"MMN",
        "https://mmac-meta-martian-eth.communitynftproject.io/"
    ){
    	_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    	_setupRole(MINTER_ROLE, msg.sender);
    	_setupRole(ADMIN_ROLE, msg.sender);
    }

    function _beforeMint(
        address to,
        uint256 id
    ) internal virtual override {
    	require(totalSupply() + 1 <= maxSupply, "> maxSupply");
    }

    function setBaseUrl(string memory _newUri) public onlyRole(ADMIN_ROLE) {
        _baseTokenURI = _newUri;
    }

    function setMaxSupply(uint256 _amount) public onlyRole(ADMIN_ROLE) {
        maxSupply = _amount;
    }
}