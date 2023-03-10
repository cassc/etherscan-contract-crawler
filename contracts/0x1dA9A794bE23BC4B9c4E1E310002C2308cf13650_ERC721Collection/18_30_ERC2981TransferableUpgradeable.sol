// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "../../interfaces/ITransferableRoyalties.sol";
import "../../libs/LibShare.sol";

abstract contract ERC2981TransferableUpgradeable is
    Initializable,
    ContextUpgradeable,
    ERC165Upgradeable,
    IERC2981Upgradeable,
    ITransferableRoyalties
{
    function __ERC2981Transferable_init(LibShare.Share memory defaultRoyalty_) internal onlyInitializing {}

    function __ERC2981Transferable_init_unchained(LibShare.Share memory defaultRoyalty_) internal onlyInitializing {
        if (defaultRoyalty_.account != address(0)) {
            _setDefaultRoyalty(defaultRoyalty_);
        }
    }

    LibShare.Share private _defaultRoyalty;
    mapping(uint256 => LibShare.Share) private _tokenRoyalty;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165Upgradeable, ERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(ITransferableRoyalties).interfaceId ||
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981Upgradeable
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        LibShare.Share memory royalty = _tokenRoyalty[_tokenId];

        if (royalty.account == address(0)) {
            royalty = _defaultRoyalty;
        }

        uint256 royaltyAmount = (_salePrice * royalty.value) / LibShare.SHARE_DENOMINATOR;

        return (royalty.account, royaltyAmount);
    }

    function transferTokenRoyalty(uint256 tokenId, address receiver) external {
        require(_msgSender() == _tokenRoyalty[tokenId].account, "ERC2981: caller is not royalty receiver");
        require(receiver != address(0), "ERC2981: receiver is zero address");

        _tokenRoyalty[tokenId].account = receiver;
    }

    function transferDefaultRoyalty(address receiver) external {
        require(_msgSender() == _defaultRoyalty.account, "ERC2981: caller is not royalty receiver");
        require(receiver != address(0), "ERC2981: receiver is zero address");

        _defaultRoyalty.account = receiver;
    }

    function _setDefaultRoyalty(LibShare.Share memory defaultRoyalty) internal virtual {
        require(defaultRoyalty.value <= LibShare.SHARE_DENOMINATOR, "ERC2981: royalty fee will exceed salePrice");
        require(defaultRoyalty.account != address(0), "ERC2981: invalid receiver");

        _defaultRoyalty = defaultRoyalty;
    }

    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyalty;
    }

    function _setTokenRoyalty(uint256 tokenId, LibShare.Share memory _royalty) internal virtual {
        require(_royalty.value <= LibShare.SHARE_DENOMINATOR, "ERC2981: royalty fee will exceed salePrice");
        require(_royalty.account != address(0), "ERC2981: Invalid parameters");

        _tokenRoyalty[tokenId] = _royalty;
    }

    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyalty[tokenId];
    }

    uint256[50] private __gap;
}