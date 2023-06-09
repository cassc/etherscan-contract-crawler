//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/IN.sol";
import "../interfaces/INOwnerResolver.sol";
import "./PerseverancePricing.sol";


/**
 * @title Perseverance
 * @author maximonee (twitter.com/maximonee_)
 * @notice This contract provides minting for the Perseverance NFT by Giorgio Balbi (twitter.com/GiorgioBalbi)
 */
contract Perseverance is PerseverancePricing {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    DerivativeParameters params = DerivativeParameters(false, false, 0, 500, 2);
    mapping(address => bool) allowList;
    mapping(uint256 => bool) nUsed;

    INOwnerResolver public immutable nOwnerResolver;

    constructor (address _n, address masterMint, address dao, address nOwnersRegistry)
        PerseverancePricing("Perseverance", "PSVC", IN(_n), params, 77000000000000000, masterMint, dao)
    {
        // Start token IDs at 1
        _tokenIds.increment();

        nOwnerResolver =  INOwnerResolver(nOwnersRegistry);
    }

    bool public allowListPresaleActive;
    bool public preSaleActive;
    bool public publicSaleActive;
    bool public isSaleHalted;

    uint8 public constant MAX_PUBLIC_MINT = 2;

    // Oct 31 17:30 UTC
    uint32 allowListSaleLaunchTime = 1635701400;
    // Oct 31 18:00 UTC
    uint32 preSaleLaunchTime = 1635703200;
    // Oct 31 20:00 UTC
    uint32 publicSaleLaunchTime = 1635710400;

    string public baseTokenURI = "https://arweave.net/lv6GVLBJZ_L28f_Md0JiVoRLghRAJ-NuSd0ud5BzY_Y/";

    /**
    Updates the presale state for allow list
     */
    function setAllowListPresaleState(bool _allowListPresaleActive) public onlyAdmin {
        allowListPresaleActive = _allowListPresaleActive;
    }

    /**
    Updates the presale state for n holders
     */
    function setPreSaleState(bool _preSaleActiveState) public onlyAdmin {
        preSaleActive = _preSaleActiveState;
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

    function setAllowListAddresses(address[] calldata addresses) external onlyAdmin {
        for(uint256 i = 0; i < addresses.length; i++) {
            allowList[addresses[i]] = true;
        }
    }

    function _isPreSaleActive() internal view returns (bool) {
        if((block.timestamp >= preSaleLaunchTime || preSaleActive) && !isSaleHalted) {
            return true;
        }

        return false;
    }

    function _isPublicSaleActive() internal view returns (bool) {
        if((block.timestamp >= publicSaleLaunchTime || publicSaleActive) && !isSaleHalted) {
            return true;
        }

        return false;
    }

    function _isAllowListActive() internal view returns (bool) {
        if((block.timestamp >= allowListSaleLaunchTime || allowListPresaleActive) && !isSaleHalted) {
            return true;
        }

        return false;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
    Update the base token URI
     */
    function setBaseURI(string memory _newBaseURI) public onlyDAO {
        baseTokenURI = _newBaseURI;
    }

    /**
     * @notice Allow a n token holder to bulk mint tokens with id of their n tokens' id
     * @param recipient Recipient of the mint
     * @param tokenIds Ids to be minted
     * @param paid Amount paid for the mint
     */
    function mintWithN(address recipient, uint256[] calldata tokenIds, uint256 paid) public override virtual nonReentrant {
        uint256 maxTokensToMint = tokenIds.length;
        require(_isPreSaleActive() || (_isAllowListActive() && allowList[recipient]), "Perseverance:PRE_SALE_NOT_ACTIVE");
        require(maxTokensToMint <= totalMintsAvailable(), "NilPass:MAX_ALLOCATION_REACHED");
        require(
            balanceOf(recipient) + maxTokensToMint <= params.maxMintAllowance ||
            (_isPublicSaleActive() && balanceOf(recipient) + maxTokensToMint <= MAX_PUBLIC_MINT),
            "Perseverance:MINT_ABOVE_MAX_MINT_ALLOWANCE"
        );

        // Make sure the same n isn't passed in twice
        // Only need to check first 2 elements as max is 2 per wallet/tx
        if (maxTokensToMint > 1) {
            require(tokenIds[0] != tokenIds[1], "Perseverance:N_TOKENS_MUST_BE_DIFFERENT");
        }

        require(paid == getNextPriceForNHoldersInWei(maxTokensToMint), "NilPass:INVALID_PRICE");

        for (uint256 i = 0; i < maxTokensToMint; i++) {
            require(!nUsed[tokenIds[i]], "Perseverance:N_ALREADY_USED");
        }

        for (uint256 i = 0; i < maxTokensToMint; i++) {
            uint256 tokenId = _tokenIds.current();
            _safeMint(recipient, tokenId);
            _tokenIds.increment();

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
    function mint(address recipient, uint8 amount, uint256 paid) public override virtual nonReentrant {
        require(
            _isPublicSaleActive() ||
            (_isAllowListActive() && allowList[recipient] && balanceOf(recipient) + amount <= params.maxMintAllowance),
            "Perseverance:PUBLIC_SALE_NOT_ACTIVE_OR_NOT_ON_ALLOWLIST"
        );
        require(amount <= totalMintsAvailable(), "NilPass:MAX_ALLOCATION_REACHED");
        require(balanceOf(recipient) + amount <= MAX_PUBLIC_MINT, "Perseverance:MINT_ABOVE_MAX_MINT_ALLOWANCE");

        require(paid == getNextPriceForOpenMintInWei(amount), "NilPass:INVALID_PRICE");

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = _tokenIds.current();
            _safeMint(recipient, tokenId);
            _tokenIds.increment();
        }
    }

    /**
     * @notice Calculate the total available number of mints
     * @return total mint available
     */
    function totalMintsAvailable() public view override returns (uint256) {
        return derivativeParams.maxTotalSupply - totalSupply();
    }

    function canMint(address account) public virtual override view returns (bool) {
        uint256 balance = balanceOf(account);

        if(_isPublicSaleActive() && (totalMintsAvailable() > 0) && balance < MAX_PUBLIC_MINT) {
            return true;
        }

        if(_isPreSaleActive() && (totalMintsAvailable() > 0) && (nOwnerResolver.balanceOf(account) > 0) && (balance < params.maxMintAllowance)) {
            return true;
        }

        if(_isAllowListActive() && (totalMintsAvailable() > 0) && allowList[account] && (balance < params.maxMintAllowance)) {
            return true;
        }

        return false;
    }
}