//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./libsv2/common/ZeroCopySink.sol";
import "./libsv2/utils/Utils.sol";

interface ICCM {
    function crossChain(uint64 _toChainId, bytes calldata _toContract, bytes calldata _method, bytes calldata _txData) external returns (bool);
}

interface ICCMProxy {
    function getEthCrossChainManager() external view returns (address);
}

interface ILockProxy {
    function registry(address _assetHash) external view returns (bytes32);
    function ccmProxy() external view returns (ICCMProxy);
    function counterpartChainId() external view returns (uint64);
}

contract BridgeEntrance is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // used for cross-chain lock and unlock methods
    struct TransferTxArgs {
        bytes fromAssetAddress;
        bytes fromAssetDenom;
        bytes toAssetDenom;
        bytes recoveryAddress;
        bytes toAddress;
        uint256 amount;
        uint256 withdrawFeeAmount;
        bytes withdrawFeeAddress;
    }

    address public constant ETH_ASSET_HASH = address(0);

    ILockProxy public lockProxy;

    event LockEvent(
        address fromAssetAddress,
        uint64 toChainId,
        bytes fromAssetDenom,
        bytes recoveryAddress,
        bytes txArgs
    );

    constructor(address _lockProxy) {
        require(_lockProxy != address(0), "lockProxy cannot be empty");
        lockProxy = ILockProxy(_lockProxy);
    }

    /// @dev Performs a deposit
    /// @param _assetHash the asset to deposit
    /// @param _bytesValues[0]: _targetProxyHash the associated proxy hash on Switcheo Carbon
    /// @param _bytesValues[1]: _recoveryAddress the hex version of the Switcheo Carbon recovery address to deposit to
    /// @param _bytesValues[2]: _fromAssetDenom the associated asset hash on Switcheo Carbon
    /// @param _bytesValues[3]: _withdrawFeeAddress the hex version of the Switcheo Carbon address to send the fee to
    /// @param _bytesValues[4]: _toAddress the L1 address to bridge to
    /// @param _bytesValues[5]: _toAssetDenom the associated asset denom on Switcheo Carbon
    /// @param _uint256Values[0]: amount, the number of tokens to deposit
    /// @param _uint256Values[1]: withdrawFeeAmount, the number of tokens to be used as fees
    /// @param _uint256Values[2]: callAmount, some tokens may burn an amount before transfer
    /// so we allow a callAmount to support these tokens
    function lock(
        address _assetHash,
        bytes[] calldata _bytesValues,
        uint256[] calldata _uint256Values
    )
        external
        payable
        nonReentrant
        returns (bool)
    {
        // it is very important that this function validates the success of a transfer correctly
        // since, once this line is passed, the deposit is assumed to be successful
        // which will eventually result in the specified amount of tokens being minted for the
        // _recoveryAddress on Switcheo Carbon
        _transferIn(_assetHash, _uint256Values[0], _uint256Values[2]);

        _lock(_assetHash, _bytesValues, _uint256Values);

        return true;
    }

    /// @dev Validates that an asset's registration matches the given params
    /// @param _assetHash the address of the asset to check
    /// @param _proxyAddress the expected proxy address on Switcheo Carbon
    /// @param _fromAssetDenom the expected asset hash on Switcheo Carbon
    function _validateAssetRegistration(
        address _assetHash,
        bytes memory _proxyAddress,
        bytes memory _fromAssetDenom
    )
        private
        view
    {
        require(_proxyAddress.length == 20, "Invalid proxyAddress");
        bytes32 value = keccak256(abi.encodePacked(
            _proxyAddress,
            _fromAssetDenom
        ));
        require(lockProxy.registry(_assetHash) == value, "Asset not registered");
    }

    /// @dev validates the asset registration and calls the CCM contract
    /// @param _bytesValues[0]: _targetProxyHash the associated proxy hash on Switcheo Carbon
    /// @param _bytesValues[1]: _recoveryAddress the hex version of the Switcheo Carbon recovery address to deposit to
    /// @param _bytesValues[2]: _fromAssetDenom the associated asset hash on Switcheo Carbon
    /// @param _bytesValues[3]: _withdrawFeeAddress the hex version of the Switcheo Carbon address to send the fee to
    /// @param _bytesValues[4]: _toAddress the L1 address to bridge to
    /// @param _bytesValues[5]: _toAssetDenom the associated asset denom on Switcheo Carbon
    /// @param _uint256Values[0]: _amount, the number of tokens to deposit
    /// @param _uint256Values[1]: _withdrawFeeAmount, the number of tokens to be used as fees
    function _lock(
        address _fromAssetAddress,
        bytes[] calldata _bytesValues,
        uint256[] calldata _uint256Values
    )
        private
    {
        bytes memory _targetProxyHash = _bytesValues[0];
        bytes memory _recoveryAddress = _bytesValues[1];
        bytes memory _fromAssetDenom = _bytesValues[2];

        uint256 _amount = _uint256Values[0];
        uint256 _withdrawFeeAmount = _uint256Values[1];

        require(_targetProxyHash.length == 20, "Invalid targetProxyHash");
        require(_fromAssetDenom.length > 0, "Empty fromAssetDenom");
        require(_recoveryAddress.length > 0, "Empty recoveryAddress");
        require(_bytesValues[4].length > 0, "Empty toAddress");
        require(_bytesValues[5].length > 0, "Empty toAssetDenom");
        require(_amount > 0, "Amount must be more than zero");
        require(_withdrawFeeAmount < _amount, "Fee amount cannot be greater than amount");

        _validateAssetRegistration(_fromAssetAddress, _targetProxyHash, _fromAssetDenom);

        TransferTxArgs memory txArgs = TransferTxArgs({
            fromAssetAddress: Utils.addressToBytes(_fromAssetAddress),
            fromAssetDenom: _fromAssetDenom,
            toAssetDenom: _bytesValues[5],
            recoveryAddress: _recoveryAddress,
            toAddress: _bytesValues[4],
            amount: _amount,
            withdrawFeeAmount: _withdrawFeeAmount,
            withdrawFeeAddress: _bytesValues[3]
        });

        bytes memory txData = _serializeTransferTxArgs(txArgs);
        ICCM ccm = _getCcm();
        uint64 counterpartChainId = lockProxy.counterpartChainId();
        require(
            ccm.crossChain(counterpartChainId, _targetProxyHash, "unlock", txData),
            "EthCrossChainManager crossChain executed error!"
        );

        emit LockEvent(_fromAssetAddress, counterpartChainId, _fromAssetDenom, _recoveryAddress, txData);
    }

    function _getCcm() private view returns (ICCM) {
      ICCMProxy ccmProxy = lockProxy.ccmProxy();
      ICCM ccm = ICCM(ccmProxy.getEthCrossChainManager());
      return ccm;
    }

    /// @dev transfers funds from an address into this contract
    /// for ETH transfers, we only check that msg.value == _amount, and _callAmount is ignored
    /// for token transfers, the difference between this contract's before and after balance must equal _amount
    /// these checks are assumed to be sufficient in ensuring that the expected amount
    /// of funds were transferred in
    function _transferIn(
        address _assetHash,
        uint256 _amount,
        uint256 _callAmount
    )
        private
    {
        if (_assetHash == ETH_ASSET_HASH) {
            require(msg.value == _amount, "ETH transferred does not match the expected amount");
            (bool sent,) = address(lockProxy).call{value: msg.value}("");
            require(sent, "Failed to send Ether to LockProxy");
            return;
        }

        IERC20 token = IERC20(_assetHash);
        uint256 before = token.balanceOf(address(lockProxy));
        token.safeTransferFrom(msg.sender, address(lockProxy), _callAmount);
        uint256 transferred = token.balanceOf(address(lockProxy)).sub(before);
        require(transferred == _amount, "Tokens transferred does not match the expected amount");
    }

    function _serializeTransferTxArgs(TransferTxArgs memory args) private pure returns (bytes memory) {
        bytes memory buff;
        buff = abi.encodePacked(
            ZeroCopySink.WriteVarBytes(args.fromAssetAddress),
            ZeroCopySink.WriteVarBytes(args.fromAssetDenom),
            ZeroCopySink.WriteVarBytes(args.toAssetDenom),
            ZeroCopySink.WriteVarBytes(args.recoveryAddress),
            ZeroCopySink.WriteVarBytes(args.toAddress),
            ZeroCopySink.WriteUint255(args.amount),
            ZeroCopySink.WriteUint255(args.withdrawFeeAmount),
            ZeroCopySink.WriteVarBytes(args.withdrawFeeAddress)
        );
        return buff;
    }
}