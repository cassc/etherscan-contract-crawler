// SPDX-License-Identifier: MIT
// creator: piotrostr.eth

pragma solidity 0.8.13;

// _______________/\/\/\/\/\__/\/\______/\/\__/\/\/\/\/\____/\/\______________
// ____________/\/\__________/\/\/\__/\/\/\__/\/\____/\/\__/\/\_______________
// _____________/\/\/\/\____/\/\/\/\/\/\/\__/\/\/\/\/\____/\/\________________
// __________________/\/\__/\/\__/\__/\/\__/\/\__________/\/\_________________
// _________/\/\/\/\/\____/\/\______/\/\__/\/\__________/\/\/\/\/\____________
//
// ________/\/\__/\/\____/\/\/\____/\/\__/\/\____/\/\/\/\____/\/\/\___________
// _______/\/\__/\/\__/\/\/\/\/\__/\/\/\/\____/\/\/\/\____/\/\/\/\/\__________
// ________/\/\/\____/\/\________/\/\______________/\/\__/\/\_________________
// _________/\________/\/\/\/\__/\/\________/\/\/\/\______/\/\/\/\____________

// @@@@@@@@@@@@@@@&@&&&@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@&@@&@&@&&&@&&&&&@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@&@&@@&&@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@@@@@@&@&@@@@&&&&&@&@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@@&@@@@&@@&@&&&@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@@@@@@@@@@&@&@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@@@@@@@@&&&@@&&&@@&&&&&&&@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*^^^^^^&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@****,*,*,,,.,,.,,,,.,,&&&&&&&&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@@@@@@@@@@@,****/((///**,,*,,,.,,...,.&&&&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@@@@@@@@/***/(####/(#####((/*,,,,*.,*..,#&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@@@,      ,                 (((**,,,,,.,,&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@(  *****.***/**(/*..**,           /**,,,.*,.&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@((.            *&       ,**/          ,,,,,.,&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@((            **           */,          ,,,,,,&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@*                       **,,       /,     ,&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@((                    ****,        ///*,...&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@/  *****     /      .,,*/*,        /////(///&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@/....,@//*(*///*,*,,,,,..........,/////*/(*/&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@@@@@&%#####((/(#%%###((((//////**//***//&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@@@@*%%#(#((#(####%%%####((////***//////&&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@@@@/%#((///*,*/#%#%###((((///***/&&&&&&&&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@@@@/#%%(((#######(((#((///****//&&&&&&&&&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@@@@&/%#(/(#####((/////******///&&&&&&&&&&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@@@@@/(%%%##(((//******////////*&&&&&&&&&&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@@@@@@@#//////////////((((((///&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%#########((((/*...&&&&&&&&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@@@@@@@%,&%%&&&%%%%######(((//*  .,&&&&&&&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@@@@@*,,.&&&&&&%%%%%%####(((//*.,,,,,&&&&&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@@,,**,.#%&&&&&%%%%%######((/*.,,,,,,&&&&&&&&&&&&&&&&&&&&&&

import "./SMPLverseBase.sol";

contract SMPLverse is SMPLverseBase {
    /**
     * @dev upon user's approving an upload it is added to this mapping
     */
    mapping(uint256 => bytes32) public uploads;

    event SMPLAssigned(
        address indexed user,
        uint256 tokenId,
        bytes32 userImageHash
    );

    /**
     * @dev Stores the copy of a hash of the user-uploaded image
     *
     * @param imageHash  sha256 32-byte hash of the image of the user
     *
     * Emits a {SMPLAssigned} event.
     */
    function uploadImage(bytes32 imageHash, uint256 tokenId)
        external
        callerIsUser
        whenNotPaused
    {
        TokenOwnership memory ownership = _ownershipOf(tokenId);
        require(ownership.addr == msg.sender, "token not owned by sender");

        require(
            uploads[tokenId] == bytes32(0),
            "image already uploaded for this tokenId"
        );

        uploads[tokenId] = imageHash;
        emit SMPLAssigned(msg.sender, tokenId, imageHash);
    }

    function _getAvailableTokensCount(address owner)
        internal
        view
        returns (uint256)
    {
        uint256[] memory tokensOfOwner = _tokensOfOwner(owner);
        uint256 count = 0;
        for (uint256 i = 0; i < tokensOfOwner.length; i++) {
            if (uploads[tokensOfOwner[i]] == bytes32(0)) {
                count++;
            }
        }
        return count;
    }

    function getAvailableTokensCount(address owner)
        external
        view
        returns (uint256)
    {
        return _getAvailableTokensCount(owner);
    }

    function getAvailableTokens(address owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory tokensOfOwner = _tokensOfOwner(owner);
        uint256 count = _getAvailableTokensCount(owner);

        uint256 index = 0;
        uint256[] memory availableTokens = new uint256[](count);
        for (uint256 i = 0; i < tokensOfOwner.length; i++) {
            if (uploads[tokensOfOwner[i]] == bytes32(0)) {
                availableTokens[index] = tokensOfOwner[i];
                index++;
            }
        }
        return availableTokens;
    }
}