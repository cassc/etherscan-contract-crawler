// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC677Receiver} from "../../interfaces/IERC20/IERC677Receiver.sol";

abstract contract ERC677Receiver is IERC677Receiver, ERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC677Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}