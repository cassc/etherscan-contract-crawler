// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC165.sol";

interface IERC721DefaultOwnerCloneable is IERC165 {
    function initializeDefaultOwner(address defaultOwner_) external;    
}