// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * MMMMMW0dxxxdkXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMM0cdKNNKloXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMKolk00kloXMWNK0KKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMXkxxddkXWKdoddxxxxkOKXXXNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMWWMMMXllO000KKKOkxxxxkkkkkkkkkO0KNWMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMKccO000000KKXNNNNNNNXXXK0OkkkkkkOKNMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMN0xocck0000000000KKKKXXXNNNNWWWWNX0kkkkOKWMMMMMMMMMMMMMMMMM
 * MMMMMMMMWXkoodkOOO00000000000000000000KKXXNNWWWMWXOxxk0NMMMMMMMMMMMMMM
 * MMMMMMWKxlokO000000000000000000000000000000KXWMMMMMMN0kxkKWMMMMMMMMMMM
 * MMMMMXxlok0000000000000000000000000000000000KNMMMMMMMMMN0xxONMMMMMMMMM
 * MMMW0ook0000000000000000000000000000000000000XWMMMMMMMMMMWKxdONMMMMMMM
 * MMWkldO000000000000000000000000000000000000000KXNWMMWNNWMMMWKxd0WMMMMM
 * MNxcx00000000000000000000000000000000000000000000KXOc,':ONWWMW0dkNMMMM
 * Wkcd0000000000000000Oo;,:dO00000000000000000000000d.    .oXWWMMXxdKMMM
 * KloO000000000000000k;    .:k000000000000000000000O:    ;'.dNNWWMNxoKMM
 * dck000000000000000Oc    '..lO00000000000000000000O:       ;KNNWWMNxoXM
 * lo0000000000000000x'   .:;.;k00000000000000000000Ol.      'ONNNWWMXdxN
 * cd0000000000000000x'       ,k000000000000000000000x'      .xNNNNWWM0o0
 * cd0000000000000000x'       ;O000000000000000000000Oo.     ;kXNNNNWMNdd
 * cd0000000000000000k;      .lO0000000000000000000000Od:'.,ck0KXNNNWWWko
 * olO0000000000000000d'     'x000000000000000O0000000000Okxk000XNNNNWMOl
 * kcx00000000000000000x:...;xOOxkO00000OOxolc::cclooodolccok000KNNNNWMOl
 * XolO00000000000000000OkkkO00kollccclcc:;,,;;;;,,,,,'.,lk00000KNNNNWMko
 * M0loO0000000000000000000000000Oko:,''',,,,,,,,,,,;;:okO000000KNNNNWWxd
 * MWOloO000000000000000000000000000OkkxdddddddoodddxkO000000000XNNNWMKoO
 * MMW0lok00000000000000000000000000000000000000000000000000000KXNNWWNddN
 * MMMMXdlxO000000000000000000000000000000000000000000000000000XNNNWNxdXM
 * MMMMMWOolxO000000000000000000000000000000000000000000000000KNNNWKxdKMM
 * MMMMMMMNOoldO000000000000000000000000000000000000000000000KNNNXkdkNMMM
 * MMMMMMMMMN0dooxO00000000000000000000000000000000000000000KXKkxdkXWMMMM
 * MMMMMMMMMMMWXOxdooxkO0000000000000000000000000000000Okxxdxxxk0NMMMMMMM
 * MMMMMMMMMMMMMMMNKOxdddoooddxxxxkkkkkkkxxxxxddddoooodddxkOKNWMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMWNKOxdollccccccccccccccccllodxk0KNWMMMMMMMMMMMMMMMM
 *
 * @title ISquishiverseLootboxPool
 * @custom:website www.squishiverse.com
 * @author Lozz (@lozzereth / www.allthingsweb3.com)
 * @notice SquishiverseLootboxPool Interface
 */
interface ISquishiverseLootboxPool {
    /// @notice Claiming is paused
    error ClaimPaused();

    /// @notice Signature claim is invalid
    error InvalidClaimSignature();

    /// @notice The nonce specified is invalid
    error InvalidClaimNonce();

    /// @notice Cancel functionality is disabled
    error CancellingDisabled();

    /// @notice Cancel claim event
    event CancelClaim(address from, uint256 oldBlock, uint256 newBlock);

    /**
     * @dev Claim ERC721 tokens
     */
    function claimErc721(
        address recipient,
        IERC721 nftAddress,
        uint256[] calldata tokenIds,
        uint256 oldBlock,
        uint256 newBlock,
        bytes calldata signature
    ) external;

    /**
     * @dev Claim an ERC20 amount
     */
    function claimErc20(
        address recipient,
        IERC20 tokenAddress,
        uint256 amount,
        uint256 oldBlock,
        uint256 newBlock,
        bytes calldata signature
    ) external;

    /**
     * @notice Set the oracle address to verify the data
     * @param address_ Address of the oracle
     */
    function setOracleAddress(address address_) external;

    /**
     * @notice Allows contract owner to withdraw an ERC721 token from the contract
     * @param nftAddress ERC721 contract
     * @param tokenIds Token IDs to transfer
     */
    function withdrawErc721(IERC721 nftAddress, uint256[] calldata tokenIds)
        external;

    /**
     * @dev Allows contract owner to withdraw token from the contract
     * @param tokenAddress ERC20 contract
     * @param amount Amount of token to withdraw
     */
    function withdrawErc20(IERC20 tokenAddress, uint256 amount) external;
}