pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED

/**
 * @title RefinableERC1155Token Interface
 */
interface IRefinableERC1155Token {
    struct Fee {
        address payable recipient;
        uint256 value;
    }

    function mint(uint256 _tokenId, bytes memory _signature, Fee[] memory _fees, uint256 _supply, string memory _uri) external;
}