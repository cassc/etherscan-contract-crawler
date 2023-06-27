// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

contract BrandverseAmbassadorToken is ERC721A, Ownable {
    uint private constant MAX_SUPPLY = 111;
    uint private constant MAX_MINT = 1;
    
    mapping (address => uint) public userMintedAmount;
    bytes32 public merkleRoot;
    bool public tokenUriLocked;
    string private _baseTokenURI;

    constructor() ERC721A("BrandverseAmbassadorToken", "BAT") {}

    modifier whitelistOnly(bytes32[] calldata _proof) {
        require(isWhitelisted(msg.sender, _proof, merkleRoot), "NOT_WHITELISTED");
        _;
    }

    function ownerClaim(uint256 _count) external onlyOwner {
        require(totalSupply() + _count <= MAX_SUPPLY, "EXCEEDS_MAX_SUPPLY");
        _safeMint(msg.sender, _count);
    }

    function claim(bytes32[] calldata _proof) external whitelistOnly(_proof) {
        require(totalSupply() + 1 <= MAX_SUPPLY, "EXCEEDS_MAX_SUPPLY");
        require(userMintedAmount[msg.sender] + 1 <= MAX_MINT, "MAX_MINT");
        userMintedAmount[msg.sender]++;
        _safeMint(msg.sender, 1);
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function lockMetadata() external onlyOwner {
        tokenUriLocked = true;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        require(!tokenUriLocked, "METADATA_LOCKED");
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function isWhitelisted(address _account, bytes32[] calldata _proof, bytes32 _root) internal pure returns (bool) {
        return MerkleProof.verify(_proof, _root, leaf(_account));
    }

    function maxSupply() external pure returns (uint256) {
        return MAX_SUPPLY;
    }
    
    function getTotalSupply() external view returns (uint256) {
        return totalSupply();
    }
}