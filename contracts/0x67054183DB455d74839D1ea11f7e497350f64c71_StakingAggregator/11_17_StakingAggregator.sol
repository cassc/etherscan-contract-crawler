// SPDX-License-Identifier: NONE
pragma solidity 0.8.17;
import "../interfaces/RocketStorage.sol";
import "../interfaces/RocketDepositPool.sol";
import "../interfaces/RocketTokenRETH.sol";
import "../interfaces/RocketDAOProtocolSettingsDepositInterface.sol";
import "../interfaces/RocketVault.sol";
import "../interfaces/ILido.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title A staking aggregation contract for RocketPool and Lido
/// @author Jack Clancy - Consensys
contract StakingAggregator is Ownable2Step, ReentrancyGuard, Pausable {
    using Address for address payable;

    RocketStorageInterface immutable rocketStorage;
    LidoInterface public immutable lidoProxyAddress;
    address public immutable lidoReferralAddress;
    uint256 public fee; // fee in 1/10th of bps
    uint256 public constant MAX_FEE = 2000; // maxFee in 1/10th of bps - 2% or 200bps
    uint256 public constant FEE_BASE = 100000;
    address payable public feesRecipient;

    constructor(
        address _owner,
        address _lidoReferralAddress,
        RocketStorageInterface _rocketStorageAddress,
        LidoInterface _lidoProxyAddress,
        uint256 _fee,
        address payable _feesRecipient
    ) {
        _transferOwnership(_owner);
        lidoReferralAddress = _lidoReferralAddress;
        rocketStorage = _rocketStorageAddress;
        lidoProxyAddress = _lidoProxyAddress;
        fee = _fee;
        feesRecipient = _feesRecipient;
    }

    error TransferFailed(address recipient, uint256 amount);
    error NoTokensMinted(address recipient);
    error FeeTooHigh(uint256 fee);
    error ContractNotFound();
    error InvalidFeesRecipient(address attemptedRecipient);
    error IncompatibleFeeRate(uint256 contractRate, uint256 permittedRate);

    event FeeUpdated(uint256 _newFee);
    event FeesRecipientUpdated(address recipient);

    /// @notice Deposits ETH to Lido and forwards minted stETH to caller
    function depositToLido(uint256 maxFeeRate) external payable nonReentrant whenNotPaused {
        // Check that user has allowed the fee rate
        if (maxFeeRate < fee) revert IncompatibleFeeRate(fee, maxFeeRate);
        // Forward deposit minus fee to Lido & get amount of stETH
        uint256 sharesMinted = lidoProxyAddress.submit{value: msg.value - ((msg.value * fee) / FEE_BASE)}(
            lidoReferralAddress
        );
        if (sharesMinted == 0) revert NoTokensMinted(msg.sender);
        // Forward minted stETH back to user
        if (lidoProxyAddress.transferShares(msg.sender, sharesMinted) == 0)
            revert TransferFailed(msg.sender, sharesMinted);
        // Withdraw fee
        if (address(this).balance != 0) feesRecipient.sendValue(address(this).balance);        
    }

    /// @notice Deposits ETH to RocketPool and forwards minted rETH to caller
    function depositToRP(uint256 maxFeeRate) external payable nonReentrant whenNotPaused {
        // Check that user has allowed the fee rate
        if (maxFeeRate < fee) revert IncompatibleFeeRate(fee, maxFeeRate);
        // Load contracts
        address rocketDepositPoolAddress = getContractAddress(
            "rocketDepositPool"
        );
        RocketDepositPoolInterface rocketDepositPool = RocketDepositPoolInterface(
                rocketDepositPoolAddress
            );
        address rocketTokenRETHAddress = getContractAddress("rocketTokenRETH");
        RocketTokenRETHInterface rocketTokenRETH = RocketTokenRETHInterface(
            rocketTokenRETHAddress
        );
        // Forward deposit minus fee to RP & get amount of rETH minted
        uint256 rethBalance1 = rocketTokenRETH.balanceOf(address(this));
        rocketDepositPool.deposit{value: msg.value - ((msg.value * fee) / FEE_BASE)}();
        uint256 rethBalance2 = rocketTokenRETH.balanceOf(address(this));
        if (rethBalance2 <= rethBalance1) revert NoTokensMinted(msg.sender);
        uint256 rethMinted = rethBalance2 - rethBalance1;
        // Forward minted rETH back to user
        if (!rocketTokenRETH.transfer(msg.sender, rethMinted))
            revert TransferFailed(msg.sender, rethMinted);
        // Withdraw fee
        if (address(this).balance != 0) feesRecipient.sendValue(address(this).balance);        
    }

    /// @notice Updates the fee for staking transactions
    /// @dev Fee is in 0.1bp increments. i.e. fee = 10 is setting to 1bp
    /// @param _newFee The new fee for future transactions
    function updateFee(uint256 _newFee) external onlyOwner {
        if (_newFee > MAX_FEE) revert FeeTooHigh(_newFee);
        fee = _newFee;
        emit FeeUpdated(_newFee);
    }

    /// @notice Updates the recipient of the fees collected by the contract
    /// @param _newFeesRecipent The recipient of future fees
    function updateFeesRecipient(address payable _newFeesRecipent)
        external
        onlyOwner
    {
        if (_newFeesRecipent == address(0))
            revert InvalidFeesRecipient(_newFeesRecipent);
        feesRecipient = _newFeesRecipent;
        emit FeesRecipientUpdated(_newFeesRecipent);
    }

    /// @notice Returns several RocketPool constants that the FE needs
    /// @dev Deposit fee in wei. Number needs to be divided by 1e18 to get in percentage
    function fetchRPConstants() external view returns (uint256[4] memory) {
        address rocketTokenRETHAddress = getContractAddress("rocketTokenRETH");
        address rocketDAOSettingsAddress = getContractAddress(
            "rocketDAOProtocolSettingsDeposit"
        );
        address rocketVaultAddress = getContractAddress("rocketVault");
        RocketDAOProtocolSettingsDepositInterface rocketDAOProtocolSettingsDeposit = RocketDAOProtocolSettingsDepositInterface(
                rocketDAOSettingsAddress
            );
        RocketVaultInterface rocketVault = RocketVaultInterface(
            rocketVaultAddress
        );
        RocketTokenRETHInterface rocketTokenRETH = RocketTokenRETHInterface(
            rocketTokenRETHAddress
        );
        uint256 currentDeposits = rocketVault.balanceOf("rocketDepositPool");
        uint256 depositFee = rocketDAOProtocolSettingsDeposit.getDepositFee();
        uint256 depositPoolCap = rocketDAOProtocolSettingsDeposit
            .getMaximumDepositPoolSize();
        uint256 exchangeRate = rocketTokenRETH.getExchangeRate();
        return [currentDeposits, depositFee, depositPoolCap, exchangeRate];
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev Get the address of a RocketPool network contract by name
    function getContractAddress(string memory _contractName)
        internal
        view
        returns (address)
    {
        address contractAddress = rocketStorage.getAddress(
            keccak256(abi.encodePacked("contract.address", _contractName))
        );
        if (contractAddress == address(0)) revert ContractNotFound();
        return contractAddress;
    }

    /// @notice Recovers arbitrary ERC-20 tokens in case any mistakenly get sent to contract
    /// @param tokenAddress address of the token to be sent
    /// @param tokenAmount amount of token to be sent
    /// @param recipient recipient of tokens 
    function recoverERC20(address tokenAddress, uint256 tokenAmount, address recipient) public virtual onlyOwner {
        IERC20(tokenAddress).transfer(recipient, tokenAmount);
    }

}