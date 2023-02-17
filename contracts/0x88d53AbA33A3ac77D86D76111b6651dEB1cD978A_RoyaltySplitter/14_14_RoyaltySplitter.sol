// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import {AddressUpgradeable} from "@openzeppelin-upgradeable/contracts/utils/AddressUpgradeable.sol";
import {IWETH} from "./IWETH.sol";
import {IBlurPool} from "./IBlurPool.sol";

/**
 * @title RoyaltySplitter
 * @author Lozz (@lozzereth / www.allthingsweb3.com)
 * @notice Lightweight royalty splitter solution.
 */
contract RoyaltySplitter is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /// @notice Shareholding of an address
    mapping(address => uint256) private _shares;

    /// @notice Shareholders
    address[] private _shareholders;

    /// @notice Total shares of shareholders combined
    uint256 private _totalShares;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address[] memory shareholders, uint256[] memory shares_)
        external
        initializer
    {
        __UUPSUpgradeable_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        for (uint256 i = 0; i < shareholders.length; i++) {
            _addShareholder(shareholders[i], shares_[i]);
        }
    }

    /**
     * @dev Add a new shareholder to the contract
     * @param account The address of the shareholder to add
     * @param shares_ The number of shares owned by the shareholder
     */
    function _addShareholder(address account, uint256 shares_) private {
        require(
            account != address(0),
            "RoyaltySplitter: account is the zero address"
        );
        require(shares_ > 0, "RoyaltySplitter: shares are 0");
        require(
            _shares[account] == 0,
            "RoyaltySplitter: account already has shares"
        );
        _shareholders.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
    }

    /**
     * @notice Release all of an ETH token for all shareholders
     */
    function releaseAll() public nonReentrant {
        _convertWethBalance();
        _convertBlurPoolBalance();
        _releaseEth();
    }

    /**
     * @notice Release only ETH from the contract
     */
    function releaseEth() public nonReentrant {
        _releaseEth();
    }

    /**
     * @dev Release the eth balances to shareholders
     */
    function _releaseEth() internal {
        uint256 balance = address(this).balance;
        uint256 totalShares = _totalShares;
        for (uint256 s; s < _shareholders.length; ++s) {
            address shareholder = _shareholders[s];
            AddressUpgradeable.sendValue(
                payable(shareholder),
                (balance * _shares[shareholder]) / totalShares
            );
        }
    }

    /**
     * @notice Convert WETH balance
     */
    function _convertWethBalance() internal {
        IWETH wrappedEther = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        uint256 balance = wrappedEther.balanceOf(address(this));
        if (balance > 0) {
            wrappedEther.withdraw(balance);
        }
    }

    /**
     * @notice Convert BLUR Pool Balance
     */
    function _convertBlurPoolBalance() internal {
        IBlurPool blur = IBlurPool(0x0000000000A39bb272e79075ade125fd351887Ac);
        uint256 balance = blur.balanceOf(address(this));
        if (balance > 0) {
            blur.withdraw(balance);
        }
    }

    /**
     * @dev Authorize contract owner to make upgrades
     * @notice Implementation contract
     */
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /**
     * @notice Return the implementation contract
     */
    function getImplementation() external view returns (address) {
        return _getImplementation();
    }
}