// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface INFT {
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract ZorbViz is ERC721, Ownable, IERC2981 {
    using Strings for uint256;

    // zorb NFT contract address, mainnet: 0xCa21d4228cDCc68D4e23807E5e370C07577Dd152
    address public zorbNFT;

    address payable public royaltyRecipient;

    uint256 public constant PUBLIC_SALE_PRICE = 0.04 ether;

    string public baseURI;

    constructor(
        address _zorbNFT,
        address payable _royaltyRecipient,
        string memory _baseUri
    ) ERC721("Zorb Viz", "ZORBVIZ") {
        zorbNFT = _zorbNFT;
        royaltyRecipient = _royaltyRecipient;
        baseURI = _baseUri;
    }

    function mint(uint256 tokenId) external payable tokenIdInRange(tokenId) {
        if (INFT(zorbNFT).balanceOf(msg.sender) > 0) {
            _mint(msg.sender, tokenId);
        } else {
            require(
                PUBLIC_SALE_PRICE == msg.value,
                "Incorrect ETH value sent, must be .04 ether"
            );
            _mint(msg.sender, tokenId);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        return string(abi.encodePacked(baseURI, "/", tokenId.toString()));
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    // January 1, 2021: 1609480800
    modifier tokenIdInRange(uint256 tokenID) {
        uint256 numberOfDays = 1609480800 + tokenID * 1 days;

        require(
            tokenID > 0 && numberOfDays < block.timestamp,
            "Token ID is out of range"
        );
        _;
    }

    function withdraw() public {
        uint256 balance = address(this).balance;
        payable(royaltyRecipient).transfer(balance);
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");

        uint256 royaltyFee = 40; // 4%
        uint256 royaltyPayment = (salePrice * royaltyFee) / 1000;

        return (royaltyRecipient, royaltyPayment);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    fallback() external payable {}

    receive() external payable {}
}