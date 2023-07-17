// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "solmate/tokens/WETH.sol";
import "solmate/utils/SafeTransferLib.sol";
import "../libraries/Ownable.sol";
import "../Vault.sol";

/// @notice contract to deposit/withdraw native tokens, e.g. ETH/WETH, MATIC/WMATIC
contract WethZap is Ownable {
    using SafeTransferLib for WETH;

    Vault public immutable vault;
    WETH public immutable WETH9;

    bool public paused;

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(address indexed owner, uint256 assets, uint256 shares);

    error NoDepositETH();
    error Paused();
    error AlreadyValue();

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    constructor(Vault _vault) {
        vault = _vault;
        WETH9 = WETH(payable(address(_vault.asset())));
    }

    receive() external payable {
        if (msg.sender != address(WETH9)) revert NoDepositETH(); // use the depositETH function
    }

    function pause() external onlyOwner {
        if (paused) revert AlreadyValue();
        paused = true;
    }

    function unpause() external onlyOwner {
        if (!paused) revert AlreadyValue();
        paused = false;
    }

    function safeDepositETH(address _receiver, uint256 _minShares)
        external
        payable
        whenNotPaused
        returns (uint256 shares)
    {
        WETH9.deposit{value: msg.value}();
        WETH9.safeApprove(address(vault), msg.value);

        shares = vault.safeDeposit(msg.value, _receiver, _minShares);
        emit Deposit(msg.sender, _receiver, msg.value, shares);
    }

    function depositETH(address _receiver) external payable whenNotPaused returns (uint256 shares) {
        WETH9.deposit{value: msg.value}();
        WETH9.safeApprove(address(vault), msg.value);

        shares = vault.deposit(msg.value, _receiver);
        emit Deposit(msg.sender, _receiver, msg.value, shares);
    }

    /// @notice user has to approve zap using vault share tokens
    function safeRedeemETH(uint256 _shares, uint256 _minAssets) external whenNotPaused returns (uint256 assets) {
        assets = vault.safeRedeem(_shares, address(this), msg.sender, _minAssets);
        WETH9.withdraw(assets);
        SafeTransferLib.safeTransferETH(msg.sender, assets);
        emit Withdraw(msg.sender, assets, _shares);
    }

    /// @notice user has to approve zap using vault share tokens
    function redeemETH(uint256 _shares) external whenNotPaused returns (uint256 assets) {
        assets = vault.redeem(_shares, address(this), msg.sender);
        WETH9.withdraw(assets);
        SafeTransferLib.safeTransferETH(msg.sender, assets);
        emit Withdraw(msg.sender, assets, _shares);
    }
}