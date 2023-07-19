// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

import '@mimic-fi/v2-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/BaseAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/TokenThresholdAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/RelayedAction.sol';

import '../interfaces/IGnosisSafe.sol';
import '../interfaces/IMetamaskFeeDistributor.sol';

import 'hardhat/console.sol';

contract MetamaskClaimer is BaseAction, TokenThresholdAction, RelayedAction {
    using ECDSA for bytes32;
    using FixedPoint for uint256;

    // Base gas amount charged to cover gas payment
    uint256 public constant override BASE_GAS = 60e3;

    // Address of the gnosis safe owning th metamask fee shares
    address public safe;

    // Address of the metamask fee distributor contract
    address public metamaskFeeDistributor;

    // Address of the token to cover the relayed gas costs
    address public gasToken;

    /**
     * @dev Emitted every time a new safe is set
     */
    event SafeSet(address indexed safe);

    /**
     * @dev Emitted every time a new metamask fee distributor is set
     */
    event MetamaskFeeDistributorSet(address indexed metamaskFeeDistributor);

    /**
     * @dev Emitted every time a new gas token is set
     */
    event GasTokenSet(address indexed gasToken);

    /**
     * @dev Metamask claimer action config. Only used in the constructor.
     */
    struct Config {
        address admin;
        address registry;
        address smartVault;
        address safe;
        address metamaskFeeDistributor;
        address thresholdToken;
        uint256 thresholdAmount;
        address relayer;
        address gasToken;
        uint256 gasPriceLimit;
    }

    /**
     * @dev Creates a new metamask claimer action
     */
    constructor(Config memory config) BaseAction(config.admin, config.registry) {
        require(address(config.smartVault) != address(0), 'SMART_VAULT_ZERO');
        smartVault = ISmartVault(config.smartVault);
        emit SmartVaultSet(config.smartVault);

        _setSafe(config.safe);
        _setMetamaskFeeDistributor(config.metamaskFeeDistributor);

        thresholdToken = config.thresholdToken;
        thresholdAmount = config.thresholdAmount;
        emit ThresholdSet(config.thresholdToken, config.thresholdAmount);

        isRelayer[config.relayer] = true;
        emit RelayerSet(config.relayer, true);

        _setGasToken(config.gasToken);
        gasPriceLimit = config.gasPriceLimit;
        emit LimitsSet(config.gasPriceLimit, 0);
    }

    /**
     * @dev Sets safe reference. Sender must be authorized.
     * @param newSafe Address of the new safe to be set
     */
    function setSafe(address newSafe) external auth {
        _setSafe(newSafe);
    }

    /**
     * @dev Sets metamask fee distributor reference. Sender must be authorized.
     * @param newMetamaskFeeDistributor Address of the new metamask fee distributor to be set
     */
    function setMetamaskFeeDistributor(address newMetamaskFeeDistributor) external auth {
        _setMetamaskFeeDistributor(newMetamaskFeeDistributor);
    }

    /**
     * @dev Sets the paying gas token. Sender must be authorized.
     * @param newGasToken Address of the new gas token to pay for relayed transactions
     */
    function setGasToken(address newGasToken) external auth {
        _setGasToken(newGasToken);
    }

    /**
     * @dev Claims all the available balance for a given token in the metamask fee distributor
     * @param token Address of the token to be claimed
     */
    function call(address token) external auth nonReentrant redeemGas(gasToken) {
        require(IGnosisSafe(safe).isOwner(address(smartVault)), 'SMART_VAULT_NOT_SAFE_OWNER');

        uint256 balance = IMetamaskFeeDistributor(metamaskFeeDistributor).available(token, address(smartVault));
        _validateThreshold(token, balance);

        bytes memory contractSignature = abi.encodePacked(
            uint256(uint160(address(smartVault))),
            bytes32(0),
            bytes1(0x01)
        );

        _claimTokens(token, contractSignature);
        _transferTokens(token, balance, contractSignature);
        emit Executed();
    }

    /**
     * @dev Executes a transaction on the safe to claim all the available tokens in metamask's distributor
     * @param token Address of the token to be claimed
     * @param contractSignature Signature for the safe
     */
    function _claimTokens(address token, bytes memory contractSignature) internal {
        address[] memory tokens = new address[](1);
        tokens[0] = token;
        bytes memory metamaskClaimData = abi.encodeWithSelector(IMetamaskFeeDistributor.withdraw.selector, tokens);
        bytes memory safeClaimData = abi.encodeWithSelector(
            IGnosisSafe.execTransaction.selector,
            metamaskFeeDistributor,
            0,
            metamaskClaimData,
            IGnosisSafe.Operation.Call,
            0,
            0,
            0,
            address(0),
            address(0),
            contractSignature
        );

        // solhint-disable-next-line avoid-low-level-calls
        smartVault.call(safe, safeClaimData, 0, new bytes(0));
    }

    /**
     * @dev Executes a transaction on the safe to transfer an amount of tokens to the smart vault
     * @param token Address of the token to be transferred
     * @param amount Amount of tokens to be transferred
     * @param contractSignature Signature for the safe
     */
    function _transferTokens(address token, uint256 amount, bytes memory contractSignature) internal {
        bytes memory tokenTransferData = abi.encodeWithSelector(IERC20.transfer.selector, address(smartVault), amount);
        bytes memory safeTransferData = abi.encodeWithSelector(
            IGnosisSafe.execTransaction.selector,
            token,
            0,
            tokenTransferData,
            IGnosisSafe.Operation.Call,
            0,
            0,
            0,
            address(0),
            address(0),
            contractSignature
        );

        // solhint-disable-next-line avoid-low-level-calls
        smartVault.call(safe, safeTransferData, 0, new bytes(0));
    }

    /**
     * @dev Sets safe reference
     * @param newSafe Address of the new safe to be set
     */
    function _setSafe(address newSafe) private {
        safe = newSafe;
        emit SafeSet(newSafe);
    }

    /**
     * @dev Sets metamask fee distributor reference
     * @param newMetamaskFeeDistributor Address of the new metamask fee distributor to be set
     */
    function _setMetamaskFeeDistributor(address newMetamaskFeeDistributor) private {
        metamaskFeeDistributor = newMetamaskFeeDistributor;
        emit MetamaskFeeDistributorSet(newMetamaskFeeDistributor);
    }

    /**
     * @dev Sets the paying gas token
     * @param newGasToken Address of the new gas token to pay for relayed transactions
     */
    function _setGasToken(address newGasToken) private {
        require(newGasToken != address(0), 'GAS_TOKEN_ZERO');
        gasToken = newGasToken;
        emit GasTokenSet(newGasToken);
    }
}