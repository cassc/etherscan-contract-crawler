// SPDX-License-Identifier: MIT LICENSE
pragma solidity 0.8.11;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IPXLP {
    function rareAuctionMint(uint256 quantity) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function transferOwnership(address newOwner) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
}

contract PixelPandasVendingMachine is Ownable, IERC721Receiver, ReentrancyGuard {
    constructor(address _pixelPandasAddress) {
        pixelPandasContract = IPXLP(_pixelPandasAddress);
        MINT_INDEX = pixelPandasContract.totalSupply();
    }

    IPXLP pixelPandasContract;
    mapping(address => uint256) walletMintAmounts;

    uint256 public MAX_MINT_AMOUNT = 20;
    uint256 public MINT_INDEX;

    function mint(uint256 quantity) external nonReentrant {
        require(pixelPandasContract.totalSupply() + quantity <= 8888, "Sold out");
        require(quantity <= MAX_MINT_AMOUNT, "You cannot exceed the maximum mint amount");
        require(walletMintAmounts[msg.sender] + quantity <= MAX_MINT_AMOUNT, "You cannot exceed the maximum mint amount");
        walletMintAmounts[msg.sender] += quantity;

        // Call pixelpandas rareAuctionMint function
        pixelPandasContract.rareAuctionMint(quantity);

        // Transfer minted token from VendingMachine contract to user
        for(uint256 i = 1; i <= quantity; i++) {
            pixelPandasContract.transferFrom(address(this), msg.sender, MINT_INDEX + i);
        }

        MINT_INDEX += quantity;
    }

    // Setter functions
    function setMaxMintAmount(uint256 _newAmount) external onlyOwner {
        MAX_MINT_AMOUNT = _newAmount;
    }

    function setMintStartingIndex(uint256 _newIndex) external onlyOwner {
        MINT_INDEX = _newIndex;
    }

    function setPixelPandas(address _newAddress) external onlyOwner {
        pixelPandasContract = IPXLP(_newAddress);
    }

    function onERC721Received(
		address,
		address,
		uint256,
		bytes calldata
	) external pure override returns (bytes4) {
		return IERC721Receiver.onERC721Received.selector;
	}

    // Transfer ownership of Pixel Pandas contract
    function transferOwnershipOfPixelPandas(address _newOwner) external nonReentrant onlyOwner {
        pixelPandasContract.transferOwnership(_newOwner);
    }
}