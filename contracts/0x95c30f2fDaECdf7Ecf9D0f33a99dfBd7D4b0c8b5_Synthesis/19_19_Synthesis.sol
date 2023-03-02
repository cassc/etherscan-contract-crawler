// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@manifoldxyz/creator-core-solidity/contracts/extensions/CreatorExtension.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC1155CreatorCore.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Synthesis is IERC1155Receiver, CreatorExtension, Ownable {
    struct BurnRedemption {
        uint256[] burn_token_ids;
        uint256[] burn_token_amounts;
        uint256[] redeem_token_ids;
        uint256[] redeem_token_amounts;
    }

    struct GatedRedemption {
        uint256[] gated_token_ids;
        uint256[] gated_token_amounts;
        uint256[] redeem_token_ids;
        uint256[] redeem_token_amounts;
        uint256[] redeem_token_maxes;
    }

    address _creatorCore;
    BurnRedemption[] _burnRedemptions;
    GatedRedemption[] _gatedRedemptions;

    constructor(
        address creatorCore,
        BurnRedemption[] memory burnRedemptions,
        GatedRedemption[] memory gatedRedemptions
    ) {
        _creatorCore = creatorCore;
        for (uint8 r = 0; r < burnRedemptions.length; ++r) {
            _burnRedemptions.push(burnRedemptions[r]);
        }
        for (uint8 r = 0; r < gatedRedemptions.length; ++r) {
            _gatedRedemptions.push(gatedRedemptions[r]);
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(CreatorExtension, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function onERC1155Received(
        address, // operator,
        address, // from,
        uint256, // id,
        uint256, // value,
        bytes calldata // data
    ) external pure returns (bytes4) {
        revert("Only batch transfers are supported");
    }

    function onERC1155BatchReceived(
        address, // operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata // data
    ) external returns (bytes4) {
        for (uint8 r = 0; r < _burnRedemptions.length; ++r) {
            if (
                _burnRedemptions[r].burn_token_ids.length != ids.length ||
                _burnRedemptions[r].burn_token_amounts.length != values.length
            ) continue;

            bool redeemable = true;
            for (
                uint8 i = 0;
                i < _burnRedemptions[r].burn_token_ids.length;
                ++i
            ) {
                if (
                    _burnRedemptions[r].burn_token_ids[i] != ids[i] ||
                    _burnRedemptions[r].burn_token_amounts[i] != values[i]
                ) {
                    redeemable = false;
                    break;
                }
            }

            if (!redeemable) continue;

            address[] memory to = new address[](1);
            to[0] = from;

            IERC1155CreatorCore(_creatorCore).burn(address(this), ids, values);
            IERC1155CreatorCore(_creatorCore).mintBaseExisting(
                to,
                _burnRedemptions[r].redeem_token_ids,
                _burnRedemptions[r].redeem_token_amounts
            );

            return this.onERC1155BatchReceived.selector;
        }

        revert("No burn redemption found");
    }

    function gatedRedemption(
        uint256[] calldata ids,
        uint256[] calldata values
    ) external {
        for (uint8 r = 0; r < _gatedRedemptions.length; ++r) {
            if (
                _gatedRedemptions[r].gated_token_ids.length != ids.length ||
                _gatedRedemptions[r].gated_token_amounts.length != values.length
            ) continue;

            bool redeemable = true;
            for (
                uint8 i = 0;
                i < _gatedRedemptions[r].gated_token_ids.length;
                ++i
            ) {
                if (
                    _gatedRedemptions[r].gated_token_ids[i] != ids[i] ||
                    _gatedRedemptions[r].gated_token_amounts[i] != values[i]
                ) {
                    redeemable = false;
                    break;
                }
            }

            if (!redeemable) continue;

            for (
                uint8 i = 0;
                i < _gatedRedemptions[r].gated_token_ids.length;
                ++i
            ) {
                require(
                    IERC1155(_creatorCore).balanceOf(
                        msg.sender,
                        _gatedRedemptions[r].gated_token_ids[i]
                    ) >= _gatedRedemptions[r].gated_token_amounts[i],
                    "Insufficient gated token amounts"
                );
            }

            for (
                uint8 i = 0;
                i < _gatedRedemptions[r].redeem_token_ids.length;
                ++i
            ) {
                require(
                    IERC1155(_creatorCore).balanceOf(
                        msg.sender,
                        _gatedRedemptions[r].redeem_token_ids[i]
                    ) +
                        _gatedRedemptions[r].redeem_token_amounts[i] <=
                        _gatedRedemptions[r].redeem_token_maxes[i],
                    "Maximum gated token redemption would be exceeded"
                );
            }

            address[] memory to = new address[](1);
            to[0] = msg.sender;

            IERC1155CreatorCore(_creatorCore).mintBaseExisting(
                to,
                _gatedRedemptions[r].redeem_token_ids,
                _gatedRedemptions[r].redeem_token_amounts
            );

            return;
        }

        revert("No gated redemption found");
    }
}