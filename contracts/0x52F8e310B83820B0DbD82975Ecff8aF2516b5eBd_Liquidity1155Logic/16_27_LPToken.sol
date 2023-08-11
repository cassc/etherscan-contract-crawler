// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IAddressesRegistry} from "../interfaces/IAddressesRegistry.sol";
import {Errors} from "../libraries/Errors.sol";
import {ILPToken} from "../interfaces/ILPToken.sol";

/**
 * @title LPToken
 * @author Souq.Finance
 * @notice The LP Token contract of each liquidity pool
 * @notice License: https://souq-nft-amm-v1.s3.amazonaws.com/LICENSE.md
 */
contract LPToken is ILPToken, ERC20, ERC20Burnable, Pausable {
    using SafeERC20 for IERC20;
    IAddressesRegistry internal immutable addressesRegistry;
    address public immutable pool;
    uint8 public immutable tokenDecimals;

    constructor(
        address _pool,
        address registry,
        address[] memory tokens,
        string memory symbol,
        string memory name,
        uint8 _decimals
    ) ERC20(name, symbol) {
        require(_pool != address(0), Errors.ADDRESS_IS_ZERO);
        require(registry != address(0), Errors.ADDRESS_IS_ZERO);
        tokenDecimals = _decimals;
        pool = _pool;
        addressesRegistry = IAddressesRegistry(registry);
        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC1155(tokens[i]).setApprovalForAll(address(pool), true);
        }
    }

    /**
     * @dev modifier for when the the msg sender is the liquidity pool that created it only
     */
    modifier onlyPool() {
        require(_msgSender() == address(pool), Errors.CALLER_MUST_BE_POOL);
        _;
    }

    /**
     * @dev Returns the number of decimals for this token. Public due to override.
     * @return uint8 the number of decimals
     */
    function decimals() public view override returns (uint8) {
        return tokenDecimals;
    }

    /// @inheritdoc ILPToken
    function getTotal() external view returns (uint256) {
        return totalSupply();
    }

    /// @inheritdoc ILPToken
    function getBalanceOf(address account) external view returns (uint256) {
        return balanceOf(account);
    }

    /// @inheritdoc ILPToken
    function pause() external onlyPool {
        //_pause already emits an event
        _pause();
    }

    /// @inheritdoc ILPToken
    function unpause() external onlyPool {
        //_unpause already emits an event
        _unpause();
    }

    /// @inheritdoc ILPToken
    function checkPaused() external view returns (bool) {
        return paused();
    }

    /// @inheritdoc ILPToken
    function setApproval20(address token, uint256 amount) external onlyPool {
        bool returnApproved = IERC20(token).approve(pool, amount);
        require(returnApproved, Errors.APPROVAL_FAILED);
    }

    /// @inheritdoc ILPToken
    function mint(address to, uint256 amount) external onlyPool {
        //_mint already emits a transfer event
        _mint(to, amount);
    }

    /// @inheritdoc ILPToken
    function burn(address from, uint256 amount) external onlyPool {
        //_burn already emits a transfer event
        _burn(from, amount);
    }

    /// @inheritdoc ILPToken
    function RescueTokens(address token, uint256 amount, address receiver) external onlyPool {
        //event emitted in the pool logic library
        IERC20(token).safeTransfer(receiver, amount);
    }

    /**
     * @dev Implementation of the ERC1155 token received hook.
     */
    function onERC1155Received(address, address, uint256, uint256, bytes memory) external virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @dev Implementation of the ERC1155 batch token received hook.
     */
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) external virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}