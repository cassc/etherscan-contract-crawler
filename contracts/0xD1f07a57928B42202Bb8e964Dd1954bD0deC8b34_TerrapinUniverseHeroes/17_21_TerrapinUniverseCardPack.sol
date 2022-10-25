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
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

enum TokenOrigin {
    Unknown,
    Gen1,
    WL,
    HeroRedemption
}

/**
 * @title Terrapin Universe Card Pack
 *
 * @notice ERC-721 NFT Token Contract.
 *
 * @author 0x1687572416fdd591bcc710fa07cee94a76eea201681884b1d5cc528cba584815
 */
abstract contract TerrapinUniverseCardPack is
    Ownable,
    AccessControl,
    ReentrancyGuard,
    ERC721AQueryable
{
    using Address for address payable;
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant REDEEMER_ROLE = keccak256("REDEEMER_ROLE");
    uint256 public constant MINT_COUNT_PER_GEN1 = 2;
    uint256 public constant START_TOKEN_ID = 1;
    uint256 public constant maxSupply = 2000;
    address public constant NULL_ADDRESS = address(0);
    address public constant OS_CONDUIT_ADDRESS =
        0x1E0049783F008A0085193E00003D00cd54003c71;
    TerrapinGenesis public immutable terrapinGenesis;

    bool public mintActive;
    string public baseURI;

    EnumerableSet.UintSet internal _usedGen1TokenIds;

    event MintActiveUpdated(bool mintActive);
    event BaseURIUpdated(string oldBaseURI, string baseURI);

    error InvalidGen1TokenIds();
    error InvalidTokenId();
    error InvalidTerrapinGenesisAddress();

    constructor(
        string memory name_,
        string memory symbol_,
        TerrapinGenesis terrapinGenesis_,
        string memory baseURI_,
        address[] memory operators
    ) ERC721A(name_, symbol_) {
        terrapinGenesis = terrapinGenesis_;
        baseURI = baseURI_;

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        for (uint256 index = 0; index < operators.length; ++index) {
            _grantRole(OPERATOR_ROLE, operators[index]);
        }
    }

    function burn(uint256[] calldata tokenIds)
        external
        onlyRole(REDEEMER_ROLE)
    {
        for (uint256 index = 0; index < tokenIds.length; ++index) {
            uint256 tokenId = tokenIds[index];

            _burn(tokenId, false);
        }
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

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(_msgSender()).sendValue(address(this).balance);
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function numberMinted(address account) external view returns (uint256) {
        return _numberMinted(account);
    }

    function usedGen1TokenIds() external view returns (uint256[] memory) {
        return _usedGen1TokenIds.values();
    }

    function originOf(uint256 tokenId)
        external
        view
        virtual
        returns (TokenOrigin);

    /**
     * @notice Used to calculate valid and unused gen1TokenIds for the
     * given `account` off-chain. The results of this function may be
     * safely passed to {mint}.
     */
    function eligibleGen1TokenIdsOf(address account)
        external
        view
        returns (uint256[] memory)
    {
        if (address(terrapinGenesis) == NULL_ADDRESS)
            revert InvalidTerrapinGenesisAddress();

        uint256[] memory tokenIds = terrapinGenesis.tokensOfOwner(account);
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
            if (isGen1TokenIdUsed(tokenId) != true) {
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

    function isGen1TokenIdUsed(uint256 tokenId) public view returns (bool) {
        return _usedGen1TokenIds.contains(tokenId);
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

    function _mintViaGen1(address to, uint256[] calldata tokenIds) internal {
        uint256 numberToMint = MINT_COUNT_PER_GEN1;
        for (
            uint256 mintIndex = 0;
            mintIndex < tokenIds.length && numberToMint == MINT_COUNT_PER_GEN1;
            ++mintIndex
        ) {
            numberToMint = _allowableMintAmount(MINT_COUNT_PER_GEN1);
            if (numberToMint > 0) {
                _usedGen1TokenIds.add(tokenIds[mintIndex]);
                _safeMint(to, numberToMint);
            }
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _soldOut() internal view returns (bool) {
        return _totalMinted() >= maxSupply;
    }

    function _allowableMintAmount(uint256 targetAmount)
        internal
        view
        returns (uint256)
    {
        uint256 remainingMintableAmount = maxSupply - _totalMinted();
        return Math.min(targetAmount, remainingMintableAmount);
    }

    function _hasMintedTokenId(uint256 tokenId) internal view returns (bool) {
        return tokenId >= _startTokenId() && tokenId < _nextTokenId();
    }

    function _startTokenId() internal pure override returns (uint256) {
        return START_TOKEN_ID;
    }

    function _areGen1TokenIdsEligible(
        uint256[] calldata tokenIds,
        address account
    ) internal view returns (bool) {
        if (address(terrapinGenesis) == NULL_ADDRESS)
            revert InvalidTerrapinGenesisAddress();

        bool eligible = true;

        bool[] memory duplicatesCheck = new bool[](terrapinGenesis.maxSupply());

        for (uint256 index = 0; index < tokenIds.length && eligible; ++index) {
            uint256 tokenId = tokenIds[index];
            uint256 duplicateCheckIndex = tokenId - _startTokenId();
            bool isContractOperatorOrTokenOwner = hasRole(
                OPERATOR_ROLE,
                account
            ) || terrapinGenesis.ownerOf(tokenId) == account;
            bool tokenIdIsUnused = _usedGen1TokenIds.contains(tokenId) != true;
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