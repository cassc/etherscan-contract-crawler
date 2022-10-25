//SPDX-License-Identifier: MIT

/*
 ***************************************************************************************************************************
 *                                                                                                                         *
 * ___________                                     .__           ____ ___        .__                                       *
 * \__    ___/____ _______ _______ _____   ______  |__|  ____   |    |   \ ____  |__|___  __  ____ _______  ______  ____   *
 *   |    | _/ __ \\_  __ \\_  __ \\__  \  \____ \ |  | /    \  |    |   //    \ |  |\  \/ /_/ __ \\_  __ \/  ___/_/ __ \  *
 *   |    | \  ___/ |  | \/ |  | \/ / __ \_|  |_> >|  ||   |  \ |    |  /|   |  \|  | \   / \  ___/ |  | \/\___ \ \  ___/  *
 *   |____|  \___  >|__|    |__|   (____  /|   __/ |__||___|  / |______/ |___|  /|__|  \_/   \___  >|__|  /____  > \___  > *
 *               \/                     \/ |__|             \/                \/                 \/            \/      \/  *
 *                                                                                                                         *
 ***************************************************************************************************************************
 */

pragma solidity ^0.8.9;

import {TerrapinGenesis, MintNotActive, MaxSupplyExceeded, InvalidSignature, AccountPreviouslyMinted, InvalidValue, ValueUnchanged} from "../TerrapinGenesis.sol";
import "./TerrapinUniverseCardPack.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

/**
 * @title Terrapin Universe
 *
 * @notice ERC-721 NFT Token Contract.
 *
 * @author 0x1687572416fdd591bcc710fa07cee94a76eea201681884b1d5cc528cba584815
 */
abstract contract TerrapinUniverse is
    Ownable,
    AccessControl,
    ReentrancyGuard,
    ERC721AQueryable
{
    using Address for address payable;
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    uint256 public constant maxSupply = 2000;
    uint256 public constant START_TOKEN_ID = 1;
    uint256 public constant STAKE_START_THRESHOLD_DAYS = 3;
    address public constant NULL_ADDRESS = address(0);
    address public constant OS_CONDUIT_ADDRESS =
        0x1E0049783F008A0085193E00003D00cd54003c71;
    TerrapinGenesis public immutable terrapinGenesis;

    uint256[] public LEVEL_EXP_DAYS = [0, 14, 44, 134, 254];
    TerrapinUniverseCardPack public terrapinUniverseCardPack;

    bool public mintActive;
    string public baseURI;
    mapping(uint256 => uint256) public tokenIdToCardPackTokenId;
    mapping(uint256 => uint256) public tokenIdToRawLevelAtLastTransfer;

    EnumerableSet.UintSet internal _usedCardPackTokenIds;

    event MintActiveUpdated(bool mintActive);
    event BaseURIUpdated(string oldBaseURI, string baseURI);
    event CardPackUpdated(
        address oldTerrapinUniverseCardPack,
        address terrapinUniverseCardPack
    );

    error InvalidCardPackTokenIds();
    error InvalidTerrapinUniverseCardPackAddress();

    constructor(
        string memory name_,
        string memory symbol_,
        TerrapinGenesis terrapinGenesis_,
        TerrapinUniverseCardPack terrapinUniverseCardPack_,
        string memory baseURI_,
        address[] memory operators
    ) ERC721A(name_, symbol_) {
        terrapinGenesis = terrapinGenesis_;
        terrapinUniverseCardPack = terrapinUniverseCardPack_;
        baseURI = baseURI_;

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        for (uint256 index = 0; index < operators.length; ++index) {
            _grantRole(OPERATOR_ROLE, operators[index]);
        }
    }

    /**
     * @notice Redeem function, open to Terrapin Universe Card Pack holders.
     * Each card pack nets the message sender 1 Terrapin Universe token.
     * Card Pack tokens are BURNED and removed from owners wallet.
     *
     * For generating `cardPackTokenIds`, see
     * {TerrapinUniverse-eligibleCardPackTokenIdsOf}.
     */
    function redeem(uint256[] calldata cardPackTokenIds) external {
        redeemTo(_msgSender(), cardPackTokenIds);
    }

    function setMintActive(bool mintActive_) external onlyRole(OPERATOR_ROLE) {
        if (mintActive == mintActive_) revert ValueUnchanged();

        mintActive = mintActive_;

        emit MintActiveUpdated(mintActive);
    }

    function setBaseURI(string calldata baseURI_)
        external
        onlyRole(OPERATOR_ROLE)
    {
        if (
            keccak256(abi.encodePacked(baseURI_)) ==
            keccak256(abi.encodePacked(_baseURI()))
        ) revert ValueUnchanged();

        string memory oldBaseURI = _baseURI();
        baseURI = baseURI_;

        emit BaseURIUpdated(oldBaseURI, baseURI_);
    }

    function setCardPack(TerrapinUniverseCardPack terrapinUniverseCardPack_)
        external
        onlyRole(OPERATOR_ROLE)
    {
        if (terrapinUniverseCardPack == terrapinUniverseCardPack_)
            revert ValueUnchanged();

        TerrapinUniverseCardPack oldTerrapinUniverseCardPack = terrapinUniverseCardPack;
        terrapinUniverseCardPack = terrapinUniverseCardPack_;

        emit CardPackUpdated(
            address(oldTerrapinUniverseCardPack),
            address(terrapinUniverseCardPack)
        );
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(_msgSender()).sendValue(address(this).balance);
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function numberMinted(address account) external view returns (uint256) {
        return _numberMinted(account);
    }

    function usedCardPackTokenIds() external view returns (uint256[] memory) {
        return _usedCardPackTokenIds.values();
    }

    function levelOf(uint256 tokenId) external view returns (uint256) {
        return _levelOf(tokenId, true);
    }

    function rawLevelOf(uint256 tokenId) external view returns (uint256) {
        return _levelOf(tokenId, false);
    }

    function tokenDetailOf(uint256 tokenId)
        external
        view
        returns (
            TokenOwnership memory,
            uint256,
            uint256
        )
    {
        TokenOwnership memory ownership = _ownershipOf(tokenId);
        uint256 level = _levelOf(tokenId, true);
        uint256 rawLevel = _levelOf(tokenId, false);

        return (ownership, level, rawLevel);
    }

    function eligibleCardPackTokenIdsOf(address account)
        external
        view
        returns (uint256[] memory)
    {
        if (address(terrapinUniverseCardPack) == NULL_ADDRESS)
            revert InvalidTerrapinUniverseCardPackAddress();

        uint256[] memory tokenIds = terrapinUniverseCardPack.tokensOfOwner(
            account
        );
        uint256[] memory eligibleTokenIdsWithPadding = new uint256[](
            tokenIds.length
        );

        uint256 numberOfEligibleTokenIds = 0;
        for (
            uint256 tokenIdIndex = 0;
            tokenIdIndex < eligibleTokenIdsWithPadding.length;
            ++tokenIdIndex
        ) {
            uint256 tokenId = tokenIds[tokenIdIndex];

            bool hasNotBeenRedeemed = _usedCardPackTokenIds.contains(tokenId) !=
                true;

            if (hasNotBeenRedeemed) {
                eligibleTokenIdsWithPadding[numberOfEligibleTokenIds] = tokenId;
                ++numberOfEligibleTokenIds;
            }
        }

        uint256[] memory eligibleTokenIds = new uint256[](
            numberOfEligibleTokenIds
        );
        for (uint256 index = 0; index < numberOfEligibleTokenIds; ++index) {
            eligibleTokenIds[index] = eligibleTokenIdsWithPadding[index];
        }

        return eligibleTokenIds;
    }

    function redeemTo(address to, uint256[] calldata cardPackTokenIds)
        public
        nonReentrant
    {
        if (mintActive != true) revert MintNotActive();
        if (address(terrapinUniverseCardPack) == NULL_ADDRESS)
            revert InvalidTerrapinUniverseCardPackAddress();
        if (_canMintAdditional(cardPackTokenIds.length) != true)
            revert MaxSupplyExceeded();
        if (
            _areCardPackTokenIdsEligible(cardPackTokenIds, _msgSender()) != true
        ) revert InvalidCardPackTokenIds();

        _redeem(to, cardPackTokenIds);
    }

    function isCardPackTokenIdUsed(uint256 tokenId) public view returns (bool) {
        return _usedCardPackTokenIds.contains(tokenId);
    }

    function isApprovedForAll(address owner_, address operator)
        public
        view
        override
        returns (bool)
    {
        if (super.isApprovedForAll(owner_, operator)) {
            return true;
        }

        if (operator == OS_CONDUIT_ADDRESS) {
            return true;
        }

        return false;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, ERC721A)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    function _redeem(address to, uint256[] calldata cardPackTokenIds) internal {
        for (uint256 index = 0; index < cardPackTokenIds.length; ++index) {
            uint256 cardPackTokenId = cardPackTokenIds[index];
            uint256 thisTokenId = _nextTokenId() + index;

            tokenIdToCardPackTokenId[thisTokenId] = cardPackTokenId;
            _usedCardPackTokenIds.add(cardPackTokenId);
        }

        terrapinUniverseCardPack.burn(cardPackTokenIds);
        _safeMint(to, cardPackTokenIds.length);
    }

    function _beforeTokenTransfers(
        address from,
        address,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        for (uint256 index = 0; index < quantity; ++index) {
            uint256 tokenId = startTokenId + index;

            if (from != address(0x0)) {
                tokenIdToRawLevelAtLastTransfer[tokenId] = _levelOf(
                    tokenId,
                    false
                );
            }
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _canMintAdditional(uint256 count) internal view returns (bool) {
        return (_totalMinted() + count) <= maxSupply;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return START_TOKEN_ID;
    }

    function _levelOf(uint256 tokenId, bool applyGen1OwnershipBoost)
        internal
        view
        returns (uint256)
    {
        uint256 level = tokenIdToRawLevelAtLastTransfer[tokenId];
        if (level >= LEVEL_EXP_DAYS.length) {
            return level;
        }

        TokenOwnership memory ownership = _ownershipOf(tokenId);
        uint256 numberOfDaysOwnedByCurrentOwner = (block.timestamp -
            ownership.startTimestamp) / (1 days);

        if (numberOfDaysOwnedByCurrentOwner < STAKE_START_THRESHOLD_DAYS) {
            return level;
        }

        uint256 numGen1TokensOwned = terrapinGenesis.balanceOf(ownership.addr);
        uint256 multiplier = 1 +
            (applyGen1OwnershipBoost ? numGen1TokensOwned : 0);
        uint256 eligibleNumDaysExperience = LEVEL_EXP_DAYS[level] +
            numberOfDaysOwnedByCurrentOwner -
            STAKE_START_THRESHOLD_DAYS;
        uint256 experienceInDays = multiplier * eligibleNumDaysExperience;

        while (
            level < LEVEL_EXP_DAYS.length &&
            experienceInDays >= LEVEL_EXP_DAYS[level]
        ) {
            ++level;
        }

        return level;
    }

    function _areCardPackTokenIdsEligible(
        uint256[] calldata cardPackTokenIds,
        address account
    ) private view returns (bool) {
        if (address(terrapinUniverseCardPack) == NULL_ADDRESS)
            revert InvalidTerrapinUniverseCardPackAddress();

        bool eligible = true;

        bool[] memory duplicatesCheck = new bool[](
            terrapinUniverseCardPack.maxSupply()
        );

        for (
            uint256 index = 0;
            index < cardPackTokenIds.length && eligible;
            ++index
        ) {
            uint256 cardPackTokenId = cardPackTokenIds[index];
            uint256 duplicateCheckIndex = cardPackTokenId - _startTokenId();
            bool isContractOperatorOrTokenOwner = hasRole(
                OPERATOR_ROLE,
                account
            ) || terrapinUniverseCardPack.ownerOf(cardPackTokenId) == account;
            bool tokenIdIsUnused = isCardPackTokenIdUsed(cardPackTokenId) !=
                true;
            bool isNotDuplicate = duplicatesCheck[duplicateCheckIndex] == false;

            eligible =
                isContractOperatorOrTokenOwner &&
                tokenIdIsUnused &&
                isNotDuplicate;
            duplicatesCheck[duplicateCheckIndex] = true;
        }

        return eligible;
    }
}