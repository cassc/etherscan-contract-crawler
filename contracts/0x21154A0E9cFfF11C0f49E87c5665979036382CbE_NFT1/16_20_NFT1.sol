// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract NFT1 is ERC721A, ERC721AQueryable, Ownable, ReentrancyGuard {
    uint256 public constant MAX_SUPPLY = 8000;
    uint256 public constant FREE_MINT_SUPPLY = 400;
    uint256 public constant EARLY_ADOPTER_SUPPLY = 200 * 2;

    uint256 public freeMinted;
    uint256 public earlyAdopterMinted;
    uint256 public whitelistMinted;
    uint256 public publicMinted;

    uint256 public constant WHITELIST_MINT_PRICE = 0.02 ether;
    uint256 public constant PUBLIC_MINT_PRICE = 0.03 ether;

    bytes32 public whitelist_free;
    bytes32 public whitelist_early_adopter;
    bytes32 public whitelist_whitelist;

    mapping(address => bool) public freeMintCount;
    mapping(address => uint256) public earlyAdopterMintCount;
    mapping(address => uint256) public whitelistMintCount;

    string base_uri;
    address public NFT2_ADDRESS;

    enum MintPhase {
        FreeMint,
        WhitelistMint,
        PublicMint
    }
    MintPhase public currentPhase = MintPhase.FreeMint;

    constructor() ERC721A("Discovery Squad", "DSHOUSE") {}

    function _baseURI() internal view override returns (string memory) {
        return base_uri;
    }

    function tokenURI(
        uint256
    ) public view virtual override(ERC721A,IERC721A) returns (string memory) {
        return base_uri;
    }

    function setWhitelists(
        bytes32 new_whitelist_free,
        bytes32 new_whitelist_early_adopter,
        bytes32 new_whitelist_whitelist
    ) external onlyOwner {
        whitelist_free = new_whitelist_free;
        whitelist_early_adopter = new_whitelist_early_adopter;
        whitelist_whitelist = new_whitelist_whitelist;
    }

    function openWhitelistMint() external onlyOwner {
        require(
            currentPhase == MintPhase.FreeMint,
            "Already moved to whitelist mint phase"
        );
        currentPhase = MintPhase.WhitelistMint;
    }

    function openPublicMint() external onlyOwner {
        require(
            currentPhase == MintPhase.WhitelistMint,
            "Not in the whitelist mint phase"
        );
        require(
            freeMinted == FREE_MINT_SUPPLY,
            "Mint remaining free mint NFTs to treasury"
        );
        currentPhase = MintPhase.PublicMint;
    }

    function _is_on_whitelist(
        bytes32 whitelist,
        bytes32[] calldata proof
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(msg.sender)))
        );
        return MerkleProof.verify(proof, whitelist, leaf);
    }

    function mint(
        uint256 amount,
        bytes32[] calldata proof,
        bool early_adopter_mint
    ) external payable {
        uint256 minted = totalSupply();
        require(minted + amount <= MAX_SUPPLY, "Not enough NFTs left");
        require(
            10 >= amount && amount >= 1,
            "Amount cannot be less than 1 or more than 10 NFTs"
        );
        if (currentPhase == MintPhase.PublicMint) {
            // PUBLIC MINT
            require(
                msg.value == amount * PUBLIC_MINT_PRICE,
                "Incorrect payment"
            );
            publicMinted += amount;
            _mint(msg.sender, amount);
        } else if (early_adopter_mint) {
            // EARLY ADOPTER MINT
            require(
                _is_on_whitelist(whitelist_early_adopter, proof),
                "Not on whitelist for early adopter mint"
            );
            require(
                earlyAdopterMintCount[msg.sender] + amount <= 2,
                "You can only mint 2 Early Adopter NFTs in total"
            );
            require(
                msg.value == WHITELIST_MINT_PRICE * amount,
                "Incorrect payment"
            );
            earlyAdopterMintCount[msg.sender] += amount;
            earlyAdopterMinted += amount;
            _mint(msg.sender, amount);
        } else if (currentPhase == MintPhase.FreeMint) {
            // FREE MINT
            require(amount == 1, "Can only mint 1 free NFT");
            require(
                _is_on_whitelist(whitelist_free, proof),
                "Not on whitelist for free mint"
            );
            require(
                freeMinted < FREE_MINT_SUPPLY,
                "Free mint supply exhausted"
            );
            require(!freeMintCount[msg.sender], "Already minted a free NFT");
            freeMintCount[msg.sender] = true;
            freeMinted++;
            _mint(msg.sender, 1);
        } else if (currentPhase == MintPhase.WhitelistMint) {
            // WHITELIST MINT
            require(
                _is_on_whitelist(whitelist_whitelist, proof),
                "Not on whitelist for whitelist mint"
            );
            require(
                whitelistMintCount[msg.sender] + amount <= 2,
                "You can only mint 2 whitelist NFTs"
            );
            require(msg.value == WHITELIST_MINT_PRICE * amount, "Incorrect payment");
            whitelistMintCount[msg.sender] += amount;
            whitelistMinted += amount;
            _mint(msg.sender, amount);
        }
    }

    function mintRemainingFreeToTreasury(
        uint256 max_amount
    ) external onlyOwner {
        require(
            currentPhase == MintPhase.WhitelistMint,
            "Not in whitelist mint phase"
        );
        uint256 remainingFreeMint = FREE_MINT_SUPPLY - freeMinted;
        uint256 amount = Math.min(remainingFreeMint, max_amount);
        _mint(owner(), amount);
        freeMinted += amount;
    }

    function reveal(uint256 token_id) external {
        require(
            msg.sender == NFT2_ADDRESS,
            "This function can only be called from NFT2"
        );
        _burn(token_id);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function set_base_uri(string memory new_base_uri) public onlyOwner {
        base_uri = new_base_uri;
    }

    function set_nft2_address(address new_NFT2_ADDRESS) external onlyOwner {
        NFT2_ADDRESS = new_NFT2_ADDRESS;
    }
}