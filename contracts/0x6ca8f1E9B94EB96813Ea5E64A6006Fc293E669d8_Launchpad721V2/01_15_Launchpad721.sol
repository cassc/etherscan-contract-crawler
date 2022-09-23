// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Launchpad721V2 is ERC721URIStorage, Ownable {
    uint256 public totalSupply;
    string public baseURI;
    address public admin;
    mapping(uint256 => uint256) internal royaltyFeeMap;

    using ECDSA for bytes32;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address _admin
    )
    ERC721(_name, _symbol)
    Ownable() {
        totalSupply = 0;
        baseURI = _baseURI;
        admin = _admin;
    }

    function setAdmin(address _newAdmin) onlyOwner external {
        admin = _newAdmin;
    }

    function createCollectible(
        uint256 _tokenId,
        string memory _tokenURI,
        uint256 _fee,
        uint256 _NFTPrice,
        bytes memory _signedMessage)
    external payable
    {
        require(msg.value >= _NFTPrice, "Insufficient funds to redeem");
        string memory message = _createMessage(_tokenId, _tokenURI, _fee, _NFTPrice);
        require(
            _verifyMessage(message, _signedMessage) == admin,
            "Invalid signature"
        );
        _safeMint(msg.sender, _tokenId);
        royaltyFeeMap[_tokenId] = _fee;
        _setTokenURI(_tokenId, _tokenURI);
        totalSupply = totalSupply + 1;
    }

    function multipleMint(uint[] memory _ids, string[] memory _tokenUriArr, uint256 _fee) public onlyOwner {
        require(_ids.length == _tokenUriArr.length, "lists length not equal");
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 newItemId = _ids[i];
            _safeMint(msg.sender, newItemId);
            royaltyFeeMap[newItemId] = _fee;
            _setTokenURI(newItemId, _tokenUriArr[i]);
            totalSupply = totalSupply + 1;
        }
    }

    function burn(uint256 _tokenId) public {
        require(_exists(_tokenId), "ERC721: non-existent token");
        totalSupply = totalSupply - 1;
        _burn(_tokenId);
    }

    // If the requirements do not change, replace this method with getOwner()
    function getCreator(uint256 _tokenId) public view returns (address)
    {
        _requireMinted(_tokenId);
        return owner();
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function royaltyFee(uint256 _tokenId) public view returns (uint256)
    {
        _requireMinted(_tokenId);
        return royaltyFeeMap[_tokenId];
    }

    function _verifyMessage(string memory _message, bytes memory _signedMessage)
    internal
    pure
    returns (address)
    {
        bytes32 messageHash = keccak256(bytes(_message));
        address signerAddress = messageHash.toEthSignedMessageHash().recover(_signedMessage);
        return signerAddress;
    }

    function _createMessage(uint256 _tokenId, string memory _tokenURI, uint256 _fee, uint256 _NFTPrice)
    internal
    pure
    returns (string memory)
    {
        return
        string(
            abi.encodePacked(
                Strings.toString(_tokenId),
                _tokenURI,
                Strings.toString(_fee),
                Strings.toString(_NFTPrice)
            )
        );
    }
}