// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BabyDoge2Bridge is Ownable, ReentrancyGuard {
    uint256 public nonce;
    mapping(uint256 => bool) public processedNonces;
    mapping(address => TokenBridge) public tokenBridges;

    struct TokenBridge {
        uint256 minAmount;
        uint256 depositFee;
        uint256 withdrawFee;
        bool isSupported;
        bool isPaused;
        mapping(string => address) receivingTokenAddresses;
        mapping(address => bool) whitelistedAddresses;
    }

    event Deposit(
        address depositingTokenAddress,
        address indexed receivingTokenAddress,
        address indexed sender,
        uint256 amount,
        uint256 indexed nonce,
        string toChain
    );

    event Withdraw(
        address indexed tokenAddress,
        address indexed recipient,
        uint256 amount,
        string fromChain,
        uint256 indexed nonce
    );

    event TokenAdded(address indexed tokenAddress);
    event TokenRemoved(address indexed tokenAddress);

    constructor(
        address initialDepositingTokenAddress,
        string memory initialToChain,
        address initialReceivingTokenAddress
    ) {
        // Add initial token to the supported tokens list
        TokenBridge storage tokenBridge = tokenBridges[
            initialDepositingTokenAddress
        ];
        tokenBridge.isSupported = true;
        tokenBridge.minAmount = 1;
        tokenBridge.depositFee = 0;
        tokenBridge.withdrawFee = 0;
        tokenBridge.receivingTokenAddresses[
            initialToChain
        ] = initialReceivingTokenAddress;
    }

    function deposit(
        address depositingTokenAddress,
        uint256 amount,
        string memory toChain
    ) public nonReentrant {
        TokenBridge storage tokenBridge = tokenBridges[depositingTokenAddress];
        require(tokenBridge.isSupported, "Token not supported");
        require(
            tokenBridge.receivingTokenAddresses[toChain] != address(0),
            "Receiving token address not set for this chain"
        );
        require(
            amount >= tokenBridge.minAmount,
            "Amount less than minimum deposit amount"
        );
        require(
            IERC20(depositingTokenAddress).transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            "Token transfer failed"
        );

        uint256 fee;
        if(!tokenBridge.whitelistedAddresses[msg.sender]) {
            fee = (amount * tokenBridge.depositFee) / 10000;
        }

        uint256 netAmount = amount - fee;
        emit Deposit(
            depositingTokenAddress,
            tokenBridge.receivingTokenAddresses[toChain],
            msg.sender,
            netAmount,
            nonce,
            toChain
        );
        nonce++;
    }

    function withdraw(
        address tokenAddress,
        address recipient,
        uint256 amount,
        string memory fromChain,
        uint256 withdrawNonce
    ) external onlyOwner nonReentrant {
        require(
            !processedNonces[withdrawNonce],
            "Withdrawal already processed"
        );
        processedNonces[withdrawNonce] = true;
        TokenBridge storage tokenBridge = tokenBridges[tokenAddress];
        
        uint256 fee;
        if(!tokenBridge.whitelistedAddresses[recipient]) {
            fee = (amount * tokenBridge.withdrawFee) / 10000;
        }

        uint256 netAmount = amount - fee;
        require(
            IERC20(tokenAddress).transfer(recipient, netAmount),
            "Token transfer failed"
        );
        emit Withdraw(
            tokenAddress,
            recipient,
            netAmount,
            fromChain,
            withdrawNonce
        );
    }

    function addTokenBridge(
        address tokenAddress,
        uint256 minAmount,
        uint256 depositFee,
        uint256 withdrawFee
    ) external onlyOwner {
        TokenBridge storage tokenBridge = tokenBridges[tokenAddress];
        require(!tokenBridge.isSupported, "Token bridge already added");
        tokenBridge.isSupported = true;
        tokenBridge.minAmount = minAmount;
        tokenBridge.depositFee = depositFee;
        tokenBridge.withdrawFee = withdrawFee;
        tokenBridge.isPaused = false;
        emit TokenAdded(tokenAddress);
    }

    function removeTokenBridge(address tokenAddress) external onlyOwner {
        TokenBridge storage tokenBridge = tokenBridges[tokenAddress];
        require(tokenBridge.isSupported, "Token bridge not supported");
        tokenBridge.isSupported = false;
        emit TokenRemoved(tokenAddress);
    }

    function setTokenBridgePauseStatus(address tokenAddress, bool pauseStatus)
        external
        onlyOwner
    {
        TokenBridge storage tokenBridge = tokenBridges[tokenAddress];
        require(tokenBridge.isSupported, "Token bridge not supported");
        tokenBridge.isPaused = pauseStatus;
    }

    function setTokenBridgeMinAmount(address tokenAddress, uint256 minAmount)
        external
        onlyOwner
    {
        TokenBridge storage tokenBridge = tokenBridges[tokenAddress];
        require(tokenBridge.isSupported, "Token bridge not supported");
        tokenBridge.minAmount = minAmount;
    }

    function setTokenBridgeFee(
        address tokenAddress,
        uint256 depositFee,
        uint256 withdrawFee
    ) external onlyOwner {
        TokenBridge storage tokenBridge = tokenBridges[tokenAddress];
        require(tokenBridge.isSupported, "Token bridge not supported");
        tokenBridge.depositFee = depositFee;
        tokenBridge.withdrawFee = withdrawFee;
    }

    function setWhitelistedAddress(
        address tokenAddress,
        address[] memory whitelistedAddresses,
        bool status
    ) external onlyOwner {
        TokenBridge storage tokenBridge = tokenBridges[tokenAddress];
        require(tokenBridge.isSupported, "Token bridge not supported");

        for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
            tokenBridge.whitelistedAddresses[whitelistedAddresses[i]] = status;
        }
    }

    function setReceivingTokenAddress(
        address tokenAddress,
        string memory toChain,
        address receivingTokenAddress
    ) external onlyOwner {
        TokenBridge storage tokenBridge = tokenBridges[tokenAddress];
        require(tokenBridge.isSupported, "Token not supported");
        tokenBridge.receivingTokenAddresses[toChain] = receivingTokenAddress;
    }

    function getTokenBridgeDetails(address tokenAddress)
        external
        view
        returns (
            uint256 minAmount,
            uint256 depositFee,
            uint256 withdrawFee,
            bool isPaused
        )
    {
        TokenBridge storage tokenBridge = tokenBridges[tokenAddress];
        return (
            tokenBridge.minAmount,
            tokenBridge.depositFee,
            tokenBridge.withdrawFee,
            tokenBridge.isPaused
        );
    }

    function getReceivingTokenAddress(address tokenAddress, string memory toChain)
        external
        view
        returns (address)
    {
        TokenBridge storage tokenBridge = tokenBridges[tokenAddress];
        return tokenBridge.receivingTokenAddresses[toChain];
    }

    function isAddressWhitelisted(address tokenAddress, address userAddress)
        external
        view
        returns (bool)
    {
        TokenBridge storage tokenBridge = tokenBridges[tokenAddress];
        return tokenBridge.whitelistedAddresses[userAddress];
    }

    function getNonce() external view returns (uint256) {
        return nonce;
    }

    function isNonceProcessed(uint256 _nonce) external view returns (bool) {
        return processedNonces[_nonce];
    }

    function getTotalTransferFees(
        address depositingTokenAddress,
        uint256 amount,
        string memory toChain,
        address userAddress
    ) public view returns (uint256) {
        TokenBridge storage depositingTokenBridge = tokenBridges[depositingTokenAddress];
        require(depositingTokenBridge.isSupported, "Depositing token not supported");

        address receivingTokenAddress = depositingTokenBridge.receivingTokenAddresses[toChain];
        require(receivingTokenAddress != address(0), "Receiving token address not set for this chain");

        TokenBridge storage receivingTokenBridge = tokenBridges[receivingTokenAddress];

        uint256 totalFees = 0;

        if (!depositingTokenBridge.whitelistedAddresses[userAddress]) {
            uint256 depositFee = (amount * depositingTokenBridge.depositFee) / 10000;
            uint256 withdrawFee = (amount * receivingTokenBridge.withdrawFee) / 10000;
            totalFees = depositFee + withdrawFee;
        }

        return totalFees;
    }

    function getReceivableTokens(
        address depositingTokenAddress,
        uint256 amount,
        string memory toChain,
        address userAddress
    ) public view returns (uint256) {
        uint256 totalFees = getTotalTransferFees(depositingTokenAddress, amount, toChain, userAddress);
        uint256 receivableTokens = amount - totalFees;
        return receivableTokens;
    }

}