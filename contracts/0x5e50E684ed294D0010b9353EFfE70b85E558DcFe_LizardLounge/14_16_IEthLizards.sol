// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IEthlizards is IERC721 {
    function batchTransferFrom(address _from, address _to, uint256[] calldata _tokenId) external;
}