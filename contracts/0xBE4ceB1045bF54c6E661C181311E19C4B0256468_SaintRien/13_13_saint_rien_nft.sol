// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract SaintRien is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    mapping(bytes32 => uint256) roots;
    string public baseURI = "https://gateway.pinata.cloud/ipfs/QmQWU4uAzmHTURxSTiYEgb2rDzPCewobZuWdDGpCJABnKa/";
    bool public whiteListMint = false;
    address public owner;
    mapping(address => uint256) public amountMinted;
    uint256 supply = 0;


    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    constructor(bytes32[] memory _roots, uint256[] memory _amounts) ERC721("Saint Rien", "STR") {
        for (uint256 i = 0; i < _roots.length; i++) {
            roots[_roots[i]] = _amounts[i];
        }
        owner = msg.sender;
        _tokenIds.increment();        
    }

    function mintWL(bytes32[] memory _proof, bytes32 _root)
        public
        payable
    {
        require(whiteListMint == true,
        "The mint hasn't started yet");
        uint256 amountToMint = roots[_root];
        require(amountMinted[msg.sender] < amountToMint,
        "You cant mint any more NFTs");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(roots[_root]>0,
        "You are not whitelisted");
        require(MerkleProof.verify(_proof, _root, leaf), "Invalid merkle proof");

        for (uint256 i = 0;
             i < (amountToMint - amountMinted[msg.sender]);
             i++) {
                supply += 1;
                uint256 newItemId = _tokenIds.current();
                _mint(msg.sender, newItemId);

                string memory temp = string.concat(baseURI, Strings.toString(newItemId));
                string memory tokenURI = string.concat(temp, ".json");
                _setTokenURI(newItemId, tokenURI);
                _tokenIds.increment();
                
             }
        amountMinted[msg.sender] = amountToMint;
                
    }

    function allowWhiteListMint(bool allow) public onlyOwner {
        whiteListMint = allow;
    }

    function editWhitelist(bytes32[] memory _roots, uint256[] memory _amounts) public onlyOwner {
        for (uint256 i = 0; i < _roots.length; i++) {
            roots[_roots[i]] = _amounts[i];
        }
    }
}