// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


interface ISpynNFT is IERC721 {

    struct Gego {
        uint256 id;
        uint256 grade;
        uint256 quality;
        uint256 amount;
        uint256 realAmount;
        uint256 resBaseId;
        uint256 ruleId;
        uint256 nftType;
        address author;
        address erc20;
        uint256 createdTime;
        uint256 blockNum;
        uint256 lockedDays;
    }
    
    function mint(address to, uint256 tokenId) external returns (bool) ;
    function burn(uint256 tokenId) external;
}