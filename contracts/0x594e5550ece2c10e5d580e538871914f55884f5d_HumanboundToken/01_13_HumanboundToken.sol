// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "@violetprotocol/erc721extendable/contracts/extensions/metadata/ERC721Metadata.sol";

contract HumanboundToken is ERC721Metadata {
    constructor(
        string memory name_,
        string memory symbol_,
        address extendLogic,
        address approveLogic,
        address getterLogic,
        address onReceiveLogic,
        address transferLogic,
        address hooksLogic
    )
        ERC721Metadata(
            name_,
            symbol_,
            extendLogic,
            approveLogic,
            getterLogic,
            onReceiveLogic,
            transferLogic,
            hooksLogic
        )
    {}
}