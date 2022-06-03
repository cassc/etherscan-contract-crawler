// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract OwnableDelegateProxy { }

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract HYPEBEARS_GALLERIES is ERC1155, Ownable {
    using Strings for uint256;
    address public proxyRegistryAddress;
    bool public proxyEnabled = true;

    // A nonce to ensure we have a unique id each time we mint.
    uint256 public nonce;

    constructor(string memory _initialUri, address _proxyRegistryAddress) ERC1155(_initialUri) {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function setURI(string memory _URI) external onlyOwner {
        _setURI(_URI);
        emit UpdateURI(_URI);
    }

    function setProxyEnabled(bool _status) external onlyOwner {
        proxyEnabled = _status;
    }

    function create(address _to, uint256 _amount) external onlyOwner {
        uint256 _id = ++nonce;
        _mint(_to, _id, _amount, "");
        emit CreateItem(_id);
    }

    function mint(uint256 _id, address _to, uint256 _amount) external onlyOwner {
        require(_id <= nonce, "not exist. create first");
        _mint(_to, _id, _amount, "");
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(nonce >= _id, "Nonexistent token");
        return string(abi.encodePacked(super.uri(_id), _id.toString()));
    }

    function isApprovedForAll(
        address _owner,
        address _operator
    ) override public view returns (bool isOperator) {
        if (proxyEnabled) {
            // Whitelist OpenSea proxy contract for easy trading.
            ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
            if (address(proxyRegistry.proxies(_owner)) == _operator) {
                return true;
            }
        }
        return ERC1155.isApprovedForAll(_owner, _operator);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    event UpdateURI(string  uri);
    event CreateItem(uint256 id);
}