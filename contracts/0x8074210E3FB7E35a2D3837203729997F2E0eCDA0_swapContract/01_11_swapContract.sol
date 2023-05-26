// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./TransferHelper.sol";

/// @title Swap contract for simple bridge
contract swapContract is AccessControlEnumerable, Pausable
{

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    IERC20 public tokenAddress;
    address public feeAddress;

    uint128 public numOfThisBlockchain;
    mapping(uint128 => bool) public existingOtherBlockchain;
    mapping(uint128 => uint128) public feeAmountOfBlockchain;

    mapping(bytes32 => bool) public processedTransactions;
    
    uint256 public minTokenAmount;
    uint256 public maxGasPrice;
    

    event TransferFromOtherBlockchain(address user, uint256 amount, uint256 amountWithoutFee, bytes32 originalTxHash);
    event TransferToOtherBlockchain(uint128 blockchain, address user, uint256 amount, string newAddress);
    event FeeAmountOfBlockchainChanged(uint128 blockchain, uint256 amount);
    event MinTokenAmountChanged(uint256 amount);
    event MaxGasPriceChanged(uint256 gasPrice);
    event OtherBlockchainChanged(uint128 oldNum, uint128 newNum);
    event OtherBlockchainRemoved(uint128 blockchain);
    event OtherBlockchainAdded(uint128 blockchain);
    event FeeAddressChanged(address newFeeAddress);
    

    /** 
      * @dev throws if transaction sender is not in owner role
    */  
    modifier onlyOwner() {
        require(
            hasRole(OWNER_ROLE, _msgSender()),
            "Caller is not in owner role"
        );
        _;
    }

    /** 
      * @dev throws if transaction sender is not in owner or manager role
      */
    modifier onlyOwnerAndManager() {
        require(
            hasRole(OWNER_ROLE, _msgSender()) || hasRole(MANAGER_ROLE, _msgSender()),
            "Caller is not in owner or manager role"
        );
        _;
    }

    /** 
      * @dev Constructor of contract
      * @param _tokenAddress address Address of token contract
      * @param _feeAddress Address to receive deducted fees
      * @param _numOfThisBlockchain Number of blockchain where contract is deployed
      * @param _numsOfOtherBlockchains List of blockchain number that is supported by bridge
      * @param _minTokenAmount Minimal amount of tokens required for token swap
      * @param _maxGasPrice Maximum gas price on which relayer nodes will operate
      */
    constructor(
        IERC20 _tokenAddress,
        address _feeAddress,
        uint128 _numOfThisBlockchain,
        uint128 [] memory _numsOfOtherBlockchains,
        uint256 _minTokenAmount,
        uint256 _maxGasPrice
        
        )
    {
        tokenAddress = _tokenAddress;
        feeAddress = _feeAddress;
        for (uint i = 0; i < _numsOfOtherBlockchains.length; i++ ) {
            require(
                _numsOfOtherBlockchains[i] != _numOfThisBlockchain,
                "swapContract: Number of this blockchain is in array of other blockchains"
            );
            existingOtherBlockchain[_numsOfOtherBlockchains[i]] = true;
        }

        require(_maxGasPrice > 0, "swapContract: Gas price cannot be zero");
        
        numOfThisBlockchain = _numOfThisBlockchain;
        minTokenAmount = _minTokenAmount;
        maxGasPrice = _maxGasPrice;
        
        
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OWNER_ROLE, _msgSender());
    }

    /** 
      * @dev Returns true if blockchain of passed id is registered to swap
      * @param blockchain number of blockchain
      */
    function getOtherBlockchainAvailableByNum(uint128 blockchain) external view returns (bool)
    {
        return existingOtherBlockchain[blockchain];
    }

    /** 
      * @dev Transfers tokens from sender to the contract. 
      * User calls this function when he wants to transfer tokens to another blockchain.
      * @param blockchain Number of blockchain
      * @param amount Amount of tokens
      * @param newAddress Address in the blockchain to which the user wants to transfer
      */
    function transferToOtherBlockchain(uint128 blockchain, uint256 amount, string memory newAddress) external whenNotPaused
    {
        require( 
            amount >= minTokenAmount,
            "swapContract: Less than required minimum of tokens requested"
        );
        require(
            bytes(newAddress).length > 0,
            "swapContract: No destination address provided"
        );
        require(
            existingOtherBlockchain[blockchain] && blockchain != numOfThisBlockchain,
            "swapContract: Wrong choose of blockchain"
        );
        require(
            amount >= feeAmountOfBlockchain[blockchain],
            "swapContract: Not enough amount of tokens"
        );
        address sender = _msgSender();
        require(
            tokenAddress.balanceOf(sender) >= amount,
            "swapContract: Not enough balance"
        );
        TransferHelper.safeTransferFrom(address(tokenAddress), sender, address(this), amount);
        emit TransferToOtherBlockchain(blockchain, sender, amount, newAddress);
    }
    
    /** 
      * @dev Transfers tokens to end user in current blockchain (without fees)
      * @param user User address
      * @param amount Amount of tokens
      */
    function transferToUserWithoutFee(address user, uint256 amount) external onlyOwner whenNotPaused
    {
        TransferHelper.safeTransfer(address(tokenAddress), user, amount);
        emit TransferFromOtherBlockchain(user, amount, amount, bytes32(0));
    }

    /** 
      * @dev Transfers tokens to end user in current blockchain 
      * @param user User address
      * @param amountWithFee Amount of tokens with included fees
      * @param originalTxHash Hash of transaction from other network, on which swap was called
      */
    function transferToUserWithFee(
        address user,
        uint256 amountWithFee,
        bytes32 originalTxHash
    )
        external
        onlyOwner
        whenNotPaused
    {
        require(!isProcessedTransaction(originalTxHash), "swapContract: Transaction already processed");
        processedTransactions[originalTxHash] = true;
        uint256 fee = feeAmountOfBlockchain[numOfThisBlockchain];
        uint256 amountWithoutFee = amountWithFee - fee;
        TransferHelper.safeTransfer(address(tokenAddress), user, amountWithoutFee);
        TransferHelper.safeTransfer(address(tokenAddress), feeAddress, fee);
        emit TransferFromOtherBlockchain(user, amountWithFee, amountWithoutFee, originalTxHash);
    }

    // OTHER BLOCKCHAIN MANAGEMENT

    
    /** 
      * @dev Registers another blockchain for availability to swap
      * @param numOfOtherBlockchain number of blockchain
      */
    function addOtherBlockchain(
        uint128 numOfOtherBlockchain
    )
        external
        onlyOwner
    {
        require(
            numOfOtherBlockchain != numOfThisBlockchain,
            "swapContract: Cannot add this blockchain to array of other blockchains"
        );
        require(
            !existingOtherBlockchain[numOfOtherBlockchain],
            "swapContract: This blockchain is already added"
        );
        existingOtherBlockchain[numOfOtherBlockchain] = true;
        emit OtherBlockchainAdded(numOfOtherBlockchain);
    }

    /** 
      * @dev Unregisters another blockchain for availability to swap
      * @param numOfOtherBlockchain number of blockchain
      */
    function removeOtherBlockchain(
        uint128 numOfOtherBlockchain
    )
        external
        onlyOwner
    {
        require(
            existingOtherBlockchain[numOfOtherBlockchain],
            "swapContract: This blockchain was not added"
        );
        existingOtherBlockchain[numOfOtherBlockchain] = false;
        emit OtherBlockchainRemoved(numOfOtherBlockchain);
    }

    /** 
      * @dev Change existing blockchain id
      * @param oldNumOfOtherBlockchain number of existing blockchain
      * @param newNumOfOtherBlockchain number of new blockchain
      */
    function changeOtherBlockchain(
        uint128 oldNumOfOtherBlockchain,
        uint128 newNumOfOtherBlockchain
    )
        external
        onlyOwner
    {
        require(
            oldNumOfOtherBlockchain != newNumOfOtherBlockchain,
            "swapContract: Cannot change blockchains with same number"
        );
        require(
            newNumOfOtherBlockchain != numOfThisBlockchain,
            "swapContract: Cannot add this blockchain to array of other blockchains"
        );
        require(
            existingOtherBlockchain[oldNumOfOtherBlockchain],
            "swapContract: This blockchain was not added"
        );
        require(
            !existingOtherBlockchain[newNumOfOtherBlockchain],
            "swapContract: This blockchain is already added"
        );
        
        existingOtherBlockchain[oldNumOfOtherBlockchain] = false;
        existingOtherBlockchain[newNumOfOtherBlockchain] = true;
        emit OtherBlockchainChanged(oldNumOfOtherBlockchain, newNumOfOtherBlockchain);
    }


    // FEE MANAGEMENT

    /** 
      * @dev Changes address which receives fees from transfers
      * @param newFeeAddress New address for fees
      */
    function changeFeeAddress(address newFeeAddress) external onlyOwner
    {
        require(newFeeAddress != address(0x0), "swapContract: Fee address cannot be zero address");
        feeAddress = newFeeAddress;
        emit FeeAddressChanged(newFeeAddress);
    }

    /** 
      * @dev Changes fee values for blockchains in feeAmountOfBlockchain variables
      * @param blockchainNum Existing number of blockchain
      * @param feeAmount Fee amount to substruct from transfer amount
      */
    function setFeeAmountOfBlockchain(uint128 blockchainNum, uint128 feeAmount) external onlyOwnerAndManager
    {
        feeAmountOfBlockchain[blockchainNum] = feeAmount;
        emit FeeAmountOfBlockchainChanged(blockchainNum, feeAmount);
    }

    /** 
      * @dev Changes requirement for minimal token amount on transfers
      * @param _minTokenAmount Amount of tokens
      */
    function setMinTokenAmount(uint256 _minTokenAmount) external onlyOwnerAndManager {
        minTokenAmount = _minTokenAmount;
        emit MinTokenAmountChanged(_minTokenAmount);
    }

    /** 
      * @dev Changes parameter of maximum gas price on which relayer nodes will operate
      * @param _maxGasPrice Price of gas in wei
      */
    function setMaxGasPrice(uint256 _maxGasPrice) external onlyOwnerAndManager {
        require(_maxGasPrice > 0, "swapContract: Gas price cannot be zero");
        maxGasPrice = _maxGasPrice;
        emit MaxGasPriceChanged(_maxGasPrice);
    }


    

    

    function transferOwnerAndSetManager(address newOwner, address newManager) external onlyOwner {
        require(newOwner != address(0x0), "swapContract: Owner cannot be zero address");
        require(newManager != address(0x0), "swapContract: Manager cannot be zero address");
        require(!hasRole(OWNER_ROLE, newOwner), "swapContract: New owner cannot be current owner");
        require(!hasRole(DEFAULT_ADMIN_ROLE, newOwner), "swapContract: New owner cannot be current default admin role");
        require(!hasRole(MANAGER_ROLE, newManager), "swapContract: New manager cannot be current manager role");
        _setupRole(DEFAULT_ADMIN_ROLE, newOwner);
        _setupRole(OWNER_ROLE, newOwner);
        _setupRole(MANAGER_ROLE, newManager);
        renounceRole(OWNER_ROLE, _msgSender());
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /** 
      * @dev Pauses transfers of tokens on contract
      */
    function pauseExecution() external onlyOwner {
        _pause();
    }

    /** 
      * @dev Resumes transfers of tokens on contract
      */
    function continueExecution() external onlyOwner {
        _unpause();
    }

    /** 
      * @dev Function to check if address is belongs to owner role
      * @param account Address to check
      */
    function isOwner(address account) external view returns (bool) {
        return hasRole(OWNER_ROLE, account);
    }

    /** 
      * @dev Function to check if address is belongs to manager role
      * @param account Address to check
      */
    function isManager(address account) external view returns (bool) {
        return hasRole(MANAGER_ROLE, account);
    }
    
    /** 
      * @dev Function to check if transfer of tokens on previous
      * transaction from other blockchain was executed
      * @param originalTxHash Transaction hash to check
      */
    function isProcessedTransaction(bytes32 originalTxHash) public view returns (bool processed) {
        return processedTransactions[originalTxHash];
    }
}