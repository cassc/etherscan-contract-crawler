// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libraries/Ownable.sol";
import "./interfaces/ITeamFinanceLocker.sol";
import "./interfaces/ITokenCutter.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IProofFactoryTokenCutter.sol";
import "./interfaces/IProofFactoryGate.sol";
import "./interfaces/IProofFactory.sol";

contract ProofFactory is Ownable, IProofFactory {
    mapping(address => ProofToken) public validatedPairs;

    // struct WhitelistAdd_ {
    //     address[] whitelists;
    // }

    address public proofAdmin;
    address public routerAddress;
    address public lockerAddress;
    address public factoryGate;
    address payable public revenueAddress;
    address payable public rewardPoolAddress;

    constructor(
        address _initialRouterAddress,
        address _initialLockerAddress,
        address _initialRewardPoolAddress,
        address _initialRevenueAddress,
        address _factoryGate
    ) {
        require(_initialRouterAddress != address(0), "zero router");
        require(_initialLockerAddress != address(0), "zero locker");
        require(
            _initialRewardPoolAddress != address(0),
            "zero rewardPool"
        );
        require(_initialRevenueAddress != address(0), "zero revenue");
        require(_factoryGate != address(0), "zero factory gate");

        routerAddress = _initialRouterAddress;
        lockerAddress = _initialLockerAddress;
        proofAdmin = msg.sender;
        revenueAddress = payable(_initialRevenueAddress);
        rewardPoolAddress = payable(_initialRewardPoolAddress);
        factoryGate = _factoryGate;
    }

    function createToken(TokenParam memory _tokenParam) external payable{
        require(
            _tokenParam.unlockTime >= block.timestamp + 30 days,
            "unlock too short"
        );
        require(msg.value >= 1 ether, "not enough lp");

        address newToken = IProofFactoryGate(factoryGate).createToken(
            _tokenParam,
            routerAddress,
            proofAdmin,
            msg.sender
        );

        IERC20(newToken).approve(routerAddress, type(uint256).max);

        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);
        router.addLiquidityETH{value: msg.value}(
            address(newToken),
            IERC20(newToken).balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp
        );

        // disable trading
        IProofFactoryTokenCutter(newToken).swapTradingStatus();

        validatedPairs[newToken] = ProofToken(
            false,
            IProofFactoryTokenCutter(newToken).pair(),
            msg.sender,
            _tokenParam.unlockTime,
            0
        );

        emit TokenCreated(newToken);
    }

    function finalizeToken(address tokenAddress) external override payable {
        _checkTokenStatus(tokenAddress);

        address _pair = validatedPairs[tokenAddress].pair;
        uint256 _unlockTime = validatedPairs[tokenAddress].unlockTime;
        IERC20(_pair).approve(lockerAddress, type(uint256).max);

        uint256 lpBalance = IERC20(_pair).balanceOf(address(this));

        uint256 _lockId = ITeamFinanceLocker(lockerAddress).lockToken{
            value: msg.value
        }(_pair, msg.sender, lpBalance, _unlockTime, false, 0x0000000000000000000000000000000000000000);
        validatedPairs[tokenAddress].lockId = _lockId;

        //enable trading
        ITokenCutter(tokenAddress).swapTradingStatus();
        ITokenCutter(tokenAddress).setLaunchedAt();

        validatedPairs[tokenAddress].status = true;
    }

    function addmoreWhitelist(address tokenAddress, WhitelistAdd_ memory _WhitelistAdd) external override {
        _checkTokenStatus(tokenAddress);

        IProofFactoryTokenCutter(tokenAddress).addMoreToWhitelist(IProofFactoryTokenCutter.WhitelistAdd_(_WhitelistAdd.whitelists));
        
    }

    function cancelToken(address tokenAddress) external {
        _checkTokenStatus(tokenAddress);

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

    function factoryRevenue() external payable virtual {
        if (address(this).balance >= 0) {
            uint256 bal = address(this).balance / 2;
            revenueAddress.transfer(bal);
            rewardPoolAddress.transfer(bal);
        }
    }

    function setProofAdmin(address newProofAdmin) external onlyOwner {
        proofAdmin = newProofAdmin;
    }

    function setLockerAddress(address newlockerAddress) external onlyOwner {
        lockerAddress = newlockerAddress;
    }

    function setRouterAddress(address newRouterAddress) external onlyOwner {
        routerAddress = payable(newRouterAddress);
    }

    function setRevenueAddress(address newRevenueAddress) external onlyOwner {
        revenueAddress = payable(newRevenueAddress);
    }

    function setRewardPoolAddress(
        address newRewardPoolAddress
    ) external onlyOwner {
        rewardPoolAddress = payable(newRewardPoolAddress);
    }

    function proofRevenueAddress() external view returns (address) {
        return revenueAddress;
    }

    function proofRewardPoolAddress() external view returns (address) {
        return rewardPoolAddress;
    }

    function _checkTokenStatus(address tokenAddress) internal view {
        require(validatedPairs[tokenAddress].owner == msg.sender, "!owner");
        require(validatedPairs[tokenAddress].status == false, "validated");
    }

    receive() external payable {}
}