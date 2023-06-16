//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract GameObjectMaker is ERC1155, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private counter;

    string metadataPath;

    mapping(address => bool) private minters;

    struct GameObject {
        uint256 gameObjectId; 
        uint256 maxSupply;
        uint256 totalSupply;
        uint256 mintPrice;
        bool paidWithToken;
        bool isSaleClosed;
    }

    mapping(uint256 => GameObject) public gameObjects;

    constructor() ERC1155("") {
        metadataPath = "";
    }

    // modifiers

    modifier onlyMinter {
        if (minters[msg.sender] != true) revert();
        _;
    }

    // Getters

    function isPaidWithToken(uint256 gameObjectId) public view returns (bool) {
        return gameObjects[gameObjectId].paidWithToken;
    }

    function isSaleClosed(uint256 gameObjectId) public view returns (bool) {
        return gameObjects[gameObjectId].isSaleClosed;
    }

    function getMintPrice(uint256 gameObjectId) public view returns (uint256) {
        return gameObjects[gameObjectId].mintPrice;
    }

    function getGameObject(uint256 id) public view returns (GameObject memory) {
        return gameObjects[id];
    }

    function getTotalSupply(uint256 gameObjectId) public view returns (uint256) {
        return gameObjects[gameObjectId].totalSupply;
    }

    function exists(uint256 id) public view returns (bool) {
        return gameObjects[id].maxSupply > 0;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return (
            string(abi.encodePacked(metadataPath, Strings.toString(tokenId)))
        );
    }

    function isMinter(address _address) public view returns (bool) {
        return minters[_address];
    }

    // Setters

    function setMinter(address _address, bool value) external onlyOwner {
        minters[_address] = value;
    }

    function setMetadataPath(string memory _metadataPath) external onlyOwner {
        metadataPath = _metadataPath;
    }

    // Manage sale
    function openSingleSale(uint256 _gameObjectId) external onlyMinter {
        require(exists(_gameObjectId), "GameObject does not exist");
        gameObjects[_gameObjectId].isSaleClosed = false;
    }

    function closeSingleSale(uint256 _gameObjectId) external onlyMinter {
        require(exists(_gameObjectId), "GameObject does not exist");
        gameObjects[_gameObjectId].isSaleClosed = true;
    }

    function openSale(uint256[] calldata _gameObjectIds) external onlyMinter {
        for (uint256 i = 0; i < _gameObjectIds.length; i++) {
            require(exists(_gameObjectIds[i]), "GameObject does not exist");
            gameObjects[_gameObjectIds[i]].isSaleClosed = false;
        }
    }

    function closeSale(uint256[] calldata _gameObjectIds) external onlyMinter {
        for (uint256 i = 0; i < _gameObjectIds.length; i++) {
            require(exists(_gameObjectIds[i]), "GameObject does not exist");
            gameObjects[_gameObjectIds[i]].isSaleClosed = true;
        }
    }

    // Manage GameObjects

    function addGameObject(
        uint256 _maxSupply,
        uint256 _mintPrice,
        bool _paidWithToken
    ) public onlyOwner {
        GameObject storage go = gameObjects[counter.current()];
        go.gameObjectId = counter.current();
        go.maxSupply = _maxSupply;
        go.mintPrice = _mintPrice;
        go.paidWithToken = _paidWithToken;
        go.isSaleClosed = true;
        go.totalSupply = 0;

        counter.increment();
    }

    function editGameObject(
        uint256 _gameObjectId,
        uint256 _maxSupply,
        uint256 _mintPrice,
        bool _paidWithToken
    ) external onlyOwner {
        require(
            exists(_gameObjectId),
            "EditGameObject: gameObject does not exist"
        );
        gameObjects[_gameObjectId].maxSupply = _maxSupply;
        gameObjects[_gameObjectId].mintPrice = _mintPrice;
        gameObjects[_gameObjectId].paidWithToken = _paidWithToken;
    }

    // Mint by minter
    function mint(address _recipient, uint256 _gameObjectId, uint256 _amount) external onlyMinter {
        require(
            gameObjects[_gameObjectId].totalSupply + _amount <= gameObjects[_gameObjectId].maxSupply,
            "mint: Max supply reached"
        );
        gameObjects[_gameObjectId].totalSupply += _amount;
        _mint(_recipient, _gameObjectId, _amount, "");
    }

    // Withdraw

    function withdraw() public payable onlyOwner {
        uint256 bal = address(this).balance;
        require(payable(msg.sender).send(bal));
    }

    function withdrawToken(address _tokenAddress) public payable onlyOwner {
        ERC20 token = ERC20(_tokenAddress);
        uint256 bal = token.balanceOf(address(this));
        token.transfer(msg.sender, bal);
    }
}