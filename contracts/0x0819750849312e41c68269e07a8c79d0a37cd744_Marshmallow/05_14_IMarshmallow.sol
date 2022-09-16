// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import './IERC2981.sol';

interface IMarshmallow is IERC1155, IERC2981 {

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);

    function canAddWhitelist() external view returns(bool);
    function canChangeMetadata() external view returns(bool);
    function canChangeRoyaltyPercentage() external view returns(bool);

    function isWhitelisted(address subject) external view returns(bool);

    function royaltyPercentage() external view returns (uint256);
    function royaltyReceiver() external view returns (address);

    event RoyaltyPercentageChanged(uint256 indexed from, uint256 indexed to);

    function whitelistTheseToObtainMarshmallows(address[] calldata whitelist) external;

    function setURI(string calldata newuri) external;

    function setRoyaltyPercentage(uint256 newRoyaltyPercentage) external;

    function setRoyaltyReceiver(address newRoyaltyReceiver) external;

    function renounceAddWhitelist() external;

    function renounceChangeMetadata() external;

    function renounceChangeRoyaltyPercentage() external;

    function createMarshmallow() external;
}