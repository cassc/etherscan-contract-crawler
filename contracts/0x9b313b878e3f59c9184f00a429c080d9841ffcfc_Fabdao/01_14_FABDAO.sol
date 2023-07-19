//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma abicoder v2; // required to accept structs as function parameters

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "erc721a/contracts/ERC721A.sol";

/**
 @title Fabdao 
 @author Lee Ting Ting
 */
contract Fabdao is Ownable, ERC721A, EIP712 {
    using Address for address;

    string private baseTokenURI;

    // TO BE REMOVED!!
    uint256 public constant testMintStartTime = 0; // testing purpose
    uint256 public constant publicMintStartTime = 1656993600; // UTC+8 7/5 12:00
    uint256 public constant publicMintSecondStartTime = 1657944000; // UTC+8 7/16 12:00
    uint256 public constant whitelistMintStartTime = 1656734400; // UTC+8 7/2 12:00
    uint256 public constant mintPrice = 0.125 ether;
    uint256 public constant mintPriceSecond = 0.025 ether;
    uint256 public constant freeMintLimit = 500;
    uint256 public constant maxWhitelistMintLimitPerAddr = 12;
    uint256 public constant maxPublicMintSecondLimitPerAddr = 50;
    uint256 public constant MAX_SUPPLY = 10000;
    address public constant reserver = 0x952936E60B9a9E2E9B2950599694aFE9Ff8a8a4a;

    uint256 public freeMintCount = 0;
    mapping(address => uint256) public _mintedCounts;
    mapping(address => uint256) public _mintedCountsPublic;
    mapping(address => uint256) public _mintedCountsPublicSecond;

    // voucher for user to redeem
    struct NFTVoucher {
        address redeemer; // specify user to redeem this voucher
    }

    modifier onlyReserver () {
        require(_msgSender() == reserver || _msgSender() == owner(), "No access to reserve NFT");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI
    ) ERC721A(_name, _symbol) EIP712(_name, "1") { // version 1
        baseTokenURI = _baseTokenURI;
    }

    /// @notice Whitelist mint using the voucher
    function whitelistMint(
        NFTVoucher calldata voucher,
        bytes calldata signature,
        uint256 amount,
        address to
    ) external payable {
        // make sure that the signer is authorized to mint NFTs
        _verify(voucher, signature, to);

        // check time
        require(block.timestamp >= whitelistMintStartTime, "Sale not started");
        // require(block.timestamp >= testMintStartTime, "Sale not started");
        // check if enough maxMintCount
        require(amount + _mintedCounts[to] <= maxWhitelistMintLimitPerAddr, "Not enough maxMintCount per address");
        // check if Exceed max total supply
        require(totalSupply() + amount * 5 <= MAX_SUPPLY, "Exceed max total supply");
        // check fund
        require(msg.value >= mintPrice * amount, "Not enough fund");
        // mint
        super._safeMint(to, amount * 5);
        // increase minted count
        _mintedCounts[to] += amount;
    }

    /// @notice Public mint first 
    function publicMintFirst(address to, uint256 amount) external payable {
        // check time
        require(block.timestamp >= publicMintStartTime, "Sale not started");
        // require(block.timestamp >= testMintStartTime, "Sale not started");
        // check if enough maxMintCount
        require(amount + _mintedCountsPublic[to]<= maxWhitelistMintLimitPerAddr, "Not enough maxMintCount per address");
        // check if Exceed max total supply
        require(totalSupply() + amount * 5 <= MAX_SUPPLY, "Exceed max total supply");
        // check fund
        require(msg.value >= mintPrice * amount, "Not enough fund to mint NFT");
        // mint
        super._safeMint(to, amount * 5);
        // increase minted count
        _mintedCountsPublic[to] += amount;
    }

    /// @notice Public mint second 
    function publicMintSecond(address to, uint256 amount) external payable {
        // check time
        require(block.timestamp >= publicMintSecondStartTime, "Sale not started");
        // require(block.timestamp >= testMintStartTime, "Sale not started");
        // check if enough maxMintCount per address
        require(amount + _mintedCountsPublicSecond[to] <= maxPublicMintSecondLimitPerAddr, "Not enough maxMintCount per address per address");
        // check if Exceed max total supply
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceed max total upply");
        // check fund
        require(msg.value >= mintPriceSecond * amount, "Not enough fund to mint NFT");
        // mint
        super._safeMint(to, amount);
        // increase minted count
        _mintedCountsPublicSecond[to] += amount;
    }

    /// @dev Verify voucher
    function _verify(NFTVoucher calldata voucher, bytes calldata signature, address to) public view {
        require(voucher.redeemer == to, "Voucher not owned by the redeemer");
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("NFTVoucher(address redeemer)"),
                    to
                )
            )
        );
        require(owner() == ECDSA.recover(digest, signature), "Signature invalid or unauthorized");
    }

    /// @dev Reserve NFT. The contract owner can mint NFTs regardless of the minting start and end time.
    function reserve(address to, uint256 amount) external onlyReserver {
        // check free mint total supply
        require(freeMintCount + amount <= freeMintLimit, "Exceed free mint limit");
        // check if Exceed max total supply
        require(totalSupply() + amount * 5 <= MAX_SUPPLY, "Exceed max total supply");
        super._safeMint(to, amount * 5);
        freeMintCount += amount;
    }

    /// @dev Withdraw. The contract owner can withdraw all ETH from the NFT sale
    function withdraw() external onlyReserver {
        Address.sendValue(payable(_msgSender()), address(this).balance);
    }

    /// @dev Set new baseURI
    function setBaseURI(string memory baseURI) external onlyReserver {
        baseTokenURI = baseURI;
    }

    /// @dev override _baseURI()
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}