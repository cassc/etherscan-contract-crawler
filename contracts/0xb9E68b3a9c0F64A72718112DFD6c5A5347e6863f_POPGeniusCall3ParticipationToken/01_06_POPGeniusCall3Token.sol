// SPDX-License-Identifier: MIT

// Contract by @Montana_Wong

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "erc721a/contracts/ERC721A.sol";

contract POPGeniusCall3ParticipationToken is ERC721A, Ownable {

    uint256 public maxMintsPerWallet = 1;
    uint256 public maxSupply = 999; // Total number of NFTs that can be minted

    string public baseURI; // Base URI for token metadata

    bool public isMintEnabled = false;

    address private POP_TOKEN_ADDRESS = 0x7Eaa96D48380802A75ED6d74b91E2B30c3d474C1;

    constructor(string memory _baseTokenURI) ERC721A("POP Genius Call #3 Participation Token", "POPGENIUS3") {
        setBaseURI(_baseTokenURI);
    }

    function toggleMinting() external onlyOwner {
        isMintEnabled = !isMintEnabled;
    }

    function setMaxSupply(uint256 n) external onlyOwner {
        require(n > totalSupply(), "Cannot set supply to be lower than current outstanding tokens");
        maxSupply = n;
    }
    function setMaxMintsPerWallet(uint256 n) external onlyOwner {
        maxMintsPerWallet = n;
    }

    function mint() external payable {
        // Check if Minting has been enabled
        require(isMintEnabled, "Minting is not enabled");

        // Check if the wallet holds a POP NFT
        uint256 numPopTokensHeldByUser = ERC721A(POP_TOKEN_ADDRESS).balanceOf(msg.sender);
        require(numPopTokensHeldByUser > 0, "Must hold a CPGPOP token");

        // See if wallet has already minted
        uint256 numMintedByUser  = _numberMinted(msg.sender);
        require(numMintedByUser < maxMintsPerWallet, "Exceeded maximum mints per wallet");

        // See if the max number of tokens have already been minted
        uint256 totalSupply = totalSupply();
        require(totalSupply < maxSupply, "Maximum number of tokens have been minted in this collection.");

        _mint(msg.sender, 1);
    }

    // Allow the owner of the contract to mint NFTs
    function adminMint(address to, uint256 count) external onlyOwner {
        // See if the max number of tokens have already been minted
        require(totalSupply() < maxSupply, "Maximum number of tokens have been minted.");

        _mint(to, count);
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseURI = _baseTokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // Send balance of contract to owner
    function release() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }
}