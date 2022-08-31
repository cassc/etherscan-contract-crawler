// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TheTrollsNFT is ERC721A, Ownable {
    uint256 public mintPrice;
    uint256 public maxSupply;
    bool public isMintingEnabled;
    bool public revealNFT;
    string public preReavealURI;
    mapping(address => bool) public OG_whiteList;
    bool isPublicEnabled;
    uint256 private price1 = 0.06 ether;
    uint256 private price2 = 0.08 ether;
    uint256 private publicMintPrice;
    string internal baseTokenUri;
    address payable public withdrawalWallet;

    constructor(
    string memory _name,
    string memory _symbol,
    address payable _withdrawalWallet, 
    string memory _tokenBaseUri, 
    string memory _preRevealUri
    ) ERC721A(_name, _symbol){
        maxSupply = 2000;
        withdrawalWallet = _withdrawalWallet;
        baseTokenUri = _tokenBaseUri;
        preReavealURI = _preRevealUri;
        isMintingEnabled = false;
    }


    function setIsMintingEnabled() external onlyOwner{
        isMintingEnabled = true;
    }

    function setBaseTokenUri(string calldata _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }

    function setRevealNFT() public onlyOwner{
        revealNFT = true;
    }

    function setPreRevealURI( string memory _preReavealURI) public onlyOwner{
        preReavealURI = _preReavealURI;
    }

    function setPublicMintingPrice(uint256 _publicMintPrice) public onlyOwner{
        publicMintPrice = _publicMintPrice;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if(revealNFT == false){
            return preReavealURI;
        }

        return bytes(baseTokenUri).length != 0 ? string(abi.encodePacked(baseTokenUri, _toString(tokenId),".json")) : "";
    }

    function withdraw() external onlyOwner{
        (bool success,) = withdrawalWallet.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    function setMintPrice(uint256 _price1, uint256 _price2 ) public onlyOwner{
        price1 = _price1;
        price2 = _price2;
    }

    function setPublicSale()public onlyOwner{
        isMintingEnabled = false;
        isPublicEnabled = true;
    }

    function changeWithdrawalwallet(address payable _newWithdrawalWallet)public onlyOwner{
        withdrawalWallet = _newWithdrawalWallet;
    }
    
    function setOGWhiteList(address [] calldata _addresses) public onlyOwner{
        for(uint256 i =0 ; i<_addresses.length; i++){
            OG_whiteList[_addresses[i]] = true;
        }
        
    }

    function mint(uint256 _quantity) external payable{
        if(isPublicEnabled == true){
            OG_whiteList[msg.sender] = false;
            mintPrice = publicMintPrice;
        }else if(OG_whiteList[msg.sender]){
            mintPrice = price1;
        }else if(msg.sender == owner()){
            mintPrice=0;
        } else{
            mintPrice = price2;
        }

        require(_quantity > 0, "You need to mint at least 1 NFT");
        require(isMintingEnabled, "Minting is not started yet");
        require(msg.value == _quantity * mintPrice, "Insufficient Balance");
        require(totalSupply() + _quantity <= maxSupply, "Sold Out");

            _safeMint(msg.sender, _quantity);
        }
    }