//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

abstract contract CommonNft is Ownable, ERC721A, ReentrancyGuard {
    struct Config {
        uint256 maxSupply;
        uint256 reserved;
        uint256 firstFreeMint;
        uint256 mintPrice;
        uint256 maxTokenPerAddress;
        string baseTokenUrl;
    }
    Config public config;
    bool public isMintStarted;

    constructor(string memory name_, string memory symbol_, Config memory config_)
        ERC721A(name_, symbol_)
    {
        config = config_;
        isMintStarted = false;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _baseURI() internal view override returns (string memory) {
        return config.baseTokenUrl;
    }

    function setConfig(Config calldata config_) external onlyOwner {
        config = config_;
    }

    function toggleMintStart() external onlyOwner {
        isMintStarted = !isMintStarted;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function airdrop(
        address[] calldata addresses,
        uint256[] calldata quantities
    ) external nonReentrant onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], quantities[i]);
        }
    }

    function mint(uint256 quantity) external payable virtual;
}