// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @creator: Pak
/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/IAdminControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                           //
//  `7MMF'        .g8""8q.    .M"""bgd MMP""MM""YMM `7MM"""Mq.   .g8""8q. `7MM"""YMM MMP""MM""YMM  .M"""bgd  //
//    MM        .dP'    `YM. ,MI    "Y P'   MM   `7   MM   `MM..dP'    `YM. MM    `7 P'   MM   `7 ,MI    "Y  //
//    MM        dM'      `MM `MMb.          MM        MM   ,M9 dM'      `MM MM   d        MM      `MMb.      //
//    MM        MM        MM   `YMMNq.      MM        MMmmdM9  MM        MM MMmmMM        MM        `YMMNq.  //
//    MM      , MM.      ,MP .     `MM      MM        MM       MM.      ,MP MM   Y  ,     MM      .     `MM  //
//    MM     ,M `Mb.    ,dP' Mb     dM      MM        MM       `Mb.    ,dP' MM     ,M     MM      Mb     dM  //
//  .JMMmmmmMMM   `"bmmd"'   P"Ybmmd"     .JMML.    .JMML.       `"bmmd"' .JMMmmmmMMM   .JMML.    P"Ybmmd"   //
//                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

interface ILostPoets is IAdminControl, IERC721, IERC721Receiver, IERC1155Receiver {

    event Unveil(uint256 tokenId);
    event AddWords(uint256 indexed tokenId, uint8 count);
    event ShuffleWords(uint256 indexed tokenId);
    event WordsLocked(bool locked);
    event Activate();
    event Deactivate();

    /**
     * @dev Mint Origins
     */
    function mintOrigins(address[] calldata recipients, uint256[] calldata tokenIds) external;

    /**
     * @dev Enable token redemption
     */
    function enableRedemption(uint256 end) external;

    /**
     * @dev Disable token redemption
     */
    function disableRedemption() external;

    /**
     * @dev Set if words are locked
     */
    function lockWords(bool locked) external;

    /**
     * @dev Set the image base uri
     */
    function setPrefixURI(string calldata uri) external;

    /**
     * @dev Finalize poets
     */
    function finalizePoets(bool value, uint256[] memory tokenIds) external;

    /**
     * @dev Get word count for a token
     */
    function getWordCount(uint256 tokenId) external view returns(uint8);

    /**
     * @dev Update royalties
     */
    function updateRoyalties(address payable recipient, uint256 bps) external;

    /**
     * @dev Recover any 721's accidentally sent in.
     */
    function recoverERC721(address tokenAddress, uint256 tokenId, address destination) external;

    /**
     * @dev Update ERC1155 Burn Address
     */
    function updateERC1155BurnAddress(address erc1155BurnAddress) external;

    /**
     * @dev Update ERC721 Burn Address
     */
    function updateERC721BurnAddress(address erc721BurnAddress) external;

    /**
     * ROYALTY FUNCTIONS
     */
    function getRoyalties(uint256) external view returns (address payable[] memory recipients, uint256[] memory bps);
    function getFeeRecipients(uint256) external view returns (address payable[] memory recipients);
    function getFeeBps(uint256) external view returns (uint[] memory bps);
    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256);

}