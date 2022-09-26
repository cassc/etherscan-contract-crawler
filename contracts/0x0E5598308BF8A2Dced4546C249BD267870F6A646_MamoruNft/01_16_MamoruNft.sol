// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./IMamoruNft.sol";

/**
 * NFT sale contract
 *
 * Notice: with whitelist, pre-sale, public-sale
 */
contract MamoruNft is ERC721Enumerable, Ownable, IMamoruNft, ReentrancyGuard {
    using Strings for uint256;

    // max supply of nft
    uint256 public maxSupply = 10000;

    // max token mints per address(include preSale)
    uint256 public maxMintsPerAddress = 10;

    // max token mints per transaction
    uint256 public maxMintsPerTx = 6;

    // public sale time
    uint256 public publicSaleStartAt = 1664380800;

    // user address -> mint count (store the mint count of each address)
    mapping(address => uint256) public addressToMints;

    // Used for random index assignment
    mapping(uint256 => uint256) private _tokenIdMatrix;

    // pre sale price
    uint256 public preSalePrice = 0.001 ether;

    // public sale price
    uint256 public publicSalePrice = 0.01 ether;

    // token uri prefix
    string public baseURI;

    // current sale phase
    SalePhase public salePhase = SalePhase.LOCKED;

    // whitelist merkle root
    bytes32 public whitelistMerkleRoot;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint256 _maxSupply
    ) ERC721(_name, _symbol) {
        baseURI = _baseURI;
        maxSupply = _maxSupply;
    }

    // ======================================================== External Functions

    /**
     * Owner set new max supply.
     * @param _maxSupply New max supply.
     *
     * Requirements:
     * To avoid token id conflicts, New max supply cannot exceed original max.
     *
     * Emits a {MaxSupply} event.
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(_maxSupply > totalSupply(), "Less than total supply");
        require(_maxSupply <= maxSupply, "Exceed original max");
        maxSupply = _maxSupply;
        emit MaxSupplySet(_maxSupply);
    }

    /**
     * Owner set max mints per address.
     * @param _maxMintsPerAddress New max mints per address.
     *
     * Requirements:
     * Only owner can call this method.
     *
     * Emits a {MaxMintsPerAddressSet} event.
     */
    function setMaxMintsPerAddress(uint256 _maxMintsPerAddress) external onlyOwner {
        maxMintsPerAddress = _maxMintsPerAddress;
        emit MaxMintsPerAddressSet(_maxMintsPerAddress);
    }

    /**
     * Owner set max mints per transaction.
     * @param _maxMintsPerTx New max mints per tx.
     *
     * Emits a {MaxMintsPerTxSet} event.
     */
    function setMaxMintsPerTx(uint256 _maxMintsPerTx) external onlyOwner {
        require(_maxMintsPerTx <= maxMintsPerAddress, "Invalid max mints per tx");
        maxMintsPerTx = _maxMintsPerTx;
        emit MaxMintsPerTxSet(_maxMintsPerTx);
    }

    /**
     * Set the start time of the public sale.
     * @param _publicSaleStartAt New public sale start time.
     *
     * Emits a {PublicSaleStartTimeSet} event.
     */
    function setPublicSaleStartAt(uint256 _publicSaleStartAt) external onlyOwner {
        publicSaleStartAt = _publicSaleStartAt;
        emit PublicSaleStartTimeSet(_publicSaleStartAt);
    }

    /**
     * Set new pre-sale price.
     * @param _preSalePrice New pre-sale price.
     *
     * Emits a {PreSalePriceSet} event.
     */
    function setPreSalePrice(uint256 _preSalePrice) external onlyOwner {
        preSalePrice = _preSalePrice;
        emit PreSalePriceSet(_preSalePrice);
    }

    /**
     * Set new public-sale price.
     * @param _publicSalePrice New public-sale price.
     *
     * Emits a {PublicSalePriceSet} event.
     */
    function setPublicSalePrice(uint256 _publicSalePrice) external onlyOwner {
        publicSalePrice = _publicSalePrice;
        emit PublicSalePriceSet(_publicSalePrice);
    }

    /**
     * Owner set new whitelist merkle root.
     * @param _whitelistMerkleRoot New whitelist merkle root.
     *
     * Requirements:
     * Only owner can call this method.
     *
     * Emits a {WhitelistMerkleRootSet} event.
     */
    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot) external onlyOwner {
        whitelistMerkleRoot = _whitelistMerkleRoot;
        emit WhitelistMerkleRootSet(_whitelistMerkleRoot);
    }

    /**
     * Advance the sale phase state.
     * @param _salePhase New sale phase.
     *
     * Requirements:
     * Advances sale phase state incrementally.
     *
     * Emits a {EnterPhase} event.
     */
    function enterPhase(SalePhase _salePhase) external onlyOwner {
        require(uint8(_salePhase) > uint8(salePhase), "Can only advance phases");
        salePhase = _salePhase;
        emit EnterPhase(_salePhase);
    }

    /**
     * Mint nft.
     *
     * @param count Mint count.
     * @param merkleProof If in public-sale phase, merkleProof can be `[]`.
     *
     * Emits a {Mint} event.
     */
    function mint(uint256 count, bytes32[] calldata merkleProof) external payable nonReentrant {
        // check ether payment
        _validEthPayment(count);
        // check supply
        require(totalSupply() + count <= maxSupply, "Exceed max supply");
        // check max mints per address
        require(count + addressToMints[_msgSender()] <= maxMintsPerAddress, "Exceed max mints per address");
        // check max token mints per tx
        require(count <= maxMintsPerTx, "Exceeds max per tx");
        if (salePhase == SalePhase.PRE_SALE) {
            // if is pre-sale phase, should verify whitelist
            require(
                MerkleProof.verify(merkleProof, whitelistMerkleRoot, keccak256(abi.encodePacked(_msgSender()))),
                "Invalid merkle proof"
            );
        } else if (salePhase == SalePhase.PUBLIC_SALE) {
            // solhint-disable-next-line not-rely-on-time
            require(block.timestamp >= publicSaleStartAt, "Public sale has not started");
        }

        // increase the mint count of user
        addressToMints[_msgSender()] += count;

        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = _nextToken();
            require(!_exists(tokenId), "token id already exists");
            _safeMint(_msgSender(), tokenId);
            emit Mint(_msgSender(), tokenId);
        }
    }

    /**
     * Owner set new base URI.
     * @param _baseURI new base URI to be set.
     *
     * Requirements:
     * Only owner can call this method.
     *
     * Emits a {BaseURISet} event.
     */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        require(bytes(baseURI).length > 0, "invalid baseURI");
        baseURI = _baseURI;
        emit BaseURISet(_baseURI);
    }

    /**
     * Withdraw balance.
     *
     * Requirements:
     * Only owner can call this method.
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        // solhint-disable-next-line avoid-low-level-calls
        (bool success,) = _msgSender().call{value : balance}("");
        require(success, "Failed to send to owner");
        emit Withdraw(_msgSender(), balance);
    }

    //    /**
    //     * destruct.
    //     *
    //     * Requirements:
    //     * Only owner can call this method.
    //     */
    //    function kill() external onlyOwner {
    //        // destruct
    //        selfdestruct(payable(_msgSender()));
    //    }

    // ======================================================== Public Functions

    /**
     * Get token URI of nft by token id.
     *
     * @param tokenId Nft id.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    // ======================================================== Internal Functions

    function _validEthPayment(uint256 _count) internal view {
        if (salePhase == SalePhase.PRE_SALE) {
            // pre-sale phase
            require(msg.value >= preSalePrice * _count, "Not enough ether sent");
        } else if (salePhase == SalePhase.PUBLIC_SALE) {
            // public-sale phase
            require(msg.value >= publicSalePrice * _count, "Not enough ether sent");
        } else {
            revert("Sale is not active");
        }
    }

    /**
     * Get the next token ID.
     * @dev Randomly gets a new token ID and keeps track of the ones that are still available.
     * @return the next token ID
     */
    function _nextToken() internal returns (uint256) {
        uint256 maxIndex = maxSupply - totalSupply();
        uint256 random = uint256(
        // solhint-disable-next-line not-rely-on-time
            keccak256(abi.encodePacked(msg.sender, block.coinbase, block.difficulty, block.gaslimit, block.timestamp))
        ) % maxIndex;

        uint256 value = 0;
        if (_tokenIdMatrix[random] == 0) {
            // If this matrix position is empty, set the value to the generated random number.
            value = random;
        } else {
            // Otherwise, use the previously stored number from the matrix.
            value = _tokenIdMatrix[random];
        }

        // If the last available tokenID is still unused...
        if (_tokenIdMatrix[maxIndex - 1] == 0) {
            // ...store that ID in the current matrix position.
            _tokenIdMatrix[random] = maxIndex - 1;
        } else {
            // ...otherwise copy over the stored number to the current matrix position.
            _tokenIdMatrix[random] = _tokenIdMatrix[maxIndex - 1];
        }

        return value + 1;
    }
}