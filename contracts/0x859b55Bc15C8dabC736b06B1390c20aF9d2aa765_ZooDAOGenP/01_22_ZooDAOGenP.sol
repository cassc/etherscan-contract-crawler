pragma solidity ^0.8.13;

import './token/onft/ONFT721.sol';

import '@openzeppelin/contracts/access/Ownable.sol';

contract ZooDAOGenP is ONFT721 {
	uint256 public totalSupply;
	uint256 public maxTotalSupply = 100;

	string internal baseURI = 'https://gateway.pinata.cloud/ipfs/QmTTgWNq8mejybkyQSqyJXnxijKWFED2ZS5qbnAVJ12zSB/';

	constructor(uint256 _minGasToTransfer, address _layerZeroEndpoint)
		ONFT721('ZooDAO Gen P Cards', 'ZDC', _minGasToTransfer, _layerZeroEndpoint)
	{}

	function mintTo(address _to) external onlyOwner {
		require(totalSupply < maxTotalSupply, 'ZooNFT: reached total supply');

		_safeMint(_to, ++totalSupply);
	}

	function mintBatchTo(address _to, uint256 quantity) external onlyOwner {
		require(totalSupply + quantity <= maxTotalSupply, 'ZooNFT: reached total supply');

		uint256 counter = totalSupply;

		for (uint256 i = 0; i < quantity; i++) {
			_safeMint(_to, ++counter);
		}

		totalSupply += quantity;
	}

	function _baseURI() internal view override returns (string memory) {
		return baseURI;
	}

	function updateBaseURI(string memory _newURI) external onlyOwner {
		baseURI = _newURI;
	}

	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		return string.concat(ERC721.tokenURI(tokenId), '.json');
	}
}