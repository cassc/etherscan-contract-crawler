// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "erc721a/contracts/IERC721A.sol";

/// @title Airdrop Helper for Afropolitan
/// @author [email protected]
contract AfropolitanAirdrop {
    function dispatchERC721(
        address _token,
        address[] memory _receivers,
        uint256[] memory _ids
    ) public {
        IERC721A tokToken = IERC721A(_token);

        for (uint256 i = 0; i < _receivers.length; i++) {
            tokToken.transferFrom(msg.sender, _receivers[i], _ids[i]);
        }
    }
}