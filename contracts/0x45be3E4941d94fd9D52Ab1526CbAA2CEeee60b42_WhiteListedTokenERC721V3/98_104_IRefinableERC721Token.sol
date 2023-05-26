// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title RefinableERC721Token Interface
 */
interface IRefinableERC721Token is IERC721 {
    struct Fee {
        address payable recipient;
        uint256 value;
    }

    function mint(
        uint256 _tokenId,
        bytes memory _signature,
        Fee[] memory _fees,
        string memory _tokenURI
    ) external;

    function setBaseURI(string memory _baseURI) external;

    function setContractURI(string memory _contractURI) external;
}