// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

import "./handlers/Handler.sol";
import "./interfaces/ILaserWallet.sol";
import "./state/LaserState.sol";

interface ILaserGuard {
    function checkTransaction(address to) external;
}

///@title LaserWallet - Modular EVM based smart contract wallet.
///@author Rodrigo Herrera I.
contract LaserWallet is ILaserWallet, LaserState, Handler {
    string public constant VERSION = "1.0.0";

    bytes4 private constant EIP1271_MAGIC_VALUE = bytes4(keccak256("isValidSignature(bytes32,bytes)"));

    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH =
        keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");

    bytes32 private constant LASER_TYPE_STRUCTURE =
        keccak256(
            "LaserOperation(address to,uint256 value,bytes callData,uint256 nonce,uint256 maxFeePerGas,uint256 maxPriorityFeePerGas,uint256 gasLimit)"
        );

    constructor() {
        owner = address(this);
    }

    receive() external payable {}

    ///@dev Setup function, sets initial storage of the wallet.
    ///@notice It can't be called after initialization.
    function init(
        address _owner,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer,
        address laserModule,
        bytes calldata laserModuleData,
        bytes calldata ownerSignature
    ) external {
        activateWallet(_owner, laserModule, laserModuleData);

        bytes32 signedHash = keccak256(abi.encodePacked(maxFeePerGas, maxPriorityFeePerGas, gasLimit, block.chainid));

        address signer = Utils.returnSigner(signedHash, ownerSignature, 0);

        if (signer != _owner) revert LW__init__notOwner();

        if (gasLimit > 0) {
            // Using infura relayer for now ...
            uint256 fee = (tx.gasprice / 100) * 6;
            uint256 gasPrice = tx.gasprice + fee;

            gasLimit = (gasLimit * 3150) / 3200;
            uint256 gasUsed = gasLimit - gasleft() + 8000;

            uint256 refundAmount = gasUsed * gasPrice;

            bool success = Utils.call(
                relayer == address(0) ? tx.origin : relayer,
                refundAmount,
                new bytes(0),
                gasleft()
            );

            if (!success) revert LW__init__refundFailure();
        }
        // emit Setup(_owner, laserModule);
    }

    /**
     * @dev Executes a generic transaction. It does not support 'delegatecall' for security reasons.
     * @param to Destination address.
     * @param value Amount to send.
     * @param callData Data payload for the transaction.
     * @param ownerSignature The signatures of the transaction.
     * @notice If 'gasLimit' does not match the actual gas limit of the transaction, the relayer can incur losses.
     * It is the relayer's responsability to make sure that they are the same, the user does not get affected if a mistake is made.
     * We prefer to prioritize the user's safety (not overpay) over the relayer.
     */
    function exec(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer,
        bytes calldata ownerSignature
    ) external {
        // We immediately increase the nonce to avoid replay attacks.
        unchecked {
            if (nonce++ != _nonce) revert LW__exec__invalidNonce();
        }

        if (isLocked) revert LW__exec__walletLocked();

        bytes32 signedHash = keccak256(
            encodeOperation(to, value, callData, _nonce, maxFeePerGas, maxPriorityFeePerGas, gasLimit)
        );

        address signer = Utils.returnSigner(signedHash, ownerSignature, 0);

        if (signer != owner) revert LW__exec__notOwner();

        bool success = Utils.call(to, value, callData, gasleft() - 10000);

        // We do not revert the call if it fails, because the wallet needs to pay the relayer even in case of failure.
        if (success) emit ExecSuccess(to, value, nonce);
        else emit ExecFailure(to, value, nonce);

        if (laserGuard != address(0)) {
            ILaserGuard(laserGuard).checkTransaction(to);
        }

        // Using infura relayer for now ...
        uint256 fee = (tx.gasprice / 100) * 6;
        uint256 gasPrice = tx.gasprice + fee;
        uint256 gasUsed = gasLimit - gasleft() + 7000;
        uint256 refundAmount = gasUsed * gasPrice;

        success = Utils.call(relayer == address(0) ? tx.origin : relayer, refundAmount, new bytes(0), gasleft());

        if (!success) revert LW__exec__refundFailure();
    }

    ///@dev Allows to execute a transaction from an authorized module.
    function execFromModule(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer
    ) external {
        unchecked {
            nonce++;
        }
        ///@todo custom errors instead of require statement.
        require(laserModules[msg.sender] != address(0), "nop module");

        bool success = Utils.call(to, value, callData, gasleft() - 10000);

        require(success, "main call failed");

        if (gasLimit > 0) {
            // Using infura relayer for now ...
            uint256 fee = (tx.gasprice / 100) * 6;
            uint256 gasPrice = tx.gasprice + fee;
            gasLimit = (gasLimit * 63) / 64;
            uint256 gasUsed = gasLimit - gasleft() + 7000;
            uint256 refundAmount = gasUsed * gasPrice;

            success = Utils.call(relayer == address(0) ? tx.origin : relayer, refundAmount, new bytes(0), gasleft());

            require(success, "refund failed");
        }
    }

    ///@dev Locks the wallet. Once locked, only the SSR module can unlock it or recover it.
    function lock() external access {
        isLocked = true;
    }

    ///@dev Unlocks the wallet. Can only be unlocked or recovered from the SSR module.
    function unlock() external access {
        isLocked = false;
    }

    ///@dev Implementation of EIP 1271: https://eips.ethereum.org/EIPS/eip-1271.
    ///@return Magic value  or reverts with an error message.
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4) {
        address recovered = Utils.returnSigner(hash, signature, 0);

        // The guardians and recovery owners should not be able to sign transactions that are out of scope from this wallet.
        // Only the owner should be able to sign external data.
        if (recovered != owner || isLocked) revert LaserWallet__invalidSignature();
        return EIP1271_MAGIC_VALUE;
    }

    function getChainId() public view returns (uint256 chainId) {
        return block.chainid;
    }

    function domainSeparator() public view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, getChainId(), address(this)));
    }

    function encodeOperation(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit
    ) internal view returns (bytes memory) {
        bytes32 opHash = keccak256(
            abi.encode(
                LASER_TYPE_STRUCTURE,
                to,
                value,
                keccak256(callData),
                _nonce,
                maxFeePerGas,
                maxPriorityFeePerGas,
                gasLimit
            )
        );

        return abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator(), opHash);
    }

    function operationHash(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit
    ) external view returns (bytes32) {
        return keccak256(encodeOperation(to, value, callData, _nonce, maxFeePerGas, maxPriorityFeePerGas, gasLimit));
    }
}