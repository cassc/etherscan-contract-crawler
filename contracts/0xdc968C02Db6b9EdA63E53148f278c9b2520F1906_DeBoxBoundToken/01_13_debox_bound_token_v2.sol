// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DeBoxBoundToken is ERC721, Ownable {

    address public  _signOwner;  
    string  private _urlPath;
    uint256 private _tokenId = 0;
    mapping(uint256 => bytes)    public _tokenMetas;
    mapping(address => uint256)  public _nonces;

    constructor(string memory url) ERC721("DeBox MOD", "DeBox Bound Token") {
        _urlPath = url;
        _signOwner = msg.sender;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function _baseURI() internal view override returns (string memory) {
        return _urlPath;
    }

    function setBaseURI(string memory url) external onlyOwner() {
        _urlPath = url;
    }

    function setSignOwner(address owner) external onlyOwner() {
        require(owner != address(0), "The address is invalid");
        _signOwner = owner;
    }

    function _stringToBytes(string memory source) internal pure returns (bytes memory) {
        bytes memory result = bytes(source);
        require(result.length <= 32, "Ths source string exceeds 32 bytes");
        return result;
    }

    function tokenMeta(uint256 tokenId) external view returns (bytes memory) {
        return _tokenMetas[tokenId];
    }

    function mint(string memory meta, bytes memory signature) external callerIsUser {
        bytes32 message = keccak256(abi.encodePacked(_msgSender(), meta, _nonces[_msgSender()]));
        require(ECDSA.recover(message, signature) == _signOwner, "The signature is invalid");
        _nonces[_msgSender()] += 1;
        _tokenMetas[_tokenId] = _stringToBytes(meta);
        _mint(_msgSender(), _tokenId);
        _tokenId += 1;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override (ERC721) {
        require(from == address(0) || to == address(0), "The token is non-transferable");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
}