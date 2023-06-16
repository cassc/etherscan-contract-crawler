// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @title  - Emoji Drip by Christian Rex van Minnen
/// @author - ediv === Chain/Saw

/**                                                                                      
 * 
 *                                                             
 *  ______                         _     _____         _        
 * (______)                     _ (_)   (_____)  _    (_)       
 * (_)__     __   __    ___    (_) _    (_)  (_)(_)__  _  ____  
 * (____)   (__)_(__)  (___)    _ (_)   (_)  (_)(____)(_)(____) 
 * (_)____ (_) (_) (_)(_)_(_)  (_)(_)   (_)__(_)(_)   (_)(_)_(_)
 * (______)(_) (_) (_) (___)_  (_)(_)   (_____) (_)   (_)(____) 
 *                         ( )_(_)                       (_)    
 *                          (___)                        (_)    
 *                                                        
 *                        Christian Rex van Minnen x Chain/Saw                  
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error PoapsAlreadyDropped();
error Unauthorized();
error InvalidClaim();
error AlreadyClaimed();
error ClaimablesPaused();

contract EmojiDrip is ERC721, Ownable {    

    bool public claimablesPaused = false;
    bytes32 public _merkleRoot;    
    uint256 private _nextTokenId = 0;
    string public _baseTokenURI = "ipfs://";
    string public _metadataCID;
    mapping(address => bool) public _claimed;
    event AirdropClaimed(address who, uint256 tokenId);    

    constructor(
      string memory metadataCID, 
      bytes32 merkleRoot
    ) ERC721("Emoji Drip", "EMJDRP") {        
        _metadataCID = metadataCID;        
        _merkleRoot = merkleRoot;
    }

    function setMerkleRoot(bytes32 merkleRoot) public onlyOwner {
        _merkleRoot = merkleRoot;
    }

    function setMetadataCID(string memory metadataCID) public onlyOwner {
        _metadataCID = metadataCID;
    }
  
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {        
      return string(abi.encodePacked(_baseTokenURI, _metadataCID));
    }

    function toggleClaimables() external onlyOwner {
        claimablesPaused = !claimablesPaused;
    }

    function claim(address to, bytes32[] calldata proof) external {
        if (claimablesPaused) revert ClaimablesPaused();
        if (_claimed[msg.sender]) revert AlreadyClaimed();        
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(proof, _merkleRoot, sender))
            revert InvalidClaim();
        uint256 tokenId = _nextTokenId++;        
        _mint(to, tokenId);
        _claimed[msg.sender] = true;
        emit AirdropClaimed(to, tokenId);
    }    
}