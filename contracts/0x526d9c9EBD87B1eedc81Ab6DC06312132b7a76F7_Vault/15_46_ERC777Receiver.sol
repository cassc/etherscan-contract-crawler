// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC777Receiver} from "../../interfaces/IERC20/IERC777Receiver.sol";

abstract contract ERC777Receiver is IERC777Receiver, ERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC777Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}