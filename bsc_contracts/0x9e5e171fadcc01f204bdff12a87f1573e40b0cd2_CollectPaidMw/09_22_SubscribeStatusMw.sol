// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IProfileNFT } from "../../interfaces/IProfileNFT.sol";

import { ERC721 } from "../../dependencies/solmate/ERC721.sol";

/**
 * @title SubscribeStatusMw
 * @author CyberConnect
 * @notice This checks that the user has already subscribed to the profile
 */
library SubscribeStatusMw {
    /*//////////////////////////////////////////////////////////////
                            PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

    function checkSubscribe(uint256 profileId, address collector)
        internal
        view
        returns (bool)
    {
        address essenceOwnerSubscribeNFT = IProfileNFT(msg.sender)
            .getSubscribeNFT(profileId);

        return (essenceOwnerSubscribeNFT != address(0) &&
            ERC721(essenceOwnerSubscribeNFT).balanceOf(collector) != 0);
    }
}