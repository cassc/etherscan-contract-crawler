// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Storage is Ownable {    
    mapping (string => string) public kitUser;
    mapping (string => bytes32[]) public kitHashes;
    
    event RegisterUserKitEvent(string indexed kitID, string indexed userID);
    event AddHashToKitEvent(string indexed kitID, bytes32 indexed hash);
    event DeleteHashEvent(string indexed kitID, bytes32 indexed hash);
    
    function registerUserKit(string calldata kitID, string calldata userID) external onlyOwner {
        kitUser[kitID] = userID;
        emit RegisterUserKitEvent(kitID, userID);
    }
    
    function addDocumentHashes(string calldata kitID, bytes32[] calldata hashes) external onlyOwner {
        for (uint i = 0; i < hashes.length; i++) {
            kitHashes[kitID].push(hashes[i]);
            emit AddHashToKitEvent(kitID, hashes[i]);
        }
    }
    
    function addDocumentHash(string calldata kitID, bytes32 hash) external onlyOwner {
        kitHashes[kitID].push(hash);
        emit AddHashToKitEvent(kitID, hash);
    }
    
    function deleteDocumentHash(string calldata kitID, bytes32  hash, uint index) external onlyOwner {
        uint length = kitHashes[kitID].length;

        if(hash == kitHashes[kitID][index]){
            delete kitHashes[kitID][index];
            kitHashes[kitID][index] = kitHashes[kitID][length - 1];
            delete kitHashes[kitID][length - 1];
            kitHashes[kitID].pop();
            emit DeleteHashEvent(kitID, hash);
        }
    }
}