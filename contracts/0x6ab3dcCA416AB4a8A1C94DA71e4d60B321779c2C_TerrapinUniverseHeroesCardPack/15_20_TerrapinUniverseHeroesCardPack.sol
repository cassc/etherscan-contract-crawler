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

import "./interfaces/TerrapinUniverseCardPack.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title Terrapin Universe Heroes Card Pack
 *
 * @notice ERC-721 NFT Token Contract
 *
 * @author 0x1687572416fdd591bcc710fa07cee94a76eea201681884b1d5cc528cba584815
 */
contract TerrapinUniverseHeroesCardPack is EIP712, TerrapinUniverseCardPack {
    using ECDSA for bytes32;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant MINT_SIGNER_ROLE = keccak256("MINT_SIGNER_ROLE");
    bytes32 public constant WHITELIST_TYPEHASH =
        keccak256("Whitelist(address account)");

    EnumerableSet.UintSet internal _WLOriginTokenIds;
    EnumerableSet.AddressSet internal _redeemedWhitelistAddresses;

    constructor(
        TerrapinGenesis terrapinGenesis_,
        string memory baseURI_,
        address[] memory operators,
        address[] memory mintSigners
    )
        EIP712("TerrapinUniverseHeroesCardPack", "1")
        TerrapinUniverseCardPack(
            "TerrapinUniverseHeroesCardPack",
            "TUHCP",
            terrapinGenesis_,
            baseURI_,
            operators
        )
    {
        for (uint256 index = 0; index < mintSigners.length; ++index) {
            _grantRole(MINT_SIGNER_ROLE, mintSigners[index]);
        }
    }

    /**
     * @notice Mint function, open to valid WL/Gen1 holders. A valid and unused
     * signature nets the message sender 1 token, while each owned and unused
     * Gen1 token nets the message sender MINT_COUNT_PER_GEN1 * #gen1TokenIds
     * tokens. Use the empty value `0x` for `sig`, or an empty array `[]` for
     * `gen1TokenIds` if not applicable. After redeeming, Gen1 tokens become
     * 'used' w.r.t. this function.
     *
     * For generating `gen1TokenIds`, see
     * {TerrapinUniverseCardPack-eligibleGen1TokenIdsOf}.
     */
    function mint(bytes calldata sig, uint256[] calldata gen1TokenIds)
        external
    {
        mintTo(_msgSender(), sig, gen1TokenIds);
    }

    function originOf(uint256 tokenId)
        external
        view
        override
        returns (TokenOrigin)
    {
        if (_hasMintedTokenId(tokenId) != true) revert InvalidTokenId();

        if (_WLOriginTokenIds.contains(tokenId)) {
            return TokenOrigin.WL;
        }

        return TokenOrigin.Gen1;
    }

    function mintTo(
        address to,
        bytes calldata sig,
        uint256[] calldata gen1TokenIds
    ) public nonReentrant {
        if (mintActive != true) revert MintNotActive();
        if (_soldOut()) revert MaxSupplyExceeded();
        if (_areGen1TokenIdsEligible(gen1TokenIds, _msgSender()) != true)
            revert InvalidGen1TokenIds();

        if (sig.length > 0) {
            if (_hasAccountRedeemedWhitelist(to)) {
                revert AccountPreviouslyMinted();
            }

            if (hasRole(OPERATOR_ROLE, _msgSender()) != true) {
                if (isWhitelistSignatureValid(sig, _msgSender()) != true) {
                    revert InvalidSignature();
                }
            }

            _mintViaWL(to);
        }

        _mintViaGen1(to, gen1TokenIds);
    }

    function isWhitelistSignatureValid(bytes calldata sig, address account)
        public
        view
        returns (bool)
    {
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(WHITELIST_TYPEHASH, account))
        );
        address signer = ECDSA.recover(digest, sig);

        return hasRole(MINT_SIGNER_ROLE, signer);
    }

    function _mintViaWL(address account) private {
        _WLOriginTokenIds.add(_nextTokenId());
        _redeemedWhitelistAddresses.add(account);

        _safeMint(account, 1);
    }

    function _hasAccountRedeemedWhitelist(address account)
        private
        view
        returns (bool)
    {
        return _redeemedWhitelistAddresses.contains(account);
    }
}