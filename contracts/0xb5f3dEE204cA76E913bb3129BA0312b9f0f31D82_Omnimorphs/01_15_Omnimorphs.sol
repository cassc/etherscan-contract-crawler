// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IOmniFusion.sol";

//  ____  __  __ _   _ _____ __  __  ____  _____  _____  _    _  _____
// / __ \|  \/  | \ | |_   _|  \/  |/ __ \|  __ \|  __ \| |  | |/ ____|
// | |  | | \  / |  \| | | | | \  / | |  | | |__) | |__) | |__| | (___
// | |  | | |\/| | . ` | | | | |\/| | |  | |  _  /|  ___/|  __  |\___ \
// | |__| | |  | | |\  |_| |_| |  | | |__| | | \ \| |    | |  | |____) |
//  \____/|_|  |_|_| \_|_____|_|  |_|\____/|_|  \_\_|    |_|  |_|_____/
contract Omnimorphs is ERC721Enumerable, Ownable {
    using ECDSA for bytes32;

    // price of a single NFT
    uint256 public constant TOKEN_PRICE = 0.08 ether;

    // max. number of tokens that can be purchased in one transaction
    uint public constant MAX_PURCHASE = 5;

    // maximum number of tokens ever gonna be minted on this contract
    uint256 public constant MAX_TOTAL_SUPPLY = 10000;

    // fill this out when calculated
    string public provenanceHash;

    // signer for bot protection
    address public signer;

    // make sure no nonce can be used for 2 transactions
    mapping(string => bool) private usedNonces;

    // can be used to launch and pause the sale
    bool public saleIsActive = false;

    // timestamp when presale stops
    uint public presaleActiveUntil = 0;

    // addresses that can participate in the presale event
    mapping(address => uint) private presaleAccessList;

    // how many presale tokens were already minted by address
    mapping(address => uint) private presaleTokensClaimed;

    // address of OmniFusion contract
    address public omniFusionAddress;

    // base uri for token metadata
    string public baseURI;

    // member1
    address payable public member1Address;

    // member2
    address payable public member2Address;

    // member3
    address payable public member3Address;

    constructor(
        string memory initialBaseURI,
        address payable _member1Address,
        address payable _member2Address,
        address payable _member3Address,
        address _signer
    ) ERC721('Omnimorphs', 'OMNI') {
        baseURI = initialBaseURI;
        member1Address = _member1Address;
        member2Address = _member2Address;
        member3Address = _member3Address;
        signer = _signer;
    }

    // INTERNALS

    // used internally by tokenURI
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // mints an arbitrary number of tokens for sender
    function _mintTokens(uint numberOfTokens) private {
        for (uint i = 0; i < numberOfTokens; i++) {
            // index from 1 instead of 0
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    // hashes a transaction, to verify identity
    function hashTransaction(address sender, uint256 qty, string memory nonce) private pure returns(bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(sender, qty, nonce)))
        );

        return hash;
    }

    // matches hash and signature against signer
    function matchAddressSigner(bytes32 hash, bytes memory signature) private view returns(bool) {
        return signer == hash.recover(signature);
    }

    // ONLY OWNER

    // set base uri when moving metadata
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    // starts or pauses the sale
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    // reserve some tokens for the contract owner
    function reserveTokens(uint numberOfTokens) external onlyOwner {
        require(numberOfTokens > 0, "Number of tokens cannot be lower than, or equal to 0");
        require(totalSupply() + numberOfTokens <= MAX_TOTAL_SUPPLY, "Minting would exceed MAX_TOTAL_SUPPLY");

        _mintTokens(numberOfTokens);
    }

    // set provenance hash once it's calculated
    function setProvenanceHash(string memory hash) external onlyOwner {
        provenanceHash = hash;
    }

    // owner withdraws funds to members
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        uint member3Share = balance / 10;
        uint otherMembersShare = (balance - member3Share) / 2;
        member1Address.transfer(otherMembersShare);
        member2Address.transfer(otherMembersShare);
        member3Address.transfer(member3Share);
    }

    // activate or deactivate presale
    function setPresaleActiveUntil(uint timestamp) external onlyOwner {
        presaleActiveUntil = timestamp;
    }

    // makes addresses eligible for presale minting
    function addPresaleAddresses(uint numberOfTokens, address[] calldata addresses) external onlyOwner {
        require(numberOfTokens <= 3, "One presale address can only mint 3 tokens maximum");

        for (uint256 i = 0; i < addresses.length; i++) {
            // cannot add the null address
            if (addresses[i] != address(0)) {
                // not resetting presaleTokensClaimed[addresses[i]], so we can't add an address twice
                presaleAccessList[addresses[i]] = numberOfTokens;
            }
        }
    }

    // removes addresses from the presale list
    function removePresaleAddresses(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            presaleAccessList[addresses[i]] = 0;
        }
    }

    // changes the address of the OmniFusion implementation
    function setOmniFusionAddress(address _address) external onlyOwner {
        omniFusionAddress = _address;
    }

    // set the signer
    function setSigner(address _address) external onlyOwner {
        signer = _address;
    }

    function setMember1Address(address payable _address) external onlyOwner {
        member1Address = _address;
    }

    function setMember2Address(address payable _address) external onlyOwner {
        member2Address = _address;
    }

    function setMember3Address(address payable _address) external onlyOwner {
        member3Address = _address;
    }

    // PUBLIC

    // purchase tokens from the contract presale
    function mintTokensPresale(uint numberOfTokens) external payable {
        require(isPresaleActive(), "Presale is not currently active");
        require(numberOfTokens <= presaleTokensForAddress(msg.sender), "Trying to mint too many tokens");
        require(numberOfTokens > 0, "Number of tokens cannot be lower than, or equal to 0");
        require(totalSupply() + numberOfTokens <= MAX_TOTAL_SUPPLY, "Minting would exceed MAX_TOTAL_SUPPLY");
        require(TOKEN_PRICE * numberOfTokens == msg.value, "Ether value sent is not correct");

        // if presale, add numberOfTokens to claimed token map
        presaleTokensClaimed[msg.sender] += numberOfTokens;
        _mintTokens(numberOfTokens);
    }

    // purchase tokens from the contract
    function mintTokens(bytes32 hash, bytes memory signature, string memory nonce, uint numberOfTokens) external payable {
        require(saleIsActive, "Sale is not currently active");
        require(totalSupply() + numberOfTokens <= MAX_TOTAL_SUPPLY, "Minting would exceed MAX_TOTAL_SUPPLY");
        require(numberOfTokens <= MAX_PURCHASE, "Trying to mint too many tokens");
        require(numberOfTokens > 0, "Number of tokens cannot be lower than, or equal to 0");
        require(TOKEN_PRICE * numberOfTokens == msg.value, "Ether value sent is not correct");
        require(matchAddressSigner(hash, signature), "Direct minting is not allowed");
        require(!usedNonces[nonce], "Nonce was already used");
        require(hashTransaction(msg.sender, numberOfTokens, nonce) == hash, "Hash mismatch");

        usedNonces[nonce] = true;
        _mintTokens(numberOfTokens);
    }

    // returns the number of tokens an address can mint during the presale
    function presaleTokensForAddress(address _address) public view returns (uint) {
        return presaleAccessList[_address] > presaleTokensClaimed[_address]
        ? presaleAccessList[_address] - presaleTokensClaimed[_address]
        : 0;
    }

    // presale is active, if presaleActiveUntil is in the future, and public sale is not active
    function isPresaleActive() public view returns (bool) {
        return presaleActiveUntil >= block.timestamp && !saleIsActive;
    }

    // fuse two tokens together
    function fuseTokens(uint toFuse, uint toBurn, bytes memory payload) external {
        IOmniFusion(omniFusionAddress).fuseTokens(msg.sender, toFuse, toBurn, payload);
        _burn(toBurn);
    }
}