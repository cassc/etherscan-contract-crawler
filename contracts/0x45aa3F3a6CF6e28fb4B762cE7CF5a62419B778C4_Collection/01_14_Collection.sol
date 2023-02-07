// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./utils/Base64.sol";

import "./CollectionDescriptor.sol";

/*
                                                                    
                  ████    ████        ████    ██████                
                  ████    ████        ████    ██████                
                      ████████████████████████                      
                      ████████████████████████                      
          ██▓▓    ██▓▓████░░░░░░░░░░░░░░░░████▓▓████    ████        
          ██▓▓    ████████░░░░░░░░░░░░░░  ██████████    ████        
          ░░░░▓▓▓▓░░░░░░░░░░░░▓▓▓▓▓▓▓▓░░░░░░░░░░░░▒▒▓▓▓▓░░          
        ░░░░░░████░░░░░░░░░░░░▓▓▓▓▓▓██░░░░░░░░░░░░░░████░░░░░░      
  ████  ░░██▓▓░░░░░░░░    ████░░  ████████    ░░  ░░░░░░████░░  ████
  ████    ██▓▓░░░░░░░░    ██▓▓░░  ████▓▓██    ░░  ░░░░░░████░░  ████
      ████░░░░    ░░  ░░░░██▓▓████████▓▓▓▓░░░░░░  ░░░░  ░░░░████    
      ████░░              ██▓▓████████▓▓██              ░░░░████    
        ░░▓▓▒▒              ░░▓▓▓▓▓▓██                  ████        
          ██▓▓                ▓▓▓▓▓▓██                  ████        
            ░░████                                  ████            
              ████                                  ████            
                  ████████  ░░░░░░░░░░░░░░██████████                
                  ████████░░░░░░░░░░░░░░  ██████████                
                          ████████████████                          
                          ████████████████                          

"Witness The Draft" is an art experiment combining provenance, on-chain dynamic social artwork, and a look into the documentation of the creative process.

In November 2022, I (Simon de la Rouviere) wrote a draft of a novel, called "Witnesses of Gridlock", a sequel to "Hope Runners of Gridlock".
In 30 days, I wrote 51,591 words of the draft.
As part of National Novel Writing Month (NaNoWriMo), for each day of writing, I inserted a daily log of the day's writing into a smart contract (Witness.sol).
You can find Witness.sol here: https://etherscan.io/address/0xfde89d4b870e05187dc9bbfe740686798724f614
Thus, for 30 days, there are 30 inscriptions containing the timestamp, day_nr, the total word count, and a sentence taken from the day's writing.

The NFTs:
The "Witness The Draft" project consumes these 30 days of logs on-chain, directly into a set of 30 dynamic on-chain artworks.

Each of the 30 pieces consists of 2 parts:
Its eyes and the daily log.

Each piece contains eyes in 5x6 grid with one eye open (at the start).
This initial open eye is different from the other eyes (a radiating pupil) and is located in the grid corresponding to the day.
The grid goes as follow in terms of days:
1 2 3 4 5
6 7 8 9 10
11 12 etc ....
The colour of the eyes and the positions of the pupils are all algorithmically generated from seeds that was chosen by me (the artist).

Witnessing:

This work contains a novel social mechanic where an owner can witness other pieces in the collection.
When one witnesses another piece, their piece will open an eye at the index of your piece.
eg, if you hold day 5 and you witness day 7, the 5th eye will open up in the day 7 piece.
In different terms: if you want an eye on your piece to open up (eg, eye #24), you have to ask the owner of that piece (#24) to witness your piece.
Each owner can witness all pieces, including closing the special eye of their own piece (closing your own, special eye does not change its look).
Each owner can also choose to close an eye on other pieces, a process called "unsee".
This opening and closing of eyes can be repeated ad-infinitum.
Transfers do not reset witnesses.

This project was inspired by:
- The Mesh from Takens Theorem, where one's NFT changes depending what NFTs you and other owners hold in the collection.
- Conversations with Mackenzie Davenport and his project, Ensemble, that helps surface the objects used in the creative process.

Where applicable: The art is licensed under CC BY-SA 4.0.
*/


/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract Collection is ERC721 {

    address public owner; //= 0xaF69610ea9ddc95883f97a6a3171d52165b69B03;

    CollectionDescriptor public descriptor;

    // piece => witnesses_to_piece_from_other_pieces 
    mapping (uint => bool[30]) public witnesses;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_, address _witnessAddress) ERC721(name_, symbol_) {
        descriptor = new CollectionDescriptor(_witnessAddress);
        owner = msg.sender;

        // mint 30 pieces
        // seeds are stored in the descriptor
        for(uint i = 0; i<30; i+=1) {
            super._mint(owner, i);
            witnesses[i][i] = true; // own eye is open from start
        }
    }

    // change descriptor
    // only allowed by admin/owner until Jun 01 2023.
    // this is to fix potential issues or upgrade.
    // After Jun 01 2023, it's not possible anymore.
    function changeDescriptor(address _newDescriptor) public {
        require(msg.sender == owner, 'not owner');
        require(block.timestamp < 1685592000, 'cant change descriptor anymore'); // Thu Jun 01 2023 04:00:00 GMT+0000
        descriptor = CollectionDescriptor(_newDescriptor);
    }

    // Note: Out-of-bound calls are possible, but the tx will just normally fail.

    function witnessById(uint toID, uint fromID) public {
        _witness(toID, fromID);
    }

    /* a helper function if id is confusing */
    function witnessByDay(uint toDay, uint fromDay) public {
        _witness(toDay-1, fromDay-1);
    }

    function _witness(uint toID, uint fromID) internal {
        require(msg.sender == ownerOf(fromID), 'not authorised to witness');
        require(witnesses[toID][fromID] == false, 'already witnessed that piece'); // not entirely necessary but saves someone from making a tx
        witnesses[toID][fromID] = true;
    }

    function unseeById(uint toID, uint fromID) public {
        _unsee(toID, fromID);
    }

    function unseeByDay(uint toDay, uint fromDay) public {
        _unsee(toDay-1, fromDay-1);
    }

    function _unsee(uint toID, uint fromID) internal {
        require(msg.sender == ownerOf(fromID), 'not authorised to unsee');
        require(witnesses[toID][fromID] == true, 'eyes already closed'); // not entirely necessary but saves someone from making a tx
        witnesses[toID][fromID] = false;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory name = descriptor.generateName(tokenId); 
        string memory description = descriptor.generateDescription();

        string memory image = generateBase64Image(tokenId);
        string memory attributes = generateTraits(tokenId);
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"', 
                            name,
                            '", "description":"', 
                            description,
                            '", "image": "', 
                            'data:image/svg+xml;base64,', 
                            image,'",',
                            attributes,
                            '}'
                        )
                    )
                )
            )
        );
    }

    function generateBase64Image(uint256 tokenId) public view returns (string memory) {
        bytes memory img = bytes(generateImage(tokenId));
        return Base64.encode(img);
    }

    function generateImage(uint256 tokenId) public view returns (string memory) {
        // also send along witness data
        bool[30] memory wit = witnesses[tokenId];
        return descriptor.generateImage(tokenId, wit);
    }

    function generateTraits(uint256 tokenId) public view returns (string memory) {
        return descriptor.generateTraits(tokenId);
    }

}