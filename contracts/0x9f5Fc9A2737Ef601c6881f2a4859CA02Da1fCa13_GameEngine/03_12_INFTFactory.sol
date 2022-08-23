// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;
import "./IERC721.sol";
interface INFTFactory is IERC721{

    function restrictedChangeNft(uint tokenID, uint8 nftType, uint8 level) external;
    function tokenOwnerCall(uint tokenId) external view  returns (address);
    function burnNFT(uint tokenId) external ;
    function tokenOwnerSetter(uint tokenId, address _owner) external;
    // function setTimeStamp(uint tokenId) external;
    // function actionTimestamp(uint tokenId) external returns(uint);

}