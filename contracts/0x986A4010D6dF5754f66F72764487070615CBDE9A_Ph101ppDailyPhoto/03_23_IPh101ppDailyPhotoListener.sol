// SPDX-License-Identifier: MIT
// Author: Philipp Adrian (ph101pp.eth)

pragma solidity ^0.8.12;

interface IPh101ppDailyPhotoListener {
    
    ///////////////////////////////////////////////////////////////////////////
    // Transfer Event Listener
    ///////////////////////////////////////////////////////////////////////////

    function Ph101ppDailyPhotoTransferHandler(
        address operator,
        address from,
        address to,
        uint[] memory ids,
        uint[] memory amounts,
        bytes memory data
    ) external;
    
}