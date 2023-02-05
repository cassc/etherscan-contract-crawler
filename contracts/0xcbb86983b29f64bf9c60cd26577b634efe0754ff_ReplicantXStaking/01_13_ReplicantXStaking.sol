// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "./IFrameNFT.sol";

/*
 * This contract allows users to stake and unstake ERC721 tokens,
 * and mint a FrameNFT for each staked token while unstaking
 */

contract ReplicantXStaking is Ownable, ERC721Holder {
    // Event emitted when a FrameNFT is minted,
    // used for tracking relationship of frameNFT and tokenId of voter
    event FrameNFTMinted(
        uint256 frameNFTId,
        address voterContract,
        uint256 voterTokenId,
        address voterWalletAddress,
        address frameNFTAddress
    );

    // Mapping from token address to staking/unstaking enabled status
    mapping(address => bool) public isStakingEnabledForTokenContractAddress;
    mapping(address => bool) public isUnstakingEnabledForTokenContractAddress;

    // Mapping owner address to token address to staked token count
    mapping(address => mapping(address => uint256)) private _stakedCount;
    // Mapping from owner to token address to index of staked token IDs to tokenIDs
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        private _stakedTokens;
    // Mapping from token address to token ID to index of the staked tokens list
    mapping(address => mapping(uint256 => uint256)) private _stakedTokensIndex;
    // Mapping from owner to token type to token IDs which are staked
    mapping(address => mapping(address => mapping(uint256 => bool)))
        private _userAddressToStakedTokenIdMap;

    // Mapping from token address to should enable frame minting status when unstaking
    mapping(address => bool) public shouldMintFrameWhenUnstakingForToken;
    // frameNFT contract address to mint frameNFT
    IFrameNFT public frameNFTContract;

    /**
     * @dev The contract address of the Frame NFT to be minted when unstaking
     * @param add address representing the contract address of the Frame NFT
     * contract address must conform to IFrameNFT interface to be able to mint
     */
    function setFrameNFTContract(address add) external onlyOwner {
        frameNFTContract = IFrameNFT(add);
    }

    /**
     * @dev Enable/disable minting of Frame NFT when unstaking for specific staked token
     * @param enable status of minting frame NFT enabled/disabled
     * @param tokenAddress address representing the contract address of staked NFT
     */
    function toggleMintFrameEnabledWhenUnstakingToken(
        bool enable,
        address tokenAddress
    ) external onlyOwner {
        shouldMintFrameWhenUnstakingForToken[tokenAddress] = enable;
    }

    /**
     * @dev Enable/disable staking for token
     * @param enabled status of staking enabled/disabled for token
     * @param tokenAddress address representing the contract address of token
     */
    function setStakingEnabledForTokenContractAddress(
        bool enabled,
        address tokenAddress
    ) external onlyOwner {
        isStakingEnabledForTokenContractAddress[tokenAddress] = enabled;
    }

    /**
     * @dev Enable/disable unstaking for token
     * @param enabled status of unstaking enabled/disabled for token
     * @param tokenAddress address representing the contract address of token
     */
    function setUnstakingEnabledForTokenContractAddress(
        bool enabled,
        address tokenAddress
    ) external onlyOwner {
        isUnstakingEnabledForTokenContractAddress[tokenAddress] = enabled;
    }

    /**
     * @dev Stake tokens from user from different contracts that must each be enabled in setStakingEnabledForTokenContractAddress.
     * Token must be of type ERC721
     * @param tokenContractAddresses token contract addresses of tokens intended for staking
     * @param tokenIdsForEachContract tokenIds of each contract intended for staking
     */
    function stakeTokens(
        address[] calldata tokenContractAddresses,
        uint256[][] calldata tokenIdsForEachContract
    ) public {
        require(
            tokenContractAddresses.length > 0,
            "Cannot stake 0 tokenContractAddresses"
        );
        require(
            tokenIdsForEachContract.length > 0,
            "Cannot stake 0 tokenIdsForEachContract"
        );
        require(
            tokenIdsForEachContract.length == tokenContractAddresses.length,
            "tokenContractAddresses array count different than tokenIdsForEachContract count"
        );
        for (uint256 i = 0; i < tokenContractAddresses.length; i++) {
            address tokenAddress = tokenContractAddresses[i];
            require(
                isStakingEnabledForTokenContractAddress[tokenAddress],
                "Staking not enabled for token"
            );
            uint256[] memory tokenIds = tokenIdsForEachContract[i];
            require(
                tokenIds.length > 0,
                "TokenID array cannot be empty for token"
            );
            for (uint256 j = 0; j < tokenIds.length; j++) {
                uint256 tokenId = tokenIds[j];
                require(
                    ERC721(tokenAddress).ownerOf(tokenId) == msg.sender,
                    "Not owner of tokenId"
                );
                ERC721(tokenAddress).safeTransferFrom(
                    msg.sender,
                    address(this),
                    tokenId
                );
                _addTokenToStakedEnumeration(msg.sender, tokenId, tokenAddress);
            }
        }
    }

    /**
     * @dev Unstake tokens for user from different token contracts
     * Unstaking for that token address must be enabled by calling setUnstakingEnabledForTokenContractAddress
     * TokenIds must be previously staked by the same user for the same token address

     * FrameNFTs can be minted while unstaking if enabled
     * must have toggleMintFrameEnabledWhenUnstakingToken enabled for specific token address
     * must have contract address set for frameNFTContract
     * frameNFTContract must allow this contract address to mint frameNFT in its implementation
     * @param tokenContractAddresses token contract addresses of tokens for unstaking
     * @param tokenIdsForEachContract tokenIds for each contract for unstaking 
     */
    function unstakeTokens(
        address[] calldata tokenContractAddresses,
        uint256[][] calldata tokenIdsForEachContract
    ) public {
        require(
            tokenContractAddresses.length > 0,
            "Cannot unstake 0 tokenContractAddresses"
        );
        require(
            tokenIdsForEachContract.length > 0,
            "Cannot unstake 0 tokenIdsForEachContract"
        );
        require(
            tokenIdsForEachContract.length == tokenContractAddresses.length,
            "tokenContractAddresses array count different than tokenIdsForEachContract count"
        );
        for (uint256 i = 0; i < tokenContractAddresses.length; i++) {
            address tokenAddress = tokenContractAddresses[i];
            require(
                _stakedCount[msg.sender][tokenAddress] > 0,
                "Have nothing staked"
            );
            require(
                isUnstakingEnabledForTokenContractAddress[tokenAddress],
                "Unstaking not enabled for token"
            );
            uint256[] memory tokenIds = tokenIdsForEachContract[i];
            require(
                tokenIds.length > 0,
                "TokenID array cannot be empty for token"
            );
            for (uint256 j = 0; j < tokenIds.length; j++) {
                // for each tokenID in token type
                uint256 tokenId = tokenIds[j];
                require(
                    _userAddressToStakedTokenIdMap[msg.sender][tokenAddress][
                        tokenId
                    ],
                    "Not staked by user"
                );

                ERC721(tokenAddress).safeTransferFrom(
                    address(this),
                    msg.sender,
                    tokenId
                );
                _removeTokenFromStakedEnumeration(
                    msg.sender,
                    tokenId,
                    tokenAddress
                );
                if (shouldMintFrameWhenUnstakingForToken[tokenAddress]) {
                    uint256 nextTokenId = frameNFTContract.nextTokenId();
                    frameNFTContract.mint(msg.sender);
                    emit FrameNFTMinted(
                        nextTokenId,
                        tokenAddress,
                        tokenId,
                        msg.sender,
                        address(frameNFTContract)
                    );
                }
            }
        }
    }

    /**
     * @dev The number of staked NFTs that have been staked by the given address with token address
     * @param staker address representing the staker
     * @param tokenAddress address representing the token address staked
     */
    function numStakedTokens(address staker, address tokenAddress)
        public
        view
        returns (uint256)
    {
        return _stakedCount[staker][tokenAddress];
    }

    /**
     * @dev Used to access each token that has been staked by the given address.
     * For example, we can get the `numStakedTokens` for the given address, and then
     * iterate through each index (e.g. 0, 1, 2) to get the IDs of each staked token.
     * @param staker address representing the staker
     * @param index index of the token (e.g. first staked token will have index of 0)
     * @param tokenAddress address representing the token address staked
     */
    function tokenOfStakerByIndex(
        address staker,
        uint256 index,
        address tokenAddress
    ) public view returns (uint256) {
        return _stakedTokens[staker][tokenAddress][index];
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param staker address representing the staker of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     * @param tokenAddress address representing the token address staked
     */
    function _addTokenToStakedEnumeration(
        address staker,
        uint256 tokenId,
        address tokenAddress
    ) private {
        uint256 length = _stakedCount[staker][tokenAddress];

        _stakedTokens[staker][tokenAddress][length] = tokenId;
        _stakedTokensIndex[tokenAddress][tokenId] = length;
        _userAddressToStakedTokenIdMap[staker][tokenAddress][tokenId] = true;
        _stakedCount[staker][tokenAddress] += 1;
    }

    /**
     * @dev Private function to remove a token from this contract's staked-tracking data structures.
     * This has O(1) time complexity, but alters the order of the _stakedTokens array.
     * @param staker address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     * @param tokenAddress address representing the token address for token removed
     */
    function _removeTokenFromStakedEnumeration(
        address staker,
        uint256 tokenId,
        address tokenAddress
    ) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).
        uint256 lastTokenIndex = _stakedCount[staker][tokenAddress] - 1;
        uint256 tokenIndex = _stakedTokensIndex[tokenAddress][tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _stakedTokens[staker][tokenAddress][
                lastTokenIndex
            ];

            _stakedTokens[staker][tokenAddress][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _stakedTokensIndex[tokenAddress][lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _stakedTokensIndex[tokenAddress][tokenId];
        delete _stakedTokens[staker][tokenAddress][lastTokenIndex];

        _userAddressToStakedTokenIdMap[staker][tokenAddress][tokenId] = false;
        _stakedCount[staker][tokenAddress] -= 1;
    }
}