//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title Wine Bottle Club, the Genesis collection
/// @author Consultec
contract WineBottleClubGenesis is ERC721, EIP712, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _exclusibleCount;

    uint256 private constant MAX_TOTAL_SUPPLY = 4_926;
    uint256 private constant MAX_TOKEN_PER_WALLET = 4;
    uint256 private constant MAX_OWNER_MINT = 200;
    uint16 private constant EXCLUSIBLE_REFERRER_ID = 1;

    uint256 public _tokenPublicPrice = 0.3 ether;
    uint256 public immutable _crossmintWhitelistPrice;
    uint256 public _accessListPermission = 0;
    uint256 public _ownerMintCount = 0;
    bool public _isExclusibleSale = false;
    bool public _isPublicSale = false;
    string public _baseTokenURI;
    bytes32 public _root;

    mapping(uint256 => uint256) public _redeemedTimestamp;
    mapping(address => uint256) public _maxTokenPerWallet;

    constructor(string memory baseTokenURI, uint256 crossmintWhitelistPrice)
        ERC721("WineBottleClubGenesis", "WBCG")
        EIP712("WineBottleClubGenesis", "1")
    {
        setBaseTokenURI(baseTokenURI);
        _crossmintWhitelistPrice = crossmintWhitelistPrice;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string memory baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    /// The totalSupply() function returns the total supply of the tokens.
    /// This means that the sum total of token balances of all of the token
    /// holders must match the total supply.
    /// @return the total supply of the tokens
    function totalSupply() external view returns (uint256) {
        return _tokenIds.current();
    }

    //
    // Public mint
    //

    function flipPublicSale() external onlyOwner {
        _isPublicSale = !_isPublicSale;
    }

    function setPublicSalePrice(uint256 tokenPublicPrice) external onlyOwner {
        _tokenPublicPrice = tokenPublicPrice;
    }

    function publicMint(address to, uint256 count) external payable {
        require(true == _isPublicSale, "!open");
        _mintManyLimited(to, _tokenPublicPrice, uint16(count));
    }

    //
    // Owner mint
    //

    function ownerMint(address to, uint16 count) external onlyOwner {
        unchecked {
            _ownerMintCount += count;
        }
        require(_ownerMintCount <= MAX_OWNER_MINT, "!maxwbc");
        _mintMany(to, 0, count);
    }

    //
    // Exclusible mint
    //

    function getExclusibleCount() external view returns (uint256) {
        return _exclusibleCount.current();
    }

    function flipExclusibleSale() external onlyOwner {
        _isExclusibleSale = !_isExclusibleSale;
    }

    function exclusibleMint(uint16 count) external payable {
        require(true == _isExclusibleSale, "!ex_sale");
        _exclusibleMint(_tokenPublicPrice, count);
    }

    function _exclusibleMint(uint256 tokenPrice, uint16 count) private {
        for (uint256 i = 0; i < count; i++) {
            _exclusibleCount.increment();
        }
        _mintManyLimited(msg.sender, tokenPrice, count);
    }

    //
    // Crossmint mint
    //

    function crossmintMint(address to, uint256 count) external payable {
        require(
            0xdAb1a1854214684acE522439684a145E62505233 == msg.sender,
            "!crossmint"
        );
        _mintManyLimited(to, _crossmintWhitelistPrice, uint16(count));
    }

    //
    // Access List mint
    //

    function setMerkleRoot(bytes32 root) public onlyOwner {
        _root = root;
    }

    function permitAccessLists(uint256 permission) public onlyOwner {
        _accessListPermission = permission;
    }

    function accessMint(
        uint256 tokenPrice,
        uint16 count,
        uint256 referrerId,
        bytes32[] calldata proof
    ) external payable {
        require(
            MerkleProof.verify(
                proof,
                _root,
                keccak256(abi.encode(msg.sender, tokenPrice, referrerId))
            ),
            "!proof"
        );
        require(referrerId <= _accessListPermission, "!perm");
        if (EXCLUSIBLE_REFERRER_ID == referrerId) {
            _exclusibleMint(tokenPrice, count);
        } else {
            _mintManyLimited(msg.sender, tokenPrice, count);
        }
    }

    function _mintManyLimited(
        address to,
        uint256 tokenPrice,
        uint16 count
    ) private {
        unchecked {
            _maxTokenPerWallet[to] += count;
        }
        require(_maxTokenPerWallet[to] <= MAX_TOKEN_PER_WALLET, "!max");
        _mintMany(to, tokenPrice, count);
    }

    function _mintMany(
        address to,
        uint256 tokenPrice,
        uint16 count
    ) private {
        require(count > 0, "!count");
        unchecked {
            uint256 nextTokenId = _tokenIds.current() + count;
            require(nextTokenId <= MAX_TOTAL_SUPPLY, "!supply");
            require(msg.value >= tokenPrice * count, "!ether");
        }
        for (uint256 i = 0; i < count; i++) {
            _tokenIds.increment();
            _safeMint(to, _tokenIds.current());
        }
    }

    // EIP-712 typed structured data signature
    bytes32 private constant WBC_SHIPPING_DATA_TYPEHASH =
        keccak256("WbcShippingData(bytes32 hashdata,uint64 timestamp)");

    function verifyShippingData(
        bytes32 hashdata,
        uint64 timestamp,
        address signer,
        bytes calldata signature
    ) public view returns (bool) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(WBC_SHIPPING_DATA_TYPEHASH, hashdata, timestamp)
            )
        );
        (address a, ECDSA.RecoverError e) = ECDSA.tryRecover(digest, signature);
        return (a == signer) && (e == ECDSA.RecoverError.NoError);
    }

    function redeem(
        uint256 tokenId,
        bytes32 hashdata,
        uint64 timestamp,
        bytes calldata signature
    ) public {
        require(ownerOf(tokenId) == msg.sender, "!owner");
        require(0 == _redeemedTimestamp[tokenId], "!redeemed");
        require(
            verifyShippingData(hashdata, timestamp, msg.sender, signature),
            "!data"
        );
        // solhint-disable-next-line not-rely-on-time
        _redeemedTimestamp[tokenId] = block.timestamp;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721) {
        require(
            (0 == _redeemedTimestamp[tokenId]) ||
                // solhint-disable-next-line not-rely-on-time
                (block.timestamp - _redeemedTimestamp[tokenId] >= 2 weeks),
            "!locked"
        );
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function withdraw() external {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "!transfer");
    }
}