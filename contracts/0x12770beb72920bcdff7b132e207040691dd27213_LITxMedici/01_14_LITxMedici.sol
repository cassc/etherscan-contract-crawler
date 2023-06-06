// SPDX-License-Identifier: MIT

/**
*   @title LIT x Medici
*   @author Transient Labs
*   @notice ERC 1155 contract, single owner, merkle claim
*   @dev smart contract and claim mechanics built by Transient Labs.
*/

/**
 (      (                            *                                    
 )\ )   )\ )    *   )              (  `             (                     
(()/(  (()/(  ` )  /(        )     )\))(      (     )\ )   (          (   
 /(_))  /(_))  ( )(_))    ( /(    ((_)()\    ))\   (()/(   )\    (    )\  
(_))   (_))   (_(_())     )\())   (_()((_)  /((_)   ((_)) ((_)   )\  ((_) 
| |    |_ _|  |_   _|    ((_)\    |  \/  | (_))     _| |   (_)  ((_)  (_) 
| |__   | |     | |      \ \ /    | |\/| | / -_)  / _` |   | | / _|   | | 
|____| |___|    |_|      /_\_\    |_|  |_| \___|  \__,_|   |_| \__|   |_| 
                                                                                              
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

contract LITxMedici is ERC1155, EIP2981, Ownable {
    using Strings for uint256;

    bytes32 private immutable merkleRoot;

    uint256 public availableTokenSupply;
    uint256 public tokenSupply;
    bool public mintStatus;

    mapping(address => bool) private hasMinted;

    string public constant name = "Noble Medici";

    constructor(uint256 _tokenSupply, bytes32 _merkleRoot, address _royaltyRecipient, uint256 _royaltyAmount) EIP2981(_royaltyRecipient, _royaltyAmount) ERC1155("") Ownable() {
        tokenSupply = _tokenSupply;
        availableTokenSupply = _tokenSupply;

        merkleRoot = _merkleRoot;
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
    *   @notice function to return totalSupply of a token ID
    *   @param _tokenId is the uint256 identifier of a tokenId
    *   @return uint256 value of supply
    */
    function totalSupply(uint256 _tokenId) public view returns(uint256) {
        require(_tokenId == 0, "Error: query for non-existent token id");
        return tokenSupply;
    }

    /**
    *   @notice function to retrieve user mint status
    *   @param _address is the address to look up
    *   @return boolean with status
    */
    function getHasMinted(address _address) public view returns(bool) {
        return hasMinted[_address];
    }

    /**
    *   @notice function to set the mint status
    *   @dev requires owner
    *   @param _mintStatus is a boolean indicating mint status
    */
    function setMintStatus(bool _mintStatus) public onlyOwner {
        mintStatus = _mintStatus;
    }

    /**s
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
    *   @notice function to return uri for a specific token type
    *   @param _tokenId is the uint256 representation of a token ID
    *   @return string representing the uri for the token id
    */
    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_tokenId == 0, "Error: non-existent token id");
        return string(abi.encodePacked(ERC1155.uri(_tokenId), _tokenId.toString()));
    }

    /**
    *   @notice function for minting piece
    *   @dev requires owner
    *   @param _merkleProof is the proof for whitelist
    */
    function mint(bytes32[] calldata _merkleProof) public {
        require(mintStatus, "Error: mint not open");
        require (availableTokenSupply > 0, "Error: no more tokens left to mint");
        require(!hasMinted[msg.sender], "Error: already minted");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Error: not on whitelist");

        _mint(msg.sender, 0, 1, "");

        hasMinted[msg.sender] = true;
        availableTokenSupply -= 1;
    }

    /**
    *   @notice function for minting to address
    *   @dev only owner
    *   @dev only used as backup
    *   @param _address is the address to mint to
    *   @param _num is the number to mint
    */
    function adminMint(address _address, uint256 _num) public onlyOwner {
        require (availableTokenSupply > 0, "Error: no more tokens left to mint");
        require(_address != address(0), "Error: trying to mint to zero address");

        for (uint256 i = 0; i < _num; i++) {
            _mint(_address, 0, 1, "");
        }

        availableTokenSupply -= _num;
    }

    /**
    *   @notice function to increase mint supply
    *   @dev requires owner
    *   @param _additionalSupply is a uint256 to add to supply levels
    */
    function addSupply(uint256 _additionalSupply) public onlyOwner {
        tokenSupply += _additionalSupply;
        availableTokenSupply += _additionalSupply;
    }
}