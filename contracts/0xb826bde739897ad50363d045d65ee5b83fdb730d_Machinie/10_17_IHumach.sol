// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC721Enumerable.sol";

interface IHumach  is IERC721Enumerable{

    function machinieUpgrade(uint256 tokenId_ ) external returns (uint256) ;

    function machiniesUpgrade(uint256[] memory tokenIds_ ) external  ;

    function whiteListsMintHumach(uint8 amount_ ) external payable returns (uint256 [] memory) ;

    function publicMintHumach(uint8 amount_) external payable returns (uint256 [] memory) ;
    
    function breedHumach(uint256 tokenId_) external returns (uint256) ;

    function stakeHumach (uint256 [] memory tokenIds_) external ;

    function unStakeHumach (uint256 [] memory tokenIds_) external ;

    function calculateLevel(uint256 tokenId_) external view returns(uint256,uint256) ;

    function updateTokenName (uint256 tokenId_ ,string memory name_ ) external  ;

    function updateTokenDescription (uint256 tokenId_  ,string memory description_ ) external  ;
   
    function burnHumach(uint256 tokenId_) external ;

    function updateStakStatus(uint256 tokenId_,bool status_) external ;

    function isStaking (uint256 tokenId_) external view returns(bool);

    function getStakeTime (uint256 tokenId_) external view returns (uint256);

    function getMintFee(uint256 amount_) external view returns(uint256);
  
    function getTokenIdName(uint256 tokenId_) external view returns(string memory, string memory);

    function walletOfOwner(address _owner) external view returns(uint256[] memory) ;

}