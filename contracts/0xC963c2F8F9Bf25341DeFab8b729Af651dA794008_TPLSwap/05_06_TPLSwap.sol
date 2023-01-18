//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {ERC165, IERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import {ITPLRevealedParts} from "./TPLRevealedParts/ITPLRevealedParts.sol";

/// @title TPLSwap
/// @author CyberBrokers
/// @author dev by @dievardump
/// @notice Contract allowing to swap unrevealed TPL Mech Parts against revealed TPL Mech Parts
contract TPLSwap is IERC1155Receiver, ERC165 {
    error UnknownContract();

    address public immutable UNREVEALED_PARTS;
    address public immutable REVEALED_PARTS;

    modifier onlyKnownContract() {
        if (msg.sender != UNREVEALED_PARTS) {
            revert UnknownContract();
        }
        _;
    }

    constructor(address unrevealed, address revealed) {
        UNREVEALED_PARTS = unrevealed;
        REVEALED_PARTS = revealed;
    }

    /////////////////////////////////////////////////////////
    // Getters                                             //
    /////////////////////////////////////////////////////////

    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    /////////////////////////////////////////////////////////
    // Interaction                                         //
    /////////////////////////////////////////////////////////

    /// @notice Allows an user to swap `amounts` of unrevealed parts of `ids` and get as many TPLRevealedParts
    /// @dev the user must have approved the current contract on TPLUnrevealedParts
    /// @param ids the unrevealed parts ids to swap
    /// @param amounts the amounts to swap
    function swap(uint256[] calldata ids, uint256[] calldata amounts) external {
        IERC1155Burnable(UNREVEALED_PARTS).burnBatch(msg.sender, ids, amounts);

        uint256 length = ids.length;
        for (uint256 i; i < length; i++) {
            _mintBodyPartFrom(msg.sender, ids[i], amounts[i]);
        }
    }

    /////////////////////////////////////////////////////////
    // Callbacks / Hooks                                   //
    /////////////////////////////////////////////////////////

    /// @dev hook allowing users to directly send TPLUnrevealedPartsIds to this contract in order to swap
    /// @dev tests have shown that this method will be more expensive to use than approval then swap
    function onERC1155Received(
        address, /*operator*/
        address from,
        uint256 id,
        uint256 value,
        bytes calldata
    ) external onlyKnownContract returns (bytes4) {
        // burn
        IERC1155Burnable(msg.sender).burn(address(this), id, value);

        // mint
        _mintBodyPartFrom(from, id, value);

        // ACK
        return this.onERC1155Received.selector;
    }

    /// @dev hook allowing users to directly send TPLUnrevealedPartsIds in batch to this contract in order to swap
    /// @dev tests have shown that this method will be more expensive to use than approval then swap
    function onERC1155BatchReceived(
        address, /* operator */
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata
    ) external onlyKnownContract returns (bytes4) {
        // burn
        IERC1155Burnable(msg.sender).burnBatch(address(this), ids, values);

        // mint
        uint256 length = ids.length;
        for (uint256 i; i < length; i++) {
            _mintBodyPartFrom(from, ids[i], values[i]);
        }

        // ACK
        return this.onERC1155BatchReceived.selector;
    }

    /////////////////////////////////////////////////////////
    // Internals                                           //
    /////////////////////////////////////////////////////////

    /// @dev this function mint & reveals the body part wanted from the unrevealed `id`
    /// @param to the account receiving the part
    /// @param id the unrevealed part id
    /// @param amount the amount of part wanted
    function _mintBodyPartFrom(
        address to,
        uint256 id,
        uint256 amount
    ) internal {
        // most left 12 bits are the original unrevealed id
        // most right 12 bits is the "generation" of the part. Here all parts are Genesis parts
        uint24 packedData = uint24((id << 12) | 1);

        // mint `amount` revealed parts to `to` with `packedData`
        ITPLRevealedParts(REVEALED_PARTS).mintTo(to, amount, packedData);
    }
}

interface IERC1155Burnable {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;
}