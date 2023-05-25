// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// @title:  Laser Cat
// @desc:   Build Share To Earn Community
// @artist: https://twitter.com/BitCloutCat
// @url:    https://www.lasercat.co/

/*
██╗░░░░░░█████╗░░██████╗███████╗██████╗░░█████╗░░█████╗░████████╗
██║░░░░░██╔══██╗██╔════╝██╔════╝██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝
██║░░░░░███████║╚█████╗░█████╗░░██████╔╝██║░░╚═╝███████║░░░██║░░░
██║░░░░░██╔══██║░╚═══██╗██╔══╝░░██╔══██╗██║░░██╗██╔══██║░░░██║░░░
███████╗██║░░██║██████╔╝███████╗██║░░██║╚█████╔╝██║░░██║░░░██║░░░
╚══════╝╚═╝░░╚═╝╚═════╝░╚══════╝╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░
*/

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract LaserCat is ERC721A, IERC2981, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    // ======== Supply =========
    uint256 public MaxSupply;
    uint256 public MaxReserveMint;
    uint256 public AuctionEpochSupply;
    uint256 public CurrentAuctionSupply;

    // ========= Price =========
    uint256 public whiteListMintPrice = 0.2 ether;

    // ======== Royalties =========
    address public royaltyAddress;
    uint256 public royaltyPercent;

    // ======== Auction Config =========
    bool public isAuctionMintStart;

    uint256 public auctionStartPrice;
    uint256 public auctionEndPrice;
    uint256 public auctionPriceCurveLength;
    uint256 public auctionStartTime;
    uint256 public auctionDiscountPerStep;
    uint256 public epochInterval;
    uint256 public epochSupply;

    // ======== Metadata =========
    bytes32 public root;
    address private singer;
    address private vault;
    string private _baseTokenURI;
    

    constructor(uint256 _MaxSupply, uint256 _MaxReserveMint, address _vault)
        ERC721A("LaserCat", "Cat", 1, _MaxSupply)
    {
        royaltyAddress = owner();
        royaltyPercent = 5;
        MaxSupply = _MaxSupply;
        MaxReserveMint = _MaxReserveMint;
        vault = _vault;
    }

    modifier eoaOnly() {
        require(tx.origin == msg.sender, "EOA Only");
        _;
    }

    // ======== Minting =========
    function whiteListMint(bytes32[] memory _proof)
        external
        payable
        nonReentrant
        eoaOnly
    {
        require(!isAuctionMintStart, "WhiteList not avalible for now");

        require(numberMinted(msg.sender) == 0, "Already mint LaserCat");

        require(_whitelistVerify(_proof), "Invalid merkle proof");

        require(totalSupply() <= MaxSupply, "Exceed max token supply");

        _safeMint(msg.sender, 1);

        makeChange(whiteListMintPrice);
    }

    function auctionMint(bytes memory _signature)
        external
        payable
        nonReentrant
        eoaOnly
    {
        require(isAuctionMintStart, "Auction not avalible for now");

        require(_auctionVerify(_signature), "Get vifery signature fist");

        require(numberMinted(msg.sender) == 0, "Already mint LaserCat");

        require(totalSupply() + 1 <= MaxSupply, "Exceed max token supply");

        require(
            totalSupply() + 1 <= AuctionEpochSupply,
            "Not enough remaining reserved for auction"
        );

        uint256 currentPrice = getAuctionPrice();

        _safeMint(msg.sender, 1);

        makeChange(currentPrice);
    }

    function reserveMint(address _reserveAddr, uint256 quantity)
        external
        onlyOwner
    {
        require(
            totalSupply() + quantity <= MaxSupply,
            "Exceed max token supply"
        );
        require(quantity <= MaxReserveMint, "Exceed max reserve supply");

        MaxReserveMint -= quantity;

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(_reserveAddr, 1);
        }
    }

    function makeChange(uint256 _price) private {
        require(msg.value >= _price, "Insufficient ether amount");
        if (msg.value > _price) {
            payable(msg.sender).transfer(msg.value - _price);
        }
    }

    // ======== View Function =========
    function getAuctionPrice() public view returns (uint256) {
        if (block.timestamp < auctionStartTime) {
            return auctionStartPrice;
        }
        if (block.timestamp - auctionStartTime >= auctionPriceCurveLength) {
            return auctionEndPrice;
        } else {
            uint256 steps = (block.timestamp - auctionStartTime) /
                epochInterval;
            return auctionStartPrice - (steps * auctionDiscountPerStep);
        }
    }

    function _whitelistVerify(bytes32[] memory _proof)
        internal
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                _proof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            );
    }

    function _auctionVerify(bytes memory signature)
        internal
        view
        returns (bool)
    {
        return
            keccak256(abi.encode(msg.sender, singer))
                .toEthSignedMessageHash()
                .recover(signature) == singer;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Non-existent token");
        return (royaltyAddress, (salePrice * royaltyPercent) / 100);
    }

    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    // ======== Manager Only =========

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setWhitelistRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function setAuctionMintState(bool _state) external onlyOwner {
        require(isAuctionMintStart != _state, "Set with same value.");
        require(
            getAuctionPrice() >= whiteListMintPrice,
            "Auction paramters not set correctly"
        );

        isAuctionMintStart = _state;
    }

    function setSinger(address _singer) external onlyOwner {
        singer = _singer;
    }

    function setAuctionConfig(
        uint256 _auctionStartPrice,
        uint256 _auctionEndPrice,
        uint256 _auctionStartTime,
        uint256 _epochInterval,
        uint256 _epochSupply,
        uint256 _auctionPriceCurveLength
    ) external onlyOwner {
        require(_auctionEndPrice < _auctionStartPrice, "Set with wrong price");
        require(
            _auctionPriceCurveLength > 0 && _epochInterval > 0,
            "Auction config not correctly"
        );
        require(_epochSupply > 0, "Epoch supply must more than zero");
        require(
            _auctionStartTime > block.timestamp,
            "Must start of the future time"
        );

        auctionStartTime = _auctionStartTime;

        auctionStartPrice = _auctionStartPrice;
        auctionEndPrice = _auctionEndPrice;

        auctionPriceCurveLength = _auctionPriceCurveLength;

        epochInterval = _epochInterval;
        epochSupply = _epochSupply;

        AuctionEpochSupply = totalSupply() + _epochSupply;
        CurrentAuctionSupply = _epochSupply;

        auctionDiscountPerStep =
            (auctionStartPrice - auctionEndPrice) /
            (auctionPriceCurveLength / epochInterval);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(vault).transfer(balance);
    }

    // ======== Royalties =========

    function setRoyaltyReceiver(address royaltyReceiver) public onlyOwner {
        royaltyAddress = royaltyReceiver;
    }

    function setRoyaltyPercentage(uint256 royaltyPercentage) public onlyOwner {
        royaltyPercent = royaltyPercentage;
    }
}