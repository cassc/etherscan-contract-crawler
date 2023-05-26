// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract SkullxAeons is ERC721Enumerable, Ownable {
    string public aeonsProvenance;

    uint256 public constant AEONS_MAX_SUPPLY = 2000;
    uint256 public constant SUMMON_LIMIT = 10;
    uint256 public constant PRICE = 0.03 ether;

    bool public publicSaleIsActive = false;
    bool public freeMintIsActive = false;

    uint256 public reservedLeft = 100;

    mapping(address => bool) private allowList;
    mapping(address => bool) private allowListClaimed;

    string public baseURI;

    address w0 = 0xF65b1bC72ffe0c8BcbC91da87abc53aC8Cf884FD;
    address w1 = 0x53af9B516cC5c6BdC2A500CF1ED30Ec88232B5Ec;
    address w2 = 0xD4091d661A44648D61bd3bb51E129d0d60892056;
    address w3 = 0x44403D2c7C7229a1fc4bD7379F51daC328407C5F;

    constructor(string memory uri) ERC721("Skullx: Aeons", "AEON") {
        setBaseURI(uri);
    }

    function addToAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            allowList[addresses[i]] = true;
        }
    }

    function onAllowList(address _address) external view returns (bool) {
        return allowList[_address];
    }

    function removeFromAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");
            allowList[addresses[i]] = false;
        }
    }

    function allowListClaimedBy(address owner) external view returns (bool){
        require(owner != address(0), 'Zero address not on Allow List');
        return allowListClaimed[owner];
    }

    function summon(uint256 numberOfTokens) external payable {
        uint256 supply = totalSupply();
        require(publicSaleIsActive, 'Public sale is not active');
        require(numberOfTokens <= SUMMON_LIMIT, 'Exceeds SUMMON_LIMIT');
        require(supply + numberOfTokens <= AEONS_MAX_SUPPLY - reservedLeft, 'Exceeds AEONS_MAX_SUPPLY');
        require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

        // Start index at 1
        for (uint256 i; i < numberOfTokens; i++) {
            _safeMint(msg.sender, supply + i + 1);
        }
    }

    function freeSummon() external payable {
        uint256 supply = totalSupply();
        require(freeMintIsActive, 'Free summon phase for Skullx role is not active');
        require(allowList[msg.sender], 'You are not on the Allow List');
        require(allowListClaimed[msg.sender] == false, 'Already summoned one free Aeon');
        require(supply + 1 <= AEONS_MAX_SUPPLY - reservedLeft, 'Exceeds AEONS_MAX_SUPPLY');

        // Start index at 1
        allowListClaimed[msg.sender] = true;
        _safeMint(msg.sender, supply + 1);
    }

    function giveAway(address to, uint256 numberOfTokens) external onlyOwner() {
        require(numberOfTokens <= reservedLeft, "Exceeds reserved Aeons left");
        uint256 supply = totalSupply();

        // Start index at 1
        for (uint256 i; i < numberOfTokens; i++) {
            _safeMint(to, supply + i + 1);
        }

        reservedLeft -= numberOfTokens;
    }

    function setProvenanceHash(string memory provenanceHash) external onlyOwner {
        aeonsProvenance = provenanceHash;
    }

    function togglePublicSaleIsActive() external onlyOwner {
        publicSaleIsActive = !publicSaleIsActive;
    }

    function toggleFreeMintIsActive() external onlyOwner {
        freeMintIsActive = !freeMintIsActive;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function withdrawAll() external payable onlyOwner {
        uint256 percent = address(this).balance / 100;
        require(payable(w0).send(percent * 45));
        require(payable(w1).send(percent * 25));
        require(payable(w2).send(percent * 25));
        require(payable(w3).send(percent * 5));
    }

}