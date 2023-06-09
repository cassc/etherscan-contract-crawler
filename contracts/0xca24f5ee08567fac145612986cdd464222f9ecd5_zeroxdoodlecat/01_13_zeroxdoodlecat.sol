//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract zeroxdoodlecat is ERC721A, ReentrancyGuard, Ownable {
    string private baseURI;

    uint256 private presalePrice = 0.0069 ether;
    uint256 private publicPrice = 0.009 ether;
    uint256 private reserved = 100;

    bool private saleStatus;
    bool private revealStatus;

    mapping(address => uint256) private mintOG;

    constructor() ERC721A("0xDoodleCat", "0xDoodleCat") {}

    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setSaleStatus() external onlyOwner {
        saleStatus = !saleStatus;
    }

    function getReservedAmount() public view returns (uint256) {
        return reserved;
    }

    // Mint Function

    function mintNFT(uint256 amount) public payable nonReentrant {
        address sender = _msgSender();
        uint256 NFTcount = totalSupply();
        require(saleStatus, "Sale is not started yet");
        require(amount > 0, "NFT amount must greater than 0");
        if (NFTcount < 666) {
            require(mintOG[sender] + amount <= 3, "Max 3 NFT per OG Wallet");
            mintOG[sender] += amount;
            _safeMint(sender, amount);
        } else if (666 <= NFTcount && NFTcount < 4000) {
            require(
                NFTcount + amount <= collectionSize - reserved,
                "NFTs in sale is lower than amount"
            );
            require(
                amount * presalePrice <= msg.value,
                "Ether amount mustn't less than the price"
            );
            _safeMint(sender, amount);
        } else if (4000 <= NFTcount) {
            require(
                NFTcount + amount <= collectionSize - reserved,
                "NFTs in sale is lower than amount"
            );
            require(
                amount * publicPrice <= msg.value,
                "Ether amount mustn't less than the price"
            );
            _safeMint(sender, amount);
        } else {
            revert("Sale is not started yet for this phase");
        }
    }

    function giveaway(address _to, uint256 amount) external onlyOwner {
        require(_to != address(0), "Cannot give NFT to address 0");
        require(
            amount <= reserved,
            "Supply NFT in reserved is less than amount"
        );
        reserved -= amount;
        _safeMint(_to, amount);
    }

    // Reveal Mechanism

    function setReveal() external onlyOwner {
        revealStatus = !revealStatus;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (!revealStatus) {
            return baseURI;
        }
        return super.tokenURI(tokenId);
    }

    // Withdraw Balance

    address private payoutAddress = 0xb7b35A462804CFcBC30887f51ec14B6ceA1AFeE7;

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(payoutAddress).transfer(balance);
    }
}