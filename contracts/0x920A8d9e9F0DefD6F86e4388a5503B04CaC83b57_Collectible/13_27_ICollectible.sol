// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";


interface ICollectible is IERC721Enumerable {
    function setMintPassToken(address _mintPassToken) external;
    function redeem(uint256[] calldata mpIndexes, uint256[] calldata amounts) external;
    function setRedeemStart(uint256 passID, uint256 _windowOpen) external;
    function setRedeemClose(uint256 passID, uint256 _windowClose) external;
    function setMaxRedeemPerTxn(uint256 passID, uint256 _maxRedeemPerTxn) external;
    function isRedemptionOpen(uint256 passID) external returns (bool);
    function unpause() external;
    function pause() external;
    function setBaseURI(string memory _baseTokenURI) external;
    function setIndividualTokenURI(uint256 passID, string memory uri) external;
}