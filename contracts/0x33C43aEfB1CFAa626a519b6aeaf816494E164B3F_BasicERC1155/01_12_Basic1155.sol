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

string constant NAME = "The Wes Lang F.A.T. Series 2 Airdrop 5";
string constant SYMBOL = "FAT25";
string constant IPFSURL = "bafybeiftcpgombcjub5xfddguvaumx2gywat2txff7sheaxazbs2zp6lsu";

contract BasicERC1155 is ERC1155, ERC1155Burnable, Ownable {
    uint256 private constant LIMIT = 106;
    address proxyRegistryAddress;
    mapping(uint256 => uint256) public supply;
    mapping(uint256 => mapping(address => uint256)) public supplyOfType;
    mapping(uint256 => bool) private minted;
    string contractURL;

    string public name = NAME;
    string public symbol = SYMBOL;

    constructor(address _proxyRegistryAddress) ERC1155("") {
        proxyRegistryAddress = _proxyRegistryAddress;
        contractURL = string(
            abi.encodePacked("ipfs://", IPFSURL, "/metadata.json")
        );
        _setURI(string(abi.encodePacked("ipfs://", IPFSURL, "/{id}.json")));
    }

    function _getNextEditionID(uint256 _type) internal view returns (uint256) {
        return supply[_type];
    }

    function _getNextID(uint256 _type) internal view returns (uint256) {
        return _getNextEditionID(_type) + (_type * LIMIT);
    }

    function airdrop(address[] memory _addrs, uint256 _type)
        external
        onlyOwner
    {
        require((_type >= 0) && (_type <= 2), "Invalid type");
        uint256 _amount = _addrs.length - 1;
        require(
            (supply[_type] + _amount) < LIMIT,
            "Not enough left to mint that many items"
        );
        uint256 ID = _getNextID(_type);
        for (uint256 i = 0; i <= _amount; i++) {
            _mint(_addrs[i], ID + i, 1, "");
            supplyOfType[_type][_addrs[i]] += 1;
            supply[_type] += 1;
            minted[ID + i] = true;
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