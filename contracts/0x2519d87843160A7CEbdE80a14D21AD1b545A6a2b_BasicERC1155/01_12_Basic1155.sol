// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract BasicERC1155 is ERC1155, Ownable {
    uint256 private constant LIMIT = 1100;
    address proxyRegistryAddress;
    mapping(uint256 => uint256) public supply;
    mapping(uint256 => mapping(address => uint256)) public supplyOfType;
    string contractURL;

    string public name;
    string public symbol;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress,
        string memory _IPFS_URL
    ) ERC1155("") {
        name = _name;
        symbol = _symbol;
        proxyRegistryAddress = _proxyRegistryAddress;
        contractURL = string(
            abi.encodePacked("ipfs://", _IPFS_URL, "/metadata.json")
        );
        _setURI(string(abi.encodePacked("ipfs://", _IPFS_URL, "/{id}.json")));
    }

    function airdrop(address[] memory _addrs, uint256 _type)
        external
        onlyOwner
    {
        require(_type == 0, "Invalid type");
        uint256 _amount = _addrs.length - 1;
        require(
            (supply[_type] + _amount) < LIMIT,
            "Not enough left to mint that many items"
        );
        for (uint256 i = 0; i <= _amount; i++) {
            _mint(_addrs[i], _type, 1, "");
            supplyOfType[_type][_addrs[i]] += 1;
            supply[_type] += 1;
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function balanceOfType(address _addresss, uint256 _type)
        public
        view
        returns (uint256)
    {
        return supplyOfType[_type][_addresss];
    }

    function setURI(string memory _uri) public onlyOwner {
        _setURI(_uri);
    }

    function setProxyAddress(address _a) public onlyOwner {
        proxyRegistryAddress = _a;
    }

    function getProxyAddress() public view onlyOwner returns (address) {
        return proxyRegistryAddress;
    }

    function contractURI() public view returns (string memory) {
        return contractURL;
    }

    function setContractURI(string memory _contractURL) public onlyOwner {
        contractURL = _contractURL;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        return ERC1155.isApprovedForAll(_owner, _operator);
    }
}