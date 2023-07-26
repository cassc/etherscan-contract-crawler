//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../interfaces/IN.sol";
import "../interfaces/INOwnerResolver.sol";
import "../interfaces/IKarmaScore.sol";
import "./VisionsPricing.sol";

/**
 * @title Visio(n)s
 */
contract Visions is VisionsPricing {
    using Strings for uint256;
    using Counters for Counters.Counter;

    string public baseTokenURI;
    string public metadataExtension;

    bool public karmaSaleActive;
    bool public nHolderSaleActive;
    bool public publicSaleActive;
    bool public isSaleHalted;
    bool public airdropClaimed;

    uint256 public constant KARMASALE_AMOUNT = 160;
    uint256 public constant NHOLDERSALE_AMOUNT = 60;
    uint256 public constant AIRDROP_RESERVE = 50;

    // Nov 17 18:00 UTC
    uint32 karmaSaleLaunchTime = 1637172000;
    // Nov 17 19:00 UTC (1 hour later)
    uint32 nHolderSaleLaunchTime = karmaSaleLaunchTime + 3600;
    // Nov 17 20:00 UTC (1 hour later)
    uint32 publicSaleLaunchTime = nHolderSaleLaunchTime + 3600;

    DerivativeParameters params = DerivativeParameters(false, false, 0, 383, 4);
    mapping(uint256 => bool) public override nUsed;

    INOwnerResolver public immutable nOwnerResolver;
    IKarmaScore public immutable karmaScoreResolver;

    constructor(
        address _n,
        address masterMint,
        address dao,
        address nOwnersRegistry,
        address karmaScore        
    ) VisionsPricing("Visio(n)s", "VISIONS", IN(_n), params, 77000000000000000, masterMint, dao) {
        // Start token IDs at 1
        baseTokenURI = "https://arweave.net/hDGOAc0ku7--6GRnTfPKsM3bkvjIXLi-0MIkOFEMSJw/";
        metadataExtension = ".json";

        nOwnerResolver = INOwnerResolver(nOwnersRegistry);
        karmaScoreResolver = IKarmaScore(karmaScore);
    }

    function claimAirdrop(address[] memory recipients) public onlyAdmin {
        require(!airdropClaimed, "Visions: AIRDROP_ALREADY_CLAIMED");
        uint256 recipientsLength = recipients.length;
        for (uint256 i = 0; i < 50; i++) {
            _mint(recipients[i % recipientsLength], i + 1);
        }
        airdropClaimed = true;
    }

    /**
    Updates the karma sale state for n holders
     */
    function setKarmaSaleState(bool _preSaleActiveState) public onlyAdmin {
        karmaSaleActive = _preSaleActiveState;
    }

    /**
    Updates the n holder sale state for n holders
     */
    function setnHolderSaleState(bool _nHolderSaleState) public onlyAdmin {
        nHolderSaleActive = _nHolderSaleState;
    }

    /**
    Updates the public sale state for non-n holders
     */
    function setPublicSaleState(bool _publicSaleActiveState) public onlyAdmin {
        publicSaleActive = _publicSaleActiveState;
    }

    /**
    Give the ability to halt the sale if necessary due to automatic sale enablement based on time
     */
    function setSaleHaltedState(bool _saleHaltedState) public onlyAdmin {
        isSaleHalted = _saleHaltedState;
    }

    /**
    Return true if the high karma sale is active
     */
    function _isKarmaSaleActive() internal view returns (bool) {
        return ((block.timestamp >= karmaSaleLaunchTime || karmaSaleActive) && !isSaleHalted);
    }

    /**
    Return true if the regular karma sale is active
     */
    function _isnHolderSaleActive() internal view returns (bool) {
        return ((block.timestamp >= nHolderSaleLaunchTime || nHolderSaleActive) && !isSaleHalted);
    }

    /**
    Return true if the public sale is active
     */
    function _isPublicSaleActive() internal view returns (bool) {
        return ((block.timestamp >= publicSaleLaunchTime || publicSaleActive) && !isSaleHalted);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(super.tokenURI(tokenId), metadataExtension));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURIAndExtension(string calldata baseTokenUri_, string calldata metadataExtension_)
        external
        onlyDAO
    {
        baseTokenURI = baseTokenUri_;
        metadataExtension = metadataExtension_;
    }

    /**
    Return the max number of mints per wallet (2 when presale, 4 when public)
     */
    function _maxMintsPerWallet() internal view returns (uint256) {
        return _isPublicSaleActive() ? 4 : 2;
    }

    function getKarma(bytes calldata data) internal view returns (uint256) {
        if (data.length > 0) {
            (address account, uint256 karmaScore, bytes32[] memory merkleProof) = abi.decode(
                data,
                (address, uint256, bytes32[])
            );
            if (karmaScoreResolver.verify(account, karmaScore, merkleProof)) {
                return account == address(0) ? 1000 : karmaScore;
            }
        }
        return 1000;
    }

    /**
     * @notice Allow a n token holder to bulk mint tokens with id of their n tokens' id
     * @param recipient Recipient of the mint
     * @param tokenIds Ids to be minted
     * @param paid Amount paid for the mint
     * @param data data to verify Merkle proof
     */
    function mintWithN(
        address recipient,
        uint256[] calldata tokenIds,
        uint256 paid,
        bytes calldata data
    ) public virtual override nonReentrant {
        uint256 maxTokensToMint = tokenIds.length;
        uint256 karma = getKarma(data);
        require(
            (_isPublicSaleActive()) || (karmaSaleActive && karma >= 1020) || (nHolderSaleActive && karma >= 1000),
            "Visions:SALE_NOT_OPEN_FOR_YOU"
        );
        require(maxTokensToMint <= totalMintsAvailable(), "NilPass:MAX_ALLOCATION_REACHED");
        require(balanceOf(recipient) + maxTokensToMint <= _maxMintsPerWallet(), "Visions:MINT_ABOVE_ALLOWANCE");

        require(paid == getNextPriceForNHoldersInWei(maxTokensToMint), "NilPass:INVALID_PRICE");

        for (uint256 i = 0; i < maxTokensToMint; i++) {
            require(!nUsed[tokenIds[i]], "Visions:N_ALREADY_USED");
            uint256 tokenId = totalSupply() + 1;
            _safeMint(recipient, tokenId);

            nUsed[tokenIds[i]] = true;
        }
    }

    /**
     * @notice Allow anyone to mint a token with the supply id if this pass is unrestricted.
     *         n token holders can use this function without using the n token holders allowance,
     *         this is useful when the allowance is fully utilized.
     * @param recipient Recipient of the mint
     * @param amount Amount of tokens to mint
     * @param paid Amount paid for the mint
     */
    function mint(
        address recipient,
        uint8 amount,
        uint256 paid,
        bytes calldata
    ) public virtual override nonReentrant {
        require(_isPublicSaleActive(), "Visions:USER_NOT_ALLOWED_TO_MINT");
        require(amount <= totalMintsAvailable(), "NilPass:MAX_ALLOCATION_REACHED");
        require(balanceOf(recipient) + amount <= _maxMintsPerWallet(), "NilPass:MINT_ABOVE_MAX_MINT_ALLOWANCE");

        require(paid == getNextPriceForOpenMintInWei(amount), "NilPass:INVALID_PRICE");

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = totalSupply() + 1;
            _safeMint(recipient, tokenId);
        }
    }

    /**
     * @notice Calculate the currently available number of reserved tokens for n token holders
     * @return Reserved mint available
     */
    function nHoldersMintsAvailable() public view override returns (uint256) {
        return totalMintsAvailable();
    }

    /**
     * @notice Calculate the currently available number of open mints
     * @return Open mint available
     */
    function openMintsAvailable() public view override returns (uint256) {
        if (_isPublicSaleActive()) {
            return params.maxTotalSupply + 1 - totalSupply() + 1;
        } else if (_isnHolderSaleActive()) {
            return 0;
        } else {
            return 0;
        }
    }

    /**
     * @notice Calculate the total available number of mints
     * @return total mint available
     */
    function totalMintsAvailable() public view override returns (uint256) {
        if (_isPublicSaleActive()) {
            return params.maxTotalSupply - totalSupply();
        } else if (_isnHolderSaleActive()) {
            return KARMASALE_AMOUNT + NHOLDERSALE_AMOUNT + AIRDROP_RESERVE - totalSupply();
        } else {
            return KARMASALE_AMOUNT + AIRDROP_RESERVE - totalSupply();
        }
    }

    function canMint(address account, bytes calldata data) public view virtual override returns (bool) {
        bool mintsAvailable = totalMintsAvailable() > 0;
        bool balanceBelow = balanceOf(account) < _maxMintsPerWallet();
        bool hasN = nOwnerResolver.balanceOf(account) > 0;

        /**
         * Karma Pre-sale
         * Karma >= 1020
         * 160 pieces
         * 2 per wallet
         */
        if (
            _isKarmaSaleActive() &&
            mintsAvailable &&
            balanceBelow &&
            hasN &&
            getKarma(data) >= 1020
        ) {
            return true;
        }

        /**
         * Karma Pre-sale
         * Karma >= 1000
         * 60 pieces
         * 2 per wallet
         */
        if (
            _isnHolderSaleActive() &&
            mintsAvailable &&
            balanceBelow &&
            hasN &&
            getKarma(data) >= 1000
        ) {
            return true;
        }

        // Public
        if (_isPublicSaleActive() && mintsAvailable && balanceBelow) {
            return true;
        }

        return false;
    }
}