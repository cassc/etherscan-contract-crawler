// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

interface ERC721 {
    function getLastTransfer(uint256 _id) external returns (uint256);
    function hasRedeemed(uint256 _id, uint256 i) external returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract Bricks is ERC1155, Ownable, Pausable, ERC1155Burnable, ERC1155Supply {

    address proxyRegistryAddress;
    address logicContract;
    mapping(uint256 => uint256) public price;
    uint256 maxSupply;

    string public name;
    string public symbol;

    string contractURL;
    constructor(address _proxyRegistryAddress, string memory _IPFSURL) ERC1155("") {
        maxSupply = 20000;
        proxyRegistryAddress = _proxyRegistryAddress;
        name = "Snkr Bricks by Sneaker News";
        symbol = "BRKS";
        setContractURI(
            string(abi.encodePacked("ipfs://", _IPFSURL, "/metadata.json"))
        );
        setURI(string(abi.encodePacked("ipfs://", _IPFSURL, "/{id}.json")));
    }

    function airdrop(address[] memory _addrs, uint256 _type)
        external
        virtual
        onlyOwner
    {
        uint256 _amount = _addrs.length - 1;
        require(
            (totalSupply(1) + _amount) <= maxSupply,
            "Not enough left to mint that many items"
        );
        for (uint256 i = 0; i <= _amount; i++) {
            _mint(_addrs[i], _type, 1, "");
        }
    }

    function setMaxSupply(uint256 newMax) public onlyOwner {
        require(newMax >= totalSupply(1), "Must be higher than or equal to current supply");
        maxSupply = newMax;
    }

    function getMaxSupply() public view returns (uint256) {
        return maxSupply;
    }

    function contractURI() public view returns (string memory) {
        return contractURL;
    }

    function setContractURI(string memory newContractURL) public onlyOwner {
        contractURL = newContractURL;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setLogicContract(address addr) public onlyOwner {
        logicContract = addr;
    }

    function claim(address wallet, uint256 amount) public whenNotPaused {
        require(wallet != address(0), "Cannot send to null address");
        require(msg.sender == logicContract, "Must be the correct contract.");
        require(totalSupply(1) + amount <= maxSupply, "Not enough left to mint");
        _mint(wallet, 1, amount, "");
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}