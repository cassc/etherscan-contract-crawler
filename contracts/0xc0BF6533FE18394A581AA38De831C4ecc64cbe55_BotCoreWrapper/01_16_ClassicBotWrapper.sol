// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';


interface IGetBot {
    function transfer(
        address _to,
        uint256 _tokenId
    ) external;

    function getBot(uint256 _id)
        external
        view
        returns (
        bool isGestating,
        bool isReady,
        uint256 cooldownIndex,
        uint256 nextActionAt,
        uint256 siringWithId,
        uint256 birthTime,
        uint256 matronId,
        uint256 sireId,
        uint256 generation,
        uint256 genes
    );
}


interface IBotCore is IERC721, IGetBot {}


contract BotCoreWrapper is IGetBot, ReentrancyGuard, Ownable, ERC721, ERC721Pausable, ERC721Enumerable {
    using Strings for uint256;

    IBotCore public botCore;
    string public baseURI;

    event BaseURISet(string value);

    constructor (
        address _botCoreAddress, 
        string memory _uri,
        string memory _name, 
        string memory _symbol
    ) ERC721(_name, _symbol) {
        require(_botCoreAddress != address(0), "zero address");
        botCore = IBotCore(_botCoreAddress);
        baseURI = _uri;
        emit BaseURISet(_uri);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function transfer(
        address _to,
        uint256 _tokenId
    ) external override {
        transferFrom(msg.sender, _to, _tokenId);
    }

    function transferMany(
        address[] calldata _tos,
        uint256[] calldata _tokenIds
    ) external {
        require(_tos.length == _tokenIds.length, "Wrapper: lengths mismatch");
        for (uint256 i; i < _tos.length; i++){
            transferFrom(msg.sender, _tos[i], _tokenIds[i]);
        }
    }

    function transferFromMany(
        address[] calldata _froms,
        address[] calldata _tos,
        uint256[] calldata _tokenIds
    ) external {
        require(_froms.length == _tos.length, "Wrapper: lengths mismatch");
        require(_tos.length == _tokenIds.length, "Wrapper: lengths mismatch");
        for (uint256 i; i < _froms.length; i++){
            transferFrom(_froms[i], _tos[i], _tokenIds[i]);
        }
    }

    function approveMany(
        address[] calldata _tos,
        uint256[] calldata _tokenIds
    ) external {
        require(_tos.length == _tokenIds.length, "Wrapper: lengths mismatch");
        for (uint256 i; i < _tos.length; i++){
            approve(_tos[i], _tokenIds[i]);
        }
    }

    function setBaseURI(string calldata baseURIValue) external onlyOwner {
        baseURI = baseURIValue;
        emit BaseURISet(baseURIValue);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function wrap(uint256 tokenId) external nonReentrant {
        botCore.transferFrom(msg.sender, address(this), tokenId);
        _mint(msg.sender, tokenId);
    }

    function unwrap(uint256 tokenId) external nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Wrapper: unwrap from incorrect owner");
        _burn(tokenId);
        botCore.transfer(msg.sender, tokenId);
    }

    function wrapMany(uint256[] calldata tokenIds) external nonReentrant {
        for (uint256 i; i < tokenIds.length; i++) {
            botCore.transferFrom(msg.sender, address(this), tokenIds[i]);
            _mint(msg.sender, tokenIds[i]);
        }
    }

    function unwrapMany(uint256[] calldata tokenIds) external nonReentrant {
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(ownerOf(tokenId) == msg.sender, "Wrapper: unwrap from incorrect owner");
            _burn(tokenId);
            botCore.transfer(msg.sender, tokenId);
        }
    }

    function getBot(uint256 _id)
        external
        view
        override
        returns (
        bool isGestating,
        bool isReady,
        uint256 cooldownIndex,
        uint256 nextActionAt,
        uint256 siringWithId,
        uint256 birthTime,
        uint256 matronId,
        uint256 sireId,
        uint256 generation,
        uint256 genes
    ) {
        return botCore.getBot(_id);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Pausable, ERC721Enumerable, ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }    
}