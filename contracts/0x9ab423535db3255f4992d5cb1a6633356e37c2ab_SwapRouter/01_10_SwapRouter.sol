// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./../interfaces/IERC20Mintable.sol";

/**
 * @title SwapRouter
 * @dev A contract for performing cross-chain swaps between different networks.
 */
contract SwapRouter is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct TargetChainConfig {
        uint256 swapFee;
        bool isActive;
        bool exist;
    }

    event TargetChainConfigUpdate(uint256 chainId, uint256 swapFee, bool isActive);
    event RemoveTargetChainConfig(uint256 chainId, uint256 swapFee, bool isActive);
    event FeeReceiverUpdated(address receiver);
    event SwapRequest(address indexed account, uint256 amount, uint fromChainId, uint toChainId);
    event SwapCompleted(address indexed account, uint256 amount, uint fromChainId, uint toChainId, bytes32 requestTransactionHash);

    modifier notIsSameChain(uint256 chainId) {
        require(chainId != getChainId(), "Is same chain");
        _;
    }

    modifier feeReceiverDefined() {
        require(feeReceiver != address(0), "Fee receiver is not defined");
        _;
    }

    modifier onlyMessageRelayer() {
        require(_msgSender() == messageRelayer, "Only call from message relayer");
        _;
    }

    address payable public feeReceiver;
    address public messageRelayer;
    IERC20 public swapToken;

    mapping(uint256 => TargetChainConfig) public targetChains;

    // From-ChainID > Request Transaction Hash > State
    mapping(uint256 => mapping(bytes32 => bool)) private swapState;

    /**
     * @dev Initializes the SwapRouter contract.
     * @param feeReceiver_ The address that will receive the swap fees.
     * @param token The ERC20 token used for swapping.
     */
    constructor(address payable feeReceiver_, IERC20 token, address relayer) {
        _setToken(token);
        _setFeeReceiver(feeReceiver_);
        _setMessageRelayer(relayer);
    }

    /**
     * @dev Get swap state
     * @param chainId Request chain id
     * @param transactionHash Swap transaction hash from sender chain
     */
    function isSwapCompleted(uint256 chainId, bytes32 transactionHash) public view returns (bool) {
        return swapState[chainId][transactionHash];
    }

    function _setMessageRelayer(address relayer) internal {
        require(relayer != address(0), "Message relayer cant be zero address");
        messageRelayer = relayer;
    }

    /**
     * @dev Sets the address of the message relayer.
     * @param relayer The address of the message relayer.
     */
    function setMessageRelayer(address relayer) external onlyOwner {
        _setMessageRelayer(relayer);
    }

    function _setToken(IERC20 token) internal {
        require(address(token) != address(0), "Token address cant be zero address");
        swapToken = token;
    }

    /**
     * @dev Sets the ERC20 token used for swapping.
     * @param token The ERC20 token used for swapping.
     */
    function setToken(IERC20 token) external onlyOwner {
        _setToken(token);
    }

    function _setFeeReceiver(address payable account) internal {
        require(account != address(0), "Receiver address cant be zero address");
        feeReceiver = account;
        emit FeeReceiverUpdated(account);
    }

    /**
     * @dev Sets the address that will receive the swap fees.
     * @param account The address that will receive the swap fees.
     */
    function setFeeReceiver(address payable account) external onlyOwner {
        _setFeeReceiver(account);
    }

    /**
     * @dev Sets the configuration for a target chain.
     * @param chainId The ID of the target chain.
     * @param swapFee The fee required for performing a swap on the target chain.
     * @param isActive The status of the target chain (active or inactive).
     */
    function setTargetChainConfig(uint256 chainId, uint256 swapFee, bool isActive) external onlyOwner notIsSameChain(chainId) {
        TargetChainConfig memory config = targetChains[chainId];

        config.swapFee = swapFee;
        config.isActive = isActive;
        config.exist = true;
        targetChains[chainId] = config;

        emit TargetChainConfigUpdate(chainId, swapFee, isActive);
    }

    /**
     * @dev Removes a target chain configuration.
     * @param chainId The ID of the target chain to remove.
     */
    function removeTargetChain(uint256 chainId) external onlyOwner notIsSameChain(chainId) {
        TargetChainConfig memory config = targetChains[chainId];
        require(config.exist == true, "Target chain does not exist");
        delete targetChains[chainId];
        emit RemoveTargetChainConfig(chainId, config.swapFee, config.isActive);
    }

    /**
     * @dev Initiates a swap request.
     * @param chainId The ID of the target chain.
     * @param amount The amount of tokens to swap.
     */
    function swapRequest(uint256 chainId, uint256 amount) external payable whenNotPaused feeReceiverDefined nonReentrant {
        TargetChainConfig memory config = targetChains[chainId];
        IERC20Mintable token = IERC20Mintable(address(swapToken));

        if (config.exist == false || config.isActive == false) {
            revert("Target chain is not active");
        }
        if (msg.value < config.swapFee) {
            revert("Swap fee doesnt payed");
        }

        // Transfer token
        SafeERC20.safeTransferFrom(swapToken, _msgSender(), address(this), amount);
        // Burn given amount
        token.burn(amount);

        // Transfer swap fee
        if (config.swapFee > 0) {
            (bool sent,) = feeReceiver.call{value : amount}("");
            require(sent, "Fee transfer failed");
        }

        // Emit swap request event
        emit SwapRequest(_msgSender(), amount, getChainId(), chainId);
    }

    /**
     * @dev Processes a swap request from the message relayer.
     * @param fromChainId The ID of the source chain.
     * @param requestTransactionHash The transaction hash of the swap request.
     * @param account The account to receive the swapped tokens.
     * @param amount The amount of tokens to swap.
     */
    function processSwapRequest(uint256 fromChainId, bytes32 requestTransactionHash, address account, uint256 amount) public whenNotPaused onlyMessageRelayer nonReentrant {
        require(swapState[fromChainId][requestTransactionHash] == false, "This swap request already completed");
        swapState[fromChainId][requestTransactionHash] = true;

        IERC20Mintable token = IERC20Mintable(address(swapToken));
        token.mint(account, amount);
        emit SwapCompleted(account, amount, fromChainId, getChainId(), requestTransactionHash);
    }

    /**
     * @dev Returns the ID of the current chain.
     * @return The ID of the current chain.
     */
    function getChainId() public view returns (uint) {
        return block.chainid;
    }
}