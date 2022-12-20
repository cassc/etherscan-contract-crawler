// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "./ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address _account,
        uint256 _id,
        uint256 _amount
    ) public virtual {
        require(
            _account == _msgSender() || isApprovedForAll(_account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(_account, _id, _amount);
    }

    function burnBatch(
        address _account,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) public virtual {
        require(
            _account == _msgSender() || isApprovedForAll(_account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(_account, _ids, _amounts);
    }
}