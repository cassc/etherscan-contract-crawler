// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./lib/ERC721EnumerableOpensea.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./lib/IWCNFTErrorCodes.sol";
import "./lib/WCNFTToken.sol";
import "./lib/WCNFTMerkle.sol";
import "./external/delegate-cash/IDelegationRegistry.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

contract AnthonyJames is
    ReentrancyGuard,
    WCNFTMerkle,
    WCNFTToken,
    IWCNFTErrorCodes,
    ERC721EnumerableOpensea
{
    using BitMaps for BitMaps.BitMap;

    uint256 public constant TIER_1_MAX_SUPPLY = 1060;
    uint256 public constant TIER_2_TOKEN_ID_START = 2000;
    uint256 public constant MAX_PUBLIC_MINT = 1;
    uint256 public constant PRICE_PER_TOKEN = 0.2 ether;

    // state machine
    enum Stages {
        Initialization,
        MintPass,
        MintPassEnded,
        AllowList,
        AllowListEnded,
        PublicSale,
        PublicSaleEnded,
        Redeem,
        Finished
    }

    /// function cannot be called at this time.
    error FunctionInvalidAtThisStage();

    /// check delegate.cash for contract delegation
    error NotDelegatedOnContract();

    /// check delegate.cash for token delegation
    error NotDelegatedOnToken(uint256 tokenId);

    /// cannot claim if token id has already been claimed
    error TokenIdAlreadyClaimed(uint256 tokenId);

    /// callee is not the owner of the token id in the base contract
    error NotOwnerOfMintPass(uint256 tokenId);

    /// to redeem a new token, must provide 2 or 5 tokens
    error InvalidRedemptionQuantity();

    /// invalid token id to burn
    error InvalidTokenIdToBurn(uint256 tokenId);

    /// call not owner nor approved
    error TransferCallerNotOwnerNorApproved();

    /// cannot set base contract address if not ERC721Enumerable
    error ContractIsNotERC721Enumerable();

    /// cannot set tier 2 ids less than tier 1 max supply
    error Tier2TokenIdStartMustBeGreaterThanTier1Supply();

    /// cannot use invalid goda mint pass token ids
    error InvalidMintPassTokenId();

    // this is the current stage
    Stages public stage = Stages.Initialization;

    BitMaps.BitMap private _bitmap;
    string public provenance;
    string private _baseURIextended;

    IERC721Enumerable public immutable baseContractAddress;
    address payable public immutable shareholderAddress;
    address private constant _DELEGATION_REGISTRY =
        0x00000000000076A84feF008CDAbe6409d2FE638B;

    // maintain minting and burn counters for different tiers
    uint16 public tier1Minted;
    uint16 public tier2Minted;
    uint16 public tier1Burned;

    /**
     * @dev constructor
     * @param shareholderAddress_ the shareholder address
     * @param contractAddress the contract address for mint passes
     */
    constructor(
        address payable shareholderAddress_,
        address contractAddress
    ) ERC721("Anthony James - Platonic Solids", "ANTHONYJAMES") WCNFTToken() {
        if (shareholderAddress_ == address(0)) revert ZeroAddressProvided();
        if (
            !IERC721Enumerable(contractAddress).supportsInterface(
                type(IERC721Enumerable).interfaceId
            )
        ) {
            revert ContractIsNotERC721Enumerable();
        }
        if (TIER_2_TOKEN_ID_START < TIER_1_MAX_SUPPLY) {
            revert Tier2TokenIdStartMustBeGreaterThanTier1Supply();
        }

        // set immutable variables
        shareholderAddress = shareholderAddress_;
        baseContractAddress = IERC721Enumerable(contractAddress);
    }

    /**
     * @dev checks to see if amount of tokens to be minted would exceed the
     *  maximum supply allowed
     * @param numberOfTokens the number of tokens to be minted
     */
    modifier tier1SupplyAvailable(uint256 numberOfTokens) {
        if (tier1Minted + numberOfTokens > TIER_1_MAX_SUPPLY) {
            revert ExceedsMaximumSupply();
        }
        _;
    }

    /**
     * @dev checks to see whether the contract is at the correct stage
     * @param stage_ the stage that the contract should be in
     */
    modifier atStage(Stages stage_) {
        if (stage != stage_) {
            revert FunctionInvalidAtThisStage();
        }
        _;
    }

    /**
     * @dev transitions to the next stage after operations have been completed
     */
    modifier transitionNext() {
        _;
        _nextStage();
    }

    /**
     * @dev advance to the next stage
     */
    function _nextStage() internal {
        stage = Stages(uint256(stage) + 1);
    }

    /**
     * @dev only for use when a stage has been advanced incorrectly
     * @param stage_ the stage to advance to
     */
    function setStage(Stages stage_) external onlyOwner {
        stage = stage_;
    }

    /***************************************************************************
     * Admin
     */
    /**
     * @dev mints tokens for tier1
     * @param to recipient address
     * @param numberOfTokens number of tokens to mint
     */
    function _mintTier1(address to, uint256 numberOfTokens) internal {
        uint256 tokenIdStart = tier1Minted;
        tier1Minted = uint16(tokenIdStart + numberOfTokens);

        for (uint256 index; index < numberOfTokens; ) {
            _safeMint(to, tokenIdStart + index);

            unchecked {
                ++index;
            }
        }
    }

    /**
     * @dev mints tokens for tier2
     * @param to recipient address
     * @param numberOfTokens number of tokens to mint
     */
    function _mintTier2(address to, uint256 numberOfTokens) internal {
        uint256 tokenIdStart = TIER_2_TOKEN_ID_START + tier2Minted;
        tier2Minted = uint16(tier2Minted + numberOfTokens);

        for (uint256 index; index < numberOfTokens; ) {
            _safeMint(to, tokenIdStart + index);

            unchecked {
                ++index;
            }
        }
    }

    /**
     * @dev reserves a number of tokens
     * @param to recipient address
     * @param numberOfTokens the number of tokens to be minted
     */
    function devMint(
        address to,
        uint256 numberOfTokens
    )
        external
        onlyRole(SUPPORT_ROLE)
        tier1SupplyAvailable(numberOfTokens)
        nonReentrant
    {
        _mintTier1(to, numberOfTokens);
    }

    /***************************************************************************
     * State Machine Transitions
     */
    /**
     * @dev start mint pass stage
     */
    function startMintPassStage()
        external
        onlyRole(SUPPORT_ROLE)
        atStage(Stages.Initialization)
        transitionNext
    {}

    /**
     * @dev stop mint pass stage
     */
    function stopMintPassStage()
        external
        onlyRole(SUPPORT_ROLE)
        atStage(Stages.MintPass)
        transitionNext
    {}

    /**
     * @dev start allow list mint stage
     */
    function startAllowListStage()
        external
        onlyRole(SUPPORT_ROLE)
        atStage(Stages.MintPassEnded)
        transitionNext
    {}

    /**
     * @dev stop allow list mint stage
     */
    function stopAllowListStage()
        external
        onlyRole(SUPPORT_ROLE)
        atStage(Stages.AllowList)
        transitionNext
    {}

    /**
     * @dev start public sale stage
     */
    function startPublicSaleStage()
        external
        onlyRole(SUPPORT_ROLE)
        atStage(Stages.AllowListEnded)
        transitionNext
    {}

    /**
     * @dev stop public sale stage
     */
    function stopPublicSaleStage()
        external
        onlyRole(SUPPORT_ROLE)
        atStage(Stages.PublicSale)
        transitionNext
    {}

    /**
     * @dev start redeem stage
     */
    function startRedeemStage()
        external
        onlyRole(SUPPORT_ROLE)
        atStage(Stages.PublicSaleEnded)
        transitionNext
    {}

    /**
     * @dev stop redeem stage
     */
    function stopRedeemStage()
        external
        onlyRole(SUPPORT_ROLE)
        atStage(Stages.Redeem)
        transitionNext
    {}

    /***************************************************************************
     * Tokens
     */
    /**
     * @dev sets the base uri for {_baseURI}
     * @param baseURI_ the base uri
     */
    function setBaseURI(
        string calldata baseURI_
    ) external onlyRole(SUPPORT_ROLE) {
        _baseURIextended = baseURI_;
    }

    /**
     * @dev See {ERC721-_baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    /**
     * @dev sets the provenance hash
     * @param provenance_ the provenance hash
     */
    function setProvenance(
        string calldata provenance_
    ) external onlyRole(SUPPORT_ROLE) {
        provenance = provenance_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     * @param interfaceId the interface id
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Enumerable, WCNFTToken, AccessControl)
        returns (bool)
    {
        return
            ERC721Enumerable.supportsInterface(interfaceId) ||
            WCNFTToken.supportsInterface(interfaceId);
    }

    /***************************************************************************
     * Public
     */
    /**
     * @dev returns the supply in tier 1 (minted - burned)
     */
    function tier1Supply() external view returns (uint256) {
        return tier1Minted - tier1Burned;
    }

    /**
     * @dev returns the supply in tier 2
     */
    function tier2Supply() external view returns (uint256) {
        return tier2Minted;
    }

    /**
     * @dev checks to see whether a mint pass has been previously used
     * @param tokenId the token id
     */
    function mintPassClaimed(uint256 tokenId) public view returns (bool) {
        return _bitmap.get(tokenId);
    }

    /**
     * @notice delegate.cash is an unaffiliated external service, use it at your
     *  own risk! Their docs are available at http://delegate.cash
     *  The function expects either the user executing this function to own all
     *  of the tokens ids, or have been delegated for all of the token ids (no
     *  mixing).
     *
     * @dev allows minting using a mint pass
     * @param vault if using delegate.cash, the address that holds the mint pass.
     *  Set this to 0x000..000 if not using delegation.
     * @param tokenIds the GODA Mint Pass token IDs to claim
     */
    function mintWithMintPass(
        address vault,
        uint256[] memory tokenIds
    )
        public
        payable
        atStage(Stages.MintPass)
        tier1SupplyAvailable(tokenIds.length)
        nonReentrant
    {
        uint256 tokenIdsLength = tokenIds.length;

        // check if price is correct
        if (PRICE_PER_TOKEN * tokenIdsLength != msg.value) {
            revert WrongETHValueSent();
        }

        for (uint256 index; index < tokenIdsLength; ) {
            uint256 tokenId = tokenIds[index];
            address claimer = msg.sender;

            // mint passes only valid from 0-999
            if (tokenId >= 1000) {
                revert InvalidMintPassTokenId();
            }

            // check if mint pass has been used
            if (mintPassClaimed(tokenId)) {
                revert TokenIdAlreadyClaimed(tokenId);
            }

            // check vault if using delegation
            if (vault != address(0) && vault != msg.sender) {
                if (
                    !(
                        IDelegationRegistry(_DELEGATION_REGISTRY)
                            .checkDelegateForToken(
                                msg.sender,
                                vault,
                                address(baseContractAddress),
                                tokenId
                            )
                    )
                ) {
                    revert NotDelegatedOnToken(tokenId);
                }

                // msg.sender is delegated for vault
                claimer = vault;
            }

            // check if claimer owns a mint pass
            if (baseContractAddress.ownerOf(tokenId) != claimer)
                revert NotOwnerOfMintPass(tokenId);

            _bitmap.set(tokenId);

            unchecked {
                ++index;
            }
        }

        // mint tier 1 tokens
        _mintTier1(msg.sender, tokenIdsLength);
    }

    /**
     * @notice gets the balance of tokens owned in the base contract, and
     *  subtracts the amount already claimed
     * @param from the address to check
     */
    function availableToClaim(address from) external view returns (uint256) {
        uint256 baseBalance = baseContractAddress.balanceOf(from);
        uint256 amountClaimable;

        for (uint256 index; index < baseBalance; ) {
            if (
                !mintPassClaimed(
                    baseContractAddress.tokenOfOwnerByIndex(from, index)
                )
            ) {
                unchecked {
                    ++amountClaimable;
                }
            }

            unchecked {
                ++index;
            }
        }

        return amountClaimable;
    }

    /**
     * @notice utility function to get available ids to claim
     * @param from the address to check
     */
    function availableIdsToClaim(
        address from
    ) public view returns (uint256[] memory) {
        uint256 totalMintPasses = baseContractAddress.balanceOf(from);
        uint256[] memory availableTokenIds = new uint256[](totalMintPasses);

        uint256 amountClaimable;

        for (uint256 index; index < totalMintPasses; ) {
            uint256 tokenId = baseContractAddress.tokenOfOwnerByIndex(
                from,
                index
            );

            if (!mintPassClaimed(tokenId)) {
                availableTokenIds[amountClaimable] = tokenId;
                unchecked {
                    ++amountClaimable;
                }
            }

            unchecked {
                ++index;
            }
        }

        uint256[] memory unclaimedTokenIds = new uint256[](amountClaimable);
        for (uint256 index; index < amountClaimable; ) {
            unclaimedTokenIds[index] = availableTokenIds[index];

            unchecked {
                ++index;
            }
        }

        return unclaimedTokenIds;
    }

    /**
     * @notice get all tokens owned in the base contract, then claims the tokens
     *  NOTE: This function is gas intensive! To save gas call availableIdsToClaim()
     *  and use the returned array in mintWithMintPass().
     * @dev this will revert if any tokens have been claimed already
     */
    function claim() external payable {
        uint256[] memory tokenIds = availableIdsToClaim(msg.sender);

        mintWithMintPass(address(0), tokenIds);
    }

    /**
     * @notice delegate.cash is an unaffiliated external service, use it at your
     *  own risk! Their docs are available at http://delegate.cash

     * @dev allow minting if the msg.sender is on the allow list
     * @param vault if using delegate.cash: the address featured on the allow list,
     *  which must have delegated the calling (hot) wallet on this contract.
     *  Set vault to 0x000..000 if not using delegation.
     * @param numberOfTokens the number of tokens to be minted
     * @param tokenQuota the maximum number of tokens to mint
     * @param price the price per token
     * @param proof the merkle proof used
     */
    function mintAllowList(
        address vault,
        uint256 numberOfTokens,
        uint256 tokenQuota,
        uint256 price,
        bytes32[] memory proof
    )
        external
        payable
        atStage(Stages.AllowList)
        tier1SupplyAvailable(numberOfTokens)
        nonReentrant
    {
        // check if price is correct
        if ((numberOfTokens * price) != msg.value) revert WrongETHValueSent();

        address claimer = msg.sender;

        // check vault if using delegation
        if (vault != address(0) && vault != msg.sender) {
            if (
                !(
                    IDelegationRegistry(_DELEGATION_REGISTRY)
                        .checkDelegateForContract(
                            msg.sender,
                            vault,
                            address(this)
                        )
                )
            ) {
                revert NotDelegatedOnContract();
            }

            // msg.sender is delegated for vault
            claimer = vault;
        }

        // check if the claimer has tokens remaining in their quota
        uint256 tokensClaimed = getAllowListMinted(claimer);
        if (tokensClaimed + numberOfTokens > tokenQuota) {
            revert ExceedsAllowListQuota();
        }

        // check if the claimer is on the allowlist
        if (!onAllowListC(claimer, tokenQuota, price, proof)) {
            revert NotOnAllowList();
        }

        _setAllowListMinted(claimer, numberOfTokens);
        _mintTier1(msg.sender, numberOfTokens);
    }

    /**
     * @dev allow public minting
     * @param numberOfTokens the number of tokens to be minted
     */
    function mint(
        uint256 numberOfTokens
    )
        external
        payable
        atStage(Stages.PublicSale)
        tier1SupplyAvailable(numberOfTokens)
        nonReentrant
    {
        if (numberOfTokens > MAX_PUBLIC_MINT) {
            revert ExceedsMaximumTokensPerTransaction();
        }
        if (numberOfTokens * PRICE_PER_TOKEN != msg.value) {
            revert WrongETHValueSent();
        }

        _mintTier1(msg.sender, numberOfTokens);
    }

    /**
     * @dev redeem function to generate another token.
     *  This function bypasses the MAX_SUPPLY check since it's assumed all tokens
     *  have been sold by this point. Also doesn't check duplicate token ids
     *  because it is assumed that burn will error.
     * @param tokenIds an array of token ids. Must be either length 2 or 5
     */
    function redeem(
        uint256[] calldata tokenIds
    ) external atStage(Stages.Redeem) nonReentrant {
        uint256 tokenIdsLength = tokenIds.length;

        if (!(tokenIdsLength == 2 || tokenIdsLength == 5)) {
            revert InvalidRedemptionQuantity();
        }

        // burn all tokens
        for (uint256 index; index < tokenIdsLength; ) {
            uint256 tokenId = tokenIds[index];

            if (tokenId >= TIER_1_MAX_SUPPLY)
                revert InvalidTokenIdToBurn(tokenId);

            // emulate burn from ERC721Burnable
            if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
                revert TransferCallerNotOwnerNorApproved();
            }
            _burn(tokenId);
            _resetTokenRoyalty(tokenId);

            unchecked {
                ++index;
            }
        }
        tier1Burned += uint16(tokenIdsLength);

        _mintTier2(msg.sender, 1);
    }

    /***************************************************************************
     * Withdraw
     */
    /**
     * @dev withdraws ether from the contract to the shareholder address
     */
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = shareholderAddress.call{
            value: address(this).balance
        }("");
        if (!success) revert WithdrawFailed();
    }
}