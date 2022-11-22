/**
 *Submitted for verification at Etherscan.io on 2022-11-21
 */

// SPDX-License-Identifier: MIT
// Creator: World Cup Rabbit Club

pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract WorldCupRabbitNFT is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0.041 ether;
    uint256 public maxSupply = 400;
    uint256 public MaxperWallet = 10;
    bool public paused = false;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor(string memory _initBaseURI)
        ERC721A("WorldCupRabbitNFT", "Rabbit")
    {
        setBaseURI(_initBaseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mint(uint256 tokens) public payable nonReentrant callerIsUser {
        require(!paused, "oops contract is paused");
        require(totalSupply() + tokens <= maxSupply, "We Soldout");
        require(
            _numberMinted(_msgSenderERC721A()) + tokens <= MaxperWallet,
            "Max NFT Per Wallet exceeded"
        );
        require(msg.value >= cost * tokens, "insufficient funds");

        _safeMint(_msgSenderERC721A(), tokens);
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
            "ERC721AMetadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function isOwnerCall() public view onlyOwner returns (bool) {
        unchecked {
            return owner() == _msgSenderERC721A();
        }
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _checkOwner();
        unchecked {
            baseURI = _newBaseURI;
        }
    }

    function numberMinted(address owner)
        external
        view
        onlyOwner
        returns (uint256)
    {
        _checkOwner();
        unchecked {
            return _numberMinted(owner);
        }
    }

    function showBalance() external view onlyOwner returns (uint256) {
        _checkOwner();
        unchecked {
            return address(this).balance;
        }
    }

    function pause(bool _state) external onlyOwner nonReentrant {
        _checkOwner();
        unchecked {
            paused = _state;
        }
    }

    function withdraw() external payable onlyOwner nonReentrant {
        _checkOwner();
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
}