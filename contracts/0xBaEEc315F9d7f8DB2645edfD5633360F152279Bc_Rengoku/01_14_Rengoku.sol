//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract Rengoku is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Address for *;
    Counters.Counter private _tokenIds;
    Counters.Counter private _reservedIds;

    address private _owner1;
    address private _owner2;

    uint256 public tokenPrice = .08787 ether; //

    uint16 public maxPurchaseable = 7;

    uint16 public constant MAX_SUPPLY = 8787;

    bool public saleIsActive = true;
    uint256 public saleStartDate;
    uint256 public preSaleStartDate;

    bytes32 private immutable whitelistRoot;

    mapping(address => uint256) public addressToNumTokensOwned;
    mapping(uint256 => uint256) private claimedBitMap;
    string private _baseTokenURI = "https://rengoku-nft.s3.amazonaws.com/";

    constructor(
        uint256 saleStart,
        uint256 _preSaleStartDate,
        bytes32 _whitelistRoot,
        address owner1,
        address owner2
    ) ERC721("Rengoku", "REN") {
        saleStartDate = saleStart; // just a default date
        preSaleStartDate = _preSaleStartDate;
        whitelistRoot = _whitelistRoot;
        _owner1 = owner1;
        _owner2 = owner2;
    }

    function mintWhitelist(
        uint256 index,
        bytes32[] calldata merkleProof,
        uint256 amountReserved,
        uint256 amountToBuy
    ) external payable {
        require(saleIsActive, "Not active");
        require(block.timestamp >= preSaleStartDate, "Presale must be active");
        require(
            !isClaimed(index),
            "You have already minted your alloted amount"
        );
        bytes32 node = keccak256(
            abi.encodePacked(index, msg.sender, amountReserved)
        );
        require(
            MerkleProof.verify(merkleProof, whitelistRoot, node),
            "MerkleDistributor: Invalid proof."
        );
        if (amountReserved == 1) {
            require(
                block.timestamp - preSaleStartDate > 1 days,
                "phase 2 sale not active yet"
            );
        }
        require(
            block.timestamp < preSaleStartDate + 2 days,
            "Presale has ended"
        );
        address account = msg.sender;
        uint256 newMinted = addressToNumTokensOwned[account] + amountToBuy;
        require(newMinted <= amountReserved, "User attempting to buy too many");

        if (addressToNumTokensOwned[account] == amountReserved) {
            _setClaimed(index);
        }
        _runMint(account, amountToBuy);
    }

    // /**
    //  * Public Sale
    //  */
    function mint(uint256 numberOfTokens) external payable {
        require(block.timestamp >= saleStartDate, "Sale not yet active");
        require(
            numberOfTokens != 0 && numberOfTokens <= maxPurchaseable,
            "0/limit"
        );
        require(saleIsActive, "Sale not activated");
        _runMint(msg.sender, numberOfTokens);
    }

    function _runMint(address account, uint256 amountToBuy) private {
        uint256 totalCost = amountToBuy.mul(tokenPrice);
        require(totalCost <= msg.value, "Not enough Ether sent for purchase");
        require(
            _tokenIds.current() + amountToBuy <= MAX_SUPPLY,
            "not enough supply of tokens"
        );
        require(
            addressToNumTokensOwned[account] + amountToBuy <= maxPurchaseable,
            "mint limit reached"
        );

        addressToNumTokensOwned[account] += amountToBuy;
        for (uint256 i = 0; i < amountToBuy; i++) {
            require(
                _tokenIds.current() + 1 <= MAX_SUPPLY,
                "Token supply limit reach"
            );
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _mint(account, newItemId);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        "rengoku-",
                        Strings.toString(tokenId),
                        "-nft.json"
                    )
                )
                : "";
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] =
            claimedBitMap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function burnToken(uint256 tokenId) external {
        require(_exists(tokenId), "token not found");
        require(
            msg.sender == ERC721.ownerOf(tokenId),
            "must be owner of token"
        );
        _burn(tokenId);
    }

    function getPrice(uint256 amountToBuy) public view returns (uint256) {
        return amountToBuy.mul(tokenPrice);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        Address.sendValue(payable(_owner1), balance / 2);
        Address.sendValue(payable(_owner2), balance / 2);
    }

    function withdrawOwner() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }

    function setSaleActive(bool active) public onlyOwner {
        saleIsActive = active;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory newURI) external onlyOwner {
        _baseTokenURI = newURI;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        tokenPrice = newPrice;
    }

    function setSaleStartDate(uint256 newSaleStartDate) external onlyOwner {
        saleStartDate = newSaleStartDate;
    }

    function setPresaletartDate(uint256 newDate) external onlyOwner {
        preSaleStartDate = newDate;
    }

    function setMaxPurchaseable(uint16 newMax) external onlyOwner {
        maxPurchaseable = newMax;
    }

    function getTime() external view returns (uint256, uint256) {
        return (block.timestamp, preSaleStartDate);
    }

    /**
     * Reserve some Samurai
     */
    function reserveTokens(uint32 numToReserve) public onlyOwner {
        uint256 supply = _tokenIds.current();
        require(
            (MAX_SUPPLY - supply) >= numToReserve,
            "Not enough tokens to reserve"
        );

        for (uint8 i = 0; i < numToReserve; i++) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _mint(msg.sender, newItemId);
        }
    }
}