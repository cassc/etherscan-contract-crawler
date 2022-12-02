// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 * ApeSwapFinance
 * App:             https://apeswap.finance
 * Medium:          https://ape-swap.medium.com
 * Twitter:         https://twitter.com/ape_swap
 * Telegram:        https://t.me/ape_swap
 * Announcements:   https://t.me/ape_swap_news
 * GitHub:          https://github.com/ApeSwapFinance
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev Sweep any ERC20 token.
 * Sometimes people accidentally send tokens to a contract without any way to retrieve them.
 * This contract makes sure any erc20 tokens can be removed from the contract.
 */
contract Sweeper is Ownable {
    struct NFT {
        IERC721 nftaddress;
        uint256[] ids;
    }
    mapping(address => bool) public lockedTokens;
    bool public allowNativeSweep;

    event SweepWithdrawToken(address indexed receiver, IERC20 indexed token, uint256 balance);

    event SweepWithdrawNFTs(address indexed receiver, NFT[] indexed nfts);

    event SweepWithdrawNative(address indexed receiver, uint256 balance);

    constructor(address[] memory _lockedTokens, bool _allowNativeSweep) {
        lockTokens(_lockedTokens);
        allowNativeSweep = _allowNativeSweep;
    }

    /**
     * @dev Transfers erc20 tokens to owner
     * Only owner of contract can call this function
     */
    function sweepTokens(IERC20[] memory tokens, address to) external onlyOwner {
        NFT[] memory empty;
        sweepTokensAndNFTs(tokens, empty, to);
    }

    /**
     * @dev Transfers NFT to owner
     * Only owner of contract can call this function
     */
    function sweepNFTs(NFT[] memory nfts, address to) external onlyOwner {
        IERC20[] memory empty;
        sweepTokensAndNFTs(empty, nfts, to);
    }

    /**
     * @dev Transfers ERC20 and NFT to owner
     * Only owner of contract can call this function
     */
    function sweepTokensAndNFTs(
        IERC20[] memory tokens,
        NFT[] memory nfts,
        address to
    ) public onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = tokens[i];
            require(!lockedTokens[address(token)], "Tokens can't be sweeped");
            uint256 balance = token.balanceOf(address(this));
            token.transfer(to, balance);
            emit SweepWithdrawToken(to, token, balance);
        }

        for (uint256 i = 0; i < nfts.length; i++) {
            IERC721 nftaddress = nfts[i].nftaddress;
            require(!lockedTokens[address(nftaddress)], "Tokens can't be sweeped");
            uint256[] memory ids = nfts[i].ids;
            for (uint256 j = 0; j < ids.length; j++) {
                nftaddress.safeTransferFrom(address(this), to, ids[j]);
            }
        }
        emit SweepWithdrawNFTs(to, nfts);
    }

    /// @notice Sweep native coin
    /// @param _to address the native coins should be transferred to
    function sweepNative(address payable _to) public onlyOwner {
        require(allowNativeSweep, "Not allowed");
        uint256 balance = address(this).balance;
        _to.transfer(balance);
        emit SweepWithdrawNative(_to, balance);
    }

    /**
     * @dev Refuse native sweep.
     * Once refused can't be allowed again
     */
    function refuseNativeSweep() public onlyOwner {
        allowNativeSweep = false;
    }

    /**
     * @dev Lock single token so they can't be transferred from the contract.
     * Once locked it can't be unlocked
     */
    function lockToken(address token) public onlyOwner {
        lockedTokens[token] = true;
    }

    /**
     * @dev Lock multiple tokens so they can't be transferred from the contract.
     * Once locked it can't be unlocked
     */
    function lockTokens(address[] memory tokens) public onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            lockToken(tokens[i]);
        }
    }
}