//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

/**
 @title BardsNFT
 @author Lee Ting Ting ([email protected])
 */
contract BardsNFT is Ownable, ERC721A {
    using Address for address;

    string private baseTokenURI;

    uint256 public mintPrice = 99999999 ether; // set later, different for each stage
    uint256 public currentMaxSupply; // set later, different for each stage
    uint256 public currentMintedCnt; // set later, different for each stage
    uint256 public constant MAX_SUPPLY = 150;

    string public contractMeta;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        string memory _contractMeta
    ) ERC721A(_name, _symbol) {
        baseTokenURI = _baseTokenURI;
        contractMeta = _contractMeta;
    }

    function contractURI() public view returns (string memory) {
        return contractMeta;
    }

    function updateStage(uint256 _mintPrice, uint256 _currentMaxSupply) external onlyOwner {
        // mint all the previous stage left NFTs to the owner
        if(currentMaxSupply - currentMintedCnt > 0) reserve(owner(), currentMaxSupply - currentMintedCnt);

        mintPrice = _mintPrice;
        currentMaxSupply = _currentMaxSupply;
        currentMintedCnt = 0;
    }

    /// @notice Public mint
    function mint(address to, uint256 amount) external payable {
        // check if Exceed max total supply
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceed max total supply");
        require(currentMintedCnt + amount <= currentMaxSupply, "Exceed max current supply");
        // check fund
        require(msg.value >= mintPrice * amount, "Not enough fund to mint NFT");
        currentMintedCnt += amount;
        // mint
        super._safeMint(to, amount);
    }

    /// @dev Reserve NFT. The contract owner can mint NFTs for free.
    function reserve(address to, uint256 amount) public onlyOwner {
        // check if Exceed max total supply
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceed max total supply");
        require(currentMintedCnt + amount <= currentMaxSupply, "Exceed max current supply");
        currentMintedCnt += amount;
        super._safeMint(to, amount);
    }

    /// @dev Withdraw. The contract owner can withdraw all ETH from the NFT sale
    function withdraw() external onlyOwner {
        Address.sendValue(payable(_msgSender()), address(this).balance);
    }

    /// @dev Set new baseURI
    function setBaseURI(string memory baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    /// @dev override _baseURI()
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}