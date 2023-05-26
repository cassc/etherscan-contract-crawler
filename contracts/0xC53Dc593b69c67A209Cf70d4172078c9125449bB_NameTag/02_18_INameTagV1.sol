// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


interface INameTagV1 is IERC721Enumerable {
    struct Wave {
        uint256 limit;
        uint256 startTime;
    }

    event NameChanged(uint256 indexed tokenId, string from, string to);

    function currentWaveIndex() external view returns (uint8);
    function currentLimit() external view returns (uint256);
    function currentWave() external view returns (uint256, uint256);
    function waveByIndex(uint8 waveIndex_) external view returns (uint256, uint256);

    function price() external view returns (uint256);
    function tokenAmountBuyLimit() external view returns (uint8);

    function metadataFee() external view returns (uint256);
    function defaultMetadata() external view returns (string memory);
    function defaultNamedMetadata() external view returns (string memory);
    function metadataRole() external view returns (address);

    function changeMetadataRole(address newAddress) external;
    function setMetadataFee(uint256 metadataFee_) external;
    function setDefaultMetadata(string memory metadata_) external;
    function setDefaultNamedMetadata(string memory metadata_) external;
    function setMetadata(uint256 tokenId, string memory _metadata) external;
    function setMetadataList(uint256[] memory _tokens, string[] memory _metadata) external;

    function setTokenAmountBuyLimit(uint8 tokenAmountBuyLimit_) external;
    function setBaseURI(string memory baseURI_) external;

    function setWaveStartTime(uint8 waveIndex_, uint256 startTime_) external;
    function setPrice(uint256 price_) external;
    function withdraw(address payable wallet, uint256 amount) external;

    function addDenyList(string[] memory _words) external;
    function removeDenyList(string[] memory _words) external;

    function tokenURI(uint256 tokenId) external view returns (string memory);
    function getByName(string memory name) external view returns (uint256);
    function getTokenName(uint256 tokenId) external view returns (string memory);

    function buyNamedTokens(string[] memory _names) external payable returns (uint256[] memory);
    function buyTokens() external payable returns (uint256[] memory);
    function buyNamedToken(string memory _name) external payable returns (uint256);
    function buyToken(string memory _name) external payable returns (uint256);

    function setNames(uint256[] memory _tokens, string[] memory _names) external payable returns (bool[] memory);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);
    function renounceOwnership() external;
    function transferOwnership(address newOwner) external;
}