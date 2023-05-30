// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity ^0.8.9;

import "common8/LicenseRef-Blockwell-Smart-License.sol";
import "common8/relay/RelayBase.sol";
import "common8/ERC721.sol";
import "common8/Erc20.sol";
import "common8/ERC721TokenReceiver.sol";

/**
 * @dev Relay contract for verifying crosschain swaps.
 *
 * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
 */
contract SwapNftRelay is RelayBase, ERC721TokenReceiver {
    uint256 public swapNonce;

    event SwapToChain(
        uint256 toChainId,
        uint256 swapNonce,
        ERC721 tokenContract,
        address indexed from,
        address indexed to,
        bytes32 indexed swapId,
        uint256[] tokenIds
    );

    event SwapFromChain(
        ERC721 tokenContract,
        address indexed from,
        address indexed to,
        bytes32 indexed swapId,
        uint256 fromChainId,
        uint256[] tokenIds
    );

    error SwapIdMismatch();

    constructor(uint256 _swappersNeeded) RelayBase(_swappersNeeded) {
        name = "NFT SwapRelay";
        bwtype = SWAP_NFT_RELAY;
        bwver = 88;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    /**
     * @dev Initiates a swap to another chain. Transfers the tokens to this contract and emits an event
     *      indicating the request to swap.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function swapToChain(
        ERC721 tokenContract,
        uint256 toChainId,
        address to,
        uint256[] calldata tokenIds
    ) public {
        uint256 nonce = getSwapNonce();
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        bytes32 swapId = keccak256(
            abi.encodePacked(
                address(this),
                chainID,
                nonce,
                tokenContract,
                msg.sender,
                to,
                toChainId,
                tokenIds
            )
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenContract.transferFrom(msg.sender, address(this), tokenIds[i]);
        }

        emit SwapToChain(toChainId, nonce, tokenContract, msg.sender, to, swapId, tokenIds);
    }

    function swapFromChain(
        address relayContract,
        uint256 fromChainId,
        uint256 sourceSwapNonce,
        address sourceTokenContract,
        ERC721 tokenContract,
        address from,
        address to,
        bytes32 swapId,
        uint256[] calldata tokenIds
    ) public onlySwapper {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }
        bytes32 swapIdCheck = keccak256(
            abi.encodePacked(
                relayContract,
                fromChainId,
                sourceSwapNonce,
                sourceTokenContract,
                from,
                to,
                chainID,
                tokenIds
            )
        );
        if (swapId != swapIdCheck) {
            revert SwapIdMismatch();
        }

        if (shouldSwap(swapId, msg.sender)) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                tokenContract.transferFrom(address(this), to, tokenIds[i]);
            }
        }

        emit SwapFromChain(tokenContract, from, to, swapId, fromChainId, tokenIds);
    }

    function getSwapNonce() internal returns (uint256) {
        return ++swapNonce;
    }

    function withdraw() public onlyAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawTokens(Erc20 token) public onlyAdmin {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}