// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

// OZ Upgrades imports
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ERC1155Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";

// local override imports
import { VotesUpgradeable } from "./VotesUpgradeable.sol";

/**************************************

    ERC1155 + Votes contract

 **************************************/

abstract contract ERC1155VotesUpgradeable is Initializable, ERC1155Upgradeable, VotesUpgradeable {

    // errors
    error MaximumIdsExceeded(uint256 idsLength);

    /**************************************

        Initializers

    **************************************/

    function __ERC721Votes_init() internal onlyInitializing {}

    function __ERC721Votes_init_unchained() internal onlyInitializing {}

    /**************************************

        Transfer voting rights

        ------------------------------

        @dev AB: added iteration limit

    **************************************/

    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {

        // transfer gov
        uint256 sum_;

        // declare limit
        uint8 IDS_LIMIT = 100;
        uint256 idsLength = ids.length;

        // revert if over limit
        if (idsLength > IDS_LIMIT) {
            revert MaximumIdsExceeded(idsLength);
        }

        // loop and break on limit
        for (uint256 i = 0; i < idsLength; i++) {
            sum_ += amounts[i];
        }
        _transferVotingUnits(from, to, sum_, data);

        // super
        super._afterTokenTransfer(operator, from, to, ids, amounts, data);

    }

    /**************************************

        Get voting units

    **************************************/

    function _getVotingUnits(address account, bytes memory data) internal view virtual override 
    returns (uint256) {

        // decode
        (
            uint256 tokenId
        ) = abi.decode(
            data,
            (
                uint256
            )
        );

        // return
        return balanceOf(account, tokenId);

    }

    /**************************************

        Supports interface

    **************************************/

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual
    override(ERC1155Upgradeable, VotesUpgradeable)
    returns (bool) {

        // return combined ERC1155 and Votes interfaces
        return super.supportsInterface(interfaceId);

    }

    /**************************************

       OZ storage gap

    **************************************/

    uint256[50] private __gap;
}