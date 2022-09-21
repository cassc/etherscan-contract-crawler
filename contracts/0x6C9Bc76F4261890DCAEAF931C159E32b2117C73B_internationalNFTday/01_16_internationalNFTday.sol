//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/nftERC721A/ERC721A.sol";

contract internationalNFTday is ERC721URIStorage, Ownable, ReentrancyGuard {
    bool public publicMintActive = false;
    bool public burnProfileActive = false;
    uint256 public maxSupply = 2009;
    string public baseURI;
    uint256 public currentSupply = 1;

    // event Attest(address indexed to, uint256 _tokenId);
    // event Revoke(address indexed to, uint256 _tokenId);
    event NewNFTMinted(address sender, uint256 tokenId, string tokenURI);

    constructor() ERC721("NFT Day", "NFT-DAY") {
        console.log("This is upgradableNFT smart contract");
        // owner = _msgSenderERC721A();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Invalid token Id");

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length != 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    //base URI
    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    fallback() external payable {}

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function mintNft() public {
        //uncoment the require later
        require(balanceOf(msg.sender) < 3, "Max limit is only one per User");
        require(publicMintActive, "Wait for the party to start");
        require(currentSupply + 1 <= maxSupply, "Max NFTs are minted");
        uint256 supplyNo = currentSupply % 30;
        uint256 itemId = 1;
        if (supplyNo != 0) {
            itemId = supplyNo;
        } else {
            itemId = 30;
        }

        _safeMint(msg.sender, currentSupply);

        _setTokenURI(currentSupply, tokenURI(itemId));
        emit NewNFTMinted(msg.sender, itemId, tokenURI(itemId));

        currentSupply = currentSupply + 1;

        console.log(
            "An NFT w/ ID %s has been minted to %s",
            itemId,
            msg.sender
        );
    }

    //when user deletes the profile
    function burnToken(uint256 tokenId) external {
        require(burnProfileActive, "Wait for your profile probation to end");
        require(
            ownerOf(tokenId) == msg.sender,
            "Yoo, you are not the owner of the token."
        );
        _burn(tokenId);
    }

    function setMaxSupply(uint64 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPublicMintActive(bool _publicMintActive) external onlyOwner {
        publicMintActive = _publicMintActive;
    }

    function setBurnProfileActive(bool _burnProfileActive) external onlyOwner {
        burnProfileActive = _burnProfileActive;
    }
}