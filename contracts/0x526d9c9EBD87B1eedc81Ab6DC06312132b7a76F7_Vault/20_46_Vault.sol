// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {TokenHandler} from "../utils/TokenHandler.sol";
import {VaultStorageV1} from "./VaultStorage.sol";
import {IVaultFactory} from "../interfaces/IVaultFactory.sol";

/**
 * @title Vault Implementation
 * @author Immunefi
 * @notice Vaults are upgradeable. To not brick this, we use upgradeable libs and inherited storage
 */
contract Vault is TokenHandler, VaultStorageV1 {
    using SafeERC20 for IERC20;

    address private immutable _implementation; // immutable vars dont occupy storage slots

    constructor() {
        _implementation = address(this);
    }

    struct ERC20Payment {
        address token;
        uint256 amount;
    }

    event Withdraw(ERC20Payment[] withdrawal, uint256 nativeTokenAmt);
    event PayWhitehat(bytes32 indexed referenceId, address wh, ERC20Payment[] payout, uint256 nativeTokenAmt, address feeTo, uint256 fee);
    event PausedOnImmunefi(bool isPaused);

    /**
     * @notice Initializes the vault (proxy) with a specified owner
     * @dev Can only be delegatecalled
     * @param _owner The address which will own the vault
     */
    function initialize(
        address _owner,
        bytes calldata /* optionalCalldata in the future */
    ) public initializer {
        require(address(this) != _implementation, "Vault: Can only be called by proxy");
        _transferOwnership(_owner);
        vaultFactory = IVaultFactory(_msgSender());
    }

    /**
     * @notice Delete renounce ownership functionality
     */
    function renounceOwnership() public view override onlyOwner {
        revert("renounce disabled");
    }

    /**
     * @notice Withdraws tokens to the owner account
     * @param withdrawal The payout of tokens/token amounts to withdraw
     * @param nativeTokenAmt The payout of native Ether amount to withdraw
     */
    function withdraw(ERC20Payment[] calldata withdrawal, uint256 nativeTokenAmt) public onlyOwner {
        address payable owner = payable(owner());
        uint256 length = withdrawal.length;
        for (uint256 i; i < length; i++) {
            IERC20(withdrawal[i].token).safeTransfer(owner, withdrawal[i].amount);
        }
        if (nativeTokenAmt > 0) {
            (bool success, ) = owner.call{value: nativeTokenAmt}("");
            require(success, "Vault: Failed to send ether to owner");
        }
        emit Withdraw(withdrawal, nativeTokenAmt);
    }

    /**
     * @notice Pay a whitehat
     * @dev Only callable by owner
     * @dev If whitehats attempt to grief payments, project/immunefi reserves the right to nullify bounty payout
     * @dev The amount of gas forwarded to the whitehat should be enough for a delegatecall to be made to support
     *      gnosis safe wallets
     * @param referenceId id reference to report
     * @param wh whitehat address
     * @param payout The payout of tokens/token amounts to whitehat
     * @param nativeTokenAmt The payout of native Ether amount to whitehat
     * @param gas The amount of gas to forward to the whitehat to mitigate gas griefing
     */
    function payWhitehat(
        bytes32 referenceId,
        address payable wh,
        ERC20Payment[] calldata payout,
        uint256 nativeTokenAmt,
        uint256 gas
    ) public onlyOwner {
        address payable feeTo = payable(vaultFactory.feeTo());
        uint256 fee = vaultFactory.fee();
        uint256 feeBasis = vaultFactory.FEE_BASIS();

        for (uint256 i; i < payout.length; i++) {
            uint256 feeAmount = (payout[i].amount * fee) / feeBasis;
            if (feeAmount > 0) IERC20(payout[i].token).safeTransfer(feeTo, feeAmount);
            IERC20(payout[i].token).safeTransfer(wh, payout[i].amount);
        }

        if (nativeTokenAmt > 0) {
            uint256 feeAmount = (nativeTokenAmt * fee) / feeBasis;
            if (feeAmount > 0) {
                (bool success, ) = feeTo.call{value: feeAmount}("");
                require(success, "Vault: Failed to send ether to fee receiver");
            }
            (bool success, ) = wh.call{value: nativeTokenAmt, gas: gas}("");
            require(success, "Vault: Failed to send ether to whitehat");
        }
        emit PayWhitehat(referenceId, wh, payout, nativeTokenAmt, feeTo, fee);
    }

    /**
     * @notice Allows receival of eth
     */
    receive() external payable {}

    /**
     * @notice Sets isPausedOnImmunefi
     * @dev Only callable by owner
     * @dev Owner needs to set isPausedOnImmunefi to false before they can soft delete the vault on Immunefi
     * @dev This value is only used in the frontend
     * @param isPaused The value to store in isPausedOnImmunefi
     */
    function setIsPausedOnImmunefi(bool isPaused) public onlyOwner {
        isPausedOnImmunefi = isPaused;
        emit PausedOnImmunefi(isPaused);
    }
}