// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721A.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract Sunny is Ownable, ERC721A, ReentrancyGuard {
    string private _baseTokenURI;
    mapping(address => uint256) public allowlist;

    uint256 private _standardPackMint;
    uint256 private _premiumPackMint;
    uint256 private _totalStandardPacks;

    uint256 private _standardPackFee;

    uint256 public totalMint;
    uint256 public soldStandardPack;

    constructor() ERC721A("The 8.1: Sunny", "Sunny") {
        _totalStandardPacks = 81;
        _standardPackFee = .049 ether;
        _standardPackMint = 9;
        soldStandardPack = 0;
        totalMint = 1100;
    }

    //start Minting
    function mint(uint256 quantity) external payable onlyOwner {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(
            totalSupply() + quantity <= totalMint,
            "Can't min more than define total supply"
        );
        _safeMint(msg.sender, quantity);
    }

    function allowlistMint(uint256 quantity) external payable nonReentrant {
        require(
            totalSupply() + quantity <= totalMint,
            "Can't min more than define total supply"
        );
        require(
            allowlist[msg.sender] >= quantity,
            "not eligible for allowlist mint"
        );
        allowlist[msg.sender] = allowlist[msg.sender] - quantity;
        _safeMint(msg.sender, quantity);
    }

    function checkInAllowListForUser(address userAddress)
        external
        view
        returns (uint256)
    {
        require(allowlist[userAddress] > 0, "User Not in Standard Pack List");
        return allowlist[userAddress];
    }

    //End Minting

    function getStandardPack() external view returns (uint256) {
        return _totalStandardPacks;
    }

    function setStandardPack(uint256 totalStandardPack) external onlyOwner {
        _totalStandardPacks = totalStandardPack;
    }

    function getStandardPackFee() external view returns (uint256) {
        return _standardPackFee;
    }

    function setStandardPackFee(uint256 packFee) external onlyOwner {
        _standardPackFee = packFee;
    }

    function setStandardPackMint(uint256 mintNumber) external onlyOwner {
        _standardPackMint = mintNumber;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function seedAllowlist(
        address[] memory addresses,
        uint256[] memory numSlots
    ) external onlyOwner {
        require(
            addresses.length == numSlots.length,
            "addresses does not match numSlots length"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist[addresses[i]] = numSlots[i];
        }
    }

    function buyStandardPack(uint256 noOfPack) external payable nonReentrant {
        require(
            soldStandardPack <= _totalStandardPacks,
            "All Standard Packs has been sold"
        );
        require(
            balanceOf(msg.sender) <= _standardPackMint,
            "Maximum purchase limit reached"
        );
        require(_standardPackFee * noOfPack == msg.value, "Invalid Fee");
        _safeMint(msg.sender, noOfPack);
        soldStandardPack = soldStandardPack + noOfPack;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}