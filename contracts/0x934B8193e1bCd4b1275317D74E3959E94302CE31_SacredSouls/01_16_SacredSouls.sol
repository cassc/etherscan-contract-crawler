// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import { ERC2981 } from "@openzeppelin/contracts/token/common/ERC2981.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC721Burnable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/*

  ██████  ▄▄▄       ▄████▄   ██▀███  ▓█████ ▓█████▄      ██████  ▒█████   █    ██  ██▓      ██████ 
▒██    ▒ ▒████▄    ▒██▀ ▀█  ▓██ ▒ ██▒▓█   ▀ ▒██▀ ██▌   ▒██    ▒ ▒██▒  ██▒ ██  ▓██▒▓██▒    ▒██    ▒ 
░ ▓██▄   ▒██  ▀█▄  ▒▓█    ▄ ▓██ ░▄█ ▒▒███   ░██   █▌   ░ ▓██▄   ▒██░  ██▒▓██  ▒██░▒██░    ░ ▓██▄   
  ▒   ██▒░██▄▄▄▄██ ▒▓▓▄ ▄██▒▒██▀▀█▄  ▒▓█  ▄ ░▓█▄   ▌     ▒   ██▒▒██   ██░▓▓█  ░██░▒██░      ▒   ██▒
▒██████▒▒ ▓█   ▓██▒▒ ▓███▀ ░░██▓ ▒██▒░▒████▒░▒████▓    ▒██████▒▒░ ████▓▒░▒▒█████▓ ░██████▒▒██████▒▒
▒ ▒▓▒ ▒ ░ ▒▒   ▓▒█░░ ░▒ ▒  ░░ ▒▓ ░▒▓░░░ ▒░ ░ ▒▒▓  ▒    ▒ ▒▓▒ ▒ ░░ ▒░▒░▒░ ░▒▓▒ ▒ ▒ ░ ▒░▓  ░▒ ▒▓▒ ▒ ░
░ ░▒  ░ ░  ▒   ▒▒ ░  ░  ▒     ░▒ ░ ▒░ ░ ░  ░ ░ ▒  ▒    ░ ░▒  ░ ░  ░ ▒ ▒░ ░░▒░ ░ ░ ░ ░ ▒  ░░ ░▒  ░ ░
░  ░  ░    ░   ▒   ░          ░░   ░    ░    ░ ░  ░    ░  ░  ░  ░ ░ ░ ▒   ░░░ ░ ░   ░ ░   ░  ░  ░  
      ░        ░  ░░ ░         ░        ░  ░   ░             ░      ░ ░     ░         ░  ░      ░  
                   ░                         ░                                                     

I see you nerd! ⌐⊙_⊙
*/

contract SacredSouls is ERC2981, ERC721, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter public tokenIdCounter;
    Counters.Counter public burnCounter;
    uint256 public maxTokenSupply;

    uint256 public mintPrice = 0.055 ether;
    uint256 public customizePrice = 0.022 ether;
    uint256 public constant MAX_MINTS_PER_TXN = 7;
    uint256 public maxPresaleMintsPerWallet = 2;

    bool public preSaleIsActive;
    bool public saleIsActive;
    bool public claimIsActive;
    bool public isLocked;

    IERC721 private immutable skullsContract;
    IERC721 private immutable genesisSkullsContract;

    string public baseURI;
    string public provenance;

    mapping (address => uint256) public presaleMints;
    mapping (uint256 => bool) public isTokenClaimed;
    mapping (uint256 => bool) public isGenesisClaimed;

    // errors
    error ProvenanceLocked();
    error NotEnoughEther();
    error ExceedsMaxSupply();
    error SaleNotLive();
    error ClaimNotLive();
    error ExceedsMaxPerTxn();
    error ExceedsMaxPerWallet();
    error InvalidProof();
    error TokenAlreadyClaimed(uint256 tokenId);
    error ClaimerNotOwner(uint256 tokenId);
    error InvalidClaim();

    // replace with merkle root
    bytes32 public merkleRoot = 0xa7226142b67f7c1b77b3997e9cfbb8331d2e518be561419d7d4607b3fe5bafa4;

    event PaymentReleased(address to, uint256 amount);

    struct SoulSelection {
        uint256[4] stackedTokenIds;
        bool isGenesis;
        uint256 quizAnswers;
    }

    event SoulsClaimed(uint256 startTokenId, uint256 numClaimed, SoulSelection[] soulChoices);
    event SoulsMinted(uint256 startTokenId, uint256 numMinted, uint256[] quizAnswers);

    constructor(string memory name, string memory symbol, uint256 maxNfts, address skullsContractAddress, address genesisSkullsAddress) ERC721(name, symbol) {
        maxTokenSupply = maxNfts;

        skullsContract = IERC721(skullsContractAddress);
        genesisSkullsContract = IERC721(genesisSkullsAddress);

        _setDefaultRoyalty(msg.sender, 500);
    }

    function setMaxTokenSupply(uint256 maxNfts) external onlyOwner {
        if (isLocked) {
            revert ProvenanceLocked();
        }

        maxTokenSupply = maxNfts;
    }

    function setMintPrice(uint256 newPrice, uint256 newCustomizePrice) external onlyOwner {
        mintPrice = newPrice;
        customizePrice = newCustomizePrice;
    }

    function setMaxPresaleMintsPerWallet(uint256 newLimit) external onlyOwner {
        maxPresaleMintsPerWallet = newLimit;
    }

    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    function withdraw(uint256 amount, address payable to) external onlyOwner {
        Address.sendValue(to, amount);
        emit PaymentReleased(to, amount);
    }

    /*
    * Mint reserved NFTs for giveaways, devs, etc.
    */
    function reserveMint(uint256 reservedAmount, address mintAddress, uint256[] calldata quizAnswers) external onlyOwner {
        uint256 startTokenId = tokenIdCounter.current() + 1;

        _mintMultiple(reservedAmount, mintAddress);

        emit SoulsMinted(startTokenId, reservedAmount, quizAnswers);
    }

    function _mintMultiple(uint256 numTokens, address mintAddress) internal {
        if (tokenIdCounter.current() + numTokens > maxTokenSupply) {
            revert ExceedsMaxSupply();
        }

        unchecked {
            for (uint256 i = 0; i < numTokens; ++i) {
                tokenIdCounter.increment();
                _mint(mintAddress, tokenIdCounter.current());
            }
        }
    }

    function setStates(bool claimState, bool presaleState, bool saleState) external onlyOwner {
        claimIsActive = claimState;
        preSaleIsActive = presaleState;
        saleIsActive = saleState;
    }

    /*
    * Lock provenance, supply and base URI.
    */
    function lockProvenance() external onlyOwner {
        isLocked = true;
    }

    function totalSupply() external view returns (uint256) {
        return tokenIdCounter.current() - burnCounter.current();
    }

    function hashLeaf(address presaleAddress) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            presaleAddress
        ));
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function claim(SoulSelection[] calldata soulChoices) external payable {
        if (!claimIsActive) {
            revert ClaimNotLive();
        }

        uint256 numCustomizedSouls = 0;
        uint256 numSouls = soulChoices.length;

        unchecked {
            for (uint256 i = 0; i < numSouls; ++i) {
                SoulSelection calldata soulChoice = soulChoices[i];

                if (soulChoice.quizAnswers != 0) {
                    ++numCustomizedSouls;
                }

                for(uint256 j = 0; j < 4; ++j) {
                    if (soulChoice.stackedTokenIds[j] == 0) {
                        if (j == 0) {
                            revert InvalidClaim();
                        }

                        break;
                    }

                    if (soulChoice.isGenesis) {
                        if (isGenesisClaimed[soulChoice.stackedTokenIds[j]]) {
                            revert TokenAlreadyClaimed({
                                tokenId: soulChoice.stackedTokenIds[j]
                            });
                        }

                        if (genesisSkullsContract.ownerOf(soulChoice.stackedTokenIds[j]) != msg.sender) {
                            revert ClaimerNotOwner({
                                tokenId: soulChoice.stackedTokenIds[j]
                            });
                        }

                        isGenesisClaimed[soulChoice.stackedTokenIds[j]] = true;
                    } else {
                        if (isTokenClaimed[soulChoice.stackedTokenIds[j]]) {
                            revert TokenAlreadyClaimed({
                                tokenId: soulChoice.stackedTokenIds[j]
                            });
                        }

                        if (skullsContract.ownerOf(soulChoice.stackedTokenIds[j]) != msg.sender) {
                            revert ClaimerNotOwner({
                                tokenId: soulChoice.stackedTokenIds[j]
                            });
                        }

                        isTokenClaimed[soulChoice.stackedTokenIds[j]] = true;
                    }
                }
            }
        }

        if (msg.value < customizePrice * numCustomizedSouls) {
            revert NotEnoughEther();
        }

        uint256 startTokenId = tokenIdCounter.current() + 1;

        _mintMultiple(numSouls, msg.sender);

        emit SoulsClaimed(startTokenId, numSouls, soulChoices);
    }

    function publicMint(uint256 numberOfTokens, uint256[] calldata quizAnswers) external payable {
        if (!saleIsActive) {
            revert SaleNotLive();
        }

        if (numberOfTokens > MAX_MINTS_PER_TXN) {
            revert ExceedsMaxPerTxn();
        }

        uint256 totalPrice = mintPrice * numberOfTokens + customizePrice * quizAnswers.length;

        if (msg.value < totalPrice) {
            revert NotEnoughEther();
        }

        uint256 startTokenId = tokenIdCounter.current() + 1;

        _mintMultiple(numberOfTokens, msg.sender);

        emit SoulsMinted(startTokenId, numberOfTokens, quizAnswers);
    }

    function presaleMint(uint256 numberOfTokens, uint256[] calldata quizAnswers, bytes32[] calldata merkleProof) external payable {
        if (!preSaleIsActive) {
            revert SaleNotLive();
        }

        if (presaleMints[msg.sender] + numberOfTokens > maxPresaleMintsPerWallet) {
            revert ExceedsMaxPerWallet();
        }

        uint256 totalPrice = mintPrice * numberOfTokens + customizePrice * quizAnswers.length;

        if (msg.value < totalPrice) {
            revert NotEnoughEther();
        }

        // Compute the node and verify the merkle proof
        if (!MerkleProof.verify(merkleProof, merkleRoot, hashLeaf(msg.sender))) {
            revert InvalidProof();
        }

        uint256 startTokenId = tokenIdCounter.current() + 1;

        presaleMints[msg.sender] += numberOfTokens;

        _mintMultiple(numberOfTokens, msg.sender);

        emit SoulsMinted(startTokenId, numberOfTokens, quizAnswers);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        if (isLocked) {
            revert ProvenanceLocked();
        }

        baseURI = newBaseURI;
    }

    /*     
    * Set provenance once it's calculated.
    */
    function setProvenanceHash(string memory provenanceHash) external onlyOwner {
        if (isLocked) {
            revert ProvenanceLocked();
        }

        provenance = provenanceHash;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC2981, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (to == address(0)) {
            burnCounter.increment();
        }
    }
}