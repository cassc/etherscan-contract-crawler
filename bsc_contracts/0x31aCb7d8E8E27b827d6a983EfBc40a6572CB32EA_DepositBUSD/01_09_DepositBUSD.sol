// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IDepositBUSD.sol";

contract DepositBUSD is IDepositBUSD, OwnableUpgradeable, PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public minDeposit;

    address public busd;
    address public treasury;

    modifier AddressZero(address _addr) {
        require(_addr != address(0), "Set address to zero");
        _;
    }

    function init(
        uint256 _minDeposit,
        address _busd,
        address _treasury
    ) external initializer {
        __Ownable_init();
        __Pausable_init();

        minDeposit = _minDeposit;
        busd = _busd;
        treasury = _treasury;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function updateTreasury(address _newTreasury)
        external
        AddressZero(_newTreasury)
        onlyOwner
    {
        treasury = _newTreasury;
    }

    function updateBUSD(address _busd) external AddressZero(_busd) onlyOwner {
        busd = _busd;
    }

    function updateMinDeposit(uint256 _min) external onlyOwner {
        require(_min > 0, "Minimum cannot be zero");
        minDeposit = _min;
    }

    function depositAsset(
        string calldata _userId,
        uint256 _amountIn,
        uint256 _assetOut
    ) external whenNotPaused {
        require(_amountIn >= minDeposit, "Invalid amountIn");

        address _assetIn = busd;
        address _treasury = treasury;

        IERC20Upgradeable(_assetIn).safeTransferFrom(
            _msgSender(),
            _treasury,
            _amountIn
        );

        emit DepositBUSD(_userId, _treasury, _assetIn, _amountIn, _assetOut);
    }
}