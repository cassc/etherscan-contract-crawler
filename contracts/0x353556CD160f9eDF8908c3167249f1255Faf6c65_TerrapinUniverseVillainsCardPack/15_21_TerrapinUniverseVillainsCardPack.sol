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

import "./interfaces/TerrapinUniverse.sol";
import "./interfaces/TerrapinUniverseCardPack.sol";

/**
 * @title Terrapin Universe Villains Card Pack
 *
 * @notice ERC-721 NFT Token Contract
 *
 * @author 0x1687572416fdd591bcc710fa07cee94a76eea201681884b1d5cc528cba584815
 */
contract TerrapinUniverseVillainsCardPack is TerrapinUniverseCardPack {
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public constant HERO_REDEMPTION_LEVEL = 2;

    TerrapinUniverseCardPack public terrapinUniverseHeroesCardPack;
    TerrapinUniverse public terrapinUniverseHeroes;

    EnumerableSet.UintSet internal _heroRedemptionOriginTokenIds;
    EnumerableSet.UintSet internal _redeemedHeroTokenIds;

    event HeroesCardPackUpdated(
        address oldTerrapinUniverseHeroesCardPack,
        address terrapinUniverseHeroesCardPack
    );
    event HeroesUpdated(
        address oldTerrapinUniverseHeroes,
        address terrapinUniverseHeroes
    );

    error InvalidHeroTokenIds();
    error InvalidTerrapinUniverseHeroesCardPackAddress();
    error InvalidTerrapinUniverseHeroesAddress();

    constructor(
        TerrapinGenesis terrapinGenesis_,
        TerrapinUniverseCardPack terrapinUniverseHeroesCardPack_,
        TerrapinUniverse terrapinUniverseHeroes_,
        string memory baseURI_,
        address[] memory operators
    )
        TerrapinUniverseCardPack(
            "TerrapinUniverseVillainsCardPack",
            "TUVCP",
            terrapinGenesis_,
            baseURI_,
            operators
        )
    {
        terrapinUniverseHeroesCardPack = terrapinUniverseHeroesCardPack_;
        terrapinUniverseHeroes = terrapinUniverseHeroes_;
    }

    /**
     * @notice Mint function, open to valid Gen1 holders. Each owned and unused
     * Gen1 token nets the message sender MINT_COUNT_PER_GEN1 * #gen1TokenIds
     * tokens. After redeeming, Gen1 tokens become 'used' w.r.t. this function.
     *
     * For generating `gen1TokenIds`, see
     * {TerrapinUniverseCardPack-eligibleGen1TokenIdsOf}.
     */
    function mint(uint256[] calldata gen1TokenIds) external {
        mintTo(_msgSender(), gen1TokenIds);
    }

    function mintTo(address to, uint256[] calldata gen1TokenIds)
        public
        nonReentrant
    {
        if (mintActive != true) revert MintNotActive();
        if (_soldOut()) revert MaxSupplyExceeded();
        if (_areGen1TokenIdsEligible(gen1TokenIds, _msgSender()) != true)
            revert InvalidGen1TokenIds();

        _mintViaGen1(to, gen1TokenIds);
    }

    /**
     * @notice Redeem function, open to valid Terrapin Universe Hero token
     * holders. Each unused, level HERO_REDEMPTION_LEVEL or greater, WL-origin
     * Hero nets the message sender 1 Terrapin Universe Villain Card Pack
     * token. After redeeming, Hero becomes 'used' w.r.t. this function.
     *
     * For generating `heroTokenIds`, see
     * {TerrapinUniverseVillainsCardPack-eligibleHeroTokenIdsOf}.
     */
    function redeem(uint256[] calldata heroTokenIds) external {
        redeemTo(_msgSender(), heroTokenIds);
    }

    function setHeroesCardPack(
        TerrapinUniverseCardPack terrapinUniverseHeroesCardPack_
    ) external onlyRole(OPERATOR_ROLE) {
        if (terrapinUniverseHeroesCardPack == terrapinUniverseHeroesCardPack_)
            revert ValueUnchanged();

        TerrapinUniverseCardPack oldTerrapinUniverseHeroesCardPack = terrapinUniverseHeroesCardPack;
        terrapinUniverseHeroesCardPack = terrapinUniverseHeroesCardPack_;

        emit HeroesCardPackUpdated(
            address(oldTerrapinUniverseHeroesCardPack),
            address(terrapinUniverseHeroesCardPack)
        );
    }

    function setHeroes(TerrapinUniverse terrapinUniverseHeroes_)
        external
        onlyRole(OPERATOR_ROLE)
    {
        if (terrapinUniverseHeroes == terrapinUniverseHeroes_)
            revert ValueUnchanged();

        TerrapinUniverse oldTerrapinUniverseHeroes = terrapinUniverseHeroes;
        terrapinUniverseHeroes = terrapinUniverseHeroes_;

        emit HeroesUpdated(
            address(oldTerrapinUniverseHeroes),
            address(terrapinUniverseHeroes)
        );
    }

    function originOf(uint256 tokenId)
        external
        view
        override
        returns (TokenOrigin)
    {
        if (_hasMintedTokenId(tokenId) != true) revert InvalidTokenId();

        if (_heroRedemptionOriginTokenIds.contains(tokenId)) {
            return TokenOrigin.HeroRedemption;
        }

        return TokenOrigin.Gen1;
    }

    function redeemedHeroTokenIds() external view returns (uint256[] memory) {
        return _redeemedHeroTokenIds.values();
    }

    /**
     * @notice Used to calculate valid and unused heroTokenIds for the
     * given `account` off-chain. The results of this function may be
     * safely passed to {redeem}.
     */
    function eligibleHeroTokenIdsOf(address account)
        external
        view
        returns (uint256[] memory)
    {
        if (address(terrapinUniverseHeroesCardPack) == NULL_ADDRESS)
            revert InvalidTerrapinUniverseHeroesCardPackAddress();
        if (address(terrapinUniverseHeroes) == NULL_ADDRESS)
            revert InvalidTerrapinUniverseHeroesAddress();

        uint256[] memory heroTokenIds = terrapinUniverseHeroes.tokensOfOwner(
            account
        );
        uint256[] memory eligibleTokenIdsWithPadding = new uint256[](
            heroTokenIds.length
        );

        uint256 numberOfEligibleTokenIds = 0;
        for (
            uint256 tokenIdIndex = 0;
            tokenIdIndex < eligibleTokenIdsWithPadding.length;
            ++tokenIdIndex
        ) {
            uint256 heroTokenId = heroTokenIds[tokenIdIndex];
            uint256 cardPackTokenId = terrapinUniverseHeroes
                .tokenIdToCardPackTokenId(heroTokenId);

            bool heroHasNotBeenRedeemed = isHeroTokenIdRedeemed(heroTokenId) !=
                true;
            bool heroOriginIsWL = terrapinUniverseHeroesCardPack.originOf(
                cardPackTokenId
            ) == TokenOrigin.WL;
            bool heroLevelRequirementMet = terrapinUniverseHeroes.levelOf(
                heroTokenId
            ) >= HERO_REDEMPTION_LEVEL;

            if (
                heroHasNotBeenRedeemed &&
                heroOriginIsWL &&
                heroLevelRequirementMet
            ) {
                eligibleTokenIdsWithPadding[
                    numberOfEligibleTokenIds
                ] = heroTokenId;
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

    function redeemTo(address to, uint256[] calldata heroTokenIds)
        public
        nonReentrant
    {
        if (mintActive != true) revert MintNotActive();
        if (_soldOut()) revert MaxSupplyExceeded();

        if (_areHeroTokenIdsEligible(heroTokenIds, _msgSender()) != true)
            revert InvalidHeroTokenIds();

        _redeem(to, heroTokenIds);
    }

    function isHeroTokenIdRedeemed(uint256 tokenId) public view returns (bool) {
        return _redeemedHeroTokenIds.contains(tokenId);
    }

    function _redeem(address to, uint256[] calldata heroTokenIds) private {
        uint256 numberToRedeem = _allowableMintAmount(heroTokenIds.length);

        for (uint256 mintIndex = 0; mintIndex < numberToRedeem; ++mintIndex) {
            uint256 heroTokenId = heroTokenIds[mintIndex];
            uint256 cardPackTokenId = _nextTokenId() + mintIndex;

            _redeemedHeroTokenIds.add(heroTokenId);
            _heroRedemptionOriginTokenIds.add(cardPackTokenId);
        }

        _safeMint(to, numberToRedeem);
    }

    function _areHeroTokenIdsEligible(
        uint256[] calldata tokenIds,
        address account
    ) private view returns (bool) {
        if (address(terrapinUniverseHeroesCardPack) == NULL_ADDRESS)
            revert InvalidTerrapinUniverseHeroesCardPackAddress();
        if (address(terrapinUniverseHeroes) == NULL_ADDRESS)
            revert InvalidTerrapinUniverseHeroesAddress();

        bool eligible = true;

        bool[] memory duplicatesCheck = new bool[](
            terrapinUniverseHeroesCardPack.maxSupply()
        );

        for (uint256 index = 0; index < tokenIds.length && eligible; ++index) {
            uint256 heroTokenId = tokenIds[index];
            uint256 cardPackTokenId = terrapinUniverseHeroes
                .tokenIdToCardPackTokenId(heroTokenId);
            uint256 duplicateCheckIndex = heroTokenId - _startTokenId();

            bool isContractOperatorOrHeroOwner = hasRole(
                OPERATOR_ROLE,
                account
            ) || terrapinUniverseHeroes.ownerOf(heroTokenId) == account;
            bool heroHasNotBeenRedeemed = isHeroTokenIdRedeemed(heroTokenId) !=
                true;
            bool isNotDuplicate = duplicatesCheck[duplicateCheckIndex] == false;
            bool heroOriginIsWL = terrapinUniverseHeroesCardPack.originOf(
                cardPackTokenId
            ) == TokenOrigin.WL;
            bool heroLevelRequirementMet = terrapinUniverseHeroes.levelOf(
                heroTokenId
            ) >= HERO_REDEMPTION_LEVEL;

            eligible =
                isContractOperatorOrHeroOwner &&
                heroHasNotBeenRedeemed &&
                isNotDuplicate &&
                heroOriginIsWL &&
                heroLevelRequirementMet;
            duplicatesCheck[duplicateCheckIndex] = true;
        }

        return eligible;
    }
}