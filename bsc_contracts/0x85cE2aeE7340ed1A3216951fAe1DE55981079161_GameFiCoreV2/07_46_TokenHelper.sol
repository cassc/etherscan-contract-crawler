// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;

// inheritance list
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interface/type/ITokenTypes.sol";

// libs
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

// interfaces
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

abstract contract TokenHelper is Initializable, ITokenTypes {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // solhint-disable-next-line func-name-mixedcase
    function __TokenHelper_init() internal onlyInitializing {}

    // solhint-disable-next-line func-name-mixedcase
    function __TokenHelper_init_unchained() internal onlyInitializing {}

    function _tokenTransferFrom(
        TokenStandart standart,
        TransferredToken memory token,
        address from,
        address to
    ) internal {
        if (standart == TokenStandart.ERC20) {
            _erc20Validation(token);
            IERC20Upgradeable(token.tokenContract).safeTransferFrom(from, to, token.amount);
        } else if (standart == TokenStandart.ERC721) {
            _erc721Validation(token);
            IERC721Upgradeable(token.tokenContract).safeTransferFrom(from, to, token.tokenId);
        } else if (standart == TokenStandart.ERC1155) {
            _erc1155Validation(token);
            IERC1155Upgradeable(token.tokenContract).safeTransferFrom(from, to, token.tokenId, token.amount, "0x");
        } else {
            revert("TokenHelper: wrong token standart");
        }
    }

    function _tokenApprove(
        TokenStandart standart,
        TransferredToken memory token,
        address target
    ) internal {
        if (standart == TokenStandart.ERC20) {
            _erc20Validation(token);
            IERC20Upgradeable(token.tokenContract).safeApprove(target, token.amount);
        } else if (standart == TokenStandart.ERC721) {
            _erc721Validation(token);
            IERC721Upgradeable(token.tokenContract).approve(target, token.tokenId);
        } else if (standart == TokenStandart.ERC1155) {
            _erc1155Validation(token);
            IERC1155Upgradeable(token.tokenContract).setApprovalForAll(target, true);
        } else {
            revert("TokenHelper: wrong token standart");
        }
    }

    function _erc20Validation(TransferredToken memory token) internal pure {
        require(token.tokenId == 0, "TokenHelper: only for zero token id");
        require(token.amount > 0, "TokenHelper: zero token amount");
    }

    function _erc721Validation(TransferredToken memory token) internal pure {
        require(token.amount == 1, "TokenHelper: wrong token amount");
    }

    function _erc1155Validation(TransferredToken memory token) internal pure {
        require(token.amount > 0, "TokenHelper: zero erc1155 token amount");
    }

    function _tokenStandartValidation(TokenStandart standart) internal pure {
        require(standart != TokenStandart.NULL, "TokenHelper: invalid token standart");
    }

    uint256[50] private __gap;
}