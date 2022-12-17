// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title: Murakami Money Cat Coin Bank
/// @author: niftykit.com

import "solady/src/auth/OwnableRoles.sol";
import "closedsea/src/OperatorFilterer.sol";
import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "./interfaces/IMurakamiFlowerCoin.sol";
import "./interfaces/IMurakamiMoneyCatCoinBank.sol";
import {MurakamiMoneyCatCoinBankStorage} from "./libraries/MurakamiMoneyCatCoinBankStorage.sol";

contract MurakamiMoneyCatCoinBank is
    OwnableRoles,
    OperatorFilterer,
    ERC721AUpgradeable,
    ERC721AQueryableUpgradeable,
    ERC2981Upgradeable,
    ERC721HolderUpgradeable,
    IMurakamiMoneyCatCoinBank
{
    using MurakamiMoneyCatCoinBankStorage for MurakamiMoneyCatCoinBankStorage.Layout;

    uint256 public constant ADMIN_ROLE = 1 << 0;
    uint256 public constant MANAGER_ROLE = 1 << 1;
    uint256 public constant MINTER_ROLE = 1 << 2;
    uint256 public constant MAX_COIN_AMOUNT = 750;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    modifier onlyActive() {
        require(MurakamiMoneyCatCoinBankStorage.layout().active, "Not Active");
        _;
    }

    function initialize(
        address owner_,
        address royalty_,
        uint96 royaltyFee_,
        string memory name_,
        string memory symbol_,
        string memory baseUri_
    ) public initializerERC721A {
        _initializeOwner(owner_);
        __ERC721A_init(name_, symbol_);
        _registerForOperatorFiltering();

        MurakamiMoneyCatCoinBankStorage.layout().baseURI = baseUri_;
        MurakamiMoneyCatCoinBankStorage
            .layout()
            .operatorFilteringEnabled = true;

        _setDefaultRoyalty(royalty_, royaltyFee_);
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyRolesOrOwner(ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setBaseURI(
        string memory newuri
    ) external onlyRolesOrOwner(ADMIN_ROLE) {
        MurakamiMoneyCatCoinBankStorage.layout().baseURI = newuri;
    }

    function setCoin(
        address coinAddress
    ) external onlyRolesOrOwner(ADMIN_ROLE) {
        MurakamiMoneyCatCoinBankStorage.layout().coin = IMurakamiFlowerCoin(
            coinAddress
        );
    }

    function setActive(bool newActive) external onlyRolesOrOwner(ADMIN_ROLE) {
        MurakamiMoneyCatCoinBankStorage.layout().active = newActive;
    }

    function setOperatorFilteringEnabled(
        bool value
    ) public onlyRolesOrOwner(ADMIN_ROLE) {
        MurakamiMoneyCatCoinBankStorage
            .layout()
            .operatorFilteringEnabled = value;
    }

    function mint(address to) external onlyRolesOrOwner(MINTER_ROLE) {
        _mint(to, 1);
    }

    function addCoin(
        uint256 catTokenId,
        uint256 coinTokenId
    ) external onlyActive {
        require(ownerOf(catTokenId) == _msgSenderERC721A(), "Not owner of cat");

        MurakamiMoneyCatCoinBankStorage.layout().coin.safeTransferFrom(
            _msgSenderERC721A(),
            address(this),
            coinTokenId
        );

        _addCoin(catTokenId, coinTokenId);
    }

    function batchAddCoins(
        uint256 catTokenId,
        uint256[] calldata coinTokenIds
    ) external onlyActive {
        uint256 length = coinTokenIds.length;
        require(ownerOf(catTokenId) == _msgSenderERC721A(), "Not owner of cat");

        for (uint256 i = 0; i < length; ) {
            uint256 coinTokenId = coinTokenIds[i];
            MurakamiMoneyCatCoinBankStorage.layout().coin.safeTransferFrom(
                _msgSenderERC721A(),
                address(this),
                coinTokenId
            );
            _addCoin(catTokenId, coinTokenId);
            unchecked {
                i++;
            }
        }
    }

    function breakMoneyCatCoinBank(uint256 catTokenId) external onlyActive {
        require(ownerOf(catTokenId) == _msgSenderERC721A(), "Not owner of cat");
        uint256[] memory coinTokenIds = _getCoins(catTokenId);

        uint256 length = coinTokenIds.length;
        for (uint256 i = 0; i < length; ) {
            MurakamiMoneyCatCoinBankStorage.layout().coin.safeTransferFrom(
                address(this),
                _msgSenderERC721A(),
                coinTokenIds[i]
            );
            unchecked {
                i++;
            }
        }

        _burn(catTokenId);

        emit MoneyCatCoinBankBroken(catTokenId, _msgSenderERC721A());
    }

    function getEXP(uint256 catTokenId) external view returns (uint256) {
        require(_exists(catTokenId), "Token doesn't exist");
        return MurakamiMoneyCatCoinBankStorage.layout().catEXP[catTokenId];
    }

    function getCoins(
        uint256 catTokenId
    ) external view returns (uint256[] memory) {
        require(_exists(catTokenId), "Token doesn't exist");
        return _getCoins(catTokenId);
    }

    function active() external view returns (bool) {
        return MurakamiMoneyCatCoinBankStorage.layout().active;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    )
        public
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _addCoin(uint256 catTokenId, uint256 coinTokenId) internal {
        uint256 exp = MurakamiMoneyCatCoinBankStorage.layout().coin.getEXP(
            coinTokenId
        );
        require(exp > 0, "Coin not revealed");
        uint256 coinIndex = MurakamiMoneyCatCoinBankStorage.layout().coinsCount[
            catTokenId
        ];
        require(coinIndex < MAX_COIN_AMOUNT, "Max coins reached");
        MurakamiMoneyCatCoinBankStorage.layout().coinIdByIndex[catTokenId][
                coinIndex
            ] = coinTokenId;

        unchecked {
            MurakamiMoneyCatCoinBankStorage.layout().coinsCount[catTokenId]++;
            MurakamiMoneyCatCoinBankStorage.layout().catEXP[catTokenId] += exp;
        }

        emit CoinAdded(catTokenId, coinTokenId, exp);
    }

    function _getCoins(
        uint256 catTokenId
    ) internal view returns (uint256[] memory) {
        uint256 coinsCount = MurakamiMoneyCatCoinBankStorage
            .layout()
            .coinsCount[catTokenId];
        uint256[] memory coinTokenIds = new uint256[](coinsCount);

        for (uint256 i = 0; i < coinsCount; ) {
            coinTokenIds[i] = MurakamiMoneyCatCoinBankStorage
                .layout()
                .coinIdByIndex[catTokenId][i];

            unchecked {
                i++;
            }
        }

        return coinTokenIds;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return MurakamiMoneyCatCoinBankStorage.layout().baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _operatorFilteringEnabled()
        internal
        view
        virtual
        override
        returns (bool)
    {
        return
            MurakamiMoneyCatCoinBankStorage.layout().operatorFilteringEnabled;
    }

    // The following functions are overrides required by Solidity.
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721AUpgradeable, ERC2981Upgradeable, IERC721AUpgradeable)
        returns (bool)
    {
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }
}