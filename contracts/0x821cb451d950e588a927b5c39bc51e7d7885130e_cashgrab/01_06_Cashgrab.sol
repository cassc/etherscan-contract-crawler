//
//  ▄████████    ▄████████    ▄████████    ▄█    █▄       ▄██████▄     ▄████████    ▄████████ ▀█████████▄
// ███    ███   ███    ███   ███    ███   ███    ███     ███    ███   ███    ███   ███    ███   ███    ███
// ███    █▀    ███    ███   ███    █▀    ███    ███     ███    █▀    ███    ███   ███    ███   ███    ███
// ███          ███    ███   ███         ▄███▄▄▄▄███▄▄  ▄███         ▄███▄▄▄▄██▀   ███    ███  ▄███▄▄▄██▀
// ███        ▀███████████ ▀███████████ ▀▀███▀▀▀▀███▀  ▀▀███ ████▄  ▀▀███▀▀▀▀▀   ▀███████████ ▀▀███▀▀▀██▄
// ███    █▄    ███    ███          ███   ███    ███     ███    ███ ▀███████████   ███    ███   ███    ██▄
// ███    ███   ███    ███    ▄█    ███   ███    ███     ███    ███   ███    ███   ███    ███   ███    ███
// ████████▀    ███    █▀   ▄████████▀    ███    █▀      ████████▀    ███    ███   ███    █▀  ▄█████████▀
//                                                                    ███    ███

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract cashgrab is ERC721A, Ownable {
    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public constant MAX_MINT_PUBLIC = 10;

    string public baseURI = "";
    uint256 mintPrice = 0.077 ether;
    bool public whitelistMintEnabled = false;
    bool public publicMintEnabled = false;

    mapping(address => uint256) public whitelist;
    mapping(address => uint256) public publicTotalMinted;

    constructor() ERC721A("cashgrab", "CSHGRB") {}

    function whitelistMint(uint256 quantity) external payable {
        require(whitelistMintEnabled, "Whitelist mint is not active");
        require(
            whitelist[msg.sender] >= quantity,
            "Unauthorized mint quantity for user"
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Quantity exceeds max supply"
        );
        _mint(msg.sender, quantity);
        whitelist[msg.sender] -= quantity;
    }

    function publicMint(uint256 quantity) external payable {
        require(publicMintEnabled, "Public mint is not active");
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Quantity exceeds max supply"
        );
        require(
            publicTotalMinted[msg.sender] + quantity <= MAX_MINT_PUBLIC,
            "Wallet public mint limit reached"
        );
        require(msg.value == getMintCost(quantity), "Incorrect mint price");
        _mint(msg.sender, quantity);
        publicTotalMinted[msg.sender] += quantity;
    }

    function getMintCost(uint256 quantity) public view returns (uint256) {
        return mintPrice * quantity;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721A)
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function toggleWhitelistMint() external onlyOwner {
        whitelistMintEnabled = !whitelistMintEnabled;
    }

    function togglePublicMint() external onlyOwner {
        publicMintEnabled = !publicMintEnabled;
    }

    function setMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
    }

    function setWhitelist(address[] calldata addresses, uint256 mintQuantity)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = mintQuantity;
        }
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function withdrawFunds() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}