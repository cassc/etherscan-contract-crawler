// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// Uncomment this line to use console.log
// import "hardhat/console.sol";4

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DJDAOSBTv1 {
    using Address for address;
    using Strings for uint256;

    address public owner;

    mapping(address => bool) public vibeChecked;

    struct ContractData {
        string name;
        string symbol;
        string baseURI;
        uint256 totalSupply;
    }

    ContractData public contractData;

    event DJJoined(address member, uint256 index);
    event DJLeft(address exMember, uint256 index);
    event OwnerUpdated(address newMember);

    mapping(uint256 => address) private _owners;
    mapping(address => bool) private _hasMinted;
    mapping(address => uint16) public balances;
    mapping(address => uint256) public ownedToken;

    constructor() {
        contractData.name = "DJDAO Membership SBT";
        contractData.symbol = "DJ DAO SBT";
        contractData.totalSupply = 0;
        contractData.baseURI = "https://djdao.s3.amazonaws.com/DJDAOSBT.json";
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    function name() public view returns (string memory) {
        return contractData.name;
    }

    function symbol() public view returns (string memory) {
        return contractData.symbol;
    }

    function changeOwner(address newOwner) public onlyOwner {
        owner = newOwner;
        emit OwnerUpdated(newOwner);
    }

    function setBaseURI(string memory newURI) public onlyOwner {
        contractData.baseURI = newURI;
    }

    function addGoodVibes(address[] memory newDJs) public onlyOwner {
        for (uint256 i = 0; i < newDJs.length; i++) {
            vibeChecked[newDJs[i]] = true;
        }
    }

    function removeGoodVibes(address[] memory oldDJs) public onlyOwner {
        for (uint256 i = 0; i < oldDJs.length; i++) {
            vibeChecked[oldDJs[i]] = false;
        }
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function join() public {
        require(!_hasMinted[msg.sender], "Already Joined");
        require(vibeChecked[msg.sender], "Bad Vibes");
        contractData.totalSupply++;
        balances[msg.sender] = 1;
        _owners[contractData.totalSupply] = msg.sender;
        ownedToken[msg.sender] = contractData.totalSupply;
        _hasMinted[msg.sender] = true;
        emit DJJoined(msg.sender, contractData.totalSupply);
    }

    function leave() public {
        require(_hasMinted[msg.sender], "Not Joined");
        uint256 tokenToDelete = ownedToken[msg.sender];
        _hasMinted[msg.sender] = false;
        balances[msg.sender] = 0;
        _owners[tokenToDelete] = address(0);
        delete ownedToken[msg.sender];
        _hasMinted[msg.sender] = false;
        emit DJLeft(msg.sender, tokenToDelete);
    }

    function kick(address kickee) public onlyOwner {
        require(_hasMinted[kickee], "Not Joined");
        uint256 tokenToDelete = ownedToken[kickee];
        _hasMinted[kickee] = false;
        balances[kickee] = 0;
        _owners[tokenToDelete] = address(0);
        delete ownedToken[kickee];
        _hasMinted[msg.sender] = false;
        emit DJLeft(kickee, tokenToDelete);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    function tokenURI(uint256 id) public view returns (string memory) {
        _requireMinted(id);
        return contractData.baseURI;
    }
}