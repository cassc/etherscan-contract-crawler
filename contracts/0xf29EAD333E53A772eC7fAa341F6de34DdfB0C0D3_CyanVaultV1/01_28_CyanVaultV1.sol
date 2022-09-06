// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./CyanVaultTokenV1.sol";
import "./IStableSwapSTETH.sol";

contract CyanVaultV1 is
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC721HolderUpgradeable,
    PausableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant CYAN_ROLE = keccak256("CYAN_ROLE");
    bytes32 public constant CYAN_PAYMENT_PLAN_ROLE =
        keccak256("CYAN_PAYMENT_PLAN_ROLE");
    bytes32 public constant CYAN_BALANCER_ROLE =
        keccak256("CYAN_BALANCER_ROLE");

    event DepositETH(
        address indexed from,
        uint256 ethAmount,
        uint256 tokenAmount
    );
    event Lend(address indexed to, uint256 amount);
    event Earn(uint256 paymentAmount, uint256 profitAmount);
    event NftDefaulted(uint256 unpaidAmount, uint256 estimatedPriceOfNFT);
    event NftLiquidated(uint256 defaultedAssetsAmount, uint256 soldAmount);
    event WithdrawETH(
        address indexed from,
        uint256 ethAmount,
        uint256 tokenAmount
    );
    event GetDefaultedNFT(
        address indexed to,
        address indexed contractAddress,
        uint256 indexed tokenId
    );
    event UpdatedDefaultedNFTAssetAmount(uint256 amount);
    event UpdatedServiceFeePercent(uint256 from, uint256 to);
    event UpdatedSafetyFundPercent(uint256 from, uint256 to);
    event InitializedServiceFeePercent(uint256 to);
    event InitializedSafetyFundPercent(uint256 to);
    event ExchangedEthToStEth(uint256 ethAmount, uint256 receivedStEthAmount);
    event ExchangedStEthToEth(uint256 stEthAmount, uint256 receivedEthAmount);
    event ReceivedETH(uint256 amount, address indexed from);
    event WithdrewERC20(address indexed token, address to, uint256 amount);
    event CollectedServiceFee(uint256 collectedAmount, uint256 remainingAmount);

    address public _cyanVaultTokenAddress;
    CyanVaultTokenV1 private _cyanVaultTokenContract;

    IERC20 private _stEthTokenContract;
    IStableSwapSTETH private _stableSwapSTETHContract;

    // Safety fund percent. (x100)
    uint256 public _safetyFundPercent;

    // Cyan service fee percent. (x100)
    uint256 public _serviceFeePercent;

    // Remaining amount of ETH
    uint256 private REMAINING_AMOUNT;

    // Total loaned amount
    uint256 private LOANED_AMOUNT;

    // Total defaulted NFT amount
    uint256 private DEFAULTED_NFT_ASSET_AMOUNT;

    // Cyan collected service fee
    uint256 private COLLECTED_SERVICE_FEE_AMOUNT;

    function initialize(
        address cyanVaultTokenAddress,
        address cyanPaymentPlanAddress,
        address stEthTokenAddress,
        address curveStableSwapStEthAddress,
        address cyanSuperAdmin,
        uint256 safetyFundPercent,
        uint256 serviceFeePercent
    ) external initializer {
        require(
            cyanVaultTokenAddress != address(0),
            "Cyan Vault Token address cannot be zero"
        );
        require(
            safetyFundPercent <= 10000,
            "Safety fund percent must be equal or less than 100 percent"
        );
        require(
            serviceFeePercent <= 200,
            "Service fee percent must not be greater than 2 percent"
        );

        __AccessControl_init();
        __ReentrancyGuard_init();
        __ERC721Holder_init();
        __Pausable_init();

        _cyanVaultTokenAddress = cyanVaultTokenAddress;
        _cyanVaultTokenContract = CyanVaultTokenV1(_cyanVaultTokenAddress);
        _safetyFundPercent = safetyFundPercent;
        _serviceFeePercent = serviceFeePercent;

        LOANED_AMOUNT = 0;
        DEFAULTED_NFT_ASSET_AMOUNT = 0;
        REMAINING_AMOUNT = 0;

        _stEthTokenContract = IERC20(stEthTokenAddress);
        _stableSwapSTETHContract = IStableSwapSTETH(
            curveStableSwapStEthAddress
        );

        _setupRole(DEFAULT_ADMIN_ROLE, cyanSuperAdmin);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CYAN_PAYMENT_PLAN_ROLE, cyanPaymentPlanAddress);

        emit InitializedServiceFeePercent(serviceFeePercent);
        emit InitializedSafetyFundPercent(safetyFundPercent);
    }

    // User stakes ETH
    function depositETH() external payable nonReentrant whenNotPaused {
        require(msg.value > 0, "Must deposit more than 0 ETH");

        // Cyan collecting service fee from deposits
        uint256 cyanServiceFee = (msg.value * _serviceFeePercent) / 10000;

        uint256 depositedAmount = msg.value - cyanServiceFee;
        uint256 mintAmount = calculateTokenByETH(depositedAmount);

        REMAINING_AMOUNT += depositedAmount;
        COLLECTED_SERVICE_FEE_AMOUNT += cyanServiceFee;
        _cyanVaultTokenContract.mint(msg.sender, mintAmount);

        emit DepositETH(msg.sender, depositedAmount, mintAmount);
    }

    // Cyan lends money from Vault to do BNPL or PAWN
    function lend(address to, uint256 amount)
        external
        nonReentrant
        whenNotPaused
        onlyRole(CYAN_PAYMENT_PLAN_ROLE)
    {
        require(to != address(0), "to address cannot be zero");

        uint256 maxWithdrableAmount = getMaxWithdrawableAmount();
        require(amount <= maxWithdrableAmount, "Not enough ETH in the Vault");

        LOANED_AMOUNT += amount;
        REMAINING_AMOUNT -= amount;
        payable(to).transfer(amount);

        emit Lend(to, amount);
    }

    // Cyan Payment Plan contract transfers paid amount back to Vault
    function earn(uint256 amount, uint256 profit)
        external
        payable
        nonReentrant
        onlyRole(CYAN_PAYMENT_PLAN_ROLE)
    {
        require(msg.value == amount + profit, "Wrong tranfer amount");

        REMAINING_AMOUNT += msg.value;
        if (LOANED_AMOUNT >= amount) {
            LOANED_AMOUNT -= amount;
        } else {
            LOANED_AMOUNT = 0;
        }

        emit Earn(amount, profit);
    }

    // When BNPL or PAWN plan defaults
    function nftDefaulted(uint256 unpaidAmount, uint256 estimatedPriceOfNFT)
        external
        nonReentrant
        onlyRole(CYAN_PAYMENT_PLAN_ROLE)
    {
        DEFAULTED_NFT_ASSET_AMOUNT += estimatedPriceOfNFT;

        if (LOANED_AMOUNT >= unpaidAmount) {
            LOANED_AMOUNT -= unpaidAmount;
        } else {
            LOANED_AMOUNT = 0;
        }

        emit NftDefaulted(unpaidAmount, estimatedPriceOfNFT);
    }

    // Liquidating defaulted BNPL or PAWN token and tranferred sold amount to Vault
    function liquidateNFT(uint256 totalDefaultedNFTAmount)
        external
        payable
        whenNotPaused
        onlyRole(CYAN_ROLE)
    {
        REMAINING_AMOUNT += msg.value;
        DEFAULTED_NFT_ASSET_AMOUNT = totalDefaultedNFTAmount;

        emit NftLiquidated(msg.value, totalDefaultedNFTAmount);
    }

    // User unstakes tokenAmount of tokens and gets back ETH
    function withdraw(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Non-positive token amount");

        uint256 balance = _cyanVaultTokenContract.balanceOf(msg.sender);
        require(balance >= amount, "Check the token balance");

        uint256 withdrawableTokenBalance = getWithdrawableBalance(msg.sender);
        require(
            amount <= withdrawableTokenBalance,
            "Not enough active balance in Cyan Vault"
        );

        uint256 withdrawETHAmount = calculateETHByToken(amount);

        REMAINING_AMOUNT -= withdrawETHAmount;
        _cyanVaultTokenContract.burn(msg.sender, amount);
        payable(msg.sender).transfer(withdrawETHAmount);

        emit WithdrawETH(msg.sender, withdrawETHAmount, amount);
    }

    // Cyan updating total amount of defaulted NFT assets
    function updateDefaultedNFTAssetAmount(uint256 amount)
        external
        whenNotPaused
        onlyRole(CYAN_ROLE)
    {
        DEFAULTED_NFT_ASSET_AMOUNT = amount;
        emit UpdatedDefaultedNFTAssetAmount(amount);
    }

    // Get defaulted NFT from Vault to Cyan Admin account
    function getDefaultedNFT(address contractAddress, uint256 tokenId)
        external
        nonReentrant
        whenNotPaused
        onlyRole(CYAN_ROLE)
    {
        require(contractAddress != address(0), "Zero contract address");

        IERC721 originalContract = IERC721(contractAddress);

        require(
            originalContract.ownerOf(tokenId) == address(this),
            "Vault is not the owner of the token"
        );

        originalContract.safeTransferFrom(address(this), msg.sender, tokenId);

        emit GetDefaultedNFT(msg.sender, contractAddress, tokenId);
    }

    function getWithdrawableBalance(address user)
        public
        view
        returns (uint256)
    {
        uint256 tokenBalance = _cyanVaultTokenContract.balanceOf(user);
        uint256 ethAmountForToken = calculateETHByToken(tokenBalance);
        uint256 maxWithdrawableAmount = getMaxWithdrawableAmount();

        if (ethAmountForToken <= maxWithdrawableAmount) {
            return tokenBalance;
        }
        return calculateTokenByETH(maxWithdrawableAmount);
    }

    function getMaxWithdrawableAmount() public view returns (uint256) {
        uint256 util = ((LOANED_AMOUNT + DEFAULTED_NFT_ASSET_AMOUNT) *
            _safetyFundPercent) / 10000;
        if (REMAINING_AMOUNT > util) {
            return REMAINING_AMOUNT - util;
        }
        return 0;
    }

    function getCurrentAssetAmounts()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            REMAINING_AMOUNT,
            LOANED_AMOUNT,
            DEFAULTED_NFT_ASSET_AMOUNT,
            COLLECTED_SERVICE_FEE_AMOUNT,
            _stEthTokenContract.balanceOf(address(this))
        );
    }

    function calculateTokenByETH(uint256 amount) public view returns (uint256) {
        (uint256 totalETH, uint256 totalToken) = getTotalEthAndToken();
        if (totalETH == 0 || totalToken == 0) return amount;
        return (amount * totalToken) / totalETH;
    }

    function calculateETHByToken(uint256 amount) public view returns (uint256) {
        (uint256 totalETH, uint256 totalToken) = getTotalEthAndToken();
        if (totalETH == 0 || totalToken == 0) return amount;
        return (amount * totalETH) / totalToken;
    }

    function getTotalEthAndToken() private view returns (uint256, uint256) {
        uint256 vaultStEthBalance = _stEthTokenContract.balanceOf(
            address(this)
        );
        uint256 stEthInEth = vaultStEthBalance == 0
            ? 0
            : _stableSwapSTETHContract.get_dy(1, 0, vaultStEthBalance);
        uint256 totalETH = REMAINING_AMOUNT +
            LOANED_AMOUNT +
            DEFAULTED_NFT_ASSET_AMOUNT +
            stEthInEth;
        uint256 totalToken = _cyanVaultTokenContract.totalSupply();

        return (totalETH, totalToken);
    }

    function exchangeEthToStEth(uint256 ethAmount, uint256 minStEthAmount)
        external
        nonReentrant
        onlyRole(CYAN_BALANCER_ROLE)
    {
        require(ethAmount > 0, "Exchanging ETH amount is zero");
        require(
            ethAmount <= REMAINING_AMOUNT,
            "Cannot exchange more than REMAINING_AMOUNT"
        );
        // Exchanging ETH to stETH
        REMAINING_AMOUNT -= ethAmount;
        uint256 receivedStEthAmount = _stableSwapSTETHContract.exchange{
            value: ethAmount
        }(0, 1, ethAmount, minStEthAmount);
        emit ExchangedEthToStEth(ethAmount, receivedStEthAmount);
    }

    function exchangeStEthToEth(uint256 stEthAmount, uint256 minEthAmount)
        external
        nonReentrant
        onlyRole(CYAN_BALANCER_ROLE)
    {
        require(stEthAmount > 0, "Exchanging stETH amount is zero");
        // Exchanging stETH to ETH
        bool isApproved = _stEthTokenContract.approve(
            address(_stableSwapSTETHContract),
            stEthAmount
        );
        require(
            isApproved,
            "stETH approval to stableSwapSTETH contract failed"
        );
        uint256 receivedEthAmount = _stableSwapSTETHContract.exchange(
            1,
            0,
            stEthAmount,
            minEthAmount
        );
        emit ExchangedStEthToEth(stEthAmount, receivedEthAmount);
    }

    function updateSafetyFundPercent(uint256 safetyFundPercent)
        external
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            safetyFundPercent <= 10000,
            "Safety fund percent must be equal or less than 100 percent"
        );
        emit UpdatedSafetyFundPercent(_safetyFundPercent, safetyFundPercent);
        _safetyFundPercent = safetyFundPercent;
    }

    function updateServiceFeePercent(uint256 serviceFeePercent)
        external
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            serviceFeePercent <= 200,
            "Service fee percent must not be greater than 2 percent"
        );
        emit UpdatedServiceFeePercent(_serviceFeePercent, serviceFeePercent);
        _serviceFeePercent = serviceFeePercent;
    }

    function collectServiceFee(uint256 amount)
        external
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            amount <= COLLECTED_SERVICE_FEE_AMOUNT,
            "Not enough collected service fee"
        );
        COLLECTED_SERVICE_FEE_AMOUNT -= amount;
        payable(msg.sender).transfer(amount);

        emit CollectedServiceFee(amount, COLLECTED_SERVICE_FEE_AMOUNT);
    }

    function withdrawAirDroppedERC20(address contractAddress, uint256 amount)
        external
        nonReentrant
        onlyRole(CYAN_ROLE)
    {
        require(
            contractAddress != address(_stEthTokenContract),
            "Cannot withdraw stETH"
        );
        IERC20Upgradeable erc20Contract = IERC20Upgradeable(contractAddress);
        require(
            erc20Contract.balanceOf(address(this)) >= amount,
            "ERC20 balance not enough"
        );
        erc20Contract.safeTransfer(msg.sender, amount);

        emit WithdrewERC20(contractAddress, msg.sender, amount);
    }

    function withdrawApprovedERC20(
        address contractAddress,
        address from,
        uint256 amount
    ) external nonReentrant onlyRole(CYAN_ROLE) {
        require(
            contractAddress != address(_stEthTokenContract),
            "Cannot withdraw stETH"
        );
        IERC20Upgradeable erc20Contract = IERC20Upgradeable(contractAddress);
        require(
            erc20Contract.allowance(from, address(this)) >= amount,
            "ERC20 allowance not enough"
        );
        erc20Contract.safeTransferFrom(from, msg.sender, amount);

        emit WithdrewERC20(contractAddress, msg.sender, amount);
    }

    receive() external payable {
        REMAINING_AMOUNT += msg.value;
        emit ReceivedETH(msg.value, msg.sender);
    }

    fallback() external payable {
        REMAINING_AMOUNT += msg.value;
        emit ReceivedETH(msg.value, msg.sender);
    }

    function pause() external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}