// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {IXERC20} from "interfaces/IXERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IXERC20Lockbox} from "interfaces/IXERC20Lockbox.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {MulticallUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/utils/MulticallUpgradeable.sol";

contract XERC20Lockbox is Initializable, MulticallUpgradeable, IXERC20Lockbox {
    using SafeERC20 for IERC20;

    /**
     * @notice The XERC20 token of this contract
     */
    IXERC20 public XERC20;

    /**
     * @notice The ERC20 token of this contract
     */
    IERC20 public ERC20;

    /**
     * @notice Whether the ERC20 token is the native gas token of this chain
     */

    bool public IS_NATIVE;

    /**
     * @notice Constructor
     *
     * @param _xerc20 The address of the XERC20 contract
     * @param _erc20 The address of the ERC20 contract
     */

    function initialize(address _xerc20, address _erc20, bool _isNative) public initializer {
        __Multicall_init();
        XERC20 = IXERC20(_xerc20);
        ERC20 = IERC20(_erc20);
        IS_NATIVE = _isNative;
    }

    /**
     * @notice Deposit native tokens into the lockbox
     */

    function deposit() public payable {
        if (!IS_NATIVE) revert IXERC20Lockbox_NotNative();
        XERC20.mint(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Deposit ERC20 tokens into the lockbox
     *
     * @param _amount The amount of tokens to deposit
     */

    function deposit(uint256 _amount) external {
        if (IS_NATIVE) revert IXERC20Lockbox_Native();

        ERC20.safeTransferFrom(msg.sender, address(this), _amount);
        XERC20.mint(msg.sender, _amount);

        emit Deposit(msg.sender, _amount);
    }

    /**
     * @notice Withdraw ERC20 tokens from the lockbox
     *
     * @param _amount The amount of tokens to withdraw
     */

    function withdraw(uint256 _amount) external {
        XERC20.burn(msg.sender, _amount);

        if (IS_NATIVE) {
            (bool _success,) = payable(msg.sender).call{value: _amount}("");
            if (!_success) revert IXERC20Lockbox_WithdrawFailed();
        } else {
            ERC20.safeTransfer(msg.sender, _amount);
        }

        emit Withdraw(msg.sender, _amount);
    }

    receive() external payable {
        deposit();
    }

    // ============ Upgrade Gap ============
    uint256[49] private __GAP; // gap for upgrade safety
}