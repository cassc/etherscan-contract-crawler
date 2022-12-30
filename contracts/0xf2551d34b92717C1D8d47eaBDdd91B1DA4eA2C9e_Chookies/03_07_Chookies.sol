// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract Chookies is ERC721A("Chookies", "CHOOK"), ERC721AQueryable, Ownable {
    // Constants
    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant MAX_MINT_PER_WALLET = 6;

    // State variables
    uint256 public price = 0.003 ether;
    string public baseTokenURI = "ipfs://QmfFm4RmCLFBD5awHTnJvuc58VHri2mMJbjswE56555RgT/";
    bool public paused = true;

    // Mint function
    function mint(uint256 amount) external payable {
        require(!paused, "contract is paused");

        require(totalSupply() + amount <= MAX_SUPPLY, "max supply would be exceeded");
        uint minted = _numberMinted(msg.sender);

        require(minted + amount <= MAX_MINT_PER_WALLET, "max mint per wallet would be exceeded");

        uint chargeableCount;

        if (minted == 0) {
            chargeableCount = amount - 1;
            require(amount > 0, "amount must be greater than 0");
            require(msg.value >= price * chargeableCount, "value not met");
        } else {
            chargeableCount = amount;
            require(amount > 0, "amount must be greater than 0");
            require(msg.sender == tx.origin, "no smart contracts");
            require(msg.value >= price * chargeableCount, "value not met");
        }
        _safeMint(msg.sender, amount);
    }

    // Admin functions

    function ownerMint(uint256 amount, address recipient) external onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "max supply would be exceeded");
        _safeMint(recipient, amount);
    }

    function setPaused(bool updated) external onlyOwner {
        paused = updated;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        baseTokenURI = uri;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{ value: address(this).balance }("");
        require(success, "failed to withdraw Ether");
    }

    // Internal overrides

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}