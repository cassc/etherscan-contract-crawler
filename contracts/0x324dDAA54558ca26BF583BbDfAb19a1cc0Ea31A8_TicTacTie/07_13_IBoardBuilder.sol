// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

interface IBoardBuilder {
    function getBoard(uint256 tokenId, address ttt)
        external
        view
        returns (string memory json);

    function getTie(uint256 tieId) external view returns (string memory json);
}