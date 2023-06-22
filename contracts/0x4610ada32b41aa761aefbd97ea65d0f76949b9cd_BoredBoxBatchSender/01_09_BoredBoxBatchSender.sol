// SPDX-License-Identifier: MIT
// vim: textwidth=119
pragma solidity 0.8.11;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import { IBoredBoxBatchSender_Functions } from "./interfaces/IBoredBoxBatchSender.sol";

/// @title Contract for sending ERC721 and/or ERC1155 assets en masse
/// @author S0AndS0
/// @custom:link https://boredbox.io/
contract BoredBoxBatchSender is IBoredBoxBatchSender_Functions {
    /// Mapping account to authorized state
    mapping(address => bool) public isAuthorized;

    /// Mapping `boxTokenId` to `contractAddress` _claimed state
    /// @dev See {IBoredBoxBatchSender_Functions-claimed}
    mapping(uint256 => mapping(address => uint256)) internal _claimed;

    /// @dev See {ERC165Checker-supportsInterface}
    ///> 0x80ac58cd
    bytes4 constant _ERC721_CONTRACT = type(IERC721).interfaceId;

    /// @dev See {ERC165Checker-supportsInterface}
    ///> 0xd9b67a26
    bytes4 constant _ERC1155_CONTRACT = type(IERC1155).interfaceId;

    /// @dev See {IERC721Receiver-onERC721Received}
    ///
    /// ```javascript
    /// web3.eth.abi.encodeFunctionSignature('onERC721Received(address,address,uint256,bytes)')
    /// //> 0x150b7a02
    /// ```
    ///
    /// address operator
    /// address from
    /// uint256 tokenId
    /// bytes calldata data
    bytes4 constant _ERC721_RECEIVER = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));

    /// @dev See {IERC1155Receiver-onERC1155Received}
    ///
    /// ```javascript
    /// web3.eth.abi.encodeFunctionSignature('onERC1155Received(address,address,uint256,uint256,bytes)')
    /// //> 0xf23a6e61
    /// ```
    ///
    /// address operator
    /// address from
    /// uint256 id
    /// uint256 value
    /// bytes calldata data
    bytes4 constant _ERC1155_RECEIVER = bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑            Storage          ↑ */
    /* ↓  Modifiers and constructor  ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    modifier onlyAuthorized() {
        require(isAuthorized[msg.sender], "Not authorized");
        _;
    }

    ///
    constructor(address owner) {
        isAuthorized[owner] = true;
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑  Modifiers and constructor  ↑ */
    /* ↓      off-chain external     ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// @dev See {IBoredBoxBatchSender_Functions-batchTransfer}
    function batchTransfer(
        address tokenContract,
        uint256[] calldata boxes,
        uint256[] calldata tokenIds,
        address[] calldata recipients
    ) external payable onlyAuthorized {
        uint256 boxes_length = boxes.length;
        require(boxes_length > 0, "Insufficient boxes provided");

        require(
            boxes_length == tokenIds.length && boxes_length == recipients.length,
            "Length missmatch between; boxes, tokenIds, and/or recipients"
        );

        if (ERC165Checker.supportsInterface(tokenContract, _ERC721_CONTRACT)) {
            uint256 box;
            uint256 tokenId;
            for (uint256 i; i < boxes_length; ) {
                box = boxes[i];
                if (_claimed[box][tokenContract] == 0) {
                    tokenId = tokenIds[i];
                    IERC721(tokenContract).transferFrom(msg.sender, recipients[i], tokenId);
                    _claimed[box][tokenContract] = ++tokenId;
                }

                unchecked {
                    ++i;
                }
            }
        } else if (ERC165Checker.supportsInterface(tokenContract, _ERC1155_CONTRACT)) {
            uint256 box;
            uint256 tokenId;
            for (uint256 i; i < boxes_length; ) {
                box = boxes[i];
                if (_claimed[box][tokenContract] == 0) {
                    tokenId = tokenIds[i];
                    IERC1155(tokenContract).safeTransferFrom(msg.sender, recipients[i], tokenId, 1, "");
                    _claimed[box][tokenContract] = ++tokenId;
                }

                unchecked {
                    ++i;
                }
            }
        } else {
            revert("Failed to recognize tokenContract");
        }
    }

    ///
    function setAuthorized(address key, bool value) external payable onlyAuthorized {
        isAuthorized[key] = value;
    }

    /// @dev See {IBoredBoxBatchSender_Functions-withdraw}
    function withdraw(address payable to, uint256 amount) external payable onlyAuthorized {
        (bool success, ) = to.call{ value: amount }("");
        require(success, "Transfer failed");
    }

    /// @dev See {IBoredBoxBatchSender_Functions-canRecieve}
    function canReceive(address to) external pure returns (uint256) {
        uint256 result;

        if (IERC721Receiver(to).onERC721Received.selector == _ERC721_RECEIVER) {
            result += 1;
        }

        if (IERC1155Receiver(to).onERC1155Received.selector == _ERC1155_RECEIVER) {
            result += 2;
        }

        return result;
    }

    /// @dev See {IBoredBoxBatchSender_Functions-claimed}
    function claimed(uint256 box, address tokenContract) external view returns (uint256) {
        uint256 tokenId = _claimed[box][tokenContract];
        require(tokenId > 0, "Not claimed");
        return --tokenId;
    }
}