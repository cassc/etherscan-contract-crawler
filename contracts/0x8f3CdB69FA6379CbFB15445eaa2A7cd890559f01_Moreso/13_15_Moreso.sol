// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/*
 * @author Moreso
 * @notice To the extent possible under law, MORESO has waived all copyright and related or neighboring rights to the collection.
 */
contract Moreso is Ownable, ERC721A, ReentrancyGuard {
    uint256 public constant MAX_SUPPLY = 3000;
    uint256 public constant WHITELIST_MINT_PRICE = 0.069 ether;
    uint256 public constant PUBLIC_MINT_PRICE = 0.08 ether;
    uint256 private constant MAX_MINTS_PER_WALLET = 5;

    bool public mintDisablePermanent = false;

    bytes32 public merkleRoot;

    mapping(address => uint256) private mintedCounter;
    mapping(address => uint256) private mintedWhitelist;
    string private _baseTokenURI;

    uint256 public whitelistMintStartTime;
    uint256 public publicMintStartTime;

    constructor(
        bytes32 merkleRoot_,
        uint256 whitelistMintStartTime_
    ) ERC721A("Moreso", "MORESO") {
        merkleRoot = merkleRoot_;
        whitelistMintStartTime = whitelistMintStartTime_;
        publicMintStartTime = whitelistMintStartTime + 24 hours;
    }

    modifier callerIsUser() {
        require(
            tx.origin == msg.sender,
            "Moreso :: Cannot be called by a contract"
        );
        _;
    }

    function whitelistMint(
        bytes32[] calldata merkleProof,
        uint256 availableToMint,
        uint256 quantity
    ) external payable callerIsUser {
        require(!mintDisablePermanent, "Minting is permanently disabled");
        require(
            block.timestamp >= whitelistMintStartTime,
            "Whitelist mint not yet open"
        );
        require(totalSupply() + quantity <= MAX_SUPPLY, "Reached max supply");
        require(
            mintedCounter[msg.sender] + quantity <= MAX_MINTS_PER_WALLET,
            "Reached max mint per wallet"
        );
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(msg.sender, availableToMint));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "Invalid Merkle Proof."
        );

        require(
            isValidValueSent(availableToMint, quantity),
            "Insufficient funds sent"
        );

        mintedCounter[msg.sender] += quantity;
        mintedWhitelist[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable callerIsUser {
        require(!mintDisablePermanent, "Minting is permanently disabled");
        require(
            block.timestamp >= publicMintStartTime,
            "PublicMint mint not yet open"
        );
        require(totalSupply() + quantity <= MAX_SUPPLY, "Reached max supply");
        require(
            mintedCounter[msg.sender] + quantity <= MAX_MINTS_PER_WALLET,
            "Reached max mint per wallet"
        );
        require(
            PUBLIC_MINT_PRICE * quantity <= msg.value,
            "Insufficient funds sent"
        );

        mintedCounter[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function isValidValueSent(
        uint256 availableToMint,
        uint256 quantity
    ) internal view returns (bool isValid) {
        uint256 amountToPay = 0;
        uint256 numWhitelistMint = 0;

        if (mintedWhitelist[msg.sender] < availableToMint) {
            numWhitelistMint = availableToMint - mintedWhitelist[msg.sender];
        }

        if (numWhitelistMint >= quantity) {
            amountToPay = quantity * WHITELIST_MINT_PRICE;
        } else {
            amountToPay =
                (quantity - numWhitelistMint) *
                PUBLIC_MINT_PRICE +
                numWhitelistMint *
                WHITELIST_MINT_PRICE;
        }

        isValid = amountToPay <= msg.value;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setMintStartTime(uint256 startTime) external onlyOwner {
        whitelistMintStartTime = startTime;
        publicMintStartTime = whitelistMintStartTime + 24 hours;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setMerkleRoot(bytes32 merkleRoot_) public onlyOwner {
        merkleRoot = merkleRoot_;
    }

    function disableMint() public onlyOwner {
        mintDisablePermanent = true;
    }

    function mintedOf(address minter) public view virtual returns (uint256) {
        return mintedCounter[minter];
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}