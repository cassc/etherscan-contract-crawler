// SPDX-License-Identifier: MIT

/************************************************************************************
 *       :::        :::::::::: :::    ::: ::::::::::: ::::::::   ::::::::  ::::    :::* 
 *     :+:        :+:        :+:    :+:     :+:    :+:    :+: :+:    :+: :+:+:   :+:  *
 *    +:+        +:+         +:+  +:+      +:+    +:+        +:+    +:+ :+:+:+  +:+   *
 *   +#+        +#++:++#     +#++:+       +#+    +#+        +#+    +:+ +#+ +:+ +#+    *
 *  +#+        +#+         +#+  +#+      +#+    +#+        +#+    +#+ +#+  +#+#+#     *
 * #+#        #+#        #+#    #+#     #+#    #+#    #+# #+#    #+# #+#   #+#+#      *
 *########## ########## ###    ### ########### ########   ########  ###    ####       *
 *************************************************************************************/


pragma solidity 0.8.6;

interface ILexicon {

    struct TokenDetails {
        uint256[] ids;
        uint8 length;
    }
    
    event Assembled(uint256 tokenId1, address by);
    event Dismantled(uint256 tokenId, address by);
    event Claimed(uint256 index, address account, string word);

    function claim(uint256 index, address account, string calldata word, bytes32[] calldata merkleProof)  external;
    function isWordClaimed(string calldata word) external returns (bool);
    function assembleMultiple(uint256[] calldata tokenIds) external;
    function dismantle(uint256 tokenId) payable external;
    function getNextWord()  view external returns (uint);
    function getWordsForToken(uint tokenId) external view returns (string[] memory returnArr);
    function mintFromAuction(address to, uint tokenId, string memory word) external;
}