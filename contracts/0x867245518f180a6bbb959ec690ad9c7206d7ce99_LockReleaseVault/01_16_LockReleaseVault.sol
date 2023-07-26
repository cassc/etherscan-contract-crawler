// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./BaseVault.sol";

/// @title Glitter Finance lock/release vault
/// @author Ackee Blockchain
/// @notice Lock/release vault which uses external ERC20 token
contract LockReleaseVault is BaseVault {
    using SafeERC20 for IERC20;
    IERC20 public token;

    constructor() initializer {}

    /// @notice Initializer function
    /// @param _token Token address
    /// @param _router Router address
    /// @param _owner Owner address
    /// @param _recoverer Recoverer address
    function initialize(
        IERC20 _token,
        IRouter _router,
        address _owner,
        address _recoverer
    ) public initializer {
        require(address(_token) != address(0), "Vault: asset is zero-address");
        __BaseVault_initialize(_router, _owner, _recoverer);
        token = _token;
    }

    /// @notice Deposit implementation - transfer into the contract
    /// @param _from Sender address
    /// @param _amount Token amount
    function _depositImpl(address _from, uint256 _amount) internal override {
        token.safeTransferFrom(_from, address(this), _amount);
    }

    /// @notice Release implementation - transfer from the contract
    /// @param _to Destination address
    /// @param _amount Token amount
    function _releaseImpl(address _to, uint256 _amount) internal override {
        require(_amount <= tokenBalance(), "Vault: insufficient funds");
        token.safeTransfer(_to, _amount);
    }

    /// @notice Get contract token balance
    /// @return Contract token balance
    function tokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this)) - fees;
    }

    /// @notice Get token decimals
    /// @return Token decimals
    function decimals() public view override returns (uint8) {
        return ERC20(address(token)).decimals();
    }
}