// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



contract MultiSig {

    event setupEvent(address[] signers, uint256 threshold);
    event ApproveHash(bytes32 indexed approvedHash, address indexed owner);
    event ExecutionFailure(bytes32 txHash);
    event ExecutionSuccess(bytes32 txHash);
    event signerAddEvent(address signer);
    event signerRemoveEvent(address signer);
    event signerChangedEvent(address oldSigner, address newSigner);
    event thresholdEvent(uint256 threshold);
    event eventAlreadySigned(address indexed signed);


    address[] private _signers;

    // Mapping to keep track of all hashes (message or transaction) that have been approved by ANY signers
    mapping(address => mapping(bytes32 => uint256)) public approvedHashes;

    uint256 internal _threshold;
    uint256 public _nonce;
    bytes32 public _currentHash;

    /**
     * @dev Throws if called by any account other than the this contract address.
     */
    modifier onlyMultiSig() {
        require(msg.sender == address(this), "Only Multisig contract can run this method");
        _;
    }

    constructor () {

    }

    /**
     * @dev setup the multisig contract.
     * @param signers List of signers.
     * @param threshold The minimum required sign for executing a transaction.
     */    
    function setupMultiSig(
        address[] memory signers,
        uint256 threshold
    ) internal {
        require(_threshold == 0, "MS11");
        require(threshold <= signers.length, "MS01");
        require(threshold > 1, "MS02");

        address signer;
        for (uint256 i = 0; i < signers.length; i++) {
            signer = signers[i];
            require(!existSigner(signer), "MS03");
            require(signer != address(0), "MS04");
            require(signer != address(this), "MS05");

            _signers.push(signer);
        }

        _threshold = threshold;
        emit setupEvent(_signers, _threshold);
    }

    /**
     * @dev Allows to execute a Safe transaction confirmed by required number of signers.
     * @param data Data payload of transaction.
     */
    function execTransaction(
        bytes calldata data
    ) external returns (bool success) {
        bytes32 txHash;
        // Use scope here to limit variable lifetime and prevent `stack too deep` errors
        {
            bytes memory txHashData =
            encodeTransactionData(
            // Transaction info
                data,
                _nonce
            );
            // Increase nonce and execute transaction.
            _nonce++;
            _currentHash = 0x0;
            txHash = keccak256(txHashData);
            checkSignatures(txHash);
        }
        // Use scope here to limit variable lifetime and prevent `stack too deep` errors
        {            
            success = execute(data);
            if (success) emit ExecutionSuccess(txHash);
            else emit ExecutionFailure(txHash);
        }
    }

    
    /**
     * @dev Get the current value of nonce
     */
    function getNonce() external view returns (uint256){
        return _nonce;
    }


    /**
     * @dev Execute a transaction
     * @param data the encoded data of the transaction
     */
    function execute(
        bytes memory data
    ) internal returns (bool success) {
        address to = address (this);
        // We require some gas to emit the events (at least 2500) after the execution
        uint256 gasToCall = gasleft() - 2500;
        assembly {
            success := call(gasToCall, to, 0, add(data, 0x20), mload(data), 0, 0)
        }
    }

    
    /**
     * @dev Checks whether the signature provided is valid for the provided data, hash. Will revert otherwise.
     * @param dataHash Hash of the data
     */
    function checkSignatures(bytes32 dataHash) public view {
        uint256 threshold = _threshold;
        // Check that a threshold is set
        require(threshold > 1, "MS02");
        address[] memory alreadySigned = getSignersOfHash(dataHash);

        require(alreadySigned.length >= threshold, "MS06");
    }

    
    /**
     * @dev Return the list of signers for a given hash
     * @param hash Hash of the data
     */
    function getSignersOfHash(
        bytes32 hash
    ) public view returns (address[] memory) {
        uint256 j = 0;
        address[] memory doneSignersTemp = new address[](_signers.length);

        uint256 i;
        address currentSigner;
        for (i = 0; i < _signers.length; i++) {
            currentSigner = _signers[i];
            if (approvedHashes[currentSigner][hash] == 1) {
                doneSignersTemp[j] = currentSigner;
                j++;
            }
        }
        address[] memory doneSigners = new address[](j);
        for (i=0; i < j; i++){
            doneSigners[i] = doneSignersTemp[i];
        }
        return doneSigners;
    }

    /**
     * @dev Marks a hash as approved. This can be used to validate a hash that is used by a signature.
     * @param data Data payload.
     */
    function approveHash(
        bytes calldata data
    ) external {
        require(existSigner(msg.sender), "MS07");

        bytes32 hashToApprove = getTransactionHash(data, _nonce);
        bytes32 hashToCancel = getCancelTransactionHash(_nonce);
        
        if(_currentHash == 0x0) {
            require(hashToApprove != hashToCancel, "MS12");
            _currentHash = hashToApprove;
        }
        else {
            require(_currentHash == hashToApprove || hashToApprove == hashToCancel, "MS13");
        }
        
        approvedHashes[msg.sender][hashToApprove] = 1;
        emit ApproveHash(hashToApprove, msg.sender);
    }


    /**
     * @dev Returns the bytes that are hashed to be signed by owners.
     * @param data Data payload.
     * @param nonce Transaction nonce.
     */    
    function encodeTransactionData(
        bytes calldata data,
        uint256 nonce
    ) public pure returns (bytes memory) {
        bytes32 safeTxHash =
        keccak256(
            abi.encode(
                keccak256(data),
                nonce
            )
        );
        return abi.encodePacked(safeTxHash);
    }

    function encodeCancelTransactionData(
        uint256 nonce
    ) public pure returns (bytes memory) {
        bytes32 safeTxHash =
        keccak256(
            abi.encode(
                keccak256(""),
                nonce
            )
        );
        return abi.encodePacked(safeTxHash);
    }

    /**
     * @dev Returns hash to be signed by owners.
     * @param data Data payload.
     */
    function getTransactionHash(
        bytes calldata data,
        uint256 nonce
    ) public pure returns (bytes32) {
        return keccak256(encodeTransactionData(data, nonce));
    }

    function getCancelTransactionHash(
        uint256 nonce
    ) public pure returns (bytes32) {
        return keccak256(encodeCancelTransactionData(nonce));
    }

    
    /**
     * @dev Check if a given address is a signer or not.
     * @param signer signer address.     
     */
    function existSigner(
        address signer
    ) public view returns (bool) {
        for (uint256 i = 0; i < _signers.length; i++) {
            address signerI = _signers[i];
            if (signerI == signer) {
                return true;
            }
        }
        return false;
    }

    
    /**
     * @dev Get the list of all signers.     
     */
    function getSigners() external view returns (address[] memory ) {
        address[] memory ret = new address[](_signers.length) ;
        for (uint256 i = 0; i < _signers.length; i++) {
            ret[i] = _signers[i];
        }
        return ret;
    }

    
    /**
     * @dev Set a new threshold for signing.
     * @param threshold the minimum required signatures for executing a transaction.     
     */
    function setThreshold(
        uint256 threshold
    ) public onlyMultiSig{
        require(threshold <= _signers.length, "MS01");
        require(threshold > 1, "MS02");
        _threshold = threshold;
        emit thresholdEvent(threshold);
    }

    
    /**
     * @dev Get threshold value.
     */
    function getThreshold() external view returns(uint256) {
        return _threshold;
    }

    
    /**
     * @dev Add a new signer and new threshold.
     * @param signer new signer address.   
     * @param threshold new threshold  
     */
    function addSigner(
        address signer,
        uint256 threshold
    ) external onlyMultiSig{
        require(!existSigner(signer), "MS03");
        require(signer != address(0), "MS04");
        require(signer != address(this), "MS05");
        _signers.push(signer);
        emit signerAddEvent(signer);
        setThreshold(threshold);
    }


    /**
     * @dev Remove an old signer
     * @param signer an old signer.     
     * @param threshold new threshold
     */
    function removeSigner(
        address signer,
        uint256 threshold
    ) external onlyMultiSig{
        require(existSigner(signer), "MS07");
        require(_signers.length - 1 > 1, "MS09");
        require(_signers.length - 1 >= threshold, "MS10");
        require(signer != address(0), "MS04");
 
        for (uint256 i = 0; i < _signers.length - 1; i++) {
            if (_signers[i] == signer) {
                _signers[i] = _signers[_signers.length - 1];
                break;
            }
        }
        
        _signers.pop();
        emit signerRemoveEvent(signer);
        setThreshold(threshold);
    }

    
    /**
     * @dev Replace an old signer with a new one
     * @param oldSigner old signer.     
     * @param newSigner new signer
     */
    function changeSigner(
        address oldSigner,
        address newSigner
    ) external onlyMultiSig{
        require(existSigner(oldSigner), "MS07");
        require(!existSigner(newSigner), "MS03");
        require(newSigner != address(0), "MS04");
        require(newSigner != address(this), "MS05");
        
        for (uint256 i = 0; i < _signers.length; i++) {
            if (_signers[i] == oldSigner) {
                _signers[i] = newSigner;
                break;
            }
        }

        emit signerChangedEvent(oldSigner, newSigner);
    }

}