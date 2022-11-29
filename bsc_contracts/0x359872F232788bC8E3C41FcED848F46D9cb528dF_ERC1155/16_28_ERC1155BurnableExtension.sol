// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../common/Errors.sol";
import "../../IERC1155.sol";
import "../../base/ERC1155BaseInternal.sol";
import "./IERC1155BurnableExtension.sol";

/**
 * @title Extension of {ERC1155} that allows users or approved operators to burn tokens.
 */
abstract contract ERC1155BurnableExtension is IERC1155BurnableExtension, ERC1155BaseInternal {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || IERC1155(address(this)).isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] calldata ids,
        uint256[] calldata values
    ) public virtual {
        require(
            account == _msgSender() || IERC1155(address(this)).isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }

    function burnByFacet(
        address account,
        uint256 id,
        uint256 amount
    ) public virtual {
        if (address(this) != msg.sender) {
            revert ErrSenderIsNotSelf();
        }

        _burn(account, id, amount);
    }

    function burnBatchByFacet(
        address account,
        uint256[] calldata ids,
        uint256[] calldata values
    ) public virtual {
        if (address(this) != msg.sender) {
            revert ErrSenderIsNotSelf();
        }

        _burnBatch(account, ids, values);
    }
}