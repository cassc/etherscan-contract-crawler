// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @title  - CONIUNCTIO by Christian Rex van Minnen
/// @author - ediv === Chain/Saw

/**                                                                                      
 *              :                                                                          :     
 *       .,    t#,     L.                 :      L.                   .,                  t#,    
 *      ,Wt   ;##W.    EW:        ,ft t   Ef     EW:        ,ft      ,Wt          t      ;##W.   
 *     i#D.  :#L:WE    E##;       t#E Ej  E#t    E##;       t#E     i#D. GEEEEEEELEj    :#L:WE   
 *    f#f   .KG  ,#D   E###t      t#E E#, E#t    E###t      t#E    f#f   ,;;L#K;;.E#,  .KG  ,#D  
 *  .D#i    EE    ;#f  E#fE#f     t#E E#t E#t    E#fE#f     t#E  .D#i       t#E   E#t  EE    ;#f 
 * :KW,    f#.     t#i E#t D#G    t#E E#t E#t fi E#t D#G    t#E :KW,        t#E   E#t f#.     t#i
 * t#f     :#G     GK  E#t  f#E.  t#E E#t E#t L#jE#t  f#E.  t#E t#f         t#E   E#t :#G     GK 
 *  ;#G     ;#L   LW.  E#t   t#K: t#E E#t E#t L#LE#t   t#K: t#E  ;#G        t#E   E#t  ;#L   LW. 
 *   :KE.    t#f f#:   E#t    ;#W,t#E E#t E#tf#E:E#t    ;#W,t#E   :KE.      t#E   E#t   t#f f#:  
 *    .DW:    f#D#;    E#t     :K#D#E E#t E###f  E#t     :K#D#E    .DW:     t#E   E#t    f#D#;   
 *      L#,    G#t     E#t      .E##E E#t E#K,   E#t      .E##E      L#,    t#E   E#t     G#t    
 *       jt     t      ..         G#E E#t EL     ..         G#E       jt     fE   E#t      t     
 *                                 fE ,;. :                  fE               :   ,;.            
 *                                  ,                         ,                  
 *                                                        
 *                                                      Christian Rex van Minnen x Chain/Saw                  
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error PoapsAlreadyDropped();
error Unauthorized();
error InvalidClaim();
error AlreadyClaimed();
error ClaimablesPaused();

contract Coniunctio is ERC721, Ownable, ReentrancyGuard {    

    bool public claimablesPaused = true;
    bytes32 public _merkleRoot;
    bool public _poapsDropped = false;
    uint256 private _nextTokenId = 351;
    IERC721 public _minionAddress;
    
    address[] public _poapAddresses;
    string public _baseTokenURI = "ipfs://";
    string public _metadataCID;

    mapping(address => bool) public _blankClaimed;

    event AirdropClaimed(address who, uint256 tokenId);
    event GagaClaimed(address who, uint256 tokenId);

    constructor(
        string memory metadataCID, 
        IERC721 minionAddress,
        bytes32 merkleRoot
    ) ERC721("Coniunctio", "CONI") {
        _minionAddress = minionAddress;
        _metadataCID = metadataCID;        
        _merkleRoot = merkleRoot;
    }

    function setMerkleRoot(bytes32 merkleRoot) public onlyOwner {
        _merkleRoot = merkleRoot;
    }
    
    function executePoapDrop(address[] calldata poapAddresses) external onlyOwner {        
        if (_poapsDropped) revert PoapsAlreadyDropped();        
        uint256 currTokenId = 51;
        for (uint16 i = 0; i < poapAddresses.length; i++) {            
            _mint(poapAddresses[i], currTokenId++);
        }        
        _poapsDropped = true;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");        
        if (tokenId <= 50) {
            return string(abi.encodePacked(_baseTokenURI, _metadataCID, "/", "gaga"));
        }
        if (tokenId <= 351) {
            return string(abi.encodePacked(_baseTokenURI, _metadataCID, "/", "poap"));
        }    
        return string(abi.encodePacked(_baseTokenURI, _metadataCID, "/", "airdrop"));
    }

    function toggleClaimables() external onlyOwner {
        claimablesPaused = !claimablesPaused;
    }

    function genesisClaim(address to, uint256 tokenId) external nonReentrant {
        if (claimablesPaused) revert ClaimablesPaused();
        if (tokenId > 50 || _exists(tokenId) || _minionAddress.ownerOf(tokenId) != msg.sender) 
            revert InvalidClaim();
        _mint(to, tokenId);
        emit GagaClaimed(to, tokenId);
    }

    function blankClaim(address to, bytes32[] calldata proof) external {
        if (claimablesPaused) revert ClaimablesPaused();
        if (_blankClaimed[msg.sender]) revert AlreadyClaimed();        
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(proof, _merkleRoot, sender))
            revert InvalidClaim();
        uint256 tokenId = _nextTokenId++;        
        _mint(to, tokenId);
        _blankClaimed[msg.sender] = true;
        emit AirdropClaimed(to, tokenId);
    }

    function tokenMinted(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }
}