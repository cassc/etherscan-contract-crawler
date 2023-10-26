// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Data, HeyMintStorage} from "../libraries/HeyMintStorage.sol";
import {ERC1155UDS} from "./ERC1155UDS.sol";
import {OwnableUDS} from "./OwnableUDS.sol";
import {PausableUDS} from "./PausableUDS.sol";
import {ReentrancyGuardUDS} from "./ReentrancyGuardUDS.sol";
import {RevokableOperatorFiltererUpgradeable} from "operator-filter-registry/src/upgradeable/RevokableOperatorFiltererUpgradeable.sol";
import {IERC2981Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

/**
 * @title HeyMintERC1155Upgradeable
 * @author HeyMint Launchpad (https://join.heymint.xyz)
 * @notice This contract contains shared logic to be inherited by all implementation contracts
 */
contract HeyMintERC1155Upgradeable is
    ERC1155UDS,
    OwnableUDS,
    PausableUDS,
    ReentrancyGuardUDS,
    RevokableOperatorFiltererUpgradeable
{
    using HeyMintStorage for HeyMintStorage.State;

    uint256 public constant defaultHeymintFeePerToken = 0.0007 ether;
    address public constant heymintPayoutAddress =
        0xE1FaC470dE8dE91c66778eaa155C64c7ceEFc851;

    // ============ BASE FUNCTIONALITY ============

    function uri(
        uint256 _id
    ) public view virtual override(ERC1155UDS) returns (string memory) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        uint16 id = uint16(_id);
        if (bytes(state.tokens[id].tokenUri).length > 0) {
            return state.tokens[id].tokenUri;
        }
        return state.cfg.uriBase;
    }

    /**
     * @notice Returns the owner of the contract
     */
    function owner()
        public
        view
        virtual
        override(OwnableUDS, RevokableOperatorFiltererUpgradeable)
        returns (address)
    {
        return OwnableUDS.owner();
    }

    /**
     * @notice Returns true if the contract implements the interface defined by interfaceId
     * @param interfaceId The interface identifier, as specified in ERC-165
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155UDS) returns (bool) {
        return
            super.supportsInterface(interfaceId) ||
            interfaceId == type(IERC2981Upgradeable).interfaceId;
    }

    /**
     * @notice Override ERC1155 such that zero amount token transfers are disallowed.
     * This prevents arbitrary 'creation' of new tokens in the collection by anyone.
     * Also prevents transfers from blocked operators.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override(ERC1155UDS) onlyAllowedOperator(from) {
        require(amount > 0, "AMOUNT_CANNOT_BE_ZERO");
        return super.safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @notice Override ERC1155 such that zero amount token transfers are disallowed.
     * This prevents arbitrary 'creation' of new tokens in the collection by anyone.
     * Also prevents transfers from blocked operators.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) public override(ERC1155UDS) onlyAllowedOperator(from) {
        for (uint256 i; i < ids.length; i++) {
            require(amounts[i] > 0, "AMOUNT_CANNOT_BE_ZERO");
        }
        return super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override(ERC1155UDS) notPaused onlyAllowedOperator(from) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        if (!state.data.soulboundAdminTransferInProgress) {
            require(
                !state.tokens[uint16(id)].soulbindingActive,
                "TOKEN_SOULBOUND"
            );
        }
    }

    function _beforeBatchTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155UDS) notPaused onlyAllowedOperator(from) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        if (!state.data.soulboundAdminTransferInProgress) {
            for (uint256 i; i < ids.length; i++) {
                require(
                    !state.tokens[uint16(ids[i])].soulbindingActive,
                    "TOKEN_SOULBOUND"
                );
            }
        }
    }

    // ============ HEYMINT FEE ============

    /**
     * @notice Returns the HeyMint fee per token. If the fee is active but 0, the default fee is returned
     */
    function heymintFeePerToken() public view returns (uint256) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        uint256 fee = state.data.heymintFeePerToken;
        if (!state.cfg.heyMintFeeActive) {
            return 0;
        }
        return fee == 0 ? defaultHeymintFeePerToken : fee;
    }

    // ============ PUBLIC SALE ============

    /**
     * @notice Returns the public price in wei. Public price is stored with 5 decimals (1 = 0.00001 ETH), so total 5 + 13 == 18 decimals
     */
    function publicPriceInWei(uint16 _tokenId) public view returns (uint256) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        return uint256(state.tokens[_tokenId].publicPrice) * 10 ** 13;
    }

    /**
     * @notice Returns if public sale times are active for a given token
     */
    function tokenPublicSaleTimeIsActive(
        uint16 _tokenId
    ) public view returns (bool) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        if (state.tokens[_tokenId].usePublicSaleTimes == false) {
            return true;
        }
        return
            block.timestamp >= state.tokens[_tokenId].publicSaleStartTime &&
            block.timestamp <= state.tokens[_tokenId].publicSaleEndTime;
    }
}