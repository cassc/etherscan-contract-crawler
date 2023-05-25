// SPDX-License-Identifier: MIT

/**
*   @title A LIT Invitation To Kindness
*   @author Transient Labs, Copyright (C) 2022
*   @notice ERC 1155 contract, single owner, merkle claim
*   @dev includes the public parameter `name` so it works with OS
*/

/*
             (      (                 (                                                                                          )                                                
   (         )\ )   )\ )    *   )     )\ )                           )             )                         *   )            ( /(                 (                              
   )\       (()/(  (()/(  ` )  /(    (()/(             )     (    ( /(      )   ( /(   (                   ` )  /(            )\())  (             )\ )             (             
((((_)(      /(_))  /(_))  ( )(_))    /(_))   (       /((    )\   )\())  ( /(   )\())  )\    (     (        ( )(_))   (     |((_)\   )\    (      (()/(    (       ))\   (    (   
 )\ _ )\    (_))   (_))   (_(_())    (_))     )\ )   (_))\  ((_) (_))/   )(_)) (_))/  ((_)   )\    )\ )    (_(_())    )\    |_ ((_) ((_)   )\ )    ((_))   )\ )   /((_)  )\   )\  
 (_)_\(_)   | |    |_ _|  |_   _|    |_ _|   _(_/(   _)((_)  (_) | |_   ((_)_  | |_    (_)  ((_)  _(_/(    |_   _|   ((_)   | |/ /   (_)  _(_/(    _| |   _(_/(  (_))   ((_) ((_) 
  / _ \     | |__   | |     | |       | |   | ' \))  \ V /   | | |  _|  / _` | |  _|   | | / _ \ | ' \))     | |    / _ \     ' <    | | | ' \)) / _` |  | ' \)) / -_)  (_-< (_-< 
 /_/ \_\    |____| |___|    |_|      |___|  |_||_|    \_/    |_|  \__|  \__,_|  \__|   |_| \___/ |_||_|      |_|    \___/    _|\_\   |_| |_||_|  \__,_|  |_||_|  \___|  /__/ /__/ 
                                                                                                                                                                                  
   ___                            __  ___         ______                  _          __    __        __     
  / _ \___ _    _____ _______ ___/ / / _ )__ __  /_  __/______ ____  ___ (_)__ ___  / /_  / /  ___ _/ /  ___
 / ___/ _ \ |/|/ / -_) __/ -_) _  / / _  / // /   / / / __/ _ `/ _ \(_-</ / -_) _ \/ __/ / /__/ _ `/ _ \(_-<
/_/   \___/__,__/\__/_/  \__/\_,_/ /____/\_, /   /_/ /_/  \_,_/_//_/___/_/\__/_//_/\__/ /____/\_,_/_.__/___/
                                        /___/                                                               
*/

pragma solidity ^0.8.0;

import "ERC1155.sol";
import "Ownable.sol";
import "Strings.sol";
import "MerkleProof.sol";
import "EIP2981.sol";

contract InvitationToKindness is ERC1155, EIP2981, Ownable {
    using Strings for uint256;

    bytes32 private litRiderMerkleRoot;
    bytes32 private rareRiderMerkleRoot;

    uint256 constant LIT_RIDER = 0;
    uint256 constant LIT_PAMP = 1;
    uint256 constant LIT_CDM = 2;

    mapping(address => bool) private hasMinted;
    bool public claimOpen;
    uint256[] private availableRareRiderIds;
    uint256[] private rareRiderSupply;

    string public name = "A LIT Invitation to Kindness";

    constructor(bytes32 _litRiderMerkleRoot, bytes32 _rareRiderMerkleRoot, address _royaltyRecipient, uint256 _royaltyAmount) EIP2981(_royaltyRecipient, _royaltyAmount) ERC1155("") Ownable() {
        availableRareRiderIds = [LIT_PAMP, LIT_CDM];
        rareRiderSupply = [334, 30];

        litRiderMerkleRoot = _litRiderMerkleRoot;
        rareRiderMerkleRoot = _rareRiderMerkleRoot;
    }

    /**
    *   @notice overrides supportsInterface function
    *   @param _interfaceId is supplied from anyone/contract calling this function, as defined in ERC 165
    *   @return a boolean saying if this contract supports the interface or not
    */
    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC1155, EIP2981) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    /**
    *   @notice function to update allowlist merkle root if needed
    *   @dev requires owner
    *   @param _litRiderRoot is the new lit rider merkle root
    *   @param _rareRiderRoot is the new rare rider merkle root*/
    function updateAllowlistRoots(bytes32 _litRiderRoot, bytes32 _rareRiderRoot) public onlyOwner {
        litRiderMerkleRoot = _litRiderRoot;
        rareRiderMerkleRoot = _rareRiderRoot;
    }

    /**
    *   @notice sets the baseURI for the tokens
    *   @dev requires owner
    *   @param _uri is the base URI set for each token
    */
    function setBaseURI(string memory _uri) public onlyOwner {
        _setURI(_uri);
    }

    /**
    *   @notice function to change the royalty recipient
    *   @dev requires owner
    *   @dev this is useful if an account gets compromised or anything like that
    *   @param _newRecipient is the new royalty recipient
    */
    function changeRoyaltyRecipient(address _newRecipient) public onlyOwner {
        require(_newRecipient != address(0), "Error: new recipient is the zero address");
        royaltyAddr = _newRecipient;
    }

    /**
    *   @notice function to change the royalty percentage
    *   @dev requires owner
    *   @dev this is useful if the amount was set improperly at contract creation. This can in fact happen... humans are prone to mistakes :) 
    *   @param _newPerc is the new royalty percentage, in basis points (out of 10,000)
    */
    function changeRoyaltyPercentage(uint256 _newPerc) public onlyOwner {
        require(_newPerc <= 10000, "Error: new percentage is greater than 10,0000");
        royaltyPerc = _newPerc;
    }

    /**
    *   @notice getter function for if an address has minted
    *   @param _address is the address to check
    *   @return boolean
    */
    function getHasMinted(address _address) public returns (bool){
        return hasMinted[_address];
    }

    /**
    *   @notice function to return uri for a specific token type
    *   @param _tokenId is the uint256 representation of a token ID
    *   @return string representing the uri for the token id
    */
    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_tokenId == LIT_RIDER || _tokenId == LIT_CDM || _tokenId == LIT_PAMP, "Error: non-existent token id");
        return string(abi.encodePacked(ERC1155.uri(_tokenId), _tokenId.toString()));
    }

    /**
    *   @notice function to set the claim status
    *   @dev requires owner
    *   @param _status is the status to set the claim to
    */
    function setClaimStatus(bool _status) public onlyOwner {
        claimOpen = _status;
    }

    /**
    *   @notice function for minting riders
    *   @dev requires owner
    *   @param _litRiderMerkleProof is the proof for lit riders
    *   @param _rareRiderMerkleProof is the proof for rare riders
    */
    function mint(bytes32[] calldata _litRiderMerkleProof, bytes32[] calldata _rareRiderMerkleProof) public {
        require(claimOpen, "Error: claim not open");
        require(!hasMinted[msg.sender], "Error: already claimed");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        bool isLitRider = MerkleProof.verify(_litRiderMerkleProof, litRiderMerkleRoot, leaf);
        require(isLitRider, "Error: not on the allowlist for the claim");
        bool isRareRider = MerkleProof.verify(_rareRiderMerkleProof, rareRiderMerkleRoot, leaf);
        if (isRareRider && availableRareRiderIds.length != 0) {
            _mint(msg.sender, LIT_RIDER, 1, "");
            uint256 rider = _getRandomNum(availableRareRiderIds.length);
            _mint(msg.sender, availableRareRiderIds[rider], 1, "");

            rareRiderSupply[rider]--;
            if (rareRiderSupply[rider] == 0) {
                availableRareRiderIds[rider] = availableRareRiderIds[availableRareRiderIds.length - 1];
                availableRareRiderIds.pop();
                rareRiderSupply[rider] = rareRiderSupply[rareRiderSupply.length - 1];
                rareRiderSupply.pop();
            }
        }
        else {
            _mint(msg.sender, LIT_RIDER, 2, "");
        }
        hasMinted[msg.sender] = true;
    }

    /**
    *   @notice function for minting specific rider to address
    *   @dev only owner
    *   @dev only used as backup
    *   @param _tokenId is the token id to mint
    *   @param _address is the address to mint to
    */
    function adminMint(address _address, uint256 _tokenId) public onlyOwner {
        require(_tokenId == LIT_RIDER || _tokenId == LIT_CDM || _tokenId == LIT_PAMP, "Error: invalid token id");

        _mint(_address, _tokenId, 1, "");
    }

    /**
    *   @dev Generates a pseudo-random number
    *   @param _upper is a uint256 meant to be the upper bound of the random number generation
    */
    function _getRandomNum(uint256 _upper) private view returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.coinbase, block.difficulty, msg.sender)));

        return random % _upper;
    }
}