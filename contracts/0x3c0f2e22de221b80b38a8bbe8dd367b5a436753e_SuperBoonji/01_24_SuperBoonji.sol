// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './jupiter/JupiterNFT.sol';
import './ISuperBoonji.sol';

interface BoonjiContract {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract SuperBoonji is JupiterNFT, ISuperBoonji{
    event BurnAndMint(address indexed to, uint256[] burnedTokens, uint256 indexed mintedTokenId);

    address internal _boonjiAddress;    
    address internal _burnAddress;
    uint256 public _mintPrice;
    constructor(
		address proxyRegistryAddress,
		string memory name,
		string memory symbol,
		string memory baseTokenURI,
        address[] memory operators,
        address __boonjiAddress,
        address __burnAddress,
        uint256 mintPrice
	) JupiterNFT(proxyRegistryAddress, name, symbol, baseTokenURI, operators){
        _boonjiAddress = __boonjiAddress;
        _burnAddress = __burnAddress;
        _mintPrice = mintPrice;
    }

    function burnAndMint(uint256[] memory _boonjai) payable override external{
        require(msg.value >= _mintPrice, "Not enough ETH sent; check price!");

        BoonjiContract boonjiNft = BoonjiContract(_boonjiAddress);
        for(uint i = 0; i < _boonjai.length; i++) {
			require(boonjiNft.ownerOf(_boonjai[i]) ==  _msgSender());
            boonjiNft.safeTransferFrom(_msgSender(), _burnAddress, _boonjai[i]);
		}

        currentTokenId++;
		_safeMint(_msgSender(), currentTokenId);
        emit BurnAndMint (_msgSender(), _boonjai, currentTokenId);
        return;
    }

    function withdraw () external {
        require(operators[msg.sender], "only operators");
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function getMintPrice() public view returns(uint){
        return _mintPrice;
    }

    function setMintPrice(uint256 mintPrice) external{
        require(operators[msg.sender], "only operators");
        _mintPrice = mintPrice;
    }
}