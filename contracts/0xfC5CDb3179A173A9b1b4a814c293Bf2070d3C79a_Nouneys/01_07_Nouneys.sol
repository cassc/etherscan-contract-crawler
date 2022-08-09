// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Nouneys is ERC721A, Ownable {
    // Merkle Root for Presale
    bytes32 public presaleRoot;

    // Presale Active
    bool public isPresaleActive;

    // Sale Active
    bool public isSaleActive;

    // Price
    uint256 public price;

    // Current Season
    uint16 public season;

    // Treasury
    address public treasury;

    // Base URI
    string private baseURI;

    // Max per wallet for presale per season
    mapping(uint16 => uint16) public presaleMaxPerWallet;

    // Max per wallet for sale per season
    mapping(uint16 => uint16) public saleMaxPerWallet;

    // Max supply per season
    mapping(uint16 => uint256) public maxSupply;

    // Current supply per season
    mapping(uint16 => uint256) public currentSupply;

    // Tracks redeem for presale per season
    mapping(uint16 => mapping(address => uint16)) private presaleRedeemedCount;

    // Tracks redeem for sale per season
    mapping(uint16 => mapping(address => uint16)) private saleRedeemedCount;

    constructor(uint256 price_, address treasury_)
        ERC721A("Nouneys", "Nouneys")
    {
        price = price_;
        treasury = treasury_;
        isPresaleActive = false;
        isSaleActive = false;
    }

    function mint(uint16 quantity, bytes32[] calldata proof) external payable {
        require(isPresaleActive, "Presale Not Active");
        require(msg.value >= price * quantity, "Incorrect Value");
        require(
            maxSupply[season] >= currentSupply[season] + quantity,
            "Max Supply Exceeded"
        );
        require(
            presaleMaxPerWallet[season] >=
                presaleRedeemedCount[season][_msgSender()] + quantity,
            "Max Minted"
        );
        require(
            MerkleProof.verify(
                proof,
                presaleRoot,
                keccak256(abi.encodePacked(_msgSender()))
            ),
            "Not Eligible"
        );

        unchecked {
            presaleRedeemedCount[season][_msgSender()] =
                presaleRedeemedCount[season][_msgSender()] +
                quantity;
            currentSupply[season] = currentSupply[season] + quantity;
        }

        _mint(_msgSender(), quantity);
    }

    function mint(uint16 quantity) external payable {
        require(isSaleActive, "Sale Not Active");
        require(msg.value >= price * quantity, "Incorrect Value");
        require(
            maxSupply[season] >= currentSupply[season] + quantity,
            "Max Supply Exceeded"
        );
        require(
            saleMaxPerWallet[season] >=
                saleRedeemedCount[season][_msgSender()] + quantity,
            "Max Minted"
        );

        unchecked {
            saleRedeemedCount[season][_msgSender()] =
                saleRedeemedCount[season][_msgSender()] +
                quantity;
            currentSupply[season] = currentSupply[season] + quantity;
        }

        _mint(_msgSender(), quantity);
    }

    function withdraw() external {
        uint256 balance = address(this).balance;
        require(balance > 0, "0 balance");
        Address.sendValue(payable(treasury), balance);
    }

    function isEligiblePresale(bytes32[] calldata proof, address address_)
        external
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                proof,
                presaleRoot,
                keccak256(abi.encodePacked(address_))
            );
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPresaleRoot(bytes32 root) external onlyOwner {
        presaleRoot = root;
    }

    function setSeason(uint16 season_) external onlyOwner {
        season = season_;
    }

    function setMaxSupply(uint16 maxSupply_) external onlyOwner {
        maxSupply[season] = maxSupply_;
    }

    function setPresaleMaxPerWallet(uint16 maxPerWallet) external onlyOwner {
        presaleMaxPerWallet[season] = maxPerWallet;
    }

    function setSaleMaxPerWallet(uint16 maxPerWallet) external onlyOwner {
        saleMaxPerWallet[season] = maxPerWallet;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setTreasury(address treasury_) external onlyOwner {
        treasury = treasury_;
    }

    function togglePresaleActive() external onlyOwner {
        isPresaleActive = !isPresaleActive;
    }

    function toggleSaleActive() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function mint(address to, uint256 quantity) external onlyOwner {
        _safeMint(to, quantity);
    }

    function getMaxSupply() external view returns (uint256) {
        return maxSupply[season];
    }

    function getCurrentSupply() external view returns (uint256) {
        return currentSupply[season];
    }

    function getPresaleMaxPerWallet() external view returns (uint16) {
        return presaleMaxPerWallet[season];
    }

    function getSaleMaxPerWallet() external view returns (uint16) {
        return saleMaxPerWallet[season];
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}