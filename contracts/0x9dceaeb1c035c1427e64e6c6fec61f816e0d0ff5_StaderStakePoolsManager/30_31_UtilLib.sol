// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import '../interfaces/IStaderConfig.sol';
import '../interfaces/INodeRegistry.sol';
import '../interfaces/IPoolUtils.sol';
import '../interfaces/IVaultProxy.sol';

library UtilLib {
    error ZeroAddress();
    error InvalidPubkeyLength();
    error CallerNotManager();
    error CallerNotOperator();
    error CallerNotStaderContract();
    error CallerNotWithdrawVault();
    error TransferFailed();

    uint64 private constant VALIDATOR_PUBKEY_LENGTH = 48;

    /// @notice zero address check modifier
    function checkNonZeroAddress(address _address) internal pure {
        if (_address == address(0)) revert ZeroAddress();
    }

    //checks for Manager role in staderConfig
    function onlyManagerRole(address _addr, IStaderConfig _staderConfig) internal view {
        if (!_staderConfig.onlyManagerRole(_addr)) {
            revert CallerNotManager();
        }
    }

    function onlyOperatorRole(address _addr, IStaderConfig _staderConfig) internal view {
        if (!_staderConfig.onlyOperatorRole(_addr)) {
            revert CallerNotOperator();
        }
    }

    //checks if caller is a stader contract address
    function onlyStaderContract(
        address _addr,
        IStaderConfig _staderConfig,
        bytes32 _contractName
    ) internal view {
        if (!_staderConfig.onlyStaderContract(_addr, _contractName)) {
            revert CallerNotStaderContract();
        }
    }

    function getPubkeyForValidSender(
        uint8 _poolId,
        uint256 _validatorId,
        address _addr,
        IStaderConfig _staderConfig
    ) internal view returns (bytes memory) {
        address nodeRegistry = IPoolUtils(_staderConfig.getPoolUtils()).getNodeRegistry(_poolId);
        (, bytes memory pubkey, , , address withdrawVaultAddress, , , ) = INodeRegistry(nodeRegistry).validatorRegistry(
            _validatorId
        );
        if (_addr != withdrawVaultAddress) {
            revert CallerNotWithdrawVault();
        }
        return pubkey;
    }

    function getOperatorForValidSender(
        uint8 _poolId,
        uint256 _validatorId,
        address _addr,
        IStaderConfig _staderConfig
    ) internal view returns (address) {
        address nodeRegistry = IPoolUtils(_staderConfig.getPoolUtils()).getNodeRegistry(_poolId);
        (, , , , address withdrawVaultAddress, uint256 operatorId, , ) = INodeRegistry(nodeRegistry).validatorRegistry(
            _validatorId
        );
        if (_addr != withdrawVaultAddress) {
            revert CallerNotWithdrawVault();
        }
        (, , , , address operator) = INodeRegistry(nodeRegistry).operatorStructById(operatorId);
        return operator;
    }

    function onlyValidatorWithdrawVault(
        uint8 _poolId,
        uint256 _validatorId,
        address _addr,
        IStaderConfig _staderConfig
    ) internal view {
        address nodeRegistry = IPoolUtils(_staderConfig.getPoolUtils()).getNodeRegistry(_poolId);
        (, , , , address withdrawVaultAddress, , , ) = INodeRegistry(nodeRegistry).validatorRegistry(_validatorId);
        if (_addr != withdrawVaultAddress) {
            revert CallerNotWithdrawVault();
        }
    }

    function getOperatorAddressByValidatorId(
        uint8 _poolId,
        uint256 _validatorId,
        IStaderConfig _staderConfig
    ) internal view returns (address) {
        address nodeRegistry = IPoolUtils(_staderConfig.getPoolUtils()).getNodeRegistry(_poolId);
        (, , , , , uint256 operatorId, , ) = INodeRegistry(nodeRegistry).validatorRegistry(_validatorId);
        (, , , , address operatorAddress) = INodeRegistry(nodeRegistry).operatorStructById(operatorId);

        return operatorAddress;
    }

    function getOperatorAddressByOperatorId(
        uint8 _poolId,
        uint256 _operatorId,
        IStaderConfig _staderConfig
    ) internal view returns (address) {
        address nodeRegistry = IPoolUtils(_staderConfig.getPoolUtils()).getNodeRegistry(_poolId);
        (, , , , address operatorAddress) = INodeRegistry(nodeRegistry).operatorStructById(_operatorId);

        return operatorAddress;
    }

    function getOperatorRewardAddress(address _operator, IStaderConfig _staderConfig)
        internal
        view
        returns (address payable)
    {
        uint8 poolId = IPoolUtils(_staderConfig.getPoolUtils()).getOperatorPoolId(_operator);
        address nodeRegistry = IPoolUtils(_staderConfig.getPoolUtils()).getNodeRegistry(poolId);
        uint256 operatorId = INodeRegistry(nodeRegistry).operatorIDByAddress(_operator);
        return INodeRegistry(nodeRegistry).getOperatorRewardAddress(operatorId);
    }

    /**
     * @notice Computes the public key root.
     * @param _pubkey The validator public key for which to compute the root.
     * @return The root of the public key.
     */
    function getPubkeyRoot(bytes calldata _pubkey) internal pure returns (bytes32) {
        if (_pubkey.length != VALIDATOR_PUBKEY_LENGTH) {
            revert InvalidPubkeyLength();
        }

        // Append 16 bytes of zero padding to the pubkey and compute its hash to get the pubkey root.
        return sha256(abi.encodePacked(_pubkey, bytes16(0)));
    }

    function getValidatorSettleStatus(bytes calldata _pubkey, IStaderConfig _staderConfig)
        internal
        view
        returns (bool)
    {
        uint8 poolId = IPoolUtils(_staderConfig.getPoolUtils()).getValidatorPoolId(_pubkey);
        address nodeRegistry = IPoolUtils(_staderConfig.getPoolUtils()).getNodeRegistry(poolId);
        uint256 validatorId = INodeRegistry(nodeRegistry).validatorIdByPubkey(_pubkey);
        (, , , , address withdrawVaultAddress, , , ) = INodeRegistry(nodeRegistry).validatorRegistry(validatorId);
        return IVaultProxy(withdrawVaultAddress).vaultSettleStatus();
    }

    function computeExchangeRate(
        uint256 totalETHBalance,
        uint256 totalETHXSupply,
        IStaderConfig _staderConfig
    ) internal view returns (uint256) {
        uint256 DECIMALS = _staderConfig.getDecimals();
        uint256 newExchangeRate = (totalETHBalance == 0 || totalETHXSupply == 0)
            ? DECIMALS
            : (totalETHBalance * DECIMALS) / totalETHXSupply;
        return newExchangeRate;
    }

    function sendValue(address _receiver, uint256 _amount) internal {
        (bool success, ) = payable(_receiver).call{value: _amount}('');
        if (!success) {
            revert TransferFailed();
        }
    }
}