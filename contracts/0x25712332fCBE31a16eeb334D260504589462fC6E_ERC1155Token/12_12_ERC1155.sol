// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ERC1155Token is ERC1155, Ownable {
    string[] public names;
    uint256[] public ids;
    string public baseMetadataURI;
    string public name;
    uint256 public mintFee = 0.00 ether;
    uint256 public stage;
    uint256 public maxPublicSale = 10;
    bool public publicMintActive = false;

    mapping(address => uint256[5]) public publicMintLimit;
    mapping(address => uint256[11]) public mintLimit;
    mapping(string => uint256) public nameToId;
    mapping(uint256 => string) public idToName;
    mapping(uint256 => uint256) public totalSupply;

    constructor(
        string memory _contractName,
        string memory _uri,
        string[] memory _names,
        uint256[] memory _ids
    ) ERC1155(_uri) {
        names = _names;
        ids = _ids;
        setURI(_uri);
        createMapping();
        name = _contractName;
        stage = 0;
    }

    function createMapping() private {
        for (uint256 id = 0; id < ids.length; id++) {
            nameToId[names[id]] = ids[id];
            idToName[ids[id]] = names[id];
            totalSupply[ids[id]] = 999;
        }
    }

    function uri(uint256 _tokenid) public view override returns (string memory) {
        return string(abi.encodePacked(baseMetadataURI, Strings.toString(_tokenid), ".json"));
    }

    function getStage() public view returns (uint256) {
        return stage;
    }

    function setMaxPublicSale(uint256 _max) public onlyOwner {
        maxPublicSale = _max;
    }

    function getCurrentTokenId() public view returns (uint256) {
        uint256 tokenId;
        if (stage == 1 || stage == 2) {
            tokenId = 1;
        } else if (stage == 3 || stage == 4) {
            tokenId = 2;
        } else if (stage == 5 || stage == 6) {
            tokenId = 3;
        } else if (stage == 7 || stage == 8) {
            tokenId = 4;
        } else if (stage == 9 || stage == 10) {
            tokenId = 5;
        }
        return tokenId;
    }

    function setWhitelistMintLimit(address[] memory _addrs, uint256 _limit, uint256 _whitelistNumber) public onlyOwner {
        require(_whitelistNumber != 0, "Number must be above 0");
        for (uint i = 0; i < _addrs.length; i++) {
            mintLimit[_addrs[i]][_whitelistNumber] = _limit;
        }
    }

    function setStage(uint256 _stage) public onlyOwner {
        require(_stage >= 0 && _stage <= 10, "Invalid stage number");
        stage = _stage;
    }

    function setURI(string memory newuri) public onlyOwner {
        baseMetadataURI = newuri;
        _setURI(newuri);
    }

    function setFee(uint256 _fee) public onlyOwner {
        mintFee = _fee;
    }

    function togglePublicMint() public onlyOwner {
        publicMintActive = !publicMintActive;
    }

    function publicMint(uint256 amount) public payable returns (uint256) {
        require(stage != 0, "Sale not active");
        require(publicMintActive, "Public mint is not active");

        uint256 tokenId = getCurrentTokenId();
        require(
            amount + publicMintLimit[msg.sender][tokenId] <= maxPublicSale,
            "Public mint limit reached for address"
        );
        require(totalSupply[tokenId] >= amount, "Total supply limit reached");
        require(mintFee == msg.value, "Incorrect ETH value sent");

        _mint(msg.sender, tokenId, amount, "");
        totalSupply[tokenId] -= amount;
        publicMintLimit[msg.sender][tokenId] += amount;
        return tokenId;
    }

    function mint(uint256 amount) public payable returns (uint256) {
        require(stage != 0, "Sale not active");
        require(mintLimit[msg.sender][stage] != 0, "Not on whitelist");
        require(amount <= mintLimit[msg.sender][stage], "Limit reached");
        require(mintFee * amount == msg.value, "Incorrect ETH value sent");

        uint256 tokenId = getCurrentTokenId();
        require(totalSupply[tokenId] >= amount, "Total supply limit reached");

        _mint(msg.sender, tokenId, amount, "");
        mintLimit[msg.sender][stage] -= amount;
        totalSupply[tokenId] -= amount;
        return tokenId;
    }

    function withdrawEarnings() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}