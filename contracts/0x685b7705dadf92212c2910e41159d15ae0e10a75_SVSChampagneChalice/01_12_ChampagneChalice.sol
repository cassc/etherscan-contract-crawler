// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
    Champagne Chalice / 2022
*/
                                          
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SVSChampagneChalice is ERC721, Ownable {
    using Strings for uint256;

    string private _tokenBaseURI = "ipfs://QmNcVQVL3iwPhisbC8HpoqVYifu9iDJVYwdZX9LkPhjDhp";
    address private _signerAddress = 0x6d821F67BBD6961f42a5dde6fd99360e1Ab12345;
    uint256 private currentSupply;

    mapping(address => uint256[]) public burntChalices;

    bool public live;
    bool public locked;
    
    constructor() ERC721("SVS Champagne Chalice", "CHAMP") {}
    
    modifier notLocked {
        require(!locked, "CHAMP: Locked");
        _;
    }

    function getBurntChalices(address sender) view external returns (uint256[] memory) {
        return burntChalices[sender];
    }

    function mint(uint256 tokenId, bytes calldata signature) external {
        require(live, "CHAMP: Mint Not Live");
        require(_signerAddress == ECDSA.recover(keccak256(abi.encodePacked(msg.sender, tokenId)), signature), "INVALID_SIGNATURE");
        currentSupply++;

        _mint(msg.sender, tokenId);
    }

    function burn(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "CHAMP: Not owner");
        burntChalices[msg.sender].push(tokenId);
        _burn(tokenId);
    }
    
    function toggle() external onlyOwner {
        live = !live;
    }

    function lock() external onlyOwner {
        locked = true;
    }

    function setSignerAddress(address addr) external onlyOwner {
        _signerAddress = addr;
    }

    function setBaseURI(string calldata URI) external onlyOwner notLocked {
        _tokenBaseURI = URI;
    }

    function totalSupply() public view returns(uint256) {
        return currentSupply;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        
        return _tokenBaseURI;
    }
}