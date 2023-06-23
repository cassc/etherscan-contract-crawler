// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*
 *     ,_,
 *    (',')
 *    {/"\}
 *    -"-"-
 */

import "IERC721.sol";
import "DefaultOperatorFiltererUpgradeable.sol";
import "ERC721Royalty.sol";
import "ERC721x.sol";

// TODO add revokable filterer + maintain some list of undesired marketplaces
contract GenesisPass is ERC721x("Courbet Genesis Pass", unicode"💎🎟️") {

	bool public paused;
	string public updateableURI;
	mapping(address => bool) public minters;

	constructor() {
		paused = true;
	}

	modifier notPaused() {
		if (paused) revert("paused");
		_;
	}

	function setMinters(address _minter, bool _val) external onlyOwner {
		minters[_minter] = _val;
	}

	function setPause(bool _val) external onlyOwner {
		paused = _val;
	}

	function updateURI(string calldata _newURI) external onlyOwner {
		updateableURI = _newURI;
	}

	function mint(address _to, uint256 _tokenId) external {
		if (!minters[msg.sender]) revert();
		_mint(_to, _tokenId);
	}

	function transferFrom(address _from, address _to, uint256 _tokenId) public override notPaused {
		ERC721x.transferFrom(_from, _to, _tokenId);
	}

	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public override notPaused {
		ERC721x.safeTransferFrom(_from, _to, _tokenId, _data);
	}

	function _baseURI() internal view override returns (string memory) {
        return updateableURI;
    }
}