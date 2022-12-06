// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

// TIMESTEADER LLC

contract Time is ERC721, IERC2981, Ownable {
    using Strings for uint256;

    uint256 public fee = 1000000000000; // in wei
    uint256 public royaltyPercent = 500;
    uint256 public maxMintLength = 10;
    bool public saleActive = false;

    struct _te {
        bool isActive;
        string uri;
    }

    struct _wladd {
        uint fee;
        uint mintLength;
    }

    struct _wlSet {
        address add;
        uint fee;
        uint mintLength;
    }
    
    mapping(address => _wladd) internal _wl;
    mapping(uint => _te) internal _tes;

    constructor() ERC721("Time", "TIME") {}

    function mintTo (
        address recipient,
        uint256[] calldata kt
    ) public payable
    {
        require(saleActive, "Sale not active");
        require(msg.value >= fee * kt.length, "Insufficient minting fee");
        require(kt.length < maxMintLength, "You're trying to mint too many tokens at once");
        
        for (uint256 i = 0; i < kt.length; i++) {
            require(isTeActive(getTeFromTokenId(kt[i])), "TE not active.");
            _safeMint(recipient, kt[i]);
        }
    }

    function whiteListMint(
        uint256[] calldata kt
    ) public payable 
    {
        require(_wl[msg.sender].mintLength > 0, 
            "Not on whitelist. Or mints exhausted.");
        require(msg.value >= _wl[msg.sender].fee * kt.length, 
            "Insufficient fee");
        require(_wl[msg.sender].mintLength >= kt.length, 
            "You're trying to mint too many tokens at once. Check your whitelist address's mintLength");

        for (uint256 i = 0; i < kt.length; i++) {
            require(isTeActive(getTeFromTokenId(kt[i])), "TE not active.");
            _safeMint(msg.sender, kt[i]);
            _wl[msg.sender].mintLength--;
        }
    }

    function setWhiteList(
        _wlSet[] memory wlSet
    ) public onlyOwner 
    {
        for (uint256 i = 0; i < wlSet.length; i++) {
            address add = wlSet[i].add;
            _wl[add].fee = wlSet[i].fee;
            _wl[add].mintLength = wlSet[i].mintLength;
        }
    }
    
    function getWhiteListAddress(
        address add
    ) public view
    returns (address, uint, uint) 
    {
        return (
            add, 
            _wl[add].fee, 
            _wl[add].mintLength
            );
    }
             
    function ownerMint(
        address recipient,
        uint256[] calldata kt
    ) public onlyOwner {
        for (uint256 i = 0; i < kt.length; i++) {
            _safeMint(recipient, kt[i]);
        }
    }

    function exists (
        uint256 kt
    ) public view
    returns (bool)
    {
        return _exists(kt);
    }

    function isTeActive (
        uint te
    ) public view
    returns (bool isActive)
    {
        return _tes[te].isActive;
    }

    function setActiveTe (
        uint te,
        bool isActive,
        string memory uri
    ) public onlyOwner
    {
        require(!isTeActive(te) || !isActive, "TE Partition already active. If you need to set baseURI, use setTeBaseURI");

        _tes[te].isActive = isActive;

        bytes memory uriBytes = bytes(uri); 
        if(uriBytes.length > 0) {
            _tes[te].uri = uri;
        }
    }

    function setMaxMintLength (
        uint newLength
    ) public onlyOwner
    {
        maxMintLength = newLength;
    }

    function toggleSaleState() public onlyOwner {
        saleActive = !saleActive;
    }

    function tokenURI (
        uint256 tokenId
    ) public view override
    returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        uint te = getTeFromTokenId(tokenId);
        string memory tokenBaseUri = _tes[te].uri;

        return bytes(tokenBaseUri).length != 0
          ? string(abi.encodePacked(tokenBaseUri, tokenId.toString()))
          : "";
    }

    function withdraw() public payable onlyOwner
    {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setTeBaseURI (
        uint te,
        string memory teBaseURI
    ) public onlyOwner
    {
        _tes[te].uri = teBaseURI; 
    }

    function getTeBaseURI (
        uint te
    ) public view
    returns (string memory)
    {
        return _tes[te].uri;
    }

    function setFee (
        uint256 newFee
    ) public onlyOwner
    {
        fee = newFee;
    }

    function getTeFromTokenId (
        uint256 tokenId
    ) public pure
    returns (uint)
    {   
        require(tokenId > 99999, "TokenId must be greater than 99999");
        return tokenId/100000;
    }

    function setRoyaltyPercent (
        uint256 newRoyaltyPercent
    ) public onlyOwner
    {
        royaltyPercent = newRoyaltyPercent;
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view override
    returns (address receiver, uint256 royaltyAmount)
    {
        return (owner(), (salePrice * royaltyPercent) / 10000);
    }

}