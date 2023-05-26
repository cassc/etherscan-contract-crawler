// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

//@author Lewis B
//@title Soulda

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

contract Soulda is Ownable, ERC721A, ReentrancyGuard {

    using Strings for uint256;

    string public baseURI;

    uint256 private constant MAX_SUPPLY = 7777;

    bytes32 public merkleRoot;

    uint256 public saleStartTime = 1656975601;

    mapping(address => uint256) public totalMinted;
    mapping(uint256 => string) public soulaType;
    

    constructor(
        string memory _baseURI,
        bytes32 _merkleRoot
    ) ERC721A("Soulda", "SOULDA16") {
        baseURI = _baseURI;
        merkleRoot = _merkleRoot;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
    
      // For marketing etc.
    function devMint(address[] memory _team, uint256[] memory _teamMint) external onlyOwner {
        for (uint256 i = 0; i < _team.length; i++) {
            require(totalSupply() + _teamMint[i] <= MAX_SUPPLY, "Max supply exceeded");
            _safeMint(_team[i], _teamMint[i]);
        }
    }

    function whitelistMint(address _account, uint256 _quantity, bytes32[] calldata _proof, string memory _soulType) external payable callerIsUser {
        require(currentTime() >= saleStartTime, "Soulda whitelist has not opened yet");
        require(isWhiteListed(msg.sender, _proof), "Not whitelisted");
        require(totalMinted[msg.sender] + _quantity <= 2, "You can only mint 2 NFT on the Soulda Whitelist Sale");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply exceeded");
        soulaType[totalSupply()] = _soulType;
        totalMinted[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    function publicSaleMint(address _account, uint256 _quantity, string memory _soulType) external payable callerIsUser {
        require(currentTime() > saleStartTime + 16 hours, "Soulda public mint is not open yet");
        require(currentTime() < saleStartTime + 64 hours, "Soulda public mint is closed");
        require(totalMinted[msg.sender] + _quantity <= 2, "You can only mint up to 2 Soulda NFTs on the Public Mint");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply exceeded");
        soulaType[totalSupply()] = _soulType;
        totalMinted[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    // Metadata

    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    //Sale Timing
    function setSaleStartTime(uint256 _saleStartTime) external onlyOwner {
        saleStartTime = _saleStartTime;
    }


    function currentTime() internal view returns(uint256) {
        return block.timestamp;
    }

    //Whitelist
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function isWhiteListed(address _account, bytes32[] calldata _proof) internal view returns(bool) {
        return _verify(leaf(_account), _proof);
    }

    function leaf(address _account) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _verify(bytes32 _leaf, bytes32[] memory _proof) internal view returns(bool) {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }


}