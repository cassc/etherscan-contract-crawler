// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";
import "./base64.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721TradableCHAIN
 * ERC721TradableCHAIN - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721TradableCHAIN is ContextMixin, ERC721Enumerable, NativeMetaTransaction, Ownable {
    using SafeMath for uint256;
    
    struct tokenInfo {
        address _owner;
        address _creator;
        string _name;
        string _description;
        string _animation;
        string _image;
        string _codec;
        string _codec_animation;
        string _attributes;
        uint256 _number_likes;
        bool _image_encoded;
        bool _animation_image_encoded;
        bool _featured;
        bool _locked;
        bool _created;
        mapping (address => bool) _likes;
    }
    mapping (uint256 => tokenInfo) TOKENS;
    address proxyRegistryAddress;
    uint256 internal _currentTokenId;

    event Unveiled(uint256 tokenId, address receiver);

    constructor(string memory _name, string memory _symbol, address _proxyRegistryAddress ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        _initializeEIP712(_name);
    }

    function mintToken() public {
        uint256 newTokenId = _getNextTokenId();
        tokenInfo storage newToken = TOKENS[newTokenId];
        newToken._owner = msg.sender;
        _mint(msg.sender, newTokenId);
        _incrementTokenId();
        emit Unveiled(newTokenId, msg.sender);
    }

      function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        TOKENS[tokenId]._owner = to;
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        TOKENS[tokenId]._owner = to;
        _safeTransfer(from, to, tokenId, data);
    }

    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    function _incrementTokenId() private {
        _currentTokenId++;
    }

    function baseTokenURI() virtual public view returns (string memory);

    function isApprovedForAll(address owner, address operator) override public view returns (bool) {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    function _msgSender() internal override view returns (address sender) {
        return ContextMixin.msgSender();
    }

    modifier onlyME() {
        require((owner() == msg.sender), "no");
        _;
    }

    function withdraw(address payable recipient, uint256 amount) external onlyME {
        recipient.transfer(amount);
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }
    
    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

}