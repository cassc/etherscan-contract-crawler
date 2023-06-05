// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
    Pixel Vampire Syndicate / 2022 / Companions
*/
                                          
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract PixelVampireSyndicate is ERC721, Ownable {
    using Strings for uint256;

    string private _tokenBaseURI = "ipfs://QmeqN5KMBtftUW6XiUnPpMM4tqPGJBc5HJe7o1gn7ybV6e/";
    address private _signerAddress = 0x13c4584c7536e71AB917d5f1bE440E479681003a;
    uint256 private currentSupply;

    bool public live;
    bool public locked;
    
    constructor() ERC721("Pixel Vampire Syndicate", "PVS") {}
    
    modifier notLocked {
        require(!locked, "PVS: Locked");
        _;
    }

    function mint(uint256[] calldata tokens, bytes calldata signature) external {
        require(live, "PVS: Blood Claim Not Live");
        require(_signerAddress == ECDSA.recover(keccak256(abi.encodePacked(msg.sender, tokens)), signature), "INVALID_SIGNATURE");

        uint256 totalClaimed;
        
        for (uint256 i; i < tokens.length; i++) {
            if (_exists(tokens[i])) continue;

            totalClaimed++;
            _mint(msg.sender, tokens[i]);
        }

        require(totalClaimed > 0, "PVS: Cant claim none");

        currentSupply += totalClaimed;
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
        
        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }
}