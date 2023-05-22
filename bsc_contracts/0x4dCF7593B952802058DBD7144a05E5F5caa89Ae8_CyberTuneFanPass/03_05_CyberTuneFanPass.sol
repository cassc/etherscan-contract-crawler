// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CyberTuneFanPass is ERC721A, Ownable {
    string private baseURI;

    uint256 private price = 0.01 ether;
    uint256 private totalCount = 7500;
    bool public mintIsActive = false;
    uint256 private maxMintCount = 10;

    constructor(address reserveHolder) ERC721A("CyberTune FanPass", "FanPass") {
        _mint(reserveHolder, 2500); //reserved for airdrop and giveaways
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function toggleMintIsActive() external onlyOwner {
        mintIsActive = !mintIsActive;
    }

    function withdrawBalance() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function safeMint(uint256 quantity) public payable {
        require(mintIsActive, "Mint is not active");
        require(quantity > 0, "Quantity must be greater than 0");
        require(
            balanceOf(msg.sender) + quantity <= maxMintCount,
            "Cannot mint more than 10"
        );
        require(
            _totalMinted() + quantity < totalCount,
            "Cannot mint more fanpass nft"
        );
        require(msg.value == quantity * price, "Not enough BNB to mint");

        _safeMint(msg.sender, quantity);
    }

    // ONLY OWNER FUNCTIONS
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit BaseUriChanged(_baseURI);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseURI));
    }

    /** @dev Emits event for when base URI changes */
    event BaseUriChanged(string indexed newBaseUri);
    event Received(address from, uint256 amount);
}