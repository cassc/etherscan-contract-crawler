// SPDX-License-Identifier: MIT
// Owner: Pillz inc. (USA)
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Bollz is ERC721URIStorage {

    event Minted(string returnable);


    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(uint256 => string) public tokenIdToIPFSImageLink;
    mapping(string => string) private ipfs_to_description;
    mapping(string => string) private ipfs_to_name;
    mapping(address => bool) public wlClaimed;
    mapping(uint256 => string) private indexminted_to_ipfs_map;
    mapping(uint256 => string) private index_to_ipfs_map;
    mapping(string => uint256) private ipfs_to_index_map;

    string[] ipfslinks;
    string[] ipfsminted;

    uint256 private mintedCount = 0;
    uint256 private supplyCount = 0;

    address private admin = 0xcEA03203B35DfCaCB1a53B5C746C12d69d513908;
    address private teamWallet = 0x8f0a0BaeCce0743e6ed2185c8e545f28F360cB07;
    bytes32 public merkleRoot = 0xe88deed1f874bf51753b2bffc26c559db494e6a895bcffa0e7ac15826ab9f741;
    

    uint256 currentInternalIndex = 0;
    event Log(string lmsg);

    constructor() ERC721("Bollz", "PILLZ"){

    }


     function rnd(uint maxNumber,uint minNumber) public view returns (uint amnt) {
        amnt = uint(keccak256(abi.encodePacked(block.number, msg.sender, block.timestamp))) % (maxNumber-minNumber);
        amnt = amnt + minNumber;
        return amnt;
    } 

    function getTokenURI(string memory ndescr, string memory nname, string memory nimage ) public pure returns (string memory){
        bytes memory dataURI = abi.encodePacked(
            '{',
                '"name": "', nname, '",',
                '"description": "', ndescr ,'",',
                '"image": "', nimage, '",',
            '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }

    function addNft(string memory name, string memory ipfs, string memory description) public returns (string memory) {
        require(msg.sender == admin, "Only PILLZ inc staff can change this data.");
        index_to_ipfs_map[currentInternalIndex] = ipfs;
        ipfs_to_description[ipfs] = description;
        ipfs_to_name[ipfs] = name;
        supplyCount = supplyCount + 1;
        currentInternalIndex = currentInternalIndex + 1;
        ipfslinks.push(ipfs);
    }


    function editMerkleRoot(bytes32 newMerkleRoot) public {
        merkleRoot = newMerkleRoot;
    }

    function getMerkleRoot() public view returns(bytes32) {
        return merkleRoot;
    }

    function promoteCharacter(string memory previpfs, string memory ipfslink) public {
        require(_exists(ipfs_to_index_map[previpfs]), "Please use a token that exists.");
        require(msg.sender == admin, "Only PILLZ inc staff can change this data.");
        uint256 scopeIndex = ipfs_to_index_map[previpfs];
        index_to_ipfs_map[ipfs_to_index_map[previpfs]] = ipfslink;
        ipfs_to_index_map[previpfs] = ipfs_to_index_map[previpfs];
        ipfs_to_description[ipfslink] = ipfs_to_description[previpfs];
        ipfs_to_name[ipfslink] = ipfs_to_name[previpfs];
        _setTokenURI(scopeIndex, getTokenURI(
            ipfs_to_description[previpfs], 
            ipfs_to_name[previpfs], 
            ipfslink
        ));
    }   

    function mint(bytes32[] calldata _merkle) public returns(string memory){
        if (msg.sender != teamWallet) {
            require(!wlClaimed[msg.sender], "You has already claimed an NFT. Onlye ONE NFT allowed PER WALLET.");
        }
        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(MerkleProof.verify(_merkle, merkleRoot, leaf), "invalid merkle proof!");

        if (supplyCount > 0) {
            if (mintedCount < supplyCount) {
            
                uint target_index = ipfslinks.length-1;

                if (msg.sender != teamWallet) {
                    wlClaimed[msg.sender] = true;
                }
                
                _tokenIds.increment();
                uint256 newItemId = _tokenIds.current();
                _safeMint(msg.sender, newItemId);
                _setTokenURI(newItemId, getTokenURI(
                    ipfs_to_description[index_to_ipfs_map[target_index]], 
                    ipfs_to_name[index_to_ipfs_map[target_index]], 
                    index_to_ipfs_map[target_index]
                ));
                indexminted_to_ipfs_map[target_index] = index_to_ipfs_map[target_index];
                mintedCount = mintedCount + 1;



            }else{
                emit Log("no supply left");
                return("no suply left");
            }
        }else{
            emit Log("supply is 0");
            return("The supply is 0");
        }   
    }

}