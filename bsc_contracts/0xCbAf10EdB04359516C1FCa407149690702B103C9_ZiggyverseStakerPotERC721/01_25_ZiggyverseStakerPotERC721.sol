// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ZiggyverseStakerPotBase.sol";
import "./erc721/ERC721Staked.sol";
import "./utils/EmergencyWithdrawable.sol";
import "./IZiggyverseStakerPotERC721Listener.sol";

/**
 * @title Ziggyverse Staker Pot - ERC721 version
 *
 * The staker pot allows holders of Ziggyverse NFTs to stake their tokens 
 * for a chance to win prizes.
 * When staking, users receive a staked version of their staked NFT (this contract).
 * Chances to win in the staker pot are tracked in the {ticket} ERC20 token.
 */
contract ZiggyverseStakerPotERC721 is
    ZiggyverseStakerPotBase,
    ERC721Staked,
    EmergencyWithdrawable
{
    using ERC165Checker for address;

    IERC721Enumerable public token;
    IZiggyverseStakerPotERC721Listener public stakingListener;


    event StakingListenerSet(address indexed stakingListener);

    constructor(
        string memory _name,
        string memory _symbol,
        IERC721Enumerable _token
    ) 
        ERC721Staked(_token) 
        ERC721(_name, _symbol)
    {
        token = _token;
        _pause();
    }


    // --- User methods ---

    /**
     * @notice Stake `tokenIds`
     * Staked ERC721 tokens will be send to this contract.
     * Mints corresponding ERC721 staking tokens to senders.
     * Mints ticket ERC20 to sender, according to weight of staked tokens.
     * Expects this contract is approved to transfer Staked tokens for the sender.
     * Contract needs to not be {paused}.
     */
    function stake(uint256[] memory tokenIds) external nonReentrant whenNotPaused {
        address user = _msgSender();
        _stakeTokens(user, user, tokenIds);
    }

    /**
     * @notice Unstake `tokenIds`
     * Staked ERC721 tokens will be send back from this contract to the sender.
     * Burns the corresponding Staking ERC721 tokens from sender.
     * Burns ERC20 tickets from sender, according to the weight of the unstaked tokens.
     * Contract needs to not be {paused}.
     */
    function unstake(uint256[] memory tokenIds)
        external
        nonReentrant
        whenNotPaused
    {
        address user = _msgSender();
        _unstakeTokens(user, user, tokenIds);
    }


    // --- Admin methods ---

    /**
     * @notice Stake `tokenIds` for `to`, transfering tokens from `from`, see {stake}.
     * @dev Callable by owner, used for migration purposes to safe the user gas costs.
     */
    function stakeFor(
        address from,
        address to,
        uint256[] memory tokenIds
    ) external onlyOwner nonReentrant {
        require(from == address(this) || from == to, "Invalid 'to' address");
        _stakeTokens(from, to, tokenIds);
    }

    /**
     * @notice Unstake `tokenIds` for `user`, see {unstake}.
     * @dev Callable by owner, used for migration purposes to safe the user gas costs.
     */
    function unstakeFor(
        address user,
        uint256[] memory tokenIds
    ) external onlyOwner nonReentrant {
        _unstakeTokens(user, user, tokenIds);
    }

    /**
     * @notice Sets the staking listener to act on staking and unstaking.
     * @dev Callable by owner
     */
    function setStakingListener(
        IZiggyverseStakerPotERC721Listener _stakingListener
    ) external onlyOwner {
        require(
            address(_stakingListener).supportsInterface(
                type(IZiggyverseStakerPotERC721Listener).interfaceId
            ),
            "stakingListener-invalid"
        );
        stakingListener = _stakingListener;

        emit StakingListenerSet(address(_stakingListener));
    }


    /**
     * @notice Pauses staking and unstaking
     * @dev Callable by owner, pausing the contract is used to complete the setup and for migration purposes.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Resume normal operations
     * @dev Callable by owner
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // -- Internal methods ---

    /**
     * @dev Stake `tokenIds`
     * Staked ERC721 tokens will be send to this contract from `from`.
     * Mints corresponding Staking ERC721 tokens to `to`.
     * Mints ERC20 tickets to `to`, according to weight of staked tokens.
     * Expects this contract is approved to transfer Staked ERC721 tokens for `from`.
     */
    function _stakeTokens(
        address from,
        address to,
        uint256[] memory tokenIds
    ) internal {
        require(tokenIds.length > 0, "Cannot stake 0 tokens");

        uint256 weight;
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            weight += _stakeToken(from, to, tokenIds[i]);
        }

        _enterPot(to, weight);

        if (address(stakingListener) != address(0)) {
            stakingListener.afterTokenStake(from, to, tokenIds);
        }
    }

    /**
     * @dev Unstake `tokenIds`
     * Staked ERC721 tokens will be send back from this contract to `to`.
     * Burns the corresponding Staking ERC721 tokens from `from`.
     * Burns ERC20 tickets from `from` according to the weight of the unstaked tokens.
     */
    function _unstakeTokens(
        address from,
        address to,
        uint256[] memory tokenIds
    ) internal {
        require(tokenIds.length > 0, "Cannot unstake 0 tokens");
        uint256 weight;
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            weight += _unstakeToken(from, to, tokenIds[i]);
        }

        _leavePot(from, weight);

        if (address(stakingListener) != address(0)) {
            stakingListener.afterTokenUnstake(
                from,
                to,
                tokenIds
            );
        }
    }

    /**
     * @dev Stake `tokenId` and return its weights.
     * Staking transfers the token to this contract and mints the corresponding staking-receipt token.
     * @param from the address to transfer the staked token from
     * @param to the address to mint the staking-receipt token to
     * @param tokenId the tokenId to stake
     */
    function _stakeToken(
        address from,
        address to,
        uint256 tokenId
    ) internal returns (uint256) {
        super._stake(from, to, tokenId);
        return _weightOfToken(tokenId);
    }

    /**
     * @dev Untake `tokenId` and return its weights.
     * Unstaking transfers the token back to the user and burns the corresponding staking-receipt token.
     * @param from the address to burn the staking-receipt token from
     * @param to the address to transfer the staked token to
     * @param tokenId the tokenId to stake
     */
    function _unstakeToken(
        address from,
        address to,
        uint256 tokenId
    ) internal returns (uint256) {
        _unstake(from, to, tokenId);
        return _weightOfToken(tokenId);
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}
     * Only allow burning and minting of this token, no transfers.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        require(
            from == address(0) || to == address(0),
            "Staking Receipt not transferable"
        );
    }

    /**
     * @dev Weight per tokenId, allows to make rare NFTs get more tickets on staking.
     */
    function _weightOfToken(uint256) internal pure returns (uint256) {
        return 1;
    }
}