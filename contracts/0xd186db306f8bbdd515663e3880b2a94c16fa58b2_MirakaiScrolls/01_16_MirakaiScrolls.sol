// ███╗░░░███╗██╗██████╗░░█████╗░██╗░░██╗░█████╗░██╗
// ████╗░████║██║██╔══██╗██╔══██╗██║░██╔╝██╔══██╗██║
// ██╔████╔██║██║██████╔╝███████║█████═╝░███████║██║
// ██║╚██╔╝██║██║██╔══██╗██╔══██║██╔═██╗░██╔══██║██║
// ██║░╚═╝░██║██║██║░░██║██║░░██║██║░╚██╗██║░░██║██║
// ╚═╝░░░░░╚═╝╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝
//
// This is the main contract that mints scrolls and rerolls dna.
// DNA is 256 random bits where every 14 bits is a trait, can think that each trait slot is 14 bits.
//
// Lets say DNA =
// 11010111011111 11010001011111 00010111011111 11010100011111 ... etc ...
// |-clan trait-| |-head trait-| |-eye trait-| |- etc -|
//
// Re-rolling a trait works by generating a random 14 bit number and replacing the desired trait.
// Lets say we want to replace the head trait with NEW_HEAD = 00001111111111
//
// These are the steps to replace the head trait:
//
// 1. Create a 14 bit BITMASK of 1s -> 11111111111111
//
// 2. Shift the bitmask to match the head trait slot (14 bit increments) and negate the mask.
// Now we have
// DNA     = 11010111011111 11010001011111 00010111011111 11010100011111 ... etc ...
// BITMASK =                00000000000000 11111111111111 11111111111111 ... etc ...
//
// 3. We bitwise AND DNA with BITMASK to 'zero' out the head trait. DNA now looks like
// 11010111011111 00000000000000 00010111011111 11010100011111 ... etc ...
//
// 4. Grab the new head trait (00001111111111) and shift it into the head slot, similar to the bitmask.
// DNA      = 11010111011111 00000000000000 00010111011111 11010100011111 ... etc ...
// NEW_HEAD =                00001111111111 00000000000000 00000000000000 ... etc ...
//
// 5. We bitwise OR DNA with NEW_HEAD to add the new head trait. Now are DNA looks like
// 11010111011111 00001111111111 00010111011111 11010100011111 ... etc ...
//
// We did it!

///@author 0xBeans
///@dev This contract contains all scroll minting and trait re-rolling

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./interfaces/IMirakaiScrollsRenderer.sol";
import "./interfaces/IOrbsToken.sol";

import {console} from "forge-std/console.sol";

contract MirakaiScrolls is Ownable, ERC721 {
    using ECDSA for bytes32;

    /*==============================================================
    ==                        Custom Errors                       ==
    ==============================================================*/

    error CallerIsContract();
    error InvalidSignature();
    error MintNotActive();
    error NotEnoughSupply();
    error IncorrectEtherValue();
    error MintQuantityTooHigh();
    error TeamMintOver();
    error NotTokenOwner();
    error UnrollableTrait();
    error TokenDoesNotExist();
    error WalletAlreadyMinted();
    error ERC721Burnable_CallerIsNotOwnerNorApproved();

    // this is 14 bits of 1s - the size of a trait 'slot' in the dna
    uint256 public constant BIT_MASK_LENGTH = 14;
    uint256 public constant BIT_MASK = 2**BIT_MASK_LENGTH - 1;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 private constant TOTAL_BPS = 10000;
    uint256 public constant TEAM_RESERVE = 50;
    uint256 private constant CC0_TRAIT_MULTIPLE = 9;
    uint256 private constant CC0_MAX_MINT = 8000;

    uint256 public basePrice;
    uint256 public mintprice;
    uint256 public cc0TraitsProbability;

    // cost in ORBS to reroll trait
    uint256 public rerollTraitCost;
    uint256 public numTeamMints;

    // for pseudo-rng
    uint256 private _seed;
    uint256 private _totalSupply;
    uint256 private _totalBurned;

    function totalSupply() external view returns (uint256) {
        return _totalSupply - _totalBurned;
    }

    address public scrollsRenderer;
    address public orbsToken;

    // public key for sig verification
    address private _cc0_signer;
    address private _allowlist_signer;

    bool public mintIsActive;
    bool public cc0MintIsActive;
    bool public allowListMintIsActive;

    // tokenId to dna
    mapping(uint256 => uint256) public dna;

    mapping(address => uint256) private allowListMinted;
    mapping(bytes => uint256) private cc0SignatureUsed;

    constructor() ERC721("Mirakai Scrolls", "MIRAKAI_SCROLLS") {}

    /*==============================================================
    ==                     Minting Functions                      ==
    ==============================================================*/

    /**
     * @notice public mint
     * @dev we don't use signatures here as we expect low botting due to bear market lmao
     * and we'd rather save gas here as most of our mint is cc0 mint and WL regardless.
     * We're pre-signing out WL and cc0Mint to prevent any signer endpoint leakage.
     * We prevent contract mints as well.
     * @param quantity self-explanatory lmao, max 5
     */
    function publicMint(uint256 quantity) external payable {
        uint256 currSupply = _totalSupply;

        if (tx.origin != msg.sender) revert CallerIsContract();
        if (!mintIsActive) revert MintNotActive();
        if (currSupply + quantity > MAX_SUPPLY) revert NotEnoughSupply();
        if (quantity > 5) revert MintQuantityTooHigh();
        if (quantity * mintprice != msg.value) revert IncorrectEtherValue();

        unchecked {
            uint256 i;
            for (; i < quantity; ) {
                mint(currSupply++);
                ++i;
            }
        }

        _totalSupply = currSupply;
    }

    /**
     * @notice allowlist mint. 1 per address
     * @param signature signature used for verification
     */
    function allowListMint(bytes calldata signature) external payable {
        uint256 currSupply = _totalSupply;

        // even though there is no re-entrancy and we invalidate signatures,
        // prevent contracts from gaming psuedo rng by reverting mints based on
        // tokenDna
        if (tx.origin != msg.sender) revert CallerIsContract();
        if (!allowListMintIsActive) revert MintNotActive();
        if (currSupply + 1 > MAX_SUPPLY) revert NotEnoughSupply();
        // if (msg.value != mintprice) revert IncorrectEtherValue();
        if (msg.value < basePrice) revert IncorrectEtherValue();
        if (allowListMinted[msg.sender] > 0) revert WalletAlreadyMinted();
        if (
            !verify(
                getMessageHash(msg.sender, 1, 0),
                signature,
                _allowlist_signer
            )
        ) revert InvalidSignature();

        allowListMinted[msg.sender] = 1;

        unchecked {
            mint(currSupply++);
        }

        _totalSupply = currSupply;
    }

    /**
     * @notice mint a scroll with a possibility to have 'borrowed' cc0 trait
     * @param cc0Index the index for the cc0 trait
     * @param signature signature for verification
     */
    function cc0Mint(uint256 cc0Index, bytes calldata signature)
        external
        payable
    {
        uint256 currSupply = _totalSupply;

        // even though there is no re-entrancy and we invalidate signatures,
        // prevent contracts from gaming psuedo rng by reverting mints based on
        // tokenDna
        if (tx.origin != msg.sender) revert CallerIsContract();
        if (!cc0MintIsActive) revert MintNotActive();
        if (currSupply + 1 > CC0_MAX_MINT) revert NotEnoughSupply();
        // msg.value can be > basePrice due to tipping
        if (msg.value < basePrice) revert IncorrectEtherValue();

        // can mint multiple different cc0s if wallet contains them,
        // so we have to nullify signatures rather than msg.sender
        if (cc0SignatureUsed[signature] > 0) revert WalletAlreadyMinted();

        if (
            !verify(
                getMessageHash(msg.sender, 1, cc0Index),
                signature,
                _cc0_signer
            )
        ) revert InvalidSignature();

        unchecked {
            uint256 tokenDna = uint256(
                keccak256(
                    abi.encodePacked(
                        currSupply,
                        block.coinbase,
                        block.timestamp,
                        _seed++
                    )
                )
            );

            // if rolled a cc0Trait
            // cc0TraitsProbability should be in basis points.
            if (
                (tokenDna >> (BIT_MASK_LENGTH * CC0_TRAIT_MULTIPLE)) %
                    TOTAL_BPS <
                cc0TraitsProbability
            ) {
                tokenDna = setDna(tokenDna, cc0Index);
            } else {
                // cc0 trait 0 == no cc0 trait rolled
                tokenDna = setDna(tokenDna, 0);
            }

            cc0SignatureUsed[signature] = 1;
            dna[currSupply] = tokenDna;

            _mint(msg.sender, currSupply++);
        }

        _totalSupply = currSupply;
    }

    /**
     * @dev internal mint func that sets DNA before minting
     */
    function mint(uint256 tokenId) internal {
        unchecked {
            dna[tokenId] = setDna(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            tokenId,
                            block.coinbase,
                            block.timestamp,
                            _seed++
                        )
                    )
                ),
                0 // no cc0Trait
            );
        }

        _mint(msg.sender, tokenId);
    }

    /*==============================================================
    ==                    Change DNA Functions                    ==
    ==============================================================*/

    /**
     * @dev sets the 10th 'slot' to 0 (no cc0 trait) or a cc0 index
     * @param scrollDna dna
     * @param cc0TraitIndex 0 or a cc0 index
     * NO_CC0_INDEX = 0
     * CHAIN_RUNNER_CC0_INDEX = 1
     * BLITMAP_CC0_INDEX = 2
     * NOUN_CC0_INDEX = 3
     * MFER_CC0_INDEX = 4
     * CRYPTOADZ_CC0_INDEX = 5
     * ANONYMICE_CC0_INDEX = 6
     * GOBLIN_CC0_INDEX = 7
     */
    function setDna(uint256 scrollDna, uint256 cc0TraitIndex)
        internal
        pure
        returns (uint256)
    {
        uint256 newBitMask = ~(BIT_MASK <<
            (BIT_MASK_LENGTH * CC0_TRAIT_MULTIPLE));
        return
            (scrollDna & newBitMask) |
            (cc0TraitIndex << (BIT_MASK_LENGTH * CC0_TRAIT_MULTIPLE));
    }

    /**
     * @dev dna is split into 14 bit 'slots'. Reroll works by 'zeroing' out the desired
     * slot and replacing it with pseudo-random 14 bits. Explanation on top.
     * @param tokenId scrollId
     * @param traitBitShiftMultiplier the trait 'slot'. ie 2 means slot 2 (shift 2*14 bits to the slot).
     * CLAN_BITSHIFT_MULTIPLE = 0;
     * GENUS_BITSHIFT_MULTIPLE = 1;
     * HEAD_BITSHIFT_MULTIPLE = 2;
     * EYES_BITSHIFT_MULTIPLE = 3;
     * MOUTH_BITSHIFT_MULTIPLE = 4;
     * UPPER_BITSHIFT_MULTIPLE = 5;
     * LOWER_BITSHIFT_MULTIPLE = 6;
     * WEAPON_BITSHIFT_MULTIPLE = 7;
     * MARKING_BITSHIFT_MULTIPLE = 8;
     * CC0_TRAIT_MULTIPLE = 9;
     */
    function rerollTrait(uint256 tokenId, uint256 traitBitShiftMultiplier)
        external
    {
        // prevent contract calls to try to mitigate gaming the pseudo-rng
        if (tx.origin != msg.sender) revert CallerIsContract();
        if (ownerOf(tokenId) != msg.sender) revert NotTokenOwner();
        // cant reroll clan or cc0Trait
        if (traitBitShiftMultiplier == 0 || traitBitShiftMultiplier > 8)
            revert UnrollableTrait();

        IOrbsToken(orbsToken).burn(msg.sender, rerollTraitCost);

        uint256 currDna = dna[tokenId];
        unchecked {
            uint256 newTraitDna = (uint256(
                keccak256(
                    abi.encodePacked(
                        block.coinbase,
                        block.timestamp,
                        _seed++,
                        tokenId
                    )
                )
            ) % TOTAL_BPS) << (BIT_MASK_LENGTH * traitBitShiftMultiplier);

            uint256 newBitMask = ~(BIT_MASK <<
                (BIT_MASK_LENGTH * traitBitShiftMultiplier));

            currDna &= newBitMask;
            currDna |= newTraitDna;
        }
        dna[tokenId] = currDna;
    }

    /*==============================================================
    ==                            RNG                             ==
    ==============================================================*/

    /**
     * @notice anyone can increment seed anytime, attempts to add more entropy
     * @dev since dna is pseudo-random, this aims to add more randomness to make
     * @dev it harder to game. It may be futile, but tried my best lol.
     */
    function incrementSeed() external {
        // overflows are okay
        unchecked {
            ++_seed;
        }
    }

    /*==============================================================
    ==                       View Functions                       ==
    ==============================================================*/

    /**
     * @dev returns empty string if no renderer is set
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert TokenDoesNotExist();

        if (scrollsRenderer == address(0)) {
            return "";
        }

        return
            IMirakaiScrollsRenderer(scrollsRenderer).tokenURI(
                _tokenId,
                dna[_tokenId]
            );
    }

    /**
     * @dev should ONLY be called off-chain. Used for displaying wallet's scrolls
     */
    function walletOfOwner(address addr)
        external
        view
        returns (uint256[] memory)
    {
        uint256 count;
        uint256 walletBalance = balanceOf(addr);
        uint256[] memory tokens = new uint256[](walletBalance);

        uint256 i;
        for (; i < MAX_SUPPLY; ) {
            // early break if all tokens found
            if (count == walletBalance) {
                return tokens;
            }

            // exists will prevent throw if burned token
            if (_exists(i) && ownerOf(i) == addr) {
                tokens[count] = i;
                count++;
            }

            ++i;
        }
        return tokens;
    }

    /*==============================================================
    ==                        721 Overrides                       ==
    ==============================================================*/

    function burn(uint256 tokenId) external {
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
            revert ERC721Burnable_CallerIsNotOwnerNorApproved();
        }

        _burn(tokenId);
        delete dna[tokenId];

        unchecked {
            ++_totalBurned;
        }
    }

    /**
     * @dev override to add/remove token dripping on transfers/burns
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (from != address(0)) {
            IOrbsToken(orbsToken).stopDripping(from, 1);
        }

        if (to != address(0)) {
            IOrbsToken(orbsToken).startDripping(to, 1);
        }

        super._beforeTokenTransfer(from, to, tokenId);
    }

    /*==============================================================
    ==                    Only Owner Functions                    ==
    ==============================================================*/

    /**
     * @dev can be called more than once, but most likely wont be
     */
    function initialize(
        address _scrollsRenderer,
        address _orbsToken,
        address _cc0_signerAddr,
        address _allowlist_signerAddr,
        uint256 _basePrice,
        uint256 _cc0TraitsProbability,
        uint256 _rerollTraitCost,
        uint256 _seedNum
    ) external onlyOwner {
        scrollsRenderer = _scrollsRenderer;
        orbsToken = _orbsToken;
        _cc0_signer = _cc0_signerAddr;
        _allowlist_signer = _allowlist_signerAddr;
        basePrice = _basePrice;
        cc0TraitsProbability = _cc0TraitsProbability;
        rerollTraitCost = _rerollTraitCost;
        _seed = _seedNum;
    }

    function teamMint(uint256 quantity) external onlyOwner {
        uint256 currSupply = _totalSupply;

        if (
            quantity > (TEAM_RESERVE - numTeamMints) ||
            numTeamMints > TEAM_RESERVE
        ) revert TeamMintOver();
        // check MAX_SUPPLY incase we try to mint after we open public mints
        if (currSupply + quantity > MAX_SUPPLY) revert NotEnoughSupply();

        unchecked {
            uint256 i;
            for (; i < quantity; ) {
                ++numTeamMints;
                mint(currSupply++);

                ++i;
            }
        }

        _totalSupply = currSupply;
    }

    function setscrollsRenderer(address _scrollsRenderer) external onlyOwner {
        scrollsRenderer = _scrollsRenderer;
    }

    function setOrbsTokenAddress(address _orbsToken) external onlyOwner {
        orbsToken = _orbsToken;
    }

    function setCc0Signer(address signer) external onlyOwner {
        _cc0_signer = signer;
    }

    function setAllowlistSigner(address signer) external onlyOwner {
        _allowlist_signer = signer;
    }

    function setBasePrice(uint256 _basePrice) external onlyOwner {
        basePrice = _basePrice;
    }

    function setCc0TraitsProbability(uint256 _cc0TraitsProbability)
        external
        onlyOwner
    {
        cc0TraitsProbability = _cc0TraitsProbability;
    }

    function setRerollCost(uint256 _rerollTraitCost) external onlyOwner {
        rerollTraitCost = _rerollTraitCost;
    }

    function flipMint() external onlyOwner {
        mintIsActive = !mintIsActive;
    }

    function flipCC0Mint() external onlyOwner {
        cc0MintIsActive = !cc0MintIsActive;
    }

    function flipAllowListMint() external onlyOwner {
        allowListMintIsActive = !allowListMintIsActive;
    }

    function setSeed(uint256 seed) external onlyOwner {
        _seed = seed;
    }

    // price set after cc0 mint
    function setMintPrice(uint256 price) external onlyOwner {
        mintprice = price;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /*==============================================================
    ==                     Sig Verification                       ==
    ==============================================================*/

    function verify(
        bytes32 messageHash,
        bytes memory signature,
        address _signer
    ) internal pure returns (bool) {
        return
            messageHash.toEthSignedMessageHash().recover(signature) == _signer;
    }

    function getMessageHash(
        address account,
        uint256 quantity,
        uint256 cc0TraitIndex
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, quantity, cc0TraitIndex));
    }
}