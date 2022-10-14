// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ██████████████▌          ╟██           ████████████████          j██████████████  //
//  ██████████████▌          ╟███           ███████████████          j██████████████  //
//  ██████████████▌          ╟███▌           ██████████████          j██████████████  //
//  ██████████████▌          ╟████▌           █████████████          j██████████████  //
//  ██████████████▌          ╟█████▌          ╙████████████          j██████████████  //
//  ██████████████▌          ╟██████▄          ╙███████████          j██████████████  //
//  ██████████████▌          ╟███████           ╙██████████          j██████████████  //
//  ██████████████▌          ╟████████           ╟█████████          j██████████████  //
//  ██████████████▌          ╟█████████           █████████          j██████████████  //
//  ██████████████▌          ╟██████████           ████████          j██████████████  //
//  ██████████████▌          ╟██████████▌           ███████          j██████████████  //
//  ██████████████▌          ╟███████████▌           ██████          j██████████████  //
//  ██████████████▌          ╟████████████▄          ╙█████        ,████████████████  //
//  ██████████████▌          ╟█████████████           ╙████      ▄██████████████████  //
//  ██████████████▌          ╟██████████████           ╙███    ▄████████████████████  //
//  ██████████████▌          ╟███████████████           ╟██ ,███████████████████████  //
//  ██████████████▌                      ,████           ███████████████████████████  //
//  ██████████████▌                    ▄██████▌           ██████████████████████████  //
//  ██████████████▌                  ▄█████████▌           █████████████████████████  //
//  ██████████████▌               ,█████████████▄           ████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IResourceField is IERC165, IERC721Receiver, IERC1155Receiver {

    event Stake(address ownerAddress, address tokenAddress, uint256 tokenId, bytes data);
    event Unstake(address ownerAddress, address tokenAddress, uint256 tokenId);
    event ClaimResource(bytes32 nonce, address ownerAddress, uint256[] tokenIds, uint256[] amounts);
    
    /**
     * @dev Update the message signer
     * Can only be called by the contract owner.
     */
    function updateSigner(address signingAddress) external;

    /**
     * @dev Enable the contract
     * Can only be called by the contract owner.
     */
    function enable() external;

    /**
     * @dev Disable the contract
     * Can only be called by the contract owner or any admins.
     */
    function disable() external;

    /**
     * @dev Claim resources
     */
    function claimResources(uint256[] calldata tokenIds, uint256[] calldata amounts, bytes32 message, bytes calldata signature, bytes32 nonce) external;

    /**
     * @dev Burn resources held by the ResourceField.
     * Can only be called by the contract owner.
     */
    function burnResources(uint256[] calldata tokenIds, uint256[] calldata amounts) external;

    /**
     * @dev Stake multiple tokens.
     */
    function stakeMultiple(address[] calldata tokenAddresses, uint256[] calldata tokenIds, bytes calldata data) external;

    /**
     * @dev Unstake token
     * Can only unstake tokens that were staked by the requestor.
     */
    function unstake(address[] calldata tokenAddresses, uint256[] calldata tokenIds) external;

    /**
     * @dev Recover token.
     * Can only be used to recover a token that was sent in using transferFrom accidentally.
     * Can only be called by the contract owner.
     */
    function recover(address tokenAddress, uint256 tokenId, address recipient) external;

    /**
     * @dev Check if nonce has been used
     */
    function nonceUsed(bytes32 nonce) external view returns (bool);

}