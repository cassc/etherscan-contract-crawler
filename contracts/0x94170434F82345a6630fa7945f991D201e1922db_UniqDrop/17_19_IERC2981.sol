// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

/**
 * @dev Implementation of royalties for 721s
 *
 */
interface IERC2981 {
    /*
     * ERC165 bytes to add to interface array - set in parent contract implementing this standard
     *
     * bytes4(keccak256('royaltyInfo(uint256)')) == 0xcef6d368
     * bytes4(keccak256('receivedRoyalties(address,address,uint256,address,uint256)')) == 0x8589ff45
     * bytes4(0xcef6d368) ^ bytes4(0x8589ff45) == 0x4b7f2c2d
     * bytes4 private constant _INTERFACE_ID_ERC721ROYALTIES = 0x4b7f2c2d;
     * _registerInterface(_INTERFACE_ID_ERC721ROYALTIES);
     */
    /**

    /**
     *      @notice Called to return both the creator's address and the royalty percentage -
     *              this would be the main function called by marketplaces unless they specifically
     *              need to adjust the royaltyAmount
     *      @notice Percentage is calculated as a fixed point with a scaling factor of 100000,
     *              such that 100% would be the value 10000000, as 10000000/100000 = 100.
     *              1% would be the value 100000, as 100000/100000 = 1
     */
    function royaltyInfo(uint256 _tokenId)
        external
        returns (address receiver, uint256 amount);

    /**
     *      @notice Called when royalty is transferred to the receiver. We wrap emitting
     *              the event as we want the NFT contract itself to contain the event.
     */
    function receivedRoyalties(
        address _royaltyRecipient,
        address _buyer,
        uint256 _tokenId,
        address _tokenPaid,
        uint256 _amount
    ) external;

    event ReceivedRoyalties(
        address indexed _royaltyRecipient,
        address indexed _buyer,
        uint256 indexed _tokenId,
        address _tokenPaid,
        uint256 _amount
    );
}