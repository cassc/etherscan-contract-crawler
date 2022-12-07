// SPDX-License-Identifier: None
pragma solidity = 0.8.17;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./libraries/Ownable.sol";
import "./libraries/ProofNonReflectionTokenFees.sol";
import "./libraries/Context.sol";
import "./interfaces/ITeamFinanceLocker.sol";
import "./interfaces/ITokenCutter.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IFACTORY.sol";
import "./interfaces/IProofNonReflectionTokenCutter.sol";
import "./tokenCutters/ProofNonReflectionTokenCutter.sol";

contract ProofNonReflectionTokenFactory is Ownable {
    struct proofToken {
        bool status;
        address pair;
        address owner;
        uint256 unlockTime;
        uint256 lockId;
    }

    struct tokenParam {
        string tokenName;
        string tokenSymbol;
        uint256 initialSupply;
        uint percentToLP;
        uint256 initialMainFee;
        uint256 initialMainFeeOnSell;
        uint256 initialLpFee;
        uint256 initialLpFeeOnSell;
        uint256 initialDevFee;
        uint256 initialDevFeeOnSell;
        uint256 unlockTime;
        address operationsWallet;
        address mainWallet;
    }

    mapping(address => proofToken) public validatedPairs;

    address public proofAdmin;
    address public routerAddress;
    address public lockerAddress;
    address payable public revenueAddress;
    address payable public rewardPoolAddress;

    event TokenCreated(address _address);

    constructor(
        address initialRouterAddress,
        address initialLockerAddress,
        address initialRewardPoolAddress,
        address initialRevenueAddress
    ) {
        routerAddress = initialRouterAddress;
        lockerAddress = initialLockerAddress;
        revenueAddress = payable(initialRevenueAddress);
        rewardPoolAddress = payable(initialRewardPoolAddress);
        proofAdmin = msg.sender;
    }

    function createToken(
        tokenParam memory tokenParam_
    ) external payable {
        require(
            tokenParam_.unlockTime >= block.timestamp + 30 days,
            "unlock under 30 days"
        );
        require(msg.value >= 1 ether, "not enough liquidity");

        //create token
        ProofNonReflectionTokenFees.allFees memory fees = ProofNonReflectionTokenFees.allFees(
            tokenParam_.initialMainFee,
            tokenParam_.initialMainFeeOnSell,
            tokenParam_.initialLpFee,
            tokenParam_.initialLpFeeOnSell,
            tokenParam_.initialDevFee,
            tokenParam_.initialDevFeeOnSell
        );
        ProofNonReflectionTokenCutter newToken = new ProofNonReflectionTokenCutter();

        IProofNonReflectionTokenCutter(address(newToken)).setBasicData(
            tokenParam_.tokenName,
            tokenParam_.tokenSymbol,
            tokenParam_.initialSupply,
            tokenParam_.percentToLP,
            msg.sender,
            tokenParam_.operationsWallet,
            tokenParam_.mainWallet,
            routerAddress,
            proofAdmin,
            fees
        );
        emit TokenCreated(address(newToken));

        //add liquidity
        newToken.approve(routerAddress, type(uint256).max);
        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);
        router.addLiquidityETH{value: msg.value}(
            address(newToken),
            newToken.balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp
        );

        // disable trading
        newToken.swapTradingStatus();

        validatedPairs[address(newToken)] = proofToken(
            false,
            newToken.pair(),
            msg.sender,
            tokenParam_.unlockTime,
            0
        );
    }

    function finalizeToken(address tokenAddress) external payable {
        require(validatedPairs[tokenAddress].owner == msg.sender, "!owner");
        require(validatedPairs[tokenAddress].status == false, "validated");

        address _pair = validatedPairs[tokenAddress].pair;
        uint256 _unlockTime = validatedPairs[tokenAddress].unlockTime;
        IERC20(_pair).approve(lockerAddress, type(uint256).max);

        uint256 lpBalance = IERC20(_pair).balanceOf(address(this));

        uint256 _lockId = ITeamFinanceLocker(lockerAddress).lockToken{
            value: msg.value
        }(_pair, msg.sender, lpBalance, _unlockTime, false);
        validatedPairs[tokenAddress].lockId = _lockId;

        //enable trading
        ITokenCutter(tokenAddress).swapTradingStatus();
        ITokenCutter(tokenAddress).setLaunchedAt();

        validatedPairs[tokenAddress].status = true;
    }

    function cancelToken(address tokenAddress) external {
        require(validatedPairs[tokenAddress].owner == msg.sender, "!owner");
        require(validatedPairs[tokenAddress].status == false, "validated");

        address _pair = validatedPairs[tokenAddress].pair;
        address _owner = validatedPairs[tokenAddress].owner;

        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);
        IERC20(_pair).approve(routerAddress, type(uint256).max);
        uint256 _lpBalance = IERC20(_pair).balanceOf(address(this));

        // enable transfer and allow router to exceed tx limit to remove liquidity
        ITokenCutter(tokenAddress).cancelToken();
        router.removeLiquidityETH(
            address(tokenAddress),
            _lpBalance,
            0,
            0,
            _owner,
            block.timestamp
        );

        // disable transfer of token
        ITokenCutter(tokenAddress).swapTradingStatus();

        delete validatedPairs[tokenAddress];
    }

    function setLockerAddress(address newlockerAddress) external onlyOwner {
        lockerAddress = newlockerAddress;
    }

    function setRouterAddress(address newRouterAddress) external onlyOwner {
        routerAddress = payable(newRouterAddress);
    }

    function factoryRevenue() external payable virtual {
        if (address(this).balance >= 0) {
            uint256 bal = address(this).balance/2;
            revenueAddress.transfer(bal);
            rewardPoolAddress.transfer(bal);
        }
    }

    function setProofAdmin(address newProofAdmin) external onlyOwner {
        proofAdmin = newProofAdmin;
    }

    function setRevenueAddress(address newRevenueAddress) external onlyOwner {
        revenueAddress = payable(newRevenueAddress);
    }

    function setRewardPoolAddress(address newRewardPoolAddress) external onlyOwner {
        rewardPoolAddress = payable(newRewardPoolAddress);
    }

    receive() external payable {}
}