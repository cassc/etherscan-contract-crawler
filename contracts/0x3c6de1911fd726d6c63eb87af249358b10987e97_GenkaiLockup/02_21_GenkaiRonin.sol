// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*
 *     ,_,
 *    (',')
 *    {/"\}
 *    -"-"-
 */

import "ERC721Common.sol";


error NotValidMinter();


// TODO: implement https://docs.skymavis.com/docs/mavis-market-list erc721 common state of
// source : https://github.com/axieinfinity/contract-template/tree/main/src
// https://docs.skymavis.com/docs/deploy-verify-smart-contract
contract Genkai is ERC721Common {
	mapping(address => bool) public minters;
	string public updateableURI;
	bool public lockAll;

	function initialize(string memory name_, string memory symbol_) public initializer {
		lockAll = true;
		__ERC721x_init(name_, symbol_);
	}

	function setMinter(address _minter, bool _val) external onlyOwner {
		minters[_minter] = _val;
	}

	function updateURI(string calldata _uri) external onlyOwner {
		updateableURI = _uri;
	}

	function setLock(bool _val) external onlyOwner {
		lockAll = _val;
	}

	function mint(address _to, uint256 _tokenId) external {
		_isMinter(msg.sender);
		_mint(_to, _tokenId);
	}

	function _isMinter(address _minter) internal {
		if (!minters[_minter]) revert NotValidMinter();
	}

	function _beforeTokenTransfer(address _from, address _to, uint256 _firstTokenId, uint256 _batchSize) internal override {
		if (lockAll && _from != address(0)) revert();
		super._beforeTokenTransfer(_from, _to, _firstTokenId, _batchSize);
	}

	function _baseURI() internal view override returns (string memory) {
        return updateableURI;
    }

	function totalSupply() external pure returns(uint256) {
		return 20000;
	}
}