// "SPDX-License-Identifier: MIT"

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC721Upgradeable.sol";
import "../libraries/ExtraInfos.sol";

interface IReameNFT is IERC721Upgradeable
{
    // function mint(uint256 _loyaltyFeePercent, uint256 _amount) external returns (uint256);
    // function mintDelegate(address _creator, uint256 _loyaltyFeePercent, uint256 _amount, uint256 _collectionId) external returns (uint256);
    // function mintWithExtraInfo(address _creator, address _receiver, uint256 _loyaltyFeePercent, uint256 _amount, uint256 _collectionId, ExtraInfos.ExtraInfoV2 memory _extraInfo) external returns (uint256);
    // function setExtraLaunchTime(uint256 _tokenId, uint256 _launchTime) external;
    // function setExtraLaunchPrice(uint256 _tokenId, uint256 _launchPrice) external;
    // function setExtraApr(uint256 _tokenId, uint256 _apr) external;
    
    // function totalSupply(uint256 id) external view returns (uint256);
    // function mintBatch(uint256 _loyaltyFeePercent, uint256[] calldata _amounts, uint256 _collectionId) external returns (uint256[] memory);
    // function mintBatchWithExtraInfo(address _creator, address _receiver, uint256 _loyaltyFeePercent, uint256[] memory _amounts, uint256 _collectionId, ExtraInfos.ExtraInfoParams memory _params) external returns (uint256[] memory);

    function mint(uint256 _loyaltyFeePercent, string memory _uri, uint256 _collectionId) external returns (uint256 _tokenId);
    function mintDelegate( address _creator, uint256 _loyaltyFeePercent, string memory _uri, uint256 _collectionId ) external returns (uint256 _tokenId);
    function mintWithExtraInfo( address _creator, address _receiver, uint256 _loyaltyFeePercent, string memory _uri, uint256 _collectionId, ExtraInfos.ExtraInfoV2 memory _extraInfo ) external returns (uint256 _tokenId);
    function creatorOf(uint256 _tokenId) external view returns (address);
    function loyaltyFeePercentOf(uint256 _tokenId) external view returns (uint256);
    function calculateRoyaltyFee(uint256 _tokenId, uint256 _amount) external view returns (uint256);
    function isMaintainer(address _user) external view returns (bool);
    function isCreator(address _user) external view returns (bool);
    function currentTokenId() external view returns (uint256);
    function exists(uint256 id) external view returns (bool);
}