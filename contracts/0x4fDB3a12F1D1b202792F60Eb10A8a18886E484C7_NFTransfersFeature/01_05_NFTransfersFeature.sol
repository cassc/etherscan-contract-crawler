// SPDX-License-Identifier: Apache-2.0
/*

  CopyrightCopyright 2022 Element.Market Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../interfaces/INFTransfersFeature.sol";

contract NFTransfersFeature is INFTransfersFeature {

    using Address for address;

    function transferItems(address to, TransferItem[] calldata items) external override {
        transferItemsEx(to, items, false);
    }

    function transferERC721s(address to, address[] calldata tokens, uint256[][] calldata tokenIds) external override {
        transferERC721sEx(to, tokens, tokenIds, false);
    }

    function transferItemsEx(address to, TransferItem[] calldata items, bool revertIfIncomplete) public override {
        unchecked {
            bool someSuccess;
            if (to.isContract()) {
                for (uint256 i = 0; i < items.length; ++i) {
                    TransferItem calldata item = items[i];
                    if (item.itemType == ItemType.ERC721) {
                        require(item.amounts.length == 0, "require(item.amounts.length==0)");
                        address token = item.token;
                        uint256[] calldata ids = item.ids;
                        uint256 lengthIds = ids.length;
                        for (uint256 j = 0; j < lengthIds; ++j) {
                            if (_safeTransferERC721(token, to, ids[j])) {
                                someSuccess = true;
                            } else {
                                if (revertIfIncomplete) {
                                    revert("_safeTransferERC721/TRANSFER_FAILED");
                                }
                            }
                        }
                    } else if (item.itemType == ItemType.ERC1155) {
                        try IERC1155(item.token).safeBatchTransferFrom(msg.sender, to, item.ids, item.amounts, "") {
                            someSuccess = true;
                        } catch {
                            if (revertIfIncomplete) {
                                revert("_safeBatchTransferERC1155/TRANSFER_FAILED");
                            }
                        }
                    } else {
                        revert("INVALID_ITEM_TYPE");
                    }
                }
            } else {
                for (uint256 i = 0; i < items.length; ++i) {
                    TransferItem calldata item = items[i];
                    if (item.itemType == ItemType.ERC721) {
                        require(item.amounts.length == 0, "require(item.amounts.length==0)");
                        address token = item.token;
                        uint256[] calldata ids = item.ids;
                        uint256 lengthIds = ids.length;
                        for (uint256 j = 0; j < lengthIds; ++j) {
                            if (_transferERC721(token, to, ids[j])) {
                                someSuccess = true;
                            } else {
                                if (revertIfIncomplete) {
                                    revert("_transferERC721/TRANSFER_FAILED");
                                }
                            }
                        }
                    } else if (item.itemType == ItemType.ERC1155) {
                        try IERC1155(item.token).safeBatchTransferFrom(msg.sender, to, item.ids, item.amounts, "") {
                            someSuccess = true;
                        } catch {
                            if (revertIfIncomplete) {
                                revert("_safeBatchTransferERC1155/TRANSFER_FAILED");
                            }
                        }
                    } else {
                        revert("INVALID_ITEM_TYPE");
                    }
                }
            }
            require(someSuccess, "transferItemsEx failed.");
        }
    }

    function transferERC721sEx(address to, address[] calldata tokens, uint256[][] calldata tokenIds, bool revertIfIncomplete) public override {
        require(tokens.length == tokenIds.length, "transferERC721sEx/ARRAY_LENGTH_MISMATCH");

        unchecked {
            bool someSuccess;
            if (to.isContract()) {
                for (uint256 i = 0; i < tokens.length; ++i) {
                    address token = tokens[i];
                    uint256[] calldata ids = tokenIds[i];
                    uint256 lengthIds = ids.length;
                    for (uint256 j = 0; j < lengthIds; ++j) {
                        if (_safeTransferERC721(token, to, ids[j])) {
                            someSuccess = true;
                        } else {
                            if (revertIfIncomplete) {
                                revert("_safeTransferERC721/TRANSFER_FAILED");
                            }
                        }
                    }
                }
            } else {
                for (uint256 i = 0; i < tokens.length; ++i) {
                    address token = tokens[i];
                    uint256[] calldata ids = tokenIds[i];
                    uint256 lengthIds = ids.length;
                    for (uint256 j = 0; j < lengthIds; ++j) {
                        if (_transferERC721(token, to, ids[j])) {
                            someSuccess = true;
                        } else {
                            if (revertIfIncomplete) {
                                revert("_transferERC721/TRANSFER_FAILED");
                            }
                        }
                    }
                }
            }
            require(someSuccess, "transferERC721sEx failed.");
        }
    }

    function _transferERC721(address token, address to, uint256 tokenId) internal returns (bool success) {
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for transferFrom(address,address,uint256)
            mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), caller())
            mstore(add(ptr, 0x24), to)
            mstore(add(ptr, 0x44), tokenId)

            success := call(gas(), token, 0, ptr, 0x64, 0, 0)
        }
    }

    function _safeTransferERC721(address token, address to, uint256 tokenId) internal returns (bool success)  {
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for safeTransferFrom(address,address,uint256)
            mstore(ptr, 0x42842e0e00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), caller())
            mstore(add(ptr, 0x24), to)
            mstore(add(ptr, 0x44), tokenId)

            success := call(gas(), token, 0, ptr, 0x64, 0, 0)
        }
    }
}