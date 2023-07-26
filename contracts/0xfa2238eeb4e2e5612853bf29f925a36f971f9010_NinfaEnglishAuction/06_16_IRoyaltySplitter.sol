// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

/// @author: manifold.xyz
struct Recipient {
    address payable recipient;
    uint16 bps;
}

interface IRoyaltySplitter {
    /**
     * @dev Get the splitter recipients;
     */
    function getRecipients() external view returns (Recipient[] memory);

    function getRecipients(
        uint256 tokenId
    ) external view returns (Recipient[] memory);
}