// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "IERC20.sol";
import "AccessControlEnumerable.sol";
import "ECDSA.sol";
import "TransferHelper.sol";

contract TokenClaim is AccessControlEnumerable {
    
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    IERC20 public tokenAddress;

    mapping(address => uint256) public claimedBalanceOf;
    mapping(bytes32 => bool) public processedTransactions;
    
    uint256 internal claimedAmount;

    event TokensClaimed(
        address indexed userAddress,
        uint256 tokenAmount,
        uint256 indexed timestamp
    );

    event TokensDeposited(
        address indexed userAddress,
        uint256 tokenAmount
    );

    event TokensWithdrawn(
        address indexed userAddress,
        uint256 tokenAmount
    );

    event TokenAddressChanged(
        address tokenAddress
    );

     /**
      * @dev throws if transaction sender is not in owner role
      */
    modifier onlyOwner() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Caller is not in owner role"
        );
        _;
    }

    constructor(IERC20 _token, address _signerAddress) {
        tokenAddress =  _token;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(SIGNER_ROLE, _signerAddress);
    }

    /**
      * @dev Function to get total amount of claimed tokens
      */
    function getCurrentClaimedAmount()
        external
        view
        returns (uint256)
    {
        return claimedAmount;
    }
    
    /**
      * @dev Function to deposit  tokens on contract
      * @param amount Tokens amount
      */
    function depositToken(uint256 amount)
        external
    {
        require(amount > 0, "Amount = 0");

        TransferHelper.safeTransferFrom(address(tokenAddress), _msgSender(), address(this), amount);
        emit TokensDeposited(_msgSender(), amount);
    }

    /**
      * @dev Function to withdraw tokens from contract
      * @param amount Tokens amount
      */
    function withdrawToken(uint256 amount) 
        external
        onlyOwner
    {
        require(amount > 0, "Amount = 0");

        TransferHelper.safeTransfer(address(tokenAddress), _msgSender(), amount);

        emit TokensWithdrawn(_msgSender(), amount);
    }
    
    /**
      * @dev Function to set new token address
      * @param _newTokenAddress Address of new token
      */
    function setNewToken(IERC20 _newTokenAddress)
        external
        onlyOwner
    {
        require (address(_newTokenAddress) != address(0), "TokenClaim: Cannot set to zero address");
        tokenAddress = _newTokenAddress;
        emit TokenAddressChanged(address(tokenAddress));
    }

    /**
      * @dev Function to get Keccak hash of parameters
      * @param account User address
      */
    function getHashPacked(address account, uint256 amount, uint256 timestamp) public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, amount, timestamp));
    }
    
    /**
      * @dev Function to checks that address is in signer role
      * @param account User address
      */
    function isSigner(address account) public view returns (bool) {
        return hasRole(SIGNER_ROLE, account);
    }
    
    /**
      * @dev Function to checks that address is in owner role
      * @param account User address
    */
    function isOwner(address account) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
      * @dev Function to check that parameters was already processed
      * @param account User address
      * @param amount Tokens amount
      * @param timestamp Timestamp to release tokens
      * @return isProcessed True if transaction is already processed
      * @return hashedParams Keccak hash of parameters
      */
    function isProcessedTransaction(address account, uint256 amount, uint256  timestamp)
        public
        view
        returns (bool isProcessed, bytes32 hashedParams)
    {
        hashedParams = getHashPacked(account, amount, timestamp);
        isProcessed = processedTransactions[hashedParams];
    }

    /**
      * @dev Claims tokens for user
      * @param amount Tokens amount
      * @param timestamp Timestamp to release tokens
      * @param signature Signature of params
      */
    function claimTokens(uint256 amount, uint256 timestamp, bytes memory signature)
        public
    {
        require(amount > 0, "TokenClaim: amount <= 0");
        require (block.timestamp >= timestamp, "TokenClaim: cannot claim before time");
        address account = _msgSender();
        
        (bool isProcessed, bytes32 hashedParams) = isProcessedTransaction(account, amount, timestamp);
        require(!isProcessed, "TokenClaimt: Transaction already processed");
        address signerAddress = ECDSA.recover(ECDSA.toEthSignedMessageHash(hashedParams), signature);
        require(isSigner(signerAddress), "TokenClaim: Transaction signature is not correct");

        processedTransactions[hashedParams] = true;
        claimedBalanceOf[account] += amount;
        claimedAmount += amount;

        TransferHelper.safeTransfer(address(tokenAddress), account, amount);

        emit TokensClaimed(account, amount, timestamp);
    }
}