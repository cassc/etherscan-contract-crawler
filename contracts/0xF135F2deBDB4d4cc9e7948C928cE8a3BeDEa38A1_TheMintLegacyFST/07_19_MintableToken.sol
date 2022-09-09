//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "../external/openzeppelin-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../external/IERC677Receiver.sol";
import "../external/IERC677Token.sol";
import "../upgrade/FsBase.sol";

contract MintableToken is FsBase, ERC20PermitUpgradeable, IERC677Token {
    uint8 public erc20Decimals;
    uint256[846] private __storage_gap;
    uint256 private ___storageMarker;

    function initialize(
        uint8 _erc20Decimals,
        string memory name,
        string memory symbol
    ) public virtual initializer {
        erc20Decimals = _erc20Decimals;
        __ERC20Permit_init(symbol);
        __ERC20_init(name, symbol);
        initializeFsOwnable();
    }

    /// @notice mint amount tokens to account
    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    /// @notice burn amount tokens from account
    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }

    /// @inheritdoc ERC20Upgradeable
    function decimals() public view override returns (uint8) {
        return erc20Decimals;
    }

    /// @inheritdoc IERC677Token
    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external override returns (bool success) {
        super.transfer(to, value);
        if (Address.isContract(to)) {
            IERC677Receiver receiver = IERC677Receiver(to);
            return receiver.onTokenTransfer(msg.sender, value, data);
        }
        return true;
    }

    /// @notice Invalidate nonce for permit approval
    function useNonce() external {
        _useNonce(msg.sender);
    }
}