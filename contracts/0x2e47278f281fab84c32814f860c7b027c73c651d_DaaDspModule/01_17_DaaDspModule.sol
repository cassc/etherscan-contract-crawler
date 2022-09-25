// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import "./utils/Enum.sol";
import "./utils/SignatureDecoder.sol";
import "./utils/CompatibilityFallbackHandler.sol";
import "./utils/DFSCompatibility.sol";
import "./utils/CoWCompatibility.sol";
import "../interfaces/IERC20Minimal.sol";
import "../interfaces/IGnosisSafe.sol";
import "../interfaces/IRecipeContainer.sol";
import "../interfaces/ISignatureValidator.sol";
import "../interfaces/IWhitelistRegistry.sol";


/// @title DAA DSP Module - A gnosis safe module to execute whitelisted transactions to a DSP.


contract DaaDspModule is 
    SignatureDecoder,
    ISignatureValidator,
    CompatibilityFallbackHandler
{
    IGnosisSafe public safe;
    IDSProxy public account;
    IProxyRegistry registry;    // dsp proxy registry
    IWhitelistRegistry wl;  // daa whitelist 
    IRecipeContainer rc;    // daa recipe container
    // DFS Contracts
    address dfsRegistryAddress; 
    address recipeExecutor;
    // chain native token
    address native = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; 
    
    uint256 public nonce;
    uint256 internal threshold = 2;
    string public constant name = "DAA DSP Module";
    string public constant version  = "1";
    bool public initialized;

    // --- EIP712 ---
    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 private constant MODULE_TX_TYPEHASH = keccak256("ModuleTx(address _targetAddress,bytes calldata _data,uint256 _nonce)");
    bytes32 private constant MODULE_TX_TYPEHASH = 0xc5d6711dec9859198fc49821812819142651b1ae455a02ffb30a9452b98b011a;

    // Mapping to keep track of all hashes (message or transaction) that have been approved by ANY owners
    mapping(address => mapping(bytes32 => uint256)) public approvedHashes;


    event AccountCreated(address dspAccount);
    event ApproveHash(bytes32 indexed approvedHash, address indexed owner);
    event TransactionExecuted(bytes32 txHash);

    constructor(){}

    /// @dev Create a DSP account for the module.
    /// @param _safe Safe address.
    /// @param _index Address of the Instadapp index contract.
    function initialize(IGnosisSafe _safe, IProxyRegistry _index, IWhitelistRegistry _wl, IRecipeContainer _rc) external {
        require(!initialized, "Already initialized"); 
        safe = _safe;
        registry = IProxyRegistry(_index); 
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            block.chainid,
            address(this)
        ));
        createAccount(address(this));
        (recipeExecutor,dfsRegistryAddress) = registerDFS();
        wl = _wl; rc = _rc;
        initialized = true;
    }

    /// @dev Execute transaction on DSP.
    /// @param _targetAddress DSP transaction target names.
    /// @param _data DSP transaction data.
    /// @param signatures Owners transaction signatures.
    function executeTransaction(
        address _targetAddress,
        bytes calldata _data,
        bytes memory signatures
    ) 
        external
    {
        require(isAuthorized(msg.sender));
        require(address(account) != address(0), "DSP not created");
        bytes32 txHash;
        bytes memory txHashData =
            encodeTransactionData(
                _targetAddress,
                _data,
                nonce
            );
        txHash = getTransactionHash(_targetAddress,_data,nonce);
        // Increase nonce and prep transaction.
        nonce++;
        checkSignatures(txHash, txHashData, signatures);
        (address[] memory tokenAddress, uint[] memory amount) = this.getConnectorData(_targetAddress, _data);
        prepFunds(tokenAddress, amount);
        // execute transaction
        execute(_targetAddress,_data);
        emit TransactionExecuted(txHash);
    }

    /// @dev Execute recipe transaction on DSP.
    /// @param recipeId The id of the recipe to execute.
    /// @param signatures Owners transaction signatures.
    function executeRecipe(
        uint256 recipeId,
        bytes memory signatures
    ) external {
        require(isAuthorized(msg.sender));
        require(address(account) != address(0), "DSP not created");
        
        bytes memory _data = getRecipeTxData(recipeId);
        address _targetAddress = recipeExecutor;

        bytes32 txHash;
        bytes memory txHashData =
            encodeTransactionData(
                _targetAddress,
                _data,
                nonce
            );
        txHash = getTransactionHash(_targetAddress,_data,nonce);
        // Increase nonce and prep transaction.
        nonce++;
        checkSignatures(txHash, txHashData, signatures);
        (address[] memory tokenAddress, uint[] memory amount) = this.getConnectorData(_targetAddress, _data);
        prepFunds(tokenAddress, amount);
        // execute transaction
        execute(_targetAddress,_data);
        emit TransactionExecuted(txHash);
    }

    /// @dev Execute batch transaction on DSP via CowSwap.
    /// @param _targetAddress DSP transaction target names.
    /// @param _data DSP transaction data.
    /// @param signatures Owners transaction signatures.
    function executeBatch(
        address _targetAddress,
        bytes calldata _data,
        bytes memory signatures
    ) 
        external
    {
        require(isAuthorized(msg.sender));
        require(address(account) != address(0), "DSP not created");
        bytes32 txHash;
        bytes memory txHashData =
            encodeTransactionData(
                _targetAddress,
                _data,
                nonce
            );
        txHash = getTransactionHash(_targetAddress,_data,nonce);
        // Increase nonce and prep transaction.
        nonce++;
        checkSignatures(txHash, txHashData, signatures);
        // specific target and data checks for CoW batch
        checkBatchTx(_targetAddress,_data);
        // execute transaction
        execute(_targetAddress,_data);
        emit TransactionExecuted(txHash);
    }

    /// @dev Marks a hash as approved. This can be used to validate a hash that is used by a signature.
    /// @param hashToApprove The hash that should be marked as approved for signatures that are verified by this contract.
    function approveHash(bytes32 hashToApprove) 
        external 
    {
        require(isAuthorized(msg.sender));
        approvedHashes[msg.sender][hashToApprove] = 1;
        emit ApproveHash(hashToApprove, msg.sender);
    }

    // @dev Allow to deposit assets from the Safe to the Smart Wallet
    function depositToWallet(
        address[] memory  tokenAddress, 
        uint[] memory amount
        ) 
        external 
        {
        require(isAuthorized(msg.sender));
        uint len = tokenAddress.length;
        for (uint i=0; i < len; i++){
            if (amount[i] > 0){
                pullFromSafe(tokenAddress[i],amount[i]);
                IERC20Minimal(tokenAddress[i]).transfer(address(account),amount[i]);
            }
        }
    }

    function checkBatchTx(
        address target,
        bytes calldata data
    )
        internal
        view
    {
        require(target == batchExecutor, "BatchTgtNotAuth");
        require(bytes4(data[:4]) == bytes4(0x7bc6f593),"BatchFuncNotAuth");
    }

    /// @dev Checks whether the signature provided is valid for the provided data, hash. Will revert otherwise.
    /// @param dataHash Hash of the data (could be either a message hash or transaction hash)
    /// @param data That should be signed (this is passed to an external validator contract)
    /// @param signatures Signature data that should be verified. Can be ECDSA signature, contract signature (EIP-1271) or approved hash.
    function checkSignatures(
        bytes32 dataHash,
        bytes memory data,
        bytes memory signatures
    ) public view {
        // Load threshold to avoid multiple storage loads
        uint256 _threshold = threshold;
        // Check that a threshold is set
        require(_threshold > 0, "Threshold not set.");
        checkNSignatures(dataHash, data, signatures, _threshold);
    }

    /// @dev Checks whether the signature provided is valid for the provided data, hash. Will revert otherwise.
    /// @param dataHash Hash of the data (could be either a message hash or transaction hash)
    /// @param data That should be signed (this is passed to an external validator contract)
    /// @param signatures Signature data that should be verified. Can be ECDSA signature, contract signature (EIP-1271) or approved hash.
    /// @param requiredSignatures Amount of required valid signatures.
    function checkNSignatures(
        bytes32 dataHash,
        bytes memory data,
        bytes memory signatures,
        uint256 requiredSignatures
    ) public view {
        // Check that the provided signature data is not too short
        require(signatures.length >= requiredSignatures*65, "GS020");
        // There cannot be an owner with address 0.
        address lastOwner = address(0);
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for (i = 0; i < requiredSignatures; i++) {
            (v, r, s) = signatureSplit(signatures, i);
            if (v == 0) {
                // If v is 0 then it is a contract signature
                // When handling contract signatures the address of the contract is encoded into r
                currentOwner = address(uint160(uint256(r)));

                // Check that signature data pointer (s) is not pointing inside the static part of the signatures bytes
                // This check is not completely accurate, since it is possible that more signatures than the threshold are send.
                // Here we only check that the pointer is not pointing inside the part that is being processed
                require(uint256(s) >= requiredSignatures*65, "GS021");

                // Check that signature data pointer (s) is in bounds (points to the length of data -> 32 bytes)
                require(uint256(s)+(32) <= signatures.length, "GS022");

                // Check if the contract signature is in bounds: start of data is s + 32 and end is start + signature length
                uint256 contractSignatureLen;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    contractSignatureLen := mload(add(add(signatures, s), 0x20))
                }
                require(uint256(s)+(32)+(contractSignatureLen) <= signatures.length, "GS023");

                // Check signature
                bytes memory contractSignature;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    // The signature data for contract signatures is appended to the concatenated signatures and the offset is stored in s
                    contractSignature := add(add(signatures, s), 0x20)
                }
                require(ISignatureValidator(currentOwner).isValidSignature(data, contractSignature) == EIP1271_MAGIC_VALUE, "GS024");
            } else if (v == 1) {
                // If v is 1 then it is an approved hash
                // When handling approved hashes the address of the approver is encoded into r
                currentOwner = address(uint160(uint256(r)));
                // Hashes are automatically approved by the sender of the message or when they have been pre-approved via a separate transaction
                require(msg.sender == currentOwner || approvedHashes[currentOwner][dataHash] != 0, "GS025");
            } else if (v > 30) {
                // If v > 30 then default va (27,28) has been adjusted for eth_sign flow
                // To support eth_sign and similar we adjust v and hash the messageHash with the Ethereum message prefix before applying ecrecover
                currentOwner = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v - 4, r, s);
            } else {
                // Default is the ecrecover flow with the provided data hash
                // Use ecrecover with the messageHash for EOA signatures
                currentOwner = ecrecover(dataHash, v, r, s);
            }
            require(currentOwner > lastOwner && isAuthorized(currentOwner) && currentOwner != address(0x1), "GS026");
            lastOwner = currentOwner;
        }
    }

    /// @dev Returns hash to be signed by owners.
    /// @param _targetAddress DSP transaction target names.
    /// @param _data DSP transaction data.
    /// @param _nonce Transaction nonce.
    function getTransactionHash(
        address _targetAddress,
        bytes memory _data,
        uint256 _nonce
    ) 
        public 
        view 
        returns (bytes32) 
    {
        return keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        MODULE_TX_TYPEHASH,
                        _targetAddress,
                        _data,
                        _nonce))
                ));
    }

    /// @dev Returns hash to be signed by owners.
    /// @param recipeId The id of the recipe to execute.
    /// @param _nonce Transaction nonce.
    function getRecipeTransactionHash(
        uint256 recipeId,
        uint256 _nonce
    ) 
        public 
        view 
        returns (bytes32) 
    {
        bytes memory _data = getRecipeTxData(recipeId);
        address _targetAddress = recipeExecutor;
        return keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        MODULE_TX_TYPEHASH,
                        _targetAddress,
                        _data,
                        _nonce))
                ));
    }

    /// @dev Returns the bytes that are hashed to be signed by owners.
    /// @param _targetAddress DSP transaction target names.
    /// @param _data DSP transaction data.
    /// @param _nonce Transaction nonce.
    function encodeTransactionData(
        address _targetAddress,
        bytes memory _data,
        uint256 _nonce
    ) 
        public 
        view 
        returns (bytes memory) 
    {
        return abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        MODULE_TX_TYPEHASH,
                        _targetAddress,
                        _data,
                        _nonce))
                );
    }

    function domainSeparator() public view returns (bytes32) {
        return DOMAIN_SEPARATOR;
    }

    function getAccount() public view returns (address) {
        return address(account);
    }

    /// @dev Allows to decode the transaction data for safety checks, and to prepare the token amount to be pulled from the Safe. 
    /// @param target Tx target.
    /// @param data Contains the transaction data to be digested by the RecipeExecutor.
    function getConnectorData(
        address target,
        bytes calldata data
    ) 
        public 
        view 
        returns 
        (
            address[] memory addrList,
            uint[] memory amtList
        ) 
    {
        whitelistedOpCheck(target,data);
        if (bytes4(data[:4]) == bytes4(0x0c2c8750)) {
            Recipe memory recipe = abi.decode(data[4:], (Recipe));
            IRegistry dfsRegistry = IRegistry(dfsRegistryAddress);  
            bytes4 actionId = 0xcc063de4;
            uint len = recipe.actionIds.length;
            addrList = new address[](len);
            amtList = new uint[](len);
            for (uint i=0; i < len; i++){
                if (keccak256(abi.encodePacked(recipe.actionIds[i])) == keccak256(abi.encodePacked(actionId))){
                    address conn = dfsRegistry.getAddr(recipe.actionIds[i]);
                    ParamsPull memory params = IPullAction(conn).parseInputs(recipe.callData[i]);
                    if (params.from == address(this)){
                        addrList[i] = params.tokenAddr;
                        amtList[i] = params.amount;
                    }
                }
            }
        }
    }

    /// @dev Create a DSP account for the module.
    /// @param owner The owner of the smart wallet
    function createAccount(address owner)
        internal 
        returns (IDSProxy proxy)
    {
        require(address(account) == address(0), "DSP already created");
        account = registry.build(owner); 
        emit AccountCreated(address(account));
        return account;
    }

    function prepFunds(address[] memory  tokenAddress, uint[] memory amount) internal {
        uint len = tokenAddress.length;
        for (uint i=0; i < len; i++){
            if (amount[i] > 0){
                pullFromSafe(tokenAddress[i],amount[i]);
                IERC20Minimal(tokenAddress[i]).approve(address(account),amount[i]);
            }
        }
    }

    function whitelistedOpCheck(address target, bytes calldata data) internal view {
        _targetCheck(target,data);
        if (bytes4(data[:4]) != bytes4(0x389f87ff)) {
            _operationsCheck(target,data);
        }
    }

    ///  @dev make sure it is using DefiSaver contracts.
    ///  function is either executeRecipe(0x0c2c8750) or executeActionDirect(0x389f87ff)
    ///  target can be only recipeExecutor or only contract from allowed actionId (directSwap) and present into dfsRegistry.
    function _targetCheck(address target,bytes calldata data) internal view {
        require(bytes4(data[:4]) == bytes4(0x0c2c8750) || bytes4(data[:4]) == bytes4(0x389f87ff) ,"FuncNotAuth");
        if (bytes4(data[:4]) == bytes4(0x0c2c8750)){
            require(keccak256(abi.encodePacked(target)) == keccak256(abi.encodePacked(recipeExecutor)) ,"TgtNoAuth");
        } else if (bytes4(data[:4]) == bytes4(0x389f87ff)) {
            require(isWhitelistedTarget(target, data), "TgtNoAuth");
        }
    }

    function isWhitelistedTarget(address target,bytes calldata data) internal view returns (bool) {
        require(target != address(account), "NoProxyTgt");
        if (keccak256(abi.encodePacked(target)) == keccak256(abi.encodePacked(IRegistry(dfsRegistryAddress).getAddr((bytes4(0x02abc227))))) ||   // SendToken
            keccak256(abi.encodePacked(target)) == keccak256(abi.encodePacked(IRegistry(dfsRegistryAddress).getAddr((bytes4(0x17782156)))))      //SendTokenAndUnwrap
        ){
            ParamsSend memory params = abi.decode(data, (ParamsSend));
            require(params.to == address(safe) || params.to == address(account), "NoExtTransfer");
        }
        return(wl.isTargetWhitelisted(target));
    }

    ///  @dev Tokens can only be transferred back to the safe or to the smart wallet
    function _operationsCheck(address target, bytes calldata data) internal view returns (bool check){
        Recipe memory recipe = abi.decode(data[4:], (Recipe));
        uint len = recipe.actionIds.length;
        check = true;
        for (uint256 i = 0; i < len; i++) {
            if (keccak256(abi.encodePacked(recipe.actionIds[i])) == keccak256(abi.encodePacked(bytes4(0x02abc227))) ||  // SendToken
                keccak256(abi.encodePacked(recipe.actionIds[i])) == keccak256(abi.encodePacked(bytes4(0x17782156)))     // SendTokenAndUnwrap
            ){
                address conn = IRegistry(dfsRegistryAddress).getAddr(recipe.actionIds[i]);
                ParamsSend memory params = ISendAction(conn).parseInputs(recipe.callData[i]);
                require(params.to == address(safe) || params.to == address(account), "NoExtTransfer");
            }
            if (!wl.isActionWhitelisted(recipe.actionIds[i])) {
                check = false;
            }
        }
        require(check, "OpNotAuth");
    }

    /// @dev Leverage the Safe module functionaliity to pull the tokens required for the DSP transaction.
    /// @param token Address of the token to transfer.
    /// @param amount Number of tokens,
    function pullFromSafe(address token, uint amount) private {
        if (token == native) {
            // solium-disable-next-line security/no-send
            require(safe.execTransactionFromModule(address(this), amount, "", Enum.Operation.Call), "Could not execute ether transfer");
        } else {
            bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", address(this), amount);
            require(safe.execTransactionFromModule(token, 0, data, Enum.Operation.Call), "Could not execute token transfer");
        }
    }

    function execute(address _target, bytes memory _data) private {
        IDSProxy(account).execute(_target, _data);
    }

    function getRecipeTxData(uint recipeId) internal view returns (bytes memory _data){
        Recipe memory recipe = rc.getRecipe(recipeId);
        _data = abi.encodeWithSignature("executeRecipe((string,bytes[],bytes32[],bytes4[],uint8[][]))", recipe);
    }

    function isAuthorized(address sender) internal view returns (bool isOwner) {
        address[] memory _owners = safe.getOwners();
        uint256 len = _owners.length;
        for (uint256 i = 0; i < len; i++) {
            if (_owners[i]==sender) { isOwner = true;}
        }
        require(isOwner, "Sender not authorized");
    }

}