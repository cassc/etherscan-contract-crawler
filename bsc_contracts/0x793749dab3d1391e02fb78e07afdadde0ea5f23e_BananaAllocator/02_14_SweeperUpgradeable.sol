// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

/*
 * ApeSwapFinance
 * App:             https://apeswap.finance
 * Medium:          https://ape-swap.medium.com
 * Twitter:         https://twitter.com/ape_swap
 * Telegram:        https://t.me/ape_swap
 * Announcements:   https://t.me/ape_swap_news
 * GitHub:          https://github.com/ApeSwapFinance
 */

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev Sweep any ERC20 and IERC721 token.
 * Sometimes people accidentally send tokens to a contract without any way to retrieve them.
 * This contract makes sure any erc20 tokens can be removed from the contract.
 */
contract SweeperUpgradeable is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct NFT {
        IERC721 nftaddress;
        uint256[] ids;
    }
    mapping(address => bool) public lockedTokens;
    bool public allowNativeSweep;

    event SweepWithdrawToken(address indexed receiver, IERC20Upgradeable indexed token, uint256 balance);
    event SweepWithdrawNFTs(address indexed receiver, NFT[] indexed nfts);
    event SweepWithdrawNative(address indexed receiver, uint256 balance);
    event RefusedNativeSweep();

    function initializeSweeper(address[] memory _lockedTokens, bool _allowNativeSweep) internal onlyInitializing {
        __Ownable_init();
        lockTokens(_lockedTokens);
        allowNativeSweep = _allowNativeSweep;
    }

    /**
     * @dev Transfers erc20 tokens to specified address
     * Only owner of contract can call this function
     */
    function sweepTokens(IERC20Upgradeable[] memory tokens, address to) external onlyOwner {
        NFT[] memory empty = new NFT[](0);
        _sweepTokensAndNFTs(tokens, empty, to);
    }

    /**
     * @dev Transfers NFT to specified address
     * Only owner of contract can call this function
     */
    function sweepNFTs(NFT[] memory nfts, address to) external onlyOwner {
        IERC20Upgradeable[] memory empty = new IERC20Upgradeable[](0);
        _sweepTokensAndNFTs(empty, nfts, to);
    }

    function sweepTokensAndNFTs(
        IERC20Upgradeable[] memory tokens,
        NFT[] memory nfts,
        address to
    ) external onlyOwner {
        _sweepTokensAndNFTs(tokens, nfts, to);
    }

    /**
     * @dev Transfers ERC20 and NFT to specified address
     * Only owner of contract can call this function
     */
    function _sweepTokensAndNFTs(
        IERC20Upgradeable[] memory tokens,
        NFT[] memory nfts,
        address to
    ) internal {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20Upgradeable token = tokens[i];
            require(!lockedTokens[address(token)], "Tokens can't be swept");
            uint256 balance = token.balanceOf(address(this));
            token.safeTransfer(to, balance);
            emit SweepWithdrawToken(to, token, balance);
        }

        for (uint256 i = 0; i < nfts.length; i++) {
            IERC721 nftaddress = nfts[i].nftaddress;
            require(!lockedTokens[address(nftaddress)], "Tokens can't be swept");
            uint256[] memory ids = nfts[i].ids;
            for (uint256 j = 0; j < ids.length; j++) {
                nftaddress.safeTransferFrom(address(this), to, ids[j]);
            }
        }
        emit SweepWithdrawNFTs(to, nfts);
    }

    /// @notice Sweep native coin
    /// @param _to address the native coins should be transferred to
    function sweepNative(address payable _to) external onlyOwner {
        require(allowNativeSweep, "Not allowed");
        uint256 balance = address(this).balance;
        _to.call{value: balance};
        emit SweepWithdrawNative(_to, balance);
    }

    /**
     * @dev Refuse native sweep.
     * Once refused can't be allowed again
     */
    function refuseNativeSweep() external onlyOwner {
        allowNativeSweep = false;
        emit RefusedNativeSweep();
    }

    /**
     * @dev Lock single token so it can't be transferred from the contract.
     * Once locked it can't be unlocked
     */
    function lockToken(address token) external onlyOwner {
        _lockToken(token);
    }

    /**
     * @dev Lock multiple tokens so they can't be transferred from the contract.
     * Once locked they can't be unlocked
     */
    function lockTokens(address[] memory tokens) public onlyOwner {
        _lockTokens(tokens);
    }

    /**
     * @dev Lock single token so it can't be transferred from the contract.
     * Once locked it can't be unlocked
     */
    function _lockToken(address token) internal {
        lockedTokens[token] = true;
    }

    /**
     * @dev Lock multiple tokens so they can't be transferred from the contract.
     * Once locked they can't be unlocked
     */
    function _lockTokens(address[] memory tokens) internal {
        for (uint256 i = 0; i < tokens.length; i++) {
            _lockToken(tokens[i]);
        }
    }
}