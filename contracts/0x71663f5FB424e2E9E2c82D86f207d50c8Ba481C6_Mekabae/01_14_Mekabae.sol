// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/*
 * @author Mekabae
 * @notice To the extent possible under law, Bae Cafe S2 (MekaBae) has waived all copyright and related or neighboring rights to the collection.
 */
contract Mekabae is Ownable, ERC721A, ReentrancyGuard {
    uint256 public constant MAX_SUPPLY = 2222;
    uint256 public constant MAX_FREE_MINT = 618;
    uint256 public constant WHITELIST_MINT_PRICE = 0.069 ether;
    uint256 public constant PUBLIC_MINT_PRICE = 0.08008 ether;
    uint256 private constant MAX_MINTS_PER_TX = 100;

    bool public teamMinted;
    bool public saleIsActive;
    bool public s1MintIsActive = true;
    uint256 public countFreeMint = 0;

    bytes32 public merkleRoot;

    mapping(address => uint256) private MINTED_WHITELIST;
    string private _baseTokenURI;

    constructor(bytes32 merkleRoot_) ERC721A("Mekabae", "MEKABAE") {
        merkleRoot = merkleRoot_;
    }

    modifier callerIsUser() {
        require(
            tx.origin == msg.sender,
            "Mekabae :: Cannot be called by a contract"
        );
        _;
    }

    function whitelistMint(
        bytes32[] calldata merkleProof,
        uint256 availableToMint,
        bool isS1Holder,
        uint256 quantity
    ) external payable callerIsUser {
        require(saleIsActive, "Sale must be active to mint Mekabae");
        require(
            quantity <= MAX_MINTS_PER_TX,
            "reached max mint per transaction"
        );
        require(
            isNotReachedMaxSupply(quantity, isS1Holder),
            "reached max supply"
        );
        // Verify the merkle proof.
        bytes32 node = keccak256(
            abi.encodePacked(msg.sender, availableToMint, isS1Holder)
        );
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "Invalid Merkle Proof."
        );

        require(
            isValidValueSent(availableToMint, isS1Holder, quantity),
            "Insufficient funds sent"
        );

        if (isS1Holder && MINTED_WHITELIST[msg.sender] == 0) {
            countFreeMint += 1;
        }
        MINTED_WHITELIST[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable callerIsUser {
        require(saleIsActive, "Sale must be active to mint Mekabae");
        require(
            quantity <= MAX_MINTS_PER_TX,
            "reached max mint per transaction"
        );
        require(
            PUBLIC_MINT_PRICE * quantity <= msg.value,
            "Insufficient funds sent"
        );
        require(isNotReachedMaxSupply(quantity, false), "reached max supply");

        _safeMint(msg.sender, quantity);
    }

    function teamMint(address to) external onlyOwner {
        require(!teamMinted, "Team already minted");
        teamMinted = true;
        _safeMint(to, 100);
    }

    function isNotReachedMaxSupply(uint256 quantity, bool isS1Holder)
        internal
        view
        returns (bool isNotReached)
    {
        if (s1MintIsActive) {
            if (
                isS1Holder &&
                MINTED_WHITELIST[msg.sender] == 0 &&
                quantity == 1 &&
                totalSupply() + quantity >
                MAX_SUPPLY - MAX_FREE_MINT + countFreeMint &&
                totalSupply() + quantity <= MAX_SUPPLY
            ) {
                isNotReached = true;
            } else {
                isNotReached =
                    totalSupply() + quantity <=
                    MAX_SUPPLY - MAX_FREE_MINT + countFreeMint;
            }
        } else {
            isNotReached = totalSupply() + quantity <= MAX_SUPPLY;
        }
    }

    function isValidValueSent(
        uint256 availableToMint,
        bool isS1Holder,
        uint256 quantity
    ) internal view returns (bool isValid) {
        uint256 amountToPay = 0;
        uint256 count = 0;
        if (s1MintIsActive && isS1Holder && MINTED_WHITELIST[msg.sender] == 0) {
            count += 1;
        }
        if (
            MINTED_WHITELIST[msg.sender] < availableToMint && count < quantity
        ) {
            uint256 numWhitelistMint = availableToMint -
                MINTED_WHITELIST[msg.sender] -
                count;
            if (numWhitelistMint > quantity - count) {
                numWhitelistMint = quantity;
            }
            count += numWhitelistMint;
            amountToPay += numWhitelistMint * WHITELIST_MINT_PRICE;
        }
        if (count < quantity) {
            amountToPay += (quantity - count) * PUBLIC_MINT_PRICE;
        }
        isValid = amountToPay <= msg.value;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setMerkleRoot(bytes32 merkleRoot_) public onlyOwner {
        merkleRoot = merkleRoot_;
    }

    function flipS1MintState() public onlyOwner {
        s1MintIsActive = !s1MintIsActive;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function mintedOf(address minter) public view virtual returns (uint256) {
        return MINTED_WHITELIST[minter];
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}