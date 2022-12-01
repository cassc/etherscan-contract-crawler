// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title Thenian contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract Thenian is ERC721Enumerable, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Base URI
    string private _baseURIextended;
    uint256 public MAX_SUPPLY;
    uint256 public NFT_PRICE;
    uint256 public MAX_PER_MINT = 10;
    uint256 public SALE_START_TIMESTAMP;
    address public ORIGINAL_MINTER;
    uint256 public MAX_RESERVE = 150;
    uint256 public reservedAmount;
    bytes32 public root;
    address public multiSig = 0x7d70ee3774325C51e021Af1f7987C214d2CAA184;

    mapping(address => bool) public firstMint;
    mapping(address => uint256) public secondMint;

    constructor(
        uint256 _maxSupply,
        uint256 _nftPrice,
        uint256 _startTimestamp
    ) ERC721("Thenian", "theNFT") {
        MAX_SUPPLY = _maxSupply;
        NFT_PRICE = _nftPrice;
        SALE_START_TIMESTAMP = _startTimestamp;
    }

    function withdraw() external onlyOwner {
        (bool withdrawMultiSig, ) = multiSig.call{value: address(this).balance}("");
        require(withdrawMultiSig, "Withdraw Failed.");
    }

    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function setNftPrice(uint256 _nftPrice) external onlyOwner {
        NFT_PRICE = _nftPrice;
    }

    /**
     * Mint NFTs by owner
     */
    function reserveNFTs(address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "Invalid address to reserve.");
        require(reservedAmount.add(_amount) <= MAX_RESERVE, "Invalid amount");

        for (uint256 i = 0; i < _amount; i++) {
            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(_to, totalSupply());
            }
        }
        reservedAmount = reservedAmount.add(_amount);
    }

    /**
     * @dev Return the base URI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    /**
     * @dev Return the base URI
     */
    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    /**
     * @dev Set the base URI
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    /**
     * Get the array of token for owner.
     */
    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function verifyLeaf(bytes32[] memory proof, address sender) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(keccak256(abi.encodePacked(sender))));
        return MerkleProof.verify(proof, root, leaf);
    }

    /**
     * Mint in the first round
     */
    function mintFirst(bytes32[] memory proof) public payable {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started yet.");
        require(block.timestamp < SALE_START_TIMESTAMP + 1 days, "First round has ended.");
        require(verifyLeaf(proof, msg.sender), "Not whitelisted.");
        require(NFT_PRICE == msg.value, "BNB value sent is not correct.");
        require(!firstMint[msg.sender], "Already minted!");

        firstMint[msg.sender] = true;
        _mintTo(msg.sender, 1);
    }

    /**
     * Mint in the second round
     */
    function mintSecond(uint256 amount, bytes32[] memory proof) public payable {
        require(block.timestamp >= SALE_START_TIMESTAMP + 1 days, "Second round has not started yet.");
        require(block.timestamp < SALE_START_TIMESTAMP + 2 days, "Second round has ended.");
        require(verifyLeaf(proof, msg.sender), "Not whitelisted.");
        require(NFT_PRICE.mul(amount) == msg.value, "BNB value sent is not correct");
        require(secondMint[msg.sender].add(amount) <= MAX_PER_MINT, "Can only mint 10 in the second round");

        secondMint[msg.sender] = secondMint[msg.sender].add(amount);
        _mintTo(msg.sender, amount);
    }

    /**
     * Mint NFTs
     */
    function mintPublic(uint256 amount) public payable {
        require(block.timestamp >= SALE_START_TIMESTAMP + 2 days, "Public Sale has not started yet.");
        require(block.timestamp < SALE_START_TIMESTAMP + 5 days, "Sale is over.");
        require(amount <= MAX_PER_MINT, "Can only mint 10 NFTs at a time");
        require(balanceOf(msg.sender).add(amount) <= 15, "Can only mint 15 NFTs per wallet");
        require(NFT_PRICE.mul(amount) == msg.value, "BNB value sent is not correct");

        _mintTo(msg.sender, amount);
    }

    function _mintTo(address account, uint amount) internal {
        require(totalSupply().add(amount) <= MAX_SUPPLY, "Mint would exceed max supply.");

        if (ORIGINAL_MINTER == address(0)) {
            ORIGINAL_MINTER = account;
        }

        for (uint256 i = 0; i < amount; i++) {
            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(account, totalSupply());
            }
        }
    }
}