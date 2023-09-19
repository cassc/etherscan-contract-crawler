// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract VhighAvatarGen1 is Ownable, ERC721AQueryable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 10_000;

    /* base uri */
    string public baseTokenURI;

    /* dev mint */
    uint256 public constant MAX_DEV_MINT = 1_000;
    bool public isDevMintActive;
    uint256 public devMinted;

    /* wl mint */
    bool public isWlMintActive;
    bytes32 public merkleRoot;
    mapping(address => uint256) public wlMintedByAddress;

    /* public mint */
    uint256 public constant MAX_PUBLIC_MINT_PER_ADDRESS = 1;
    bool public isPublicMintActive;
    mapping(address => uint256) public publicMintedByAddress;

    constructor() ERC721A("Vhigh! Avatar Gen 1.0", "VAG1") {}

    modifier withinMaxSupply(uint256 amount) {
        require(
            totalSupply() + amount <= MAX_SUPPLY,
            "VAG1: reached max supply"
        );
        _;
    }

    /* base uri */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string memory baseTokenURI_) external onlyOwner {
        baseTokenURI = baseTokenURI_;
    }

    /* dev mint */
    function toggleIsDevMintActive() external onlyOwner {
        isDevMintActive = !isDevMintActive;
    }

    function devMint(
        uint256 amount
    ) external onlyOwner nonReentrant withinMaxSupply(amount) {
        require(isDevMintActive, "VAG1: dev mint is not active");
        require(
            devMinted + amount <= MAX_DEV_MINT,
            "VAG1: reached max dev mint"
        );

        unchecked {
            devMinted += amount;
        }
        _safeMint(_msgSender(), amount);
    }

    /* wl mint */
    function toggleIsWlMintActive() external onlyOwner {
        isWlMintActive = !isWlMintActive;
    }

    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }

    function wlMint(
        uint256 amount,
        bytes32[] calldata proof,
        uint256 maxMintableAmount
    ) external nonReentrant withinMaxSupply(amount) {
        require(isWlMintActive, "VAG1: wl mint is not active");
        require(_verify(proof, maxMintableAmount), "VAG1: invalid proof");
        require(
            amount <= maxMintableAmount - wlMintedByAddress[_msgSender()],
            "VAG1: not enough remaining"
        );

        unchecked {
            wlMintedByAddress[_msgSender()] += amount;
        }
        _safeMint(_msgSender(), amount);
    }

    function _verify(
        bytes32[] calldata proof,
        uint256 maxMintableAmount
    ) private view returns (bool) {
        bytes32 leaf = keccak256(
            abi.encodePacked(_msgSender(), maxMintableAmount.toString())
        );
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    /* public mint */
    function toggleIsPublicMintActive() external onlyOwner {
        isPublicMintActive = !isPublicMintActive;
    }

    function publicMint(
        uint256 amount
    ) external nonReentrant withinMaxSupply(amount) {
        require(isPublicMintActive, "VAG1: public mint is not active");
        require(
            amount <=
                MAX_PUBLIC_MINT_PER_ADDRESS -
                    publicMintedByAddress[_msgSender()],
            "VAG1: not enough remaining"
        );
        require(
            tx.origin == msg.sender,
            "VAG1: the caller is another contract"
        );

        unchecked {
            publicMintedByAddress[_msgSender()] += amount;
        }
        _safeMint(_msgSender(), amount);
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "VAG1: transfer failed");
    }
}