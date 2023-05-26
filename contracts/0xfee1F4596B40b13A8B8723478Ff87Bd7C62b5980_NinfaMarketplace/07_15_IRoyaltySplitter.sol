// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/// @author: manifold.xyz
struct Recipient {
    address payable recipient;
    uint16 bps;
}

interface IRoyaltySplitter {
    /**
     * @dev Set the splitter recipients. Total bps must total 10000.
     */
    function setRecipients(Recipient[] calldata recipients) external;

    /**
     * @dev Get the splitter recipients;
     */
    function getRecipients(
        uint256 tokenId
    ) external view returns (Recipient[] memory);
}