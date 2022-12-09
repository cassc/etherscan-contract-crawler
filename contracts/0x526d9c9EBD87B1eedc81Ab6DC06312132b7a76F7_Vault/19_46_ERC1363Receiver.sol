// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC1363Receiver} from "../../interfaces/IERC20/IERC1363Receiver.sol";

abstract contract ERC1363Receiver is IERC1363Receiver, ERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC1363Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}