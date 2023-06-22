//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title La Table du Chef - NFT Pass
/// @author theblock.company
contract TableChefPass is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _whitelistId;
    Counters.Counter private _exclusibleCount;

    uint256 private constant MAX_TOTAL_SUPPLY = 10_000;
    uint256 private constant MAX_EXCLUSIBLE_SUPPLY = 3_000;

    uint256 private _tokenPublicPrice = 0.4 ether;
    uint256 private _exclusibleTokenPrice = 0.2 ether;
    uint256 public _publicStage = 0;
    bool public _isExclusibleSale = false;
    string private _baseTokenURI;
    address public immutable _recipient;
    bytes32 public _root;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI,
        address recipient
    ) ERC721(name_, symbol_) {
        setBaseTokenURI(baseTokenURI);
        _recipient = recipient;
    }

    /// The totalSupply() function returns the total supply of the tokens.
    /// This means that the sum total of token balances of all of the token
    /// holders must match the total supply.
    /// @return the total supply of the tokens
    function totalSupply() external view returns (uint256) {
        return _tokenIds.current();
    }

    function setMerkleRoot(bytes32 root) public onlyOwner {
        _root = root;
    }

    function incWhitelistId() public onlyOwner {
        _whitelistId.increment();
    }

    function getWhitelistId() external view returns (uint256) {
        return _whitelistId.current();
    }

    function whitelistedMint(
        uint16 count,
        uint256 tokenPrice,
        bytes32[] calldata proof
    ) external payable {
        require(
            MerkleProof.verify(
                proof,
                _root,
                keccak256(
                    abi.encode(msg.sender, tokenPrice, _whitelistId.current())
                )
            ),
            "!proof"
        );
        if (0 == _whitelistId.current()) {
            _exclusibleCount.increment();
        }
        _mintMany(msg.sender, tokenPrice, count);
    }

    function setExclusibleSalePrice(uint256 price) external onlyOwner {
        _exclusibleTokenPrice = price;
    }

    function setPublicSalePrice(uint256 tokenPublicPrice) external onlyOwner {
        _tokenPublicPrice = tokenPublicPrice;
    }

    function getExclusibleCount() external view returns (uint256) {
        return _exclusibleCount.current();
    }

    function flipExclusibleSale() external onlyOwner {
        _isExclusibleSale = !_isExclusibleSale;
    }

    function exclusibleMint(uint16 count) external payable {
        require(true == _isExclusibleSale, "!ex_sale");
        require(
            _exclusibleCount.current() < MAX_EXCLUSIBLE_SUPPLY,
            "!ex_supply"
        );
        for (uint256 i = 0; i < count; i++) {
            _exclusibleCount.increment();
        }
        _mintMany(msg.sender, _exclusibleTokenPrice, count);
    }

    function incPublicStage() external onlyOwner {
        _publicStage++;
    }

    function publicMint(uint16 count) external payable {
        require(
            ((_tokenIds.current() < 6000) && (_publicStage == 1)) ||
                (_publicStage >= 2),
            "!sale"
        );
        _mintMany(msg.sender, _tokenPublicPrice, count);
    }

    function ownerMint(address to, uint16 count) external onlyOwner {
        _mintMany(to, 0, count);
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
            _mintOne(to);
        }
    }

    function _mintOne(address to) private {
        _tokenIds.increment();
        _safeMint(to, _tokenIds.current());
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string memory baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function withdraw() external {
        uint256 balance = address(this).balance;
        require(balance > 0, "!balance");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(_recipient).call{value: balance}("");
        require(success, "!transfer");
    }

    // receive() external payable {
    //     // solhint-disable-previous-line no-empty-blocks
    // }
}