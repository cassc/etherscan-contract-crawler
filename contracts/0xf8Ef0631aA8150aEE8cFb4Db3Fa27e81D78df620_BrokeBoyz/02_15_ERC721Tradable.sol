// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721Tradable is ERC721Enumerable, Ownable {
    using Strings for string;
    using SafeMath for uint256;

    address proxyRegistryAddress;
    address factoryAddress;
    uint256 private _currentTokenId = 0;

    uint256 private _currentBblockId = 0;
    uint256 private _currentMintPassId = 0;
    uint256 private _currentTessId = 0;
    uint256 private _currentRoosId = 0;

    bool private mintPassMintingEnabled = false;
    bool private tessToEvil = false;
    bool private roosToEvil = false;
    bool private bblockToEvil = false;

    bool private tessToGood = false;
    bool private roosToGood = false;
    bool private bblockToGood = false;

    mapping(uint256 => uint256) public idMappings;
    // mapping(uint256 => bool) public isGoodMapping;
    mapping(uint256 => string) public goodEvilMapping;


    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    // todo ipfs hash might be removed

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mintTo(address _to) public onlyOwner {
        uint256 newTokenId = _getNextTokenId();
        _mint(_to, newTokenId);
        _incrementTokenId();
    }

    function setMintPassEnabled(bool isEnabled) public onlyOwner {
        mintPassMintingEnabled = isEnabled;
    }

    function setTessToEvil(bool isEnabled) public onlyOwner {
        tessToEvil = isEnabled;
    }

    function setRoosToEvil(bool isEnabled) public onlyOwner {
        roosToEvil = isEnabled;
    }

    function setBblockToEvil(bool isEnabled) public onlyOwner {
        bblockToEvil = isEnabled;
    }

    function setTessToGood(bool isEnabled) public onlyOwner {
        tessToGood = isEnabled;
    }

    function setRoosToGood(bool isEnabled) public onlyOwner {
        roosToGood = isEnabled;
    }

    function setBblockToGood(bool isEnabled) public onlyOwner {
        bblockToGood = isEnabled;
    }

    function bBlockSupply() public view returns (uint256) {
        return _currentBblockId;
    }

    function tessSupply() public view returns (uint256) {
        return _currentTessId;
    }
    
    function roosSupply() public view returns (uint256) {
        return _currentRoosId;
    }

    function passSupply() public view returns (uint256) {
        return _currentMintPassId;
    }

    function lastTokenId() public view returns (uint256) {
        return _currentTokenId;
    }



    function factoryMintBblock(address _to) public {
        require(factoryAddress == _msgSender(), "Ownable: caller is not the factory!");
        uint256 newTokenId = _getNextTokenId();

        uint256 newBblockId = _getNextBblockId();
        goodEvilMapping[newTokenId] = string(abi.encodePacked("bblockg", uint2str(newBblockId), ".json"));
        idMappings[newTokenId] = newBblockId;

        _mint(_to, newTokenId);
        _incrementTokenId();
        _incrementBblockId();
    }

    function factoryMintMintPass(address _to) public {
        require(factoryAddress == _msgSender(), "Ownable: caller is not the factory!");
        uint256 newTokenId = _getNextTokenId();

        uint256 newMintPassId = _getNextMintPassId();
        goodEvilMapping[newTokenId] = string(abi.encodePacked("mintpass", uint2str(newMintPassId), ".json"));
        idMappings[newTokenId] = newMintPassId;


        _mint(_to, newTokenId);
        _incrementTokenId();
        _incrementMintPassId();
    }

    function exchangeMintPassForTess(uint256 _tokenId) public {
        require(mintPassMintingEnabled, "Minting is not unlocked yet");
        require(ownerOf(_tokenId) == _msgSender(), "Sender is not token owner");

        uint256 mintPassId = idMappings[_tokenId];
        require(keccak256(bytes(goodEvilMapping[_tokenId])) == keccak256(abi.encodePacked("mintpass", uint2str(mintPassId), ".json")), "Token is not Mintpass");

        uint256 newTokenId = _getNextTokenId();
        uint256 newTessId = _getNextTessId();
        goodEvilMapping[newTokenId] = string(abi.encodePacked("tessg", uint2str(newTessId), ".json"));
        idMappings[newTokenId] = newTessId;

        _burn(_tokenId);
        _mint(_msgSender(), newTokenId);
        _incrementTokenId();
        _incrementTessId();
    }

    function exchangeMintPassForRoos(uint256 _tokenId) public {
        require(mintPassMintingEnabled, "Minting is not unlocked yet");
        require(ownerOf(_tokenId) == _msgSender(), "Sender is not token owner");

        uint256 mintPassId = idMappings[_tokenId];
        require(keccak256(bytes(goodEvilMapping[_tokenId])) == keccak256(abi.encodePacked("mintpass", uint2str(mintPassId), ".json")), "Token is not Mintpass");

        uint256 newTokenId = _getNextTokenId();
        uint256 newRoosId = _getNextRoosId();
        goodEvilMapping[newTokenId] = string(abi.encodePacked("rooseveltg", uint2str(newRoosId), ".json"));
        idMappings[newTokenId] = newRoosId;

        _burn(_tokenId);
        _mint(_msgSender(), newTokenId);
        _incrementTokenId();
        _incrementRoosId();
    }

    function convertTessToEvil(uint256 _tokenId) public {
        require(tessToEvil, "Not available at this time");
        require(ownerOf(_tokenId) == _msgSender(), "Sender is not token owner");
        uint256 tessId = idMappings[_tokenId];
        require(keccak256(bytes(goodEvilMapping[_tokenId])) == keccak256(abi.encodePacked("tessg", uint2str(tessId), ".json")), "Token is already evil or is not tess");
        uint256 newTokenId = _getNextTokenId();
        goodEvilMapping[newTokenId] = string(abi.encodePacked("tesse", uint2str(tessId), ".json"));
        idMappings[newTokenId] = tessId;
        _burn(_tokenId);
        _mint(_msgSender(), newTokenId);
        _incrementTokenId();
    }

 
    function convertRoosToEvil(uint256 _tokenId) public {
        require(roosToEvil, "Not available at this time");
        require(ownerOf(_tokenId) == _msgSender(), "Sender is not token owner");
        uint256 roosId = idMappings[_tokenId];
        require(keccak256(bytes(goodEvilMapping[_tokenId])) == keccak256(abi.encodePacked("rooseveltg", uint2str(roosId), ".json")), "Token is already evil or is not Roosevelt");

        uint256 newTokenId = _getNextTokenId();
        goodEvilMapping[newTokenId] = string(abi.encodePacked("roosevelte", uint2str(roosId), ".json"));
        idMappings[newTokenId] = roosId;

        _burn(_tokenId);
        _mint(_msgSender(), newTokenId);
        _incrementTokenId();
    }


    function convertBblockToEvil(uint256 _tokenId) public {
        require(bblockToEvil, "Not available at this time");
        require(ownerOf(_tokenId) == _msgSender(), "Sender is not token owner");
        uint256 bblockId = idMappings[_tokenId];
        require(keccak256(bytes(goodEvilMapping[_tokenId])) == keccak256(abi.encodePacked("bblockg", uint2str(bblockId), ".json")), "Token is already evil or is not bblock");

        uint256 newTokenId = _getNextTokenId();
        goodEvilMapping[newTokenId] = string(abi.encodePacked("bblocke", uint2str(bblockId), ".json"));
        idMappings[newTokenId] = bblockId;

        _burn(_tokenId);
        _mint(_msgSender(), newTokenId);
        _incrementTokenId();
    }

    function convertTessToGood(uint256 _tokenId) public {
        require(tessToGood, "Not available at this time");
        require(ownerOf(_tokenId) == _msgSender(), "Sender is not token owner");
        uint256 tessId = idMappings[_tokenId];
        require(keccak256(bytes(goodEvilMapping[_tokenId])) == keccak256(abi.encodePacked("tesse", uint2str(tessId), ".json")), "Token is already good or is not tess");
        uint256 newTokenId = _getNextTokenId();
        goodEvilMapping[newTokenId] = string(abi.encodePacked("tessg", uint2str(tessId), ".json"));
        idMappings[newTokenId] = tessId;
        _burn(_tokenId);
        _mint(_msgSender(), newTokenId);
        _incrementTokenId();
    }

 
    function convertRoosToGood(uint256 _tokenId) public {
        require(roosToGood, "Not available at this time");
        require(ownerOf(_tokenId) == _msgSender(), "Sender is not token owner");
        uint256 roosId = idMappings[_tokenId];
        require(keccak256(bytes(goodEvilMapping[_tokenId])) == keccak256(abi.encodePacked("roosevelte", uint2str(roosId), ".json")), "Token is already good or is not Roosevelt");

        uint256 newTokenId = _getNextTokenId();
        goodEvilMapping[newTokenId] = string(abi.encodePacked("rooseveltg", uint2str(roosId), ".json"));
        idMappings[newTokenId] = roosId;

        _burn(_tokenId);
        _mint(_msgSender(), newTokenId);
        _incrementTokenId();
    }


    function convertBblockToGood(uint256 _tokenId) public {
        require(bblockToGood, "Not available at this time");
        require(ownerOf(_tokenId) == _msgSender(), "Sender is not token owner");
        uint256 bblockId = idMappings[_tokenId];
        require(keccak256(bytes(goodEvilMapping[_tokenId])) == keccak256(abi.encodePacked("bblocke", uint2str(bblockId), ".json")), "Token is already evil or is not bblock");

        uint256 newTokenId = _getNextTokenId();
        goodEvilMapping[newTokenId] = string(abi.encodePacked("bblockg", uint2str(bblockId), ".json"));
        idMappings[newTokenId] = bblockId;

        _burn(_tokenId);
        _mint(_msgSender(), newTokenId);
        _incrementTokenId();
    }


    function setFactoryAddress(address _factoryAddress) public onlyOwner {
        factoryAddress = _factoryAddress;
    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenId
     * @return uint256 for the next token ID
     */
    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    function _getNextBblockId() private view returns (uint256) {
        return _currentBblockId.add(1);
    }

    function _getNextMintPassId() private view returns (uint256) {
        return _currentMintPassId.add(1);
    }

    function _getNextTessId() private view returns (uint256) {
        return _currentTessId.add(1);
    }

    function _getNextRoosId() private view returns (uint256) {
        return _currentRoosId.add(1);
    }

    /**
     * @dev increments the value of _currentTokenId
     */
    function _incrementTokenId() private {
        _currentTokenId++;
    }

    function _incrementBblockId() private {
        _currentBblockId++;
    }

    function _incrementMintPassId() private {
        _currentMintPassId++;
    }

    function _incrementTessId() private {
        _currentTessId++;
    }

    function _incrementRoosId() private {
        _currentRoosId++;
    }

    function baseTokenURI() virtual public pure returns (string memory);

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), goodEvilMapping[_tokenId]));
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

     /**
     * @dev override transfer to prevent transfer of calimed tokens
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev override transfer to prevent transfer of calimed tokens
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev override transfer to prevent transfer of calimed tokens
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function burn(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == _msgSender());
        _burn(_tokenId); 
    }
}