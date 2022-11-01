// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IERC721TokenReceiver {
    /**
     * @notice Returns data which is used to understand weather contract has recived given token
     * @param _operator address of the operator
     * @param _from address of the token owner
     * @param _tokenId id of the token for which was transfered
     * @param _data additional data with no specific format
     * @return Returns `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
     */
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4);
}