// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC721Receiver} from "./IERC721Receiver.sol";
import {IMoneyMakingOpportunity} from "./IMoneyMakingOpportunity.sol";

contract MMOBatchVote is IERC721Receiver {
    IMoneyMakingOpportunity public immutable MMO;

    constructor(address _mmo) {
        MMO = IMoneyMakingOpportunity(_mmo);
    }

    error NotMMOToken();

    function onERC721Received(address, address from, uint256 tokenId, bytes calldata data)
        external
        override
        returns (bytes4)
    {
        if (msg.sender != address(MMO)) {
            revert NotMMOToken();
        }

        uint256[] memory votes = abi.decode(data, (uint256[]));
        for (uint256 i = 0; i < votes.length;) {
            MMO.castVote(tokenId, votes[i], true);

            unchecked {
                ++i;
            }
        }

        MMO.transferFrom(address(this), from, tokenId);

        return this.onERC721Received.selector;
    }
}