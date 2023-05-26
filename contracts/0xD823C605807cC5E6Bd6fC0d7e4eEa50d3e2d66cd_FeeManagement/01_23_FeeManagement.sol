// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './TokenSplitter.sol';
import './FeeSharingSetter.sol';
import './IWETH.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';

contract FeeManagement is AccessControl, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH;

    bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR_ROLE');

    TokenSplitter public immutable tokenSplitter;
    FeeSharingSetter public immutable feeSetter;
    IWETH public immutable weth;

    constructor(
        TokenSplitter tokenSplitter_,
        FeeSharingSetter feeSetter_,
        IWETH weth_,
        address operator_,
        address admin_
    ) {
        tokenSplitter = tokenSplitter_;
        feeSetter = feeSetter_;
        weth = weth_;

        if (admin_ == address(0)) {
            admin_ = msg.sender;
        }
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(OPERATOR_ROLE, admin_);

        if (operator_ != address(0)) {
            _grantRole(OPERATOR_ROLE, operator_);
        }
    }

    receive() external payable {}

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    // withdraw tokens
    function withdraw(address to, IERC20[] calldata tokens)
        external
        nonReentrant
        whenNotPaused
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(to != address(0), 'Withdraw: address(0) cannot be recipient');
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 currency = tokens[i];
            if (address(currency) == address(0)) {
                uint256 balance = address(this).balance;
                if (balance > 0) {
                    Address.sendValue(payable(to), balance);
                }
            } else {
                uint256 balance = currency.balanceOf(address(this));
                if (balance > 0) {
                    currency.safeTransfer(to, balance);
                }
            }
        }
    }

    function canRelease() external view returns (bool) {
        return
            block.number >
            feeSetter.rewardDurationInBlocks() + feeSetter.lastRewardDistributionBlock();
    }

    function releaseAndUpdateReward(IERC20[] memory tokens, address[] memory accounts)
        external
        nonReentrant
        whenNotPaused
        onlyRole(OPERATOR_ROLE)
    {
        _release(tokens);

        // release x2y2 to pools, skipped when the balance is less than 1 token (the release can be called by anyone)
        if (tokenSplitter.x2y2Token().balanceOf(address(tokenSplitter)) >= 1 ether) {
            for (uint256 i = 0; i < accounts.length; i++) {
                tokenSplitter.releaseTokens(accounts[i]);
            }
        }

        feeSetter.updateRewards();
    }

    function release(IERC20[] memory tokens)
        external
        nonReentrant
        whenNotPaused
        onlyRole(OPERATOR_ROLE)
    {
        _release(tokens);
    }

    function _release(IERC20[] memory tokens) internal {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            weth.deposit{value: balance}();
        }
        balance = weth.balanceOf(address(this));
        if (balance > 0) {
            weth.safeTransfer(address(feeSetter), balance);
        }

        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 currency = tokens[i];
            balance = currency.balanceOf(address(this));
            if (balance > 0) {
                currency.safeTransfer(address(feeSetter), balance);
            }
        }
    }
}