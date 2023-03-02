// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./common/Utils.sol";
import "./common/BaseModule.sol";
import "../storage/IStorage.sol";
/**
 * @title KresusRelayer
 * @notice Abstract Module to execute transactions signed by ETH-less accounts and sent by a relayer.
 */
abstract contract KresusRelayer is BaseModule {

    uint256 constant BLOCKBOUND = 10000;

    address public refundAddress;

    struct RelayerConfig {
        uint256 nonce;
        mapping(bytes32 => uint256) queuedTransactions;
        mapping(bytes32 => uint256) arrayindex;
        bytes32[] queue;
    }

    mapping (address => RelayerConfig) internal relayer;


    // Used to avoid stack too deep error
    struct StackExtension {
        Signature SignatureRequirement;
        bytes32 signHash;
        bool success;
        bytes returnData;
    }

    event TransactionExecuted(address indexed vault, bool indexed success, bytes returnData, bytes32 signedHash);
    event TransactionQueued(address indexed vault, uint256 executionTime, bytes32 signedHash);
    event Refund(address indexed vault, address indexed refundAddress, uint256 refundAmount);
    event ActionCancelled(address indexed vault);
    event AllActionsCancelled(address indexed vault);

    /**
     * @param _refundAddress the adress which the refund amount is sent.
     */
    constructor(
        address _refundAddress
    ) {
        refundAddress = _refundAddress;
    }
    
    /**
    * @notice Executes a relayed transaction.
    * @param _vault The target vault.
    * @param _data The data for the relayed transaction
    * @param _nonce The nonce used to prevent replay attacks.
    * @param _signatures The signatures as a concatenated byte array.
    * @return true if executed or queued successfully, else returns false.
    */
    function execute(
        address _vault,
        bytes calldata _data,
        uint256 _nonce,
        bytes calldata _signatures
    )
        external
        returns (bool)
    {
        // initial gas = 21k + non_zero_bytes * 16 + zero_bytes * 4
        //            ~= 21k + calldata.length * [1/3 * 16 + 2/3 * 4]
        uint256 startGas = gasleft() + 21000 + msg.data.length * 8;
        require(verifyData(_vault, _data), "KR: Target of _data != _vault");

        StackExtension memory stack;
        bool queue;
        bool _refund;
        bool allowed;
        (allowed, queue, _refund, stack.SignatureRequirement) = getRequiredSignatures(_vault, _data);

        require(allowed, "KR: Operation not allowed");

        stack.signHash = getSignHash(
            _vault,
            0,
            _data,
            _nonce
        );

        // Execute a queued tx
        if (isActionQueued(_vault, stack.signHash)){
            require(relayer[_vault].queuedTransactions[stack.signHash] < block.timestamp, "KR: Time not expired");
            (stack.success, stack.returnData) = address(this).call(_data);
            removeQueue(_vault, stack.signHash);
            emit TransactionExecuted(_vault, stack.success, stack.returnData, stack.signHash);
            if(_refund) {
                refund(_vault, startGas);
            } 
            return stack.success;
        }
        
        
        require(validateSignatures(
                _vault, 
                stack.signHash,
                _signatures, 
                stack.SignatureRequirement
            ),
            "KR: Invalid Signatures"
        );

        require(checkAndUpdateUniqueness(_vault, _nonce), "KR: Duplicate request");
        

        // Queue the Tx
        if(queue == true) {
            relayer[_vault].queuedTransactions[stack.signHash] = block.timestamp + Storage.getTimeDelay(_vault);
            relayer[_vault].queue.push(stack.signHash);
            relayer[_vault].arrayindex[stack.signHash] = relayer[_vault].queue.length-1;
            emit TransactionQueued(_vault, block.timestamp + Storage.getTimeDelay(_vault), stack.signHash);
            return true;
        }
         // Execute the tx directly without queuing
        else{
            (stack.success, stack.returnData) = address(this).call(_data); 
            emit TransactionExecuted(_vault, stack.success, stack.returnData, stack.signHash);
            if(_refund) {
                refund(_vault, startGas);
            }
            return stack.success;
        }
    }  

    /**
     * @notice cancels a transaction which was queued.
     * @param _vault The target vault.
     * @param _data The data for the relayed transaction.
     * @param _nonce The nonce used to prevent replay attacks.
     * @param _signature The signature needed to validate cancel.
     */
    function cancel(
        address _vault,
        bytes calldata _data,
        uint256 _nonce,
        bytes memory _signature
    ) 
        external 
    {
        bytes32 _actionHash = getSignHash(_vault, 0, _data, _nonce);
        bytes32 _cancelHash = getSignHash(_vault, 0, "0x", _nonce);
        require(isActionQueued(_vault, _actionHash), "KR: Invalid hash");
        Signature _sig = getCancelRequiredSignatures(_vault, _data);
        require(
            validateSignatures(
                _vault,
                _cancelHash,
                _signature,
                _sig
            ), "KR: Invalid Signatures"
        );
        removeQueue(_vault, _actionHash);
        emit ActionCancelled(_vault);
    }

    /**
     * @notice to cancel all the queued operations for a `_vault` address.
     * @param _vault The target vault.
     */
    function cancelAll(
        address _vault
    ) external onlySelf {
        uint256 len = relayer[_vault].queue.length; 
        for(uint256 i=0;i<len;i++) {
            bytes32 _actionHash = relayer[_vault].queue[i];
            require(isActionQueued(_vault, _actionHash), "KR: Invalid hash");
            relayer[_vault].queuedTransactions[_actionHash] = 0;
            relayer[_vault].arrayindex[_actionHash] = 0;
        }
        delete relayer[_vault].queue;
        emit AllActionsCancelled(_vault);
    }

    /**
    * @notice Gets the current nonce for a vault.
    * @param _vault The target vault.
    * @return nonce gets the last used nonce of the vault.
    */
    function getNonce(address _vault) external view returns (uint256 nonce) {
        return relayer[_vault].nonce;
    }

    /**
    * @notice Gets the number of valid signatures that must be provided to execute a
    * specific relayed transaction.
    * @param _vault The target vault.
    * @param _data The data of the relayed transaction.
    * @return The number of required signatures and the vault owner signature requirement.
    */
    function getRequiredSignatures(address _vault, bytes calldata _data) public view virtual returns (bool, bool, bool, Signature);

    /**
    * @notice checks validity of a signature depending on status of the vault.
    * @param _vault The target vault.
    * @param _actionHash signed hash of the request.
    * @param _data The data of the relayed transaction.
    * @param _option Type of signature.
    * @return true if it is a valid signature.
    */
    function validateSignatures(
        address _vault,
        bytes32 _actionHash,
        bytes memory _data,
        Signature _option
    ) public view virtual returns(bool);

    /**
    * @notice Gets the required signature from {Signature} enum to cancel the request.
    * @param _vault The target vault.
    * @param _data The data of the relayed transaction.
    * @return The required signature from {Signature} enum .
    */ 
    function getCancelRequiredSignatures(
        address _vault,
        bytes calldata _data
    ) public view virtual returns(Signature);

    /**
    * @notice Generates the signed hash of a relayed transaction according to ERC 1077.
    * @param _from The starting address for the relayed transaction (should be the relayer module)
    * @param _value The value for the relayed transaction.
    * @param _data The data for the relayed transaction which includes the vault address.
    * @param _nonce The nonce used to prevent replay attacks.
    */
    function getSignHash(
        address _from,
        uint256 _value,
        bytes memory _data,
        uint256 _nonce
    )
        public
        view
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(
                    bytes1(0x19),
                    bytes1(0),
                    _from,
                    _value,
                    _data,
                    block.chainid,
                    _nonce
                ))
            )
        );
    }

    /**
    * @notice Checks if the relayed transaction is unique. If yes the state is updated.
    * @param _vault The target vault.
    * @param _nonce The nonce.
    * @return true if the transaction is unique.
    */
    function checkAndUpdateUniqueness(
        address _vault,
        uint256 _nonce
    )
        public
        returns (bool)
    {
        // use the incremental nonce
        if (_nonce <= relayer[_vault].nonce) {
            return false;
        }
        uint256 nonceBlock = (_nonce & 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000) >> 128;
        if (nonceBlock > block.number + BLOCKBOUND) {
            return false;
        }
        relayer[_vault].nonce = _nonce;
        return true;
    }
       

    /**
    * @notice Refunds the gas used to the Relayer.
    * @param _vault The target vault.
    * @param _startGas The gas provided at the start of the execution.
    */
    function refund(
        address _vault,
        uint _startGas
    )
        internal
    {
            uint256 refundAmount;
            uint256 gasConsumed = _startGas - gasleft() + 23000;
            refundAmount = gasConsumed * tx.gasprice;
            invokeVault(_vault, refundAddress, refundAmount, EMPTY_BYTES);
            emit Refund(_vault, refundAddress, refundAmount);    
    }

    /**
    * @notice Checks that the vault address provided as the first parameter of _data matches _vault
    * @return false if the addresses are different.
    */
    function verifyData(address _vault, bytes calldata _data) internal pure returns (bool) {
        require(_data.length >= 36, "KR: Invalid dataVault");
        address dataVault = abi.decode(_data[4:], (address));
        return dataVault == _vault;
    }

    /**
    * @notice Check whether a given action is queued.
    * @param _vault The target vault.
    * @param  actionHash  Hash of the action to be checked. 
    * @return Boolean `true` if the underlying action of `actionHash` is queued, otherwise `false`.
    */
    function isActionQueued(
        address _vault,
        bytes32 actionHash
    )
        public
        view
        returns (bool)
    {
        return (relayer[_vault].queuedTransactions[actionHash] > 0);
    }

    /**
    * @notice Return execution time for a given queued action.
    * @param _vault The target vault.
    * @param  actionHash  Hash of the action to be checked.
    * @return uint256   execution time for a given queued action.
    */
    function queuedActionExectionTime(
        address _vault,
        bytes32 actionHash
    )
        external
        view
        returns (uint256)
    {
        return relayer[_vault].queuedTransactions[actionHash];
    }
    
    /**
    * @notice Removes an element at index from the array queue of a user
    * @param _vault The target vault.
    * @param  _actionHash  Hash of the action to be checked.
    * @return false if the index is invalid.
    */
    function removeQueue(address _vault, bytes32 _actionHash) internal returns(bool) {
        RelayerConfig storage _relayer = relayer[_vault];
        _relayer.queuedTransactions[_actionHash] = 0;

        uint256 index = _relayer.arrayindex[_actionHash];
        uint256 len = _relayer.queue.length;
        _relayer.arrayindex[_actionHash] = 0;
        _relayer.queue[index] = _relayer.queue[len - 1];
        _relayer.queue.pop();
        
        return true;
    }
}