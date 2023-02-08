//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ████████████████████████          ██████████
//                            ████████████████████████          ██████████
//                            ████████████████████████          ██████████
//                            ████████████████████████          ██████████
//                                                    ████████████████████
//                                                    ████████████████████
//                                                    ████████████████████
//                                                    ████████████████████
//
//
//  █████╗ ███╗   ██╗ ██████╗ ████████╗██╗  ██╗███████╗██████╗ ██████╗ ██╗      ██████╗  ██████╗██╗  ██╗
// ██╔══██╗████╗  ██║██╔═══██╗╚══██╔══╝██║  ██║██╔════╝██╔══██╗██╔══██╗██║     ██╔═══██╗██╔════╝██║ ██╔╝
// ███████║██╔██╗ ██║██║   ██║   ██║   ███████║█████╗  ██████╔╝██████╔╝██║     ██║   ██║██║     █████╔╝
// ██╔══██║██║╚██╗██║██║   ██║   ██║   ██╔══██║██╔══╝  ██╔══██╗██╔══██╗██║     ██║   ██║██║     ██╔═██╗
// ██║  ██║██║ ╚████║╚██████╔╝   ██║   ██║  ██║███████╗██║  ██║██████╔╝███████╗╚██████╔╝╚██████╗██║  ██╗
// ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
//
/**
 * @title IABDropManager
 * @author Anotherblock Technical Team
 * @notice ABDropManager Interface
 **/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IABDropManager {
    /**
     * @notice
     *  Drop Structure format
     *
     * @param dropId : drop unique identifier
     * @param sold : total number of sold tokens for this drop (accross all associated tokenId)
     * @param rightHolderFee : right Holder fee on each mint expressed in basis point
     * @param tokenInfo : Token Info struct defining the token information (see TokenInfo structure)
     * @param owner : right holder address
     * @param nft :  NFT contract address
     */
    struct Drop {
        uint256 dropId;
        uint256 sold;
        uint256 rightHolderFee;
        TokenInfo tokenInfo;
        address owner;
        address nft;
    }

    /**
     * @notice
     *  TokenInfo Structure format
     *
     * @param price : initial price in ETH(?) of 1 token
     * @param supply : total number of tokens for this drop (accross all associated tokenId)
     * @param royaltySharePerToken : total percentage of royalty evenly distributed among tokens holders
     */
    struct TokenInfo {
        uint256 price;
        uint256 supply;
        uint256 royaltySharePerToken;
    }

    /**
     * @notice
     *  Returns Anotherblock Treasury address
     *
     */
    function treasury() external view returns (address);

    /**
     * @notice
     *  Returns the drop `_dropId`
     *
     * @param _dropId : drop identifier
     */
    function drops(uint256 _dropId) external view returns (Drop memory);

    /**
     * @notice
     *  Create a Drop
     *  Only the contract owner can perform this operation
     *
     * @param _owner : right holder address
     * @param _nft : NFT contract address
     * @param _price : initial price in ETH of 1 NFT
     * @param _supply : total number of NFT for this drop
     * @param _royaltySharePerToken : total percentage of royalty evenly distributed among NFT holders (to be divided by 1e6)
     * @param _rightHolderFee : right Holder fee on each mint (to be divided by 1e6)
     * @param _baseFlow : base amount of AB Token to be streamed per seconds
     */
    function create(
        address _owner,
        address _nft,
        uint256 _price,
        uint256 _supply,
        uint256 _royaltySharePerToken,
        uint256 _rightHolderFee,
        int96 _baseFlow
    ) external;

    function updateDropCounter(uint256 _dropId, uint256 _quantity) external;

    /**
     * @notice
     *  Relay NFT transfer data to L2 contracts
     *
     * @param _from previous holder address
     * @param _to new holder address
     * @param _dropId drop ID associated to the token transferred
     * @param _quantity amount of token transferred
     */
    function updateOnTransfer(
        address _from,
        address _to,
        uint256 _dropId,
        uint256 _quantity
    ) external;

    /**
     * @notice
     *  Update the treasury address
     *  Only the contract owner can perform this operation
     *
     * @param _newTreasury : new treasury address
     */
    function setTreasury(address _newTreasury) external;

    /**
     * @notice
     *  Update the Drop `_dropId` drop information
     *  Only the contract owner can perform this operation
     *
     * @param _dropId :  drop identifier of the drop to be updated
     * @param _rightHolderFee : fees paid to right holder
     * @param _owner : right holder address
     */
    function setRightHolderInfo(
        uint256 _dropId,
        uint256 _rightHolderFee,
        address _owner
    ) external;

    /**
     * @notice
     *  Update the Drop `_dropId` token information
     *  Only the contract owner can perform this operation
     *
     *  Return true if `tokenCount` and `supply` are updated, false otherwise
     *
     * @param _dropId :  drop identifier of the drop to be updated
     * @param _tokenInfo : array containing the new informations to be updated
     */
    function setTokenInfo(
        uint256 _dropId,
        uint256[3] calldata _tokenInfo
    ) external returns (bool);
}