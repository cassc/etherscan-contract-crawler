// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {ERC721 as ERC721S} from "@rari-capital/solmate/src/tokens/ERC721.sol";
import "@rari-capital/solmate/src/auth/Auth.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC2981V2.sol";

//                                                   
//                                                   
//                                  XXXXXXX          
//                               X XXXX XXXXXX       
//                             XXSXSXXXXXX XXXXX     
//                             XXXXX XX  XXXXXSXX    
//                           XXXX  XXXS SSXX XXXX    
//                           XXX XXXX     XXXXXX X   
//                          XXXXXXX X      XXX XXX  
//                          XXXXXXXX       XXXXXXX   
//                           SXX XXXXX    XXXSXXSX   
//                           XXXXXXXXX XXXXXXXXXX    
//                          SXXX X XX XXXXXX XXX  
//                       XXXXXX X XXX X X XSXX   
//                      SXXXXX X XXSXXXXS XX     
//                    XSXSX  XXXXXX            
//                   SXXX XXX XXXXX                  
//                 XXXXX SXXXXXX                     
//                SXXS  X XXXXX                      
//              XXXXXX X XSX X                       
//            XSXXX XX XXXXX                         
//          XXSXSSX XXXXXX                        
//        XSXXXSXXXXXXXXX                       
//        XXXXX XXXXXX   

/// @title The Quantum Key Ring. The keys do something.
/// @author exp.table
contract QuantumKeyRing is ERC721S, ERC2981, Auth {
    using Strings for uint256;
    using BitMaps for BitMaps.BitMap;

    /// >>>>>>>>>>>>>>>>>>>>>>>  STATE  <<<<<<<<<<<<<<<<<<<<<<<<<< ///

    mapping (uint256 => string) public keyCID;
    mapping (uint256 => uint256) public keySupply;
    mapping (uint256 => uint256) public tokenIdToSkinId;

    uint private constant _SEPARATOR = 10**4;
    string private _baseURI = "ipfs://";
    address private _minter;

    /// >>>>>>>>>>>>>>>>>>>>>  CONSTRUCTOR  <<<<<<<<<<<<<<<<<<<<<< ///

	/// @notice Deploys QuantumKeyRing
    /// @dev Initiates the Auth module with no authority and the sender as the owner
    /// @param owner The owner of the contract
    /// @param authority address of the deployed authority
    constructor(address owner, address authority) ERC721S("QuantumKeyRing", "QKR") Auth(owner, Authority(authority)) {
        _baseURI = "ipfs://";
    }

    /// >>>>>>>>>>>>>>>>>>>>>  RESTRICTED  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice set address of the minter
    /// @param minter The address of the minter - should be QuantumKeyMaker
    function setMinter(address minter) public requiresAuth {
        _minter = minter;
    }

    /// @notice set the baseURI
    /// @param baseURI new base
    function setBaseURI(string calldata baseURI) public requiresAuth {
        _baseURI = baseURI;
    }

    /// @notice set the IPFS CID
    /// @param keyId The key id
    /// @param cid cid
    function setCID(uint256 keyId, string calldata cid) public requiresAuth {
        keyCID[keyId] = cid;
    }

    /// @notice sets the recipient of the royalties
    /// @param recipient address of the recipient
    function setRoyaltyRecipient(address recipient) public requiresAuth {
        _royaltyRecipient = recipient;
    }

    /// @notice sets the fee of royalties
    /// @dev The fee denominator is 10000 in BPS.
    /// @param fee fee
    /*
        Example

        This would set the fee at 5%
        ```
        keyRing.setRoyaltyFee(500)
        ```
    */
    function setRoyaltyFee(uint256 fee) public requiresAuth {
        _royaltyFee = fee;
    }

    /// >>>>>>>>>>>>>>>>>>>>>  VIEW  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice Returns the URI of the token
    /// @param tokenId id of the token
    /// @return URI for the token ; expected to be ipfs://<cid>
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        uint256 keyId = tokenId / _SEPARATOR;
        return string(abi.encodePacked(_baseURI, keyCID[keyId], "/" , tokenIdToSkinId[tokenId].toString()));
    }

    /// >>>>>>>>>>>>>>>>>>>>>  EXTERNAL  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice Mints new keys
    /// @dev there is no check regarding limiting supply
    /// @param to recipient of newly minted tokens
    /// @param keyId id of the key
    /// @param amount amount to mint
    function make(address to, uint256 keyId, uint256 amount) public {
        require(msg.sender == owner || msg.sender == _minter, "NOT_AUTHORIZED");
        uint256 currSupply = keySupply[keyId];
        for(uint i; i < amount; i++) {
            _safeMint(to, (keyId * _SEPARATOR) +  currSupply + i);
        }
        keySupply[keyId] += amount;

    }

    /// @notice Burns key
    /// @dev Can be called by the owner or approved operator
    /// @param tokenId id of the tokens
    function burn(uint256 tokenId) public {
        address owner = ownerOf[tokenId];
        require(
            msg.sender == owner || msg.sender == getApproved[tokenId] || isApprovedForAll[owner][msg.sender],
            "NOT_AUTHORIZED"
        );
        _burn(tokenId);
    }

    /// @notice Applies a skin to a key
    /// @param tokenId id of the key
    /// @param skinId index of the skin
    function applySkin(uint256 tokenId, uint256 skinId) public {
        require(ownerOf[tokenId] == msg.sender, "NOT_OWNER");
        require(skinId > tokenIdToSkinId[tokenId], "CANT_REVERT");
        tokenIdToSkinId[tokenId] = skinId;
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual override(ERC721S, ERC2981) returns (bool) {
        return ERC721S.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}