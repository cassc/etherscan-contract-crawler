// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "./IERC5725.sol";

interface IBillNft is IERC5725, IERC721EnumerableUpgradeable {
    struct TokenData {
        uint256 tokenId;
        address billAddress;
    }

    function addMinter(address minter) external;

    function mint(address to, address billAddress) external returns (uint256);

    function mintMany(uint256 amount, address to, address billAddress) external;

    function lockURI() external;

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external;

    function claimMany(uint256[] calldata _tokenIds) external;

    function pendingPayout(uint256 tokenId) external view returns (uint256 pendingPayoutAmount);

    function pendingVesting(uint256 tokenId) external view returns (uint256 pendingSeconds);

    function allTokensDataOfOwner(address owner) external view returns (TokenData[] memory);

    function getTokensOfOwnerByIndexes(address owner, uint256 start, uint256 end) external view returns (TokenData[] memory);

    function tokenDataOfOwnerByIndex(address owner, uint256 index) external view returns (TokenData memory tokenData);
}