// SPDX-License-Identifier: MIT 
//    ▄██████▄   ▄█        ▄█      ███      ▄████████    ▄█    █▄            ▄███████▄    ▄████████  ▄██████▄      ███      ▄██████▄   ▄████████  ▄██████▄   ▄█       
//   ███    ███ ███       ███  ▀█████████▄ ███    ███   ███    ███          ███    ███   ███    ███ ███    ███ ▀█████████▄ ███    ███ ███    ███ ███    ███ ███       
//   ███    █▀  ███       ███▌    ▀███▀▀██ ███    █▀    ███    ███          ███    ███   ███    ███ ███    ███    ▀███▀▀██ ███    ███ ███    █▀  ███    ███ ███       
//   ▄███        ███       ███▌     ███   ▀ ███         ▄███▄▄▄▄███▄▄        ███    ███  ▄███▄▄▄▄██▀ ███    ███     ███   ▀ ███    ███ ███        ███    ███ ███       
//▀▀███ ████▄  ███       ███▌     ███     ███        ▀▀███▀▀▀▀███▀       ▀█████████▀  ▀▀███▀▀▀▀▀   ███    ███     ███     ███    ███ ███        ███    ███ ███       
//   ███    ███ ███       ███      ███     ███    █▄    ███    ███          ███        ▀███████████ ███    ███     ███     ███    ███ ███    █▄  ███    ███ ███       
//   ███    ███ ███▌    ▄ ███      ███     ███    ███   ███    ███          ███          ███    ███ ███    ███     ███     ███    ███ ███    ███ ███    ███ ███▌    ▄ 
//   ████████▀  █████▄▄██ █▀      ▄████▀   ████████▀    ███    █▀          ▄████▀        ███    ███  ▀██████▀     ▄████▀    ▀██████▀  ████████▀   ▀██████▀  █████▄▄██ 
//              ▀                                                                        ███    ███                                                         ▀         
// https://t.me/glitchproto
// https://twitter.com/protocolglitch
// https://discord.gg/jyehnJHW9q
// GLITCH Protocol is a decentralized protocol that allows users to swap between any two tokens on the Ethereum blockchain in a trustless manner.
//
pragma solidity ^0.8.0;

import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/token/ERC20/IERC20.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/ReentrancyGuard.sol";
import "https://raw.githubusercontent.com/smartcontractkit/chainlink/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/Pausable.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/token/ERC20/utils/SafeERC20.sol";

import "./GLIQUID.sol";
import "./FeeManager.sol";

interface IExtendedERC20 is IERC20 {
    function decimals() external view returns (uint8);
}

contract GLIQUIDITY is ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    GLIQUID public gliquidToken;
    FeeManager public feeManager;

    address public devAddress;
    address public owner;
    bool public isBootstrapped = false;

    uint256 public FEE = 25;
    uint256 public OFEE = 35;
    uint256 constant ONE_DAY = 86400;

    uint256 public constant TOLERANCE = 100;

    struct FeeSnapshot {
        uint256 totalFees;
        uint256 totalSupply;
    }

    mapping(address => mapping(address => FeeSnapshot)) public userSnapshots;

    mapping(address => FeeSnapshot) public globalSnapshots;

    mapping(address => mapping(address => uint256)) public feesOwed;

    mapping(address => uint256) public dailyTokenVolumes; 
    uint256 public lastVolumeUpdateTime;

    mapping(address => bool) public isLiquidityProvider;

    uint256 public dailyFeesCollected; 
    uint256 public lastFeesUpdateTime; 

    event TokenSwapped(address indexed trader, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);
    event LiquidityAdded(address indexed provider, uint256 gliquidMinted);
    event LiquidityRemoved(address indexed provider, uint256 gliquidBurned);
    event FeesClaimed(address indexed user, address indexed token, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    constructor(address _gliquidToken, address _feeManager, address _devAddress) {
        gliquidToken = GLIQUID(_gliquidToken);
        feeManager = FeeManager(_feeManager);
        devAddress = _devAddress;
        owner = msg.sender;
    }

    function setDevAddress(address _devAddress) external onlyOwner {
        devAddress = _devAddress;
    }

    function updateFees(uint256 fee) internal {
        if (block.timestamp.sub(lastFeesUpdateTime) >= ONE_DAY) {
            dailyFeesCollected = fee;
            lastFeesUpdateTime = block.timestamp;
        } else {
            dailyFeesCollected = dailyFeesCollected.add(fee);
        }
    }

    function updateUserSnapshot(address user, address token) private {
        uint256 totalFees = feeManager.getTotalFees(token);
        uint256 totalSupply = gliquidToken.totalSupply();
        userSnapshots[user][token] = FeeSnapshot(totalFees, totalSupply);
    }

    function updateGlobalSnapshot(address token) private {
        uint256 totalFees = feeManager.getTotalFees(token);
        uint256 totalSupply = gliquidToken.totalSupply();
        globalSnapshots[token] = FeeSnapshot(totalFees, totalSupply);
    }

    function updateAllUserSnapshots(address user) private {
        address[] memory tokens = gliquidToken.getTokenAddresses();

        for (uint256 i = 0; i < tokens.length; i++) {
            updateUserSnapshot(user, tokens[i]);
        }
    }

    function updateAllGlobalSnapshots() private {
        address[] memory tokens = gliquidToken.getTokenAddresses();

        for (uint256 i = 0; i < tokens.length; i++) {
            updateGlobalSnapshot(tokens[i]);
        }
    }

    function calculateAPR() public view returns (uint256) {
        uint256 totalLiquidity = gliquidToken.getTotalValueInPool();

        if (totalLiquidity == 0) {
            return 0;
        }

        uint256 annualizedFees = dailyFeesCollected.mul(365);
        return (annualizedFees.mul(100).mul(1e18)).div(totalLiquidity);
    }

    function _getTokenValueUSD(address token, uint256 amount) internal view returns (uint256) {
        uint256 tokenPrice = gliquidToken.getTokenPriceUSD(token);

        uint256 normalizedAmount = amount;
        if (IExtendedERC20(token).decimals() < 18) {
            normalizedAmount = amount.mul(10 ** (18 - IExtendedERC20(token).decimals()));
        } else if (IExtendedERC20(token).decimals() > 18) {
            normalizedAmount = amount.div(10 ** (IExtendedERC20(token).decimals() - 18));
        }

        return normalizedAmount.mul(tokenPrice).div(10 ** 18);
    }
    
    function getClaimableAmount(address user, address token) public view returns (uint256) {
        FeeSnapshot memory userSnapshot = userSnapshots[user][token];
        FeeSnapshot memory globalSnapshot = globalSnapshots[token];

        uint256 feesOwedUserToken = feesOwed[user][token];

        if (userSnapshot.totalSupply == 0) {
            return feesOwedUserToken;
        }

        uint256 totalTokenFee = globalSnapshot.totalFees > userSnapshot.totalFees ? globalSnapshot.totalFees - userSnapshot.totalFees : 0;

        if (totalTokenFee == 0) {
            return feesOwedUserToken;
        }

        uint256 currentTotalSupply = gliquidToken.totalSupply();
        uint256 userBalance = gliquidToken.balanceOf(user);
        
        if (userBalance == 0) {
            return feesOwedUserToken;
        }

        uint256 userProportion = userBalance.mul(1e18).div(currentTotalSupply); 
       
        uint256 adjustedUserProportion = userProportion; 

        uint256 userShare = (totalTokenFee * adjustedUserProportion) / 1e18;

        return userShare.add(feesOwedUserToken);
    }

    function getAllClaimableAmounts(address user) public view returns (address[] memory, uint256[] memory) {
        address[] memory supportedTokens = gliquidToken.getTokenAddresses(); // This function should return all supported tokens.
        uint256[] memory userShares = new uint256[](supportedTokens.length);

        for (uint256 i = 0; i < supportedTokens.length; i++) {
            address token = supportedTokens[i];
            userShares[i] = getClaimableAmount(user, token);
        }

        return (supportedTokens, userShares);
    }

    function claim() external nonReentrant whenNotPaused {
        require(isLiquidityProvider[msg.sender], "You must be a liquidity provider to claim fees.");

        address[] memory _tokenAddresses = gliquidToken.getTokenAddresses();
        bool hasClaimedAny = false;

        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            address tokenAddress = _tokenAddresses[i];
            uint256 claimableAmount = getClaimableAmount(msg.sender, tokenAddress);

            if (claimableAmount == 0) continue;

            uint256 contractBalance = IERC20(tokenAddress).balanceOf(address(feeManager));
            require(contractBalance >= claimableAmount, "Not enough tokens in the contract to cover the claim");

            feeManager.withdrawFees(tokenAddress, claimableAmount, msg.sender);

            updateUserSnapshot(msg.sender, tokenAddress);

            feesOwed[msg.sender][tokenAddress] = 0;

            hasClaimedAny = true;

            emit FeesClaimed(msg.sender, tokenAddress, claimableAmount);
        }

        if(hasClaimedAny) {
            updateAllGlobalSnapshots();
        }

        require(hasClaimedAny, "No fees available to claim");
    }

    function liquidclaim(address sender) internal {
        address[] memory _tokenAddresses = gliquidToken.getTokenAddresses();
        bool hasClaimedAny = false;

        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            address tokenAddress = _tokenAddresses[i];
            uint256 claimableAmount = getClaimableAmount(sender, tokenAddress);

            if (claimableAmount == 0) continue; 

            uint256 contractBalance = IERC20(tokenAddress).balanceOf(address(feeManager));
            require(contractBalance >= claimableAmount, "Not enough tokens in the contract to cover the claim");

            feeManager.withdrawFees(tokenAddress, claimableAmount, sender);

            updateUserSnapshot(sender, tokenAddress);

            feesOwed[sender][tokenAddress] = 0;

            hasClaimedAny = true;

            emit FeesClaimed(sender, tokenAddress, claimableAmount);
        }

        if(hasClaimedAny) {
            updateAllGlobalSnapshots();
        }
    }

    function gclaim(address sender) external nonReentrant whenNotPaused {
        require(msg.sender == address(gliquidToken), "Only GLIQUID token can call this");
        require(isLiquidityProvider[sender], "You must be a liquidity provider to claim fees.");

        address[] memory _tokenAddresses = gliquidToken.getTokenAddresses();
        bool hasClaimedAny = false;

        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            address tokenAddress = _tokenAddresses[i];
            uint256 claimableAmount = getClaimableAmount(sender, tokenAddress);

            if (claimableAmount == 0) continue;

            uint256 contractBalance = IERC20(tokenAddress).balanceOf(address(this));
            require(contractBalance >= claimableAmount, "Not enough tokens in the contract to cover the claim");

            feeManager.withdrawFees(tokenAddress, claimableAmount, sender);

            updateUserSnapshot(sender, tokenAddress);

            feesOwed[sender][tokenAddress] = 0;

            hasClaimedAny = true;

            emit FeesClaimed(sender, tokenAddress, claimableAmount);
        }

        if(hasClaimedAny) {
            updateAllGlobalSnapshots();
        }

        require(hasClaimedAny, "No fees available to claim"); 
    }

    function handleTransfer(address from, address to) external nonReentrant whenNotPaused {
        require(msg.sender == address(gliquidToken), "Only GLIQUID token can call this");

        isLiquidityProvider[from] = false;

        isLiquidityProvider[to] = true;
    }

    function bootstrapLiquidity(address token, uint256 amount, uint256 gliquidAmount) external onlyOwner {
        require(!isBootstrapped, "Already bootstrapped");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        gliquidToken.mint(msg.sender, gliquidAmount);

        if (!isLiquidityProvider[msg.sender]) {
            isLiquidityProvider[msg.sender] = true;
        }

        isBootstrapped = true;
        emit LiquidityAdded(msg.sender, gliquidAmount);
    }


    function addLiquidity(address token, uint256 amount) external nonReentrant whenNotPaused {
        require(gliquidToken.isTokenSupported(token), "Token not supported");

        uint256 tokenValueUSD = _getTokenValueUSD(token, amount);
        uint256 gliquidPrice = gliquidToken.getPrice();
        require(gliquidPrice > 0, "GLIQUID price is zero");
        uint256 gliquidMinted = tokenValueUSD.mul(gliquidPrice).div(1e18);

        liquidclaim(msg.sender);

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        gliquidToken.mint(msg.sender, gliquidMinted);

        if (!isLiquidityProvider[msg.sender]) {
            isLiquidityProvider[msg.sender] = true;
        }

        updateAllUserSnapshots(msg.sender);

        updateAllGlobalSnapshots();

        emit LiquidityAdded(msg.sender, gliquidMinted);
    }

    function _distributeRemovalFees(uint256 amountIn, address tokenIn, uint256 feePercentage) internal returns (uint256 amountAfterFees) {
        uint256 feeAmount = amountIn.mul(feePercentage).div(10000);
        uint256 devFee = feeAmount.mul(30).div(100);
        uint256 lpFee = feeAmount.mul(70).div(100);

        uint256 feeInUSD = _getTokenValueUSD(tokenIn, feeAmount);

        IERC20(tokenIn).safeTransfer(devAddress, devFee);
        
        IERC20(tokenIn).safeTransfer(address(feeManager), lpFee);
        feeManager.addFees(tokenIn, lpFee);

        updateFees(feeInUSD);

        return amountIn.sub(feeAmount);
    }

    function _getEquivalentTokenAmountForUSD(address token, uint256 usdAmount) internal view returns (uint256) {
        uint256 tokenDecimals = IExtendedERC20(token).decimals();
        uint256 tokenPriceUSD = gliquidToken.getTokenPriceUSD(token);

        uint256 precision = 10 ** 18;

        uint256 rawTokenAmount = usdAmount.mul(precision).div(tokenPriceUSD);

        if (tokenDecimals < 18) {
            return rawTokenAmount.div(10 ** (18 - tokenDecimals));
        } else if (tokenDecimals > 18) {
            return rawTokenAmount.mul(10 ** (tokenDecimals - 18));
        } else {
            return rawTokenAmount;
        }
    }

    function removeLiquidity(uint256 gliquidAmount, address tokenOut) external nonReentrant whenNotPaused {
        require(gliquidToken.balanceOf(msg.sender) >= gliquidAmount, "Not enough GLIQUID tokens");
        require(gliquidToken.isTokenSupported(tokenOut), "Token not supported");
        require(isLiquidityProvider[msg.sender], "You must be a liquidity provider to remove liquidity");
        
        uint256 gliquidDecimals = gliquidToken.decimals();
        uint256 gliquidValueUSD = gliquidAmount.mul(gliquidToken.getPrice()).div(10 ** gliquidDecimals);

        uint256 tokenOutAmount = _getEquivalentTokenAmountForUSD(tokenOut, gliquidValueUSD);

        uint256 amountAfterFees = _distributeRemovalFees(tokenOutAmount, tokenOut, OFEE);
        
        require(IERC20(tokenOut).balanceOf(address(this)) >= amountAfterFees, "Not enough tokenOut balance in pool");

        liquidclaim(msg.sender);

        updateAllUserSnapshots(msg.sender);

        IERC20(tokenOut).safeTransfer(msg.sender, amountAfterFees);

        gliquidToken.burn(msg.sender, gliquidAmount);
        
        if (gliquidToken.balanceOf(msg.sender) == 0) {
            isLiquidityProvider[msg.sender] = false;
        }

        updateAllGlobalSnapshots();

        emit LiquidityRemoved(msg.sender, gliquidAmount);
    }

    function _distributeSwapFees(uint256 amountIn, address tokenIn) internal returns (uint256 amountAfterFees) {
        (uint256 feeAmount, uint256 devFee, uint256 lpFee) = calculateFees(amountIn);

        uint256 feeInUSD = _getTokenValueUSD(tokenIn, feeAmount);

        IERC20(tokenIn).safeTransferFrom(msg.sender, devAddress, devFee);

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(feeManager), lpFee);
        feeManager.addFees(tokenIn, lpFee);

        updateFees(feeInUSD);

        return amountIn.sub(feeAmount);
    }

    function swap(address tokenIn, address tokenOut, uint256 amountIn, uint256 deadline) external nonReentrant whenNotPaused {
        require(block.timestamp <= deadline, "Transaction expired");
        require(tokenIn != tokenOut, "Input and output tokens can't be the same");
        require(gliquidToken.isTokenSupported(tokenIn) && gliquidToken.isTokenSupported(tokenOut), "Token not supported");

        uint256 amountOut = getAmountOut(amountIn, tokenIn, tokenOut);

        handleSwapTransfers(tokenIn, tokenOut, amountIn, amountOut);

        updateAllGlobalSnapshots();
        
        emit TokenSwapped(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    function calculateFees(uint256 amountIn) internal view returns (uint256 feeAmount, uint256 devFee, uint256 lpFee) {
        feeAmount = amountIn.mul(FEE).div(10000);
        devFee = feeAmount.mul(30).div(100);
        lpFee = feeAmount.mul(70).div(100);

        return (feeAmount, devFee, lpFee);
    }

    function getAllDailyVolumeUSD() external view returns (uint256) {
        address[] memory supportedTokens = gliquidToken.getTokenAddresses();

        uint256 totalVolumeUSD = 0;

        for (uint256 i = 0; i < supportedTokens.length; i++) {
            totalVolumeUSD += _getTokenValueUSD(supportedTokens[i], dailyTokenVolumes[supportedTokens[i]]);
        }

        return totalVolumeUSD;
    }

    function getDailyTokenVolume(address token) external view returns (uint256) {
        return dailyTokenVolumes[token];
    }

    function updateDailyVolume(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut) internal {
        uint256 currentTime = block.timestamp;

        if (currentTime - lastVolumeUpdateTime >= 1 days) {
            resetDailyVolume();
            lastVolumeUpdateTime = currentTime;
        }

        dailyTokenVolumes[tokenIn] += amountIn;

        dailyTokenVolumes[tokenOut] += amountOut;
    }

    function resetDailyVolume() internal {
        address[] memory supportedTokens = gliquidToken.getTokenAddresses();

        for (uint256 i = 0; i < supportedTokens.length; i++) {
            dailyTokenVolumes[supportedTokens[i]] = 0;
        }
    }

    function handleSwapTransfers(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut) internal {
        require(IERC20(tokenOut).balanceOf(address(this)) >= amountOut, "Not enough tokenOut in pool");

        updateDailyVolume(tokenIn, tokenOut, amountIn, amountOut);

        uint256 amountAfterFees = _distributeSwapFees(amountIn, tokenIn);

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountAfterFees);
        
        IERC20(tokenOut).safeTransfer(msg.sender, amountOut);
    }

    function getAmountOut(uint256 amountIn, address tokenIn, address tokenOut) public view returns (uint256) {
        uint256 valueIn = _getTokenValueUSD(tokenIn, amountIn);

        uint256 feeAmount = (valueIn * FEE) / 10000;
        uint256 valueInAfterFee = valueIn.sub(feeAmount);

        uint256 tokenOutPrice = gliquidToken.getTokenPriceUSD(tokenOut);
        require(tokenOutPrice > 0, "Token out price is zero");

        uint256 adjustedValueInAfterFee = valueInAfterFee.mul(10**18);
        uint256 amountOut = adjustedValueInAfterFee.div(tokenOutPrice);

        uint8 tokenOutDecimals = IExtendedERC20(tokenOut).decimals();
        uint256 amountOutNormalized = amountOut;

        if (tokenOutDecimals < 18) {
            amountOutNormalized = amountOut.div(10 ** (18 - tokenOutDecimals));
        } else if (tokenOutDecimals > 18) {
            amountOutNormalized = amountOut.mul(10 ** (tokenOutDecimals - 18));
        }

        uint256 usdValueOut = _getTokenValueUSD(tokenOut, amountOutNormalized);
        uint256 difference = valueIn > usdValueOut ? valueIn - usdValueOut : usdValueOut - valueIn;
        require(difference <= valueIn.mul(TOLERANCE).div(10000), "USD value mismatch between tokens");

        return amountOutNormalized;
    }
}