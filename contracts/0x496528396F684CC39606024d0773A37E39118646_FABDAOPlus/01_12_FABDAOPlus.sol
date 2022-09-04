//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma abicoder v2; // required to accept structs as function parameters

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

/**
 @title FABDAOPlus
 @author Lee Ting Ting @tina1998612
 */
contract FABDAOPlus is Ownable, ERC721A {
    using Address for address;

    string private baseTokenURI;

    uint256 public constant mintPrice = 10 ether;
    uint256 public constant maxMintLimitPerAddr = 5;
    uint256 public constant MAX_SUPPLY = 100;
    address public constant reserver = 0x952936E60B9a9E2E9B2950599694aFE9Ff8a8a4a;

    mapping(address => uint256) public _mintedCountsPublic;

    modifier onlyReserver () {
        require(_msgSender() == reserver || _msgSender() == owner(), "No access to reserve NFT");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI
    ) ERC721A(_name, _symbol) { // version 1
        baseTokenURI = _baseTokenURI;
    }

    /// @notice Public mint 
    function mint(address to, uint256 amount) external payable {
        // check if exceed maxMintCount
        require(amount + _mintedCountsPublic[to]<= maxMintLimitPerAddr, "Exceed maxMintCount per address");
        // check if Exceed max total supply
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceed max total supply");
        // check fund
        require(msg.value >= mintPrice * amount, "Not enough fund to mint NFT");
        // mint
        super._safeMint(to, amount);
        // increase minted count
        _mintedCountsPublic[to] += amount;
    }

    /// @dev Reserve NFT. The contract owner can mint NFTs for free.
    function reserve(address to, uint256 amount) external onlyReserver {
        // check if Exceed max total supply
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceed max total supply");
        super._safeMint(to, amount);
    }

    /// @dev Withdraw. The contract owner can withdraw all ETH from the NFT sale
    function withdraw() external onlyReserver {
        Address.sendValue(payable(_msgSender()), address(this).balance);
    }

    /// @dev Set new baseURI
    function setBaseURI(string memory baseURI) external onlyReserver {
        baseTokenURI = baseURI;
    }

    /// @dev override _baseURI()
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}