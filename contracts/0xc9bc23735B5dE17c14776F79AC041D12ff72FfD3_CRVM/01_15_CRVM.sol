//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";

/// @title Van Minion - Genesis collection of Christian Rex van Minnen
/// @author (exp.table, ediv) === Chain/Saw

/*
*                                _       _             
*      /\   /\__ _ _ __   /\/\ (_)_ __ (_) ___  _ __  
*      \ \ / / _` | '_ \ /    \| | '_ \| |/ _ \| '_ \ 
*      \ V / (_| | | | / /\/\ \ | | | | | (_) | | | |
*      \_/ \__,_|_| |_\/    \/_|_| |_|_|\___/|_| |_|
*                                                                             
*    _______________                        _______________
*   |  ___________  |     .-.     .-.      |  ___________  |
*   | |           | |    .****. .****.     | |           | |
*   | |   X   0   | |    .*****.*****.     | |   X   0   | |
*   | |     -     | |     .*********.      | |     -     | |
*   | |   \___/   | |      .*******.       | |   \___/   | |
*   | |___________| |       .*****.        | |___________| |
*   |_______________|        .***.         |_______________|
*     _|________|_..........  .*............._|________|_
*   / ********** \                         / ********** \
*  /  ************ \                     /  ************ \
* --------------------                   --------------------
*                                                                                               
* Van Minion, is the genesis collection of Christian Rex Van Minnen. The collection consists of
* 51 exquisite, animated 1/1 works depicting Christian's psychedelic meditations on identity 
* and self within society and beyond.
* 
* Each drop will also unlock 2,000 'blanks' for public minting. These blanks represent the 
* underlying form or 'mother bust' from which all van Minions descend and will be redeemable 
* for an opportunity to customize a Van Minion of your very own in the future. A new blank 
* will be available with each drop for a total of 5 foundational shapes.
*
* Van Minion seeks to create a community centered around art where boundaries between 'creator' 
* and 'community member' are blurred--where distinctions between patron and artist, physical 
*  and digital, studio and metaverse, individual and collective become meaningless.
*/

contract CRVM is ERC721, Ownable {
    using Strings for uint256;
    using BitMaps for BitMaps.BitMap;

    bool public isOpened;
    uint256 public constant PRICE = 0.1 ether;

    uint256 private constant _SEPARATOR = 2000;
    uint256 private constant _MINT_LIMIT = 5;
    uint256 public _dropId;
    bytes32 public _merkleRoot;
    string public _baseTokenURI = "ipfs://";
    string public _ipfsCID;
    mapping (bytes32 => BitMaps.BitMap) private _claimed;
    mapping (uint256 => uint256) public _leftBlanks;

    constructor() ERC721("Van Minion", "CRVM") {}

    function withdraw(address recipient) public onlyOwner {
        SafeTransferLib.safeTransferETH(recipient, address(this).balance);
    }

    function updateMerkleRoot(bytes32 newMerkleRoot) public onlyOwner {
        _merkleRoot = newMerkleRoot;
    }

    function setBaseURI(string calldata baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function updateCID(string calldata newCID) public onlyOwner {
        _ipfsCID = newCID;
    }

    function flipOpen() public onlyOwner {
        isOpened = !isOpened;
    }

    /// @notice Mints "core" tokens, 10 per drop, until all 5 drops are done
    function coreMint(address recipient, string calldata newCID, bytes32 newMerkleRoot) public onlyOwner {
        uint256 dropId = _dropId++;
        require(dropId < 6, "Core tokens exhausted");
        if (dropId < 5) {
            _leftBlanks[dropId] = 2000;
            isOpened = false;
            _ipfsCID = newCID;
            _merkleRoot = newMerkleRoot;
            for(uint256 i = 10*dropId; i < 10*dropId + 10; i++) {
                _safeMint(recipient, i);
            }
        } else {
            _safeMint(recipient, 10*dropId);
        }                
    }

    function _internalMint(uint256 dropId, address recipient, uint256 quantity) internal {
        uint256 start = (dropId+1) * _SEPARATOR + (_SEPARATOR - _leftBlanks[dropId]);
        for(uint256 i = 0; i < quantity; i++) {
            _safeMint(recipient, start+i);
        }
        _leftBlanks[dropId] -= quantity;
    }

    /// @notice Merkle tree members can buy before everyone else
    /// @dev Users can buy it as soon as data is available, not according to isOpened
    function merkleMint(uint256 dropId, uint256 quantity, uint256 index, bytes32[] calldata proof) public payable {
        require(!_claimed[_merkleRoot].get(index),"Claimed already");
        require(quantity <= _MINT_LIMIT, "Limit of 5 per tx");
        require(quantity * PRICE == msg.value, "Incorrect eth amount");
        bytes32 node = keccak256(abi.encodePacked(msg.sender, index));
        require(MerkleProof.verify(proof, _merkleRoot, node), "Invalid proof");
        _claimed[_merkleRoot].set(index);
        _internalMint(dropId, msg.sender, quantity);
    }

    /// @notice Public minting of the blanks
    function publicMint(uint256 dropId, uint256 quantity) public payable {
        require(isOpened, "Closed");
        require(quantity * PRICE == msg.value, "Incorrect eth amount");
        require(quantity <= _MINT_LIMIT, "Limit of 5 per tx");
        _internalMint(dropId, msg.sender, quantity);
    }

    function tokenURI(uint256 tokenId) public override view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (tokenId < 51) {
            return string(abi.encodePacked(_baseTokenURI, _ipfsCID, "/", tokenId.toString()));
        } else {
            uint256 blankId = (tokenId / _SEPARATOR) * _SEPARATOR; // produce 2000 | 4000 | ... | 10000
            return string(abi.encodePacked(_baseTokenURI, _ipfsCID, "/", blankId.toString()));
        }
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId), "caller is not owner nor approved");
        _burn(tokenId);
    }

}