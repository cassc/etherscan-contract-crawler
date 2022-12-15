// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/IAccessControlEnumerableUpgradeable.sol";
import "./IBreeding.sol";

interface IMicrophoneNFT is
    IERC721EnumerableUpgradeable,
    IERC721ReceiverUpgradeable
{
    function setBaseURI(string memory _uri) external;

    function updateManagement(address _newManagement) external;

    function mint(
        uint8 _body,
        uint8 _head,
        uint8 _kind,
        uint8 _class,
        address _to
    ) external returns (uint256);

    function rescueLostMicrophone(uint256 _microphoneId, address _recipient)
        external;
}