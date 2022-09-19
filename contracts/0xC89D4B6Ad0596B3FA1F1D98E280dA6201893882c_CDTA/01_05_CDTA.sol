// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CDTA is ERC721A, Ownable {
    uint256 constant MAX_SUPPLY = 10000;
    uint256 private MAX_MINTS = 50;
    uint256 public mintPrice = 0.001 ether;
    string private _baseTokenURI = 'https://nftstorage.link/ipfs/bafybeigap6jghae4kbei37ydv7zuionhb6ad6mq4derf6yozrsq3rcrrci/';
    bool public isMintEnabled;

    constructor() ERC721A("Can't Do This Anymore", "CDTA") {}

    // Ensure the following requirements are met before allowing mint:
    // 1. Mint is enabled
    // 2. Mint quantity is less than maximum allowed mints per address
    //    (uses number minted by address, NOT current balance of address) 
    // 3. Total supply after minting does not exceed maximum supply (`MAX_SUPPLY`)
    // 4. Amount of ether sent in transaction is correct for minting
    function mint(uint256 quantity) external payable {
        require(isMintEnabled, "Minting is not enabled");
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS, "Exceeded mint limit per address");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Insufficient tokens left");
        require(msg.value == (mintPrice * quantity), "Incorrect value");

        _safeMint(msg.sender, quantity);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function toggleIsMintEnabled() external onlyOwner {
        isMintEnabled = !isMintEnabled;
    }

    function setMaxPerWallet(uint256 MAX_MINTS_) external onlyOwner {
        require(MAX_MINTS_ > 0, "Must be a positive number");
        require(MAX_MINTS_ <= MAX_SUPPLY, "Exceeds maximum supply");
        MAX_MINTS = MAX_MINTS_;
    }

    function setMintPrice(uint256 mintPrice_) external onlyOwner {
        mintPrice = mintPrice_;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}