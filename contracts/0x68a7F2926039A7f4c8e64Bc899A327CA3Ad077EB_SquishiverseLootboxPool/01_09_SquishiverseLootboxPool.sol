// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ECDSA} from "solady/src/utils/ECDSA.sol";
import {ISquishiverseLootboxPool} from "./interfaces/ISquishiverseLootboxPool.sol";

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
 * @title SquishiverseLootboxPool
 * @custom:website www.squishiverse.com
 * @author Lozz (@lozzereth / www.allthingsweb3.com)
 * @notice This contract is intended to custody and issue ERC20/ERC721 tokens on a
 *         first-come, first-serve basis.
 */
contract SquishiverseLootboxPool is
    ISquishiverseLootboxPool,
    IERC721Receiver,
    Ownable
{
    using ECDSA for bytes32;

    /// @notice Oracle to sign the addresses
    address public oracleAddress;

    /// @notice Pausibility of claims
    bool public paused;

    /// @notice Claims nonces stored against addresses
    mapping(address => uint256) public claimNonce;

    /// @notice Toggle claiming to be cancellable
    bool public cancellable;

    constructor(address oracleAddress_) {
        oracleAddress = oracleAddress_;
    }

    /**
     * @notice Claim ERC721 tokens
     * @param recipient Recipient
     * @param nftAddress ERC721 compliant address
     * @param tokenIds Token IDs to claim
     * @param oldBlock Old block number
     * @param newBlock New block number
     * @param signature Oracle signature
     */
    function claimErc721(
        address recipient,
        IERC721 nftAddress,
        uint256[] calldata tokenIds,
        uint256 oldBlock,
        uint256 newBlock,
        bytes calldata signature
    ) external notPaused hasValidNonce(recipient, oldBlock, newBlock) {
        bytes32 data = keccak256(
            abi.encodePacked(
                ISquishiverseLootboxPool.claimErc721.selector,
                recipient,
                nftAddress,
                tokenIds.length,
                oldBlock,
                newBlock
            )
        );
        if (data.toEthSignedMessageHash().recover(signature) != oracleAddress) {
            revert InvalidClaimSignature();
        }
        claimNonce[recipient] = newBlock;
        for (uint256 id; id < tokenIds.length; id++) {
            IERC721(nftAddress).safeTransferFrom(
                address(this),
                recipient,
                tokenIds[id]
            );
        }
    }

    /**
     * @notice Claim ERC20 tokens
     * @param recipient Recipient
     * @param tokenAddress ERC20 compliant address
     * @param amount Amount of token to claim
     * @param oldBlock Old block number
     * @param newBlock New block number
     * @param signature Oracle signature
     */
    function claimErc20(
        address recipient,
        IERC20 tokenAddress,
        uint256 amount,
        uint256 oldBlock,
        uint256 newBlock,
        bytes calldata signature
    ) external notPaused hasValidNonce(recipient, oldBlock, newBlock) {
        bytes32 data = keccak256(
            abi.encodePacked(
                ISquishiverseLootboxPool.claimErc20.selector,
                recipient,
                tokenAddress,
                amount,
                oldBlock,
                newBlock
            )
        );
        if (data.toEthSignedMessageHash().recover(signature) != oracleAddress) {
            revert InvalidClaimSignature();
        }
        claimNonce[recipient] = newBlock;
        IERC20(tokenAddress).transfer(recipient, amount);
    }

    modifier hasValidNonce(
        address recipient,
        uint256 oldBlock,
        uint256 newBlock
    ) {
        if (
            oldBlock != claimNonce[recipient] ||
            oldBlock >= block.number ||
            newBlock <= oldBlock
        ) {
            revert InvalidClaimNonce();
        }
        _;
    }

    /**
     * @notice Cancels a claim for an address
     * @param address_ Recipient address
     * @param oldBlock Old block number
     * @param newBlock New block number
     */
    function cancelClaimAdmin(
        address address_,
        uint256 oldBlock,
        uint256 newBlock
    ) external onlyOwner hasValidNonce(address_, oldBlock, newBlock) {
        claimNonce[address_] = newBlock;
        emit CancelClaim(address_, oldBlock, newBlock);
    }

    /**
     * @dev Cancel claim as a user
     * @param oldBlock Old block number
     * @param newBlock New block number
     */
    function cancelClaim(uint256 oldBlock, uint256 newBlock)
        external
        cancelEnabled
        hasValidNonce(msg.sender, oldBlock, newBlock)
    {
        claimNonce[msg.sender] = newBlock;
        emit CancelClaim(msg.sender, oldBlock, newBlock);
    }

    modifier cancelEnabled() {
        if (!cancellable) {
            revert CancellingDisabled();
        }
        _;
    }

    /**
     * @notice Toggle cancellable state
     */
    function toggleCancellable() external onlyOwner {
        cancellable = !cancellable;
    }

    /**
     * @notice Set the oracle address to verify the data
     * @param address_ Address of the oracle
     */
    function setOracleAddress(address address_) external onlyOwner {
        oracleAddress = address_;
    }

    /**
     * @notice Toggle pause state
     */
    function togglePaused() external onlyOwner {
        paused = !paused;
    }

    modifier notPaused() {
        if (paused) revert ClaimPaused();
        _;
    }

    /**
     * @notice Allows contract owner to withdraw an ERC721 token from the contract
     * @param nftAddress ERC721 contract
     * @param tokenIds Token IDs to transfer
     */
    function withdrawErc721(IERC721 nftAddress, uint256[] calldata tokenIds)
        external
        onlyOwner
    {
        for (uint256 t; t < tokenIds.length; ++t) {
            nftAddress.transferFrom(address(this), msg.sender, tokenIds[t]);
        }
    }

    /**
     * @dev Allows contract owner to withdraw token from the contract
     * @param tokenAddress ERC20 contract
     * @param amount Amount of token to withdraw
     */
    function withdrawErc20(IERC20 tokenAddress, uint256 amount)
        external
        onlyOwner
    {
        IERC20(tokenAddress).transfer(msg.sender, amount);
    }

    /**
     * @dev Receive ERC721 tokens
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}