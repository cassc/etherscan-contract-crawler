//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IYardbois is IERC721Enumerable {

    struct GnomeStatus {
        uint40 happinessSnapshotTime;
        uint40 happinessCounter;
        address currentJob;
        bool isUnpaid;
    }

    function mint(address _recipient, uint256 _tokenId) external;
    function setGnomeWorking(uint256 _idx) external;
    function setGnomeNotWorking(uint256 _idx, bool _isUnpaid) external;
    function gnomeStatus(uint256 _idx) external view returns (GnomeStatus memory);

}