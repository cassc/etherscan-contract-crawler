//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//  ________  _______   _______  _________  ________     ___    ___ 
// |\_____  \|\  ___ \ |\  ___ \|\___   ___\\   __  \   |\  \  /  /|
//  \|___/  /\ \   __/|\ \   __/\|___ \  \_\ \  \|\  \  \ \  \/  / /
//      /  / /\ \  \_|/_\ \  \_|/__  \ \  \ \ \  \\\  \  \ \    / / 
//     /  /_/__\ \  \_|\ \ \  \_|\ \  \ \  \ \ \  \\\  \  /     \/  
//    |\________\ \_______\ \_______\  \ \__\ \ \_______\/  /\   \  
//     \|_______|\|_______|\|_______|   \|__|  \|_______/__/ /\ __\ 
                                                                 
contract Zeetox is ERC721A, Ownable {
    // ====== Variables ======
    string private baseURI;
    uint256 private MAX_SUPPLY = 4200;
    uint256 public mintPrice = 2 ether;
    mapping(address => bool) public allowList;
    bool public publicMint = false;

    constructor() ERC721A("Zeetox NFT", "ZEETOX") {
    }

    // ====== Basic Setup ======
    function setURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

     function setSupply(uint256 _supply) external onlyOwner {
        MAX_SUPPLY = _supply;
    }

    // ====== Mint Settings ======
    function setMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    function setToPublicMint(bool _status) external onlyOwner {
        publicMint = _status;
    }

    // ====== Minting ======
    function ownerMint (uint256 _quantity) external payable onlyOwner {
        // *** Checking conditions ***
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Reach maximum supply.");
        
        // *** _safeMint's second argument now takes in a quality but not tokenID ***
        _safeMint(msg.sender, _quantity);
    }

    // ====== Allow List Settings ======
    function modifyAllowList(address[] calldata _addresses, bool allowType) external onlyOwner {
        require(_addresses.length <= 5000, "Too many addresses called.");
        for (uint256 i = 0; i < _addresses.length; i++) {
            allowList[_addresses[i]] = allowType; // allowType = true / false
        }
    }

    // ====== Minting ======
    function isAllowedToMint (address _address) public view returns (bool) {
        if (publicMint) {
            return true;
        }

        if (allowList[_address]) {
            return true;
        }
        return false;
    }

    function checkPrice (uint256 _value, uint256 _quantity) public view returns (bool) {
        uint256 requiredPrice = mintPrice * _quantity;

        if (_value >= requiredPrice) {
            return true;
        }
    
        return false;
    }

     function mint (uint256 _quantity) external payable {
        // *** Checking conditions ***]
        (bool isInAllowList) = isAllowedToMint(msg.sender);
        require(isInAllowList, "Not allow to mint.");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Reach maximum supply.");
        (bool isPriceEnough) = checkPrice(msg.value, _quantity);
        require(isPriceEnough, "Not enough ETH to mint.");
        
        // *** _safeMint's second argument now takes in a quality but not tokenID ***
        _safeMint(msg.sender, _quantity);
    }


    // ====== Token URI ======
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Token ID is not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId + 1), ".json"));
    }

    // ====== Withdraw ======
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = owner().call{value: balance}("");
        require(success, "Withdraw fail.");
    }
}