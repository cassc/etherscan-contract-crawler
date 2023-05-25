pragma solidity ^0.8.0;

import "./Base721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract LMCTOOL is Base721, ReentrancyGuard {
    address public pass = 0xd6591bBb8A4867cEa5ec732f9c30379C4A8bE730;

    uint256 public ownerNum;

    mapping(uint256 => bool) public ownerClaimed;

    constructor() public ERC721A("LMC TOOL", "LMC TOOL") {
        maxSupply = 30000;
        defaultURI = "ipfs://bafkreih7uswtki6nltmtemrbys4ku6hwzcc57mcxwg7jll3n3wtcwngkhy";
    }

    function claimByOwner(uint256[] calldata _tokenIds) external nonReentrant {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                IERC721A(pass).ownerOf(_tokenIds[i]) == _msgSender(),
                "Must be the tokenId owner"
            );
            require(!ownerClaimed[_tokenIds[i]], "Already owner claimed");
            ownerClaimed[_tokenIds[i]] = true;
        }
        require(
            totalSupply() + _tokenIds.length <= maxSupply,
            "Must lower than maxSupply"
        );
        ownerNum += _tokenIds.length;
        _mint(_msgSender(), _tokenIds.length);
    }
}