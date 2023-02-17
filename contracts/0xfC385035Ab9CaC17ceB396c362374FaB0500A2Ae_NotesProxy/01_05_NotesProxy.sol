// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract NotesProxy is OwnableUpgradeable {

  string public constant FILE_NAME_METADATA_KEY = "fileName";
  string public constant IDENTITY_METADATA_KEY  = "identity";

  struct NoteStruct {
      bytes32 hash;
      uint8 hashFunction;
      uint8 size;

      uint insertionDate;

      mapping(string => string) mData;
   }

   mapping (uint => NoteStruct) public notes;
   uint8 public noteCount;


  function initialize(address ownerAddress) public payable initializer {
    //Rather than call __Ownable_init which sets the owner to the sender we will call _transferOwnership directly and specify the owner to the initializer.
    //When deploying the template NotesProxy we can set the owner as the account submitting the transaction
    //When creating a clone from the NotesProxyFactory we will set the owner to the msg.sender explicitly. Otherwise the context would become the proxy factory and the owner would be the contract
    //The end result is that a transacting account can control both the template and the clones it creates
    _transferOwnership(ownerAddress);
  }


  function addNote(bytes32 hash, uint8 hashFunction, uint8 size) onlyOwner public {
      
      NoteStruct storage newNote = notes[noteCount++];
      newNote.hash = hash;
      newNote.hashFunction = hashFunction;
      newNote.size = size;
      newNote.insertionDate = block.timestamp;
  }


  function addNamedNote(bytes32 hash, uint8 hashFunction, uint8 size, string calldata fileName) onlyOwner public {

    addNote(hash, hashFunction, size);
    NoteStruct storage thisNote = notes[noteCount - 1];
    thisNote.mData[FILE_NAME_METADATA_KEY] = fileName;
  }


  function updateMetadata(uint8 nIndex, string memory mKey, string calldata mValue) onlyOwner public {

    NoteStruct storage thisNote = notes[nIndex];
    thisNote.mData[mKey] = mValue;
  }


  function getMetadata(uint8 nIndex, string calldata mKey) public view returns(string memory) {

    NoteStruct storage thisNote = notes[nIndex];
    return thisNote.mData[mKey];
  }
}