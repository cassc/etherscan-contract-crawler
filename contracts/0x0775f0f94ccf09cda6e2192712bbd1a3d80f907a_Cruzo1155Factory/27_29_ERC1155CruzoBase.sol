// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./ERC1155DefaultApproval.sol";

abstract contract ERC1155CruzoBase is
    ContextUpgradeable,
    ERC1155SupplyUpgradeable,
    ERC1155DefaultApproval,
    OwnableUpgradeable,
    PausableUpgradeable
{
    mapping(uint256 => address) public creators;

    /**
     * @dev Require msg.sender to be the creator of the token id
     */
    modifier onlyCreator(uint256 _id) {
        require(
            creators[_id] == _msgSender(),
            "ERC1155CruzoBase#onlyCreator: ONLY_CREATOR_ALLOWED"
        );
        _;
    }

    /**
     * @dev Pauses transfer
     */
    function pause() public onlyOwner returns (bool) {
        _pause();
        return true;
    }

    /**
     * @dev UnPauses transfer
     */
    function unpause() public onlyOwner returns (bool) {
        _unpause();
        return true;
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override(ERC1155Upgradeable, ERC1155DefaultApproval)
        returns (bool)
    {
        return ERC1155DefaultApproval.isApprovedForAll(_owner, _operator);
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        require(!paused(), "ERC1155CruzoBase: token transfer while paused");
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155CruzoBase: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155CruzoBase: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
}