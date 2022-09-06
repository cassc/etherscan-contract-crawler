//SPDX-License-Identifier: Unlicense
/*
  ___  _  _  ____  ____  __   _  _  .    .  *           .  
 / __)/ )( \/ ___)(_  _)/  \ ( \/ )  .   *  .       *       
( (__ ) \/ (\___ \  )( (  O )/ \/ \      .      .*      
 \___)\____/(____/ (__) \__/ \_)(_/    .    *     *                
 _  _   __  __  ___  ____       .     .     .         .        
/ )( \ /  \(  )/ __)(  __)  .     *        .    *    
\ \/ /(  O ))(( (__  ) _)       *     .       .     . 
 \__/  \__/(__)\___)(____)    .    *     *              
 ____  ____  ____  ____  __ _   ___  ____             *
(  __)/ ___)/ ___)(  __)(  ( \ / __)(  __)   *     .
 ) _) \___ \\___ \ ) _) /    /( (__  ) _) .     *.    .
(____)(____/(____/(____)\_)__) \___)(____)  .        .  

*/

pragma solidity ^0.8.15;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract CustomVoiceNFT is ERC721A, Ownable {
    using ECDSA for bytes32;

    address public ownerAddr;
    address private systemAddress;
    string public baseTokenURI;

    bool public isMintLive;

    mapping(string => bool) public usedNonces;
    mapping(uint256 => string) public customUrl;
    mapping(address => bool) public allowList;

    event MintLiveLog(bool live);
    event MintLog(address indexed to, uint256 indexed tokenId);

    constructor(string memory _baseTokenURI, address _systemAddress)
        ERC721A("Custom Voice Essence", "CVE")
    {
        ownerAddr = msg.sender;
        baseTokenURI = _baseTokenURI;
        systemAddress = _systemAddress;
    }

    modifier checkSignature(
        string memory _cid,
        string memory _customNonce,
        bytes32 _hash,
        bytes memory _signature
    ) {
        require(matchSigner(_hash, _signature), "Mint through website");
        require(!usedNonces[_customNonce], "Hash reused");
        require(
            hashTransaction(msg.sender, _cid, _customNonce) == _hash,
            "Hash failed"
        );
        _;
    }

    function publicMint(
        string memory _cid,
        string memory _customNonce,
        bytes32 _hash,
        bytes memory _signature
    ) external checkSignature(_cid, _customNonce, _hash, _signature) {
        require(isMintLive, "Not live");
        if (msg.sender != tx.origin) {
            //prevent bots
            require(allowList[msg.sender], "Contract not allowed");
        }

        usedNonces[_customNonce] = true;
        // start minting
        customUrl[_nextTokenId()] = _cid;
        emit MintLog(msg.sender, _nextTokenId());
        _mint(msg.sender, 1);
    }

    //=============================================================
    //  auth
    //=============================================================
    function matchSigner(bytes32 hash, bytes memory signature)
        private
        view
        returns (bool)
    {
        return
            systemAddress == hash.toEthSignedMessageHash().recover(signature);
    }

    function hashTransaction(
        address sender,
        string memory cid,
        string memory customNonce
    ) private view returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(sender, address(this), cid, customNonce)
        );

        return hash;
    }

    //=============================================================
    //  operation
    //=============================================================

    function toggleMintLive() external onlyOwner {
        bool isLive = !isMintLive;
        isMintLive = isLive;
        emit MintLiveLog(isMintLive);
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseTokenURI = _baseURI;
    }

    function setCid(uint256 _tokenId, string memory _cid) external onlyOwner {
        customUrl[_tokenId] = _cid;
    }

    function setSystemAddress(address _systemAddress) external onlyOwner {
        systemAddress = _systemAddress;
    }

    function addAllowList(address _address_CA, bool _isAllowed)
        external
        onlyOwner
    {
        allowList[_address_CA] = _isAllowed;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory end = bytes(baseTokenURI).length != 0
            ? string(abi.encodePacked(baseTokenURI, customUrl[tokenId]))
            : "";
        return end;
    }

    //=============================================================
    //  utility
    //=============================================================

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 holdingAmount = balanceOf(owner);
        uint256 tokenIdsIdx;
        address currOwnershipAddr;

        uint256[] memory list = new uint256[](holdingAmount);

        unchecked {
            for (uint256 i; i < _totalMinted(); i++) {
                TokenOwnership memory ownership = _ownershipAt(i);

                if (ownership.burned) {
                    continue;
                }

                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }

                if (currOwnershipAddr == owner) {
                    list[tokenIdsIdx++] = i;
                }

                if (tokenIdsIdx == holdingAmount) {
                    break;
                }
            }
        }

        return list;
    }
    
}