// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/AAVE/ILendingPool.sol";
import "../interfaces/AAVE/IAaveIncentivesController.sol";
import "../interfaces/IFlashStrategy.sol";
import "../interfaces/IUserIncentive.sol";
import "../interfaces/IFlashFToken.sol";

contract FlashStrategyAAVEv2 is IFlashStrategy, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address immutable flashProtocolAddress;
    address immutable lendingPoolAddress; // The AAVE V2 lending pool address
    address immutable principalTokenAddress; // The Principal token address (eg DAI)
    address immutable interestBearingTokenAddress; // The AAVE V2 interest bearing token address
    uint8 immutable principalDecimals;

    address fTokenAddress; // The Flash fERC20 token address
    uint16 referralCode = 0; // The AAVE V2 referral code
    uint256 principalBalance; // The amount of principal in this strategy
    address constant aaveIncentivesAddress = 0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5;

    address public userIncentiveAddress;
    bool public userIncentiveAddressLocked;

    uint256 maxStakeDuration = 63072000;        // Maximum stake duration for this strategy
    bool public maxStakeDurationLocked = false; // Determines if the above variable is locked (stop future updates)

    constructor(
        address _lendingPoolAddress,
        address _principalTokenAddress,
        address _interestBearingTokenAddress,
        address _flashProtocolAddress
    ) public {
        lendingPoolAddress = _lendingPoolAddress;
        principalTokenAddress = _principalTokenAddress;
        interestBearingTokenAddress = _interestBearingTokenAddress;
        flashProtocolAddress = _flashProtocolAddress;

        // Read the number of decimals from the principal token
        principalDecimals = IFlashFToken(principalTokenAddress).decimals();

        increaseAllowance();
    }

    // Implemented as a separate function just in case the strategy ever runs out of allowance
    function increaseAllowance() public {
        IERC20(principalTokenAddress).safeApprove(lendingPoolAddress, 0);
        IERC20(principalTokenAddress).safeApprove(lendingPoolAddress, type(uint256).max);
    }

    function depositPrincipal(uint256 _tokenAmount) external override onlyAuthorised returns (uint256) {
        // Register how much we are depositing
        principalBalance = principalBalance + _tokenAmount;

        // Deposit into AAVE
        ILendingPool(lendingPoolAddress).deposit(principalTokenAddress, _tokenAmount, address(this), referralCode);

        return _tokenAmount;
    }

    function withdrawYield(uint256 _tokenAmount) private {
        // Withdraw from AAVE
        uint256 returnedTokens = ILendingPool(lendingPoolAddress).withdraw(
            principalTokenAddress,
            _tokenAmount,
            address(this)
        );
        require(returnedTokens >= _tokenAmount);

        uint256 aTokenBalance = IERC20(interestBearingTokenAddress).balanceOf(address(this));
        require(aTokenBalance >= getPrincipalBalance(), "PRINCIPAL BALANCE INVALID");
    }

    function withdrawPrincipal(uint256 _tokenAmount) external override onlyAuthorised {
        // Withdraw from AAVE
        uint256 returnedTokens = ILendingPool(lendingPoolAddress).withdraw(
            principalTokenAddress,
            _tokenAmount,
            address(this)
        );
        require(returnedTokens >= _tokenAmount);

        IERC20(principalTokenAddress).safeTransfer(msg.sender, _tokenAmount);

        principalBalance = principalBalance - _tokenAmount;
    }

    function withdrawERC20(address[] calldata _tokenAddresses, uint256[] calldata _tokenAmounts) external onlyOwner {
        require(_tokenAddresses.length == _tokenAmounts.length, "ARRAY SIZE MISMATCH");

        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            // Ensure the token being withdrawn is not the interest bearing token
            require(_tokenAddresses[i] != interestBearingTokenAddress, "TOKEN ADDRESS PROHIBITED");

            // Transfer the token to the caller
            IERC20(_tokenAddresses[i]).safeTransfer(msg.sender, _tokenAmounts[i]);
        }
    }

    function getPrincipalBalance() public view override returns (uint256) {
        return principalBalance;
    }

    function getYieldBalance() public view override returns (uint256) {
        uint256 interestBearingTokenBalance = IERC20(interestBearingTokenAddress).balanceOf(address(this));

        return (interestBearingTokenBalance - getPrincipalBalance());
    }

    function getPrincipalAddress() external view override returns (address) {
        return principalTokenAddress;
    }

    function getFTokenAddress() external view returns (address) {
        return fTokenAddress;
    }

    function setFTokenAddress(address _fTokenAddress) external override onlyAuthorised {
        require(fTokenAddress == address(0), "FTOKEN ADDRESS ALREADY SET");
        fTokenAddress = _fTokenAddress;
    }

    function quoteMintFToken(uint256 _tokenAmount, uint256 _duration) external view override returns (uint256) {
        // Enforce minimum _duration
        require(_duration >= 60, "DURATION TOO LOW");

        // 1 ERC20 for 365 DAYS = 1 fERC20
        // 1 second = 0.000000031709792000
        // eg (100000000000000000 * (1 second * 31709792000)) / 10**18
        // eg (1000000 * (1 second * 31709792000)) / 10**6
        uint256 amountToMint = (_tokenAmount * (_duration * 31709792000)) / (10**principalDecimals);

        require(amountToMint > 0, "INSUFFICIENT OUTPUT");

        return amountToMint;
    }

    function quoteBurnFToken(uint256 _tokenAmount) public view override returns (uint256) {
        uint256 totalSupply = IERC20(fTokenAddress).totalSupply();
        require(totalSupply > 0, "INSUFFICIENT fERC20 TOKEN SUPPLY");

        if (_tokenAmount > totalSupply) {
            _tokenAmount = totalSupply;
        }

        // Calculate the percentage of _tokenAmount vs totalSupply provided
        // and multiply by total yield
        return (getYieldBalance() * _tokenAmount) / totalSupply;
    }

    function burnFToken(
        uint256 _tokenAmount,
        uint256 _minimumReturned,
        address _yieldTo
    ) external override nonReentrant returns (uint256) {
        // Calculate how much yield to give back
        uint256 tokensOwed = quoteBurnFToken(_tokenAmount);
        require(tokensOwed >= _minimumReturned && tokensOwed > 0, "INSUFFICIENT OUTPUT");

        // Transfer fERC20 (from caller) tokens to contract so we can burn them
        IFlashFToken(fTokenAddress).burnFrom(msg.sender, _tokenAmount);

        withdrawYield(tokensOwed);
        IERC20(principalTokenAddress).safeTransfer(_yieldTo, tokensOwed);

        // Distribute rewards if there is a reward balance within contract
        if (userIncentiveAddress != address(0)) {
            IUserIncentive(userIncentiveAddress).claimReward(_tokenAmount, _yieldTo);
        }

        emit BurnedFToken(msg.sender, _tokenAmount, tokensOwed);

        return tokensOwed;
    }

    modifier onlyAuthorised() {
        require(msg.sender == flashProtocolAddress || msg.sender == address(this), "NOT FLASH PROTOCOL");
        _;
    }

    function getMaxStakeDuration() public view override returns (uint256) {
        return maxStakeDuration;
    }

    function claimAAVEv2Rewards(address[] calldata _assets, uint256 _amount) external onlyOwner {
        IAaveIncentivesController(aaveIncentivesAddress).claimRewards(_assets, _amount, address(this));
    }

    // @notice sets the new maximum stake duration
    // @dev this can only be called by the strategy owner
    function setMaxStakeDuration(uint256 _newMaxStakeDuration) external onlyOwner {
        require(maxStakeDurationLocked == false);
        maxStakeDuration = _newMaxStakeDuration;
    }

    // @notice permanently locks the max stake duration
    // @dev this can only be called by the strategy owner
    function lockMaxStakeDuration() external onlyOwner {
        maxStakeDurationLocked = true;
    }

    // @notice set the new user incentive address
    // @dev this can only be called by the strategy owner
    function setUserIncentiveAddress(address _userIncentiveAddress) external onlyOwner {
        require(userIncentiveAddressLocked == false);
        userIncentiveAddress = _userIncentiveAddress;
    }

    // @notice permanently locks the user incentive address
    // @dev this can only be called by the strategy owner
    function lockSetUserIncentiveAddress() external onlyOwner {
        userIncentiveAddressLocked = true;
    }
}