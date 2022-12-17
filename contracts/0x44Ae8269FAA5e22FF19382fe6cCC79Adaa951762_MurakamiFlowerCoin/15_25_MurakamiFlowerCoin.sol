// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title: Murakami Lucky Coin
/// @author: niftykit.com

import "solady/src/auth/OwnableRoles.sol";
import "closedsea/src/OperatorFilterer.sol";
import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";

import "./interfaces/IMurakamiFlowerCoin.sol";
import "./interfaces/IMurakamiMoneyCatCoinBank.sol";
import "./interfaces/IMurakamiLuckyCatCoinBank.sol";
import {CoinStorage} from "./libraries/CoinStorage.sol";

contract MurakamiFlowerCoin is
    OwnableRoles,
    OperatorFilterer,
    ERC2981Upgradeable,
    ERC721AUpgradeable,
    ERC721AQueryableUpgradeable,
    IMurakamiFlowerCoin
{
    using CoinStorage for CoinStorage.Layout;

    uint256 public constant ADMIN_ROLE = 1 << 0;
    uint256 public constant MANAGER_ROLE = 1 << 1;
    uint256 public constant MINTER_ROLE = 1 << 2;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    modifier onlyActive() {
        require(CoinStorage.layout().active, "Not Active");
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

        CoinStorage.layout().baseURI = baseUri_;
        CoinStorage.layout().operatorFilteringEnabled = true;

        _setDefaultRoyalty(royalty_, royaltyFee_);
    }

    function setBaseURI(
        string memory newuri
    ) external onlyRolesOrOwner(ADMIN_ROLE) {
        CoinStorage.layout().baseURI = newuri;
    }

    function setActive(bool newActive) external onlyRolesOrOwner(ADMIN_ROLE) {
        CoinStorage.layout().active = newActive;
    }

    function mint(
        address to,
        uint256 quantity
    ) external onlyRolesOrOwner(MINTER_ROLE) {
        _mint(to, quantity);
    }

    function reveal(
        uint256 tokenId,
        uint256 exp
    ) external onlyRolesOrOwner(MANAGER_ROLE) {
        CoinStorage.layout().coinEXP[tokenId] = exp;
    }

    function revealBatch(
        uint256[] calldata coinTokenIds,
        uint256[] calldata exps
    ) external onlyRolesOrOwner(MANAGER_ROLE) {
        uint256 length = coinTokenIds.length;
        require(length == exps.length, "Lengths mismatch");
        for (uint256 i = 0; i < length; ) {
            uint256 tokenId = coinTokenIds[i];
            CoinStorage.layout().coinEXP[tokenId] = exps[i];
            unchecked {
                i++;
            }
        }
    }

    function setMoneyCatCoinBank(
        address moneyCatCoinBankAddress
    ) external onlyRolesOrOwner(ADMIN_ROLE) {
        CoinStorage.layout().moneyCatCoinBank = IMurakamiMoneyCatCoinBank(
            moneyCatCoinBankAddress
        );
    }

    function setLuckyCatCoinBank(
        address luckyCatCoinBankAddress
    ) external onlyRolesOrOwner(ADMIN_ROLE) {
        CoinStorage.layout().luckyCatCoinBank = IMurakamiLuckyCatCoinBank(
            luckyCatCoinBankAddress
        );
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyRolesOrOwner(ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(
        bool value
    ) public onlyRolesOrOwner(ADMIN_ROLE) {
        CoinStorage.layout().operatorFilteringEnabled = value;
    }

    function breakLuckyCatCoinBank(uint256 tokenId) external onlyActive {
        require(
            CoinStorage.layout().luckyCatCoinBank.ownerOf(tokenId) ==
                _msgSenderERC721A(),
            "Not owner"
        );
        CoinStorage.layout().luckyCatCoinBank.burn(tokenId);
        CoinStorage.layout().moneyCatCoinBank.mint(_msgSenderERC721A());
        _mint(_msgSenderERC721A(), 1);
        emit LuckyCatCoinBankBroken(tokenId, _msgSenderERC721A());
    }

    function getEXP(uint256 tokenId) external view returns (uint256) {
        return CoinStorage.layout().coinEXP[tokenId];
    }

    function active() external view returns (bool) {
        return CoinStorage.layout().active;
    }

    function isApprovedForAll(
        address account,
        address operator
    )
        public
        view
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (bool)
    {
        return
            _isOperatorApproved(operator) ||
            ERC721AUpgradeable.isApprovedForAll(account, operator);
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

    function _baseURI() internal view virtual override returns (string memory) {
        return CoinStorage.layout().baseURI;
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
        return CoinStorage.layout().operatorFilteringEnabled;
    }

    function _isOperatorApproved(
        address operator
    ) internal view returns (bool) {
        return address(CoinStorage.layout().moneyCatCoinBank) == operator;
    }

    function _isPriorityOperator(
        address operator
    ) internal view virtual override returns (bool) {
        return _isOperatorApproved(operator);
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