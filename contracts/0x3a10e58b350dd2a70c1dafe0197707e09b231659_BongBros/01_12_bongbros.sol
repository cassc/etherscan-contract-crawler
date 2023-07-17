//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// bongbros.wtf

contract BongBros is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;

    uint public totalSupply = 6969;
    uint public maxPerWallet = 5;

	string private ipfsBaseURI = "";
	string private unrevealedURI = "ipfs://bafybeigo32ktjp5svoq2sex2djt2wntfscoa3pxjpddthmvpmdnqjufasm";
    

    uint private price = 0.003 ether;   

    bool public mintingActive = false;
    bool public isRevealed = false;

    mapping(address => uint) public mintedPerWallet;
    
    constructor () ERC721 ("bongbros", "BONGS"){
		// mint for owner
		for(uint256 i = 0; i < 5; i++) {
            tokenIds.increment();
            uint256 newItemId = tokenIds.current();
            _safeMint(msg.sender, newItemId);
            mintedPerWallet[msg.sender]++;
        }
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        ipfsBaseURI = _baseURI;
    }

    function setMinting(bool value) public onlyOwner {
        mintingActive = value;
    }

    function revealTokens() public onlyOwner {
        require(!isRevealed, "Tokens already revealed!");
        require(bytes(ipfsBaseURI).length > 0, "BaseURI not set!");
        isRevealed = true;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        if(isRevealed) {            
            return string(abi.encodePacked(ipfsBaseURI, "/", uint2str(tokenId), ".json"));
        }
        return string(abi.encodePacked(unrevealedURI, "/", uint2str(tokenId), ".json"));
    }

    function isMintingActive() public view returns(bool) {
        return mintingActive;
    }

    function getPrice() public view returns(uint) {
		return price;
    }

    function currentSupply() public view returns(uint) {
        return tokenIds.current();
    }

    function withdrawBalance() public onlyOwner {
        (bool success, ) = payable(owner()).call{value:address(this).balance}("");
        require(success, "Withdrawal failed!");
    }

    receive() external payable {       
    }

    function mint(uint256 _amount) public payable {
		require(_amount > 0, string(abi.encodePacked("Amount minted must be greater than 0")));
        require(mintingActive, "Minting not started yet");
        require(_amount + mintedPerWallet[msg.sender] <= maxPerWallet, string(abi.encodePacked("Cannot mint more than ", uint2str(maxPerWallet), " tokens per wallet")));
		require(totalSupply >= _amount + tokenIds.current(), "Not enough tokens left!");

		// first bongbro is free
		uint toPay = 0;		
		if(mintedPerWallet[msg.sender] > 0) {
			toPay = getPrice() * _amount;
		} else {
			if(_amount > 1) {
				toPay = getPrice() * (_amount - 1);
			}
		}
		require(msg.value >= toPay, string(abi.encodePacked("Not enough ETH! At least ", uint2str(toPay), " wei has to be sent!")));
        for(uint256 i = 0; i < _amount; i++) {
            tokenIds.increment();
            uint256 newItemId = tokenIds.current();
            _safeMint(msg.sender, newItemId);
            mintedPerWallet[msg.sender]++;
        }
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}