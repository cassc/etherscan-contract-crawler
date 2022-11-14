// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol';

interface IStarship is IERC721EnumerableUpgradeable {
    function tokenURI(uint256 tokenId) external view returns (string memory);

    function mint(
        address _to,
        uint256 _tokenId,
        bool _isPioneer
    ) external;

    function isPioneer(uint256 _tokenId) external returns (bool);

    function burn(uint256 _tokenId) external;

    function exists(uint256 _tokenId) external view returns (bool);
}