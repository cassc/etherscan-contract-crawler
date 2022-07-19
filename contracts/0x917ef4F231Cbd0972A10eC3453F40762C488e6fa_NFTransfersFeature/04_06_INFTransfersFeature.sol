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

interface INFTransfersFeature {

    enum ItemType {
        ERC721,
        ERC1155
    }

    struct TransferItem {
        ItemType itemType;
        address token;
        uint256[] ids;
        uint256[] amounts;
    }

    function transferItems(address to, TransferItem[] calldata items) external;

    function transferERC721s(address to, address[] calldata tokens, uint256[][] calldata tokenIds) external;
}