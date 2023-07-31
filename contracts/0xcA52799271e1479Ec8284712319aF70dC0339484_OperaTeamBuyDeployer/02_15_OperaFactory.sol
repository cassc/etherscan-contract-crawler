pragma solidity ^0.8.17;

//SPDX-License-Identifier: MIT
import "OperaToken.sol";
import "OperaRevenue.sol";
import "WETH.sol";
import "OperaLendingPool.sol";
import "OperaLocker.sol";
import "OperaDAO.sol";
import "IERC20.sol";
import "Math.sol";

contract OperaFactory {
    uint256 public feePerEth = 1 * 10 ** 17;
    uint256 public _tokenDecimals = 1 * 10 ** 18;
    uint256 public tokenDeployedCount;
    uint256 public lockTime;
    address public owner;
    address public WETHAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // address public WETHAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public operaRewardAddress;
    address public operaPoolAddress;
    address public operaLockerAddress;
    address public operaDAOAddress;

    mapping(uint256 => address) public tokenCountToAddress;
    mapping(uint256 => uint256) public initialLiquidityFromTokenCount;

    IDEXRouter public router;

    event feeChanged(uint256 amount);
    event tokenDeployed(
        address user,
        address token,
        uint256 amountEth,
        uint256 tokenCount,
        uint256 blocktime,
        string[] stringData,
        uint256[] uintData,
        address[] addressData
    );

    constructor(address[] memory _addressData) {
        owner = msg.sender;
        operaRewardAddress = _addressData[0];
        operaPoolAddress = _addressData[1];
        operaLockerAddress = _addressData[2];
        operaDAOAddress = _addressData[3];
        // router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "only owner");
        _;
    }
    modifier onlyDAO() {
        require(
            operaDAOAddress == msg.sender || msg.sender == owner,
            "only dao"
        );
        _;
    }

    function changeAddresses(address[] memory _addressData) external onlyOwner {
        operaRewardAddress = _addressData[0];
        operaPoolAddress = _addressData[1];
        operaLockerAddress = _addressData[2];
        operaDAOAddress = _addressData[3];
    }

    function updateFeePerEth(uint256 amount) external onlyOwner {
        feePerEth = amount;
        emit feeChanged(amount);
    }

    function updateLockTime(uint256 amount) external onlyOwner {
        require(amount <= 259200, "Locktime cannot be more than 3 days.");
        lockTime = amount;
    }

    function emitDeployedEvent(
        address token,
        uint256 amount,
        string[] memory _stringData,
        address[] memory _addressData,
        uint256[] memory _intData
    ) internal {
        emit tokenDeployed(
            msg.sender,
            token,
            amount,
            tokenDeployedCount,
            block.timestamp,
            _stringData,
            _intData,
            _addressData
        );
    }

    function deployToken(
        string[] memory _stringData,
        address[] memory _addressData,
        uint256[] memory _intData,
        uint256 _amountEthToBorrow
    ) external payable returns (address) {
        require(_amountEthToBorrow > 0, "Cannot deploy with 0 liquidity");
        uint256 feeEmountEth = _amountEthToBorrow * feePerEth;
        require(feeEmountEth == msg.value, "Send enough to cover the fee");
        OperaToken deployedToken = new OperaToken(
            _stringData,
            _addressData,
            _intData,
            operaRewardAddress
        );

        uint256 tokenAmount = deployedToken.balanceOf(address(this));
        deployedToken.approve(address(router), tokenAmount);
        OperaPool lender = OperaPool(payable(operaPoolAddress));
        lender.borrowEth(_amountEthToBorrow);
        router.addLiquidityETH{value: _amountEthToBorrow * _tokenDecimals}(
            address(deployedToken),
            tokenAmount,
            0,
            0,
            address(this),
            block.timestamp + 1
        );
        tokenCountToAddress[tokenDeployedCount] = address(deployedToken);
        initialLiquidityFromTokenCount[tokenDeployedCount] = _amountEthToBorrow;

        OperaRevenue rewardContract = OperaRevenue(payable(operaRewardAddress));
        lockLPTokens(deployedToken.pair());
        rewardContract.recieveRewards{value: msg.value}();
        OperaDAO daoContract = OperaDAO(payable(operaDAOAddress));
        daoContract.startTimer(
            uint64(tokenDeployedCount),
            uint64(block.timestamp + lockTime)
        );
        emitDeployedEvent(
            address(deployedToken),
            _amountEthToBorrow,
            _stringData,
            _addressData,
            _intData
        );
        tokenDeployedCount += 1;
        deployedToken.transferOwnership(payable(msg.sender));
        return address(deployedToken);
    }

    function lockLPTokens(address tokenPair) internal {
        OperaLocker locker = OperaLocker(payable(operaLockerAddress));
        IERC20 lpToken = IERC20(tokenPair);
        uint256 curBalance = lpToken.balanceOf(address(this));
        lpToken.approve(operaLockerAddress, curBalance);
        locker.lockTokens(tokenPair, curBalance, lockTime);
    }

    function increaseLockTime(uint256 id, uint256 timer) external onlyDAO {
        address tokenAddress = tokenCountToAddress[id];
        OperaToken deployedToken = OperaToken(payable(tokenAddress));
        OperaLocker locker = OperaLocker(payable(operaLockerAddress));
        locker.increaseLockTime(deployedToken.pair(), timer);
    }

    function claimLiquidityFromLockerWithId(
        uint256 tokenId
    ) external payable onlyDAO {
        address tokenAddress = tokenCountToAddress[tokenId];
        OperaToken deployedToken = OperaToken(payable(tokenAddress));
        OperaLocker locker = OperaLocker(payable(operaLockerAddress));
        uint256 tokenAmount = locker.getAddressLockedTokens(
            address(this),
            deployedToken.pair()
        );
        locker.withdrawTokenAmount(deployedToken.pair(), tokenAmount);
    }

    function claimLiquidityFromLockerWithAddress(
        address addy
    ) external payable onlyDAO {
        OperaToken deployedToken = OperaToken(payable(addy));
        OperaLocker locker = OperaLocker(payable(operaLockerAddress));
        uint256 tokenAmount = locker.getAddressLockedTokens(
            address(this),
            deployedToken.pair()
        );
        locker.withdrawTokenAmount(deployedToken.pair(), tokenAmount);
    }

    function removeLiquidity(uint256 tokenId) external onlyDAO returns (bool) {
        address tokenAddress = tokenCountToAddress[tokenId];
        OperaToken deployedToken = OperaToken(payable(tokenAddress));
        IERC20 lpToken = IERC20(deployedToken.pair());
        lpToken.approve(address(router), lpToken.balanceOf(address(this)));
        (uint256 amountA, uint256 amountB) = router.removeLiquidity(
            tokenAddress,
            WETHAddress,
            lpToken.balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp + 1
        );
        IWETH wethContract = IWETH(payable(WETHAddress));
        wethContract.withdraw(amountB);
        uint256 extraLP;
        if (
            initialLiquidityFromTokenCount[tokenId] * _tokenDecimals >= amountB
        ) {
            OperaPool poolContract = OperaPool(payable(operaPoolAddress));
            poolContract.returnLentEth{value: amountB}(
                initialLiquidityFromTokenCount[tokenId]
            );
        } else {
            extraLP =
                amountB -
                (initialLiquidityFromTokenCount[tokenId] * _tokenDecimals);

            OperaRevenue rewardContract = OperaRevenue(
                payable(operaRewardAddress)
            );
            rewardContract.recieveRewards{value: extraLP}();
            OperaPool poolContract = OperaPool(payable(operaPoolAddress));
            poolContract.returnLentEth{
                value: initialLiquidityFromTokenCount[tokenId] * _tokenDecimals
            }(initialLiquidityFromTokenCount[tokenId]);
        }
        return true;
    }

    function removeLiquiditySafeGaurd(uint256 tokenId) external onlyOwner {
        address tokenAddress = tokenCountToAddress[tokenId];
        OperaToken deployedToken = OperaToken(payable(tokenAddress));
        IERC20 lpToken = IERC20(deployedToken.pair());
        lpToken.approve(address(router), lpToken.balanceOf(address(this)));
        (uint256 amountA, uint256 amountB) = router.removeLiquidity(
            tokenAddress,
            WETHAddress,
            lpToken.balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp + 1
        );
    }

    function removeLiquiditySafeGaurdAddress(address addy) external onlyOwner {
        OperaToken deployedToken = OperaToken(payable(addy));
        IERC20 lpToken = IERC20(deployedToken.pair());
        lpToken.approve(address(router), lpToken.balanceOf(address(this)));
        (uint256 amountA, uint256 amountB) = router.removeLiquidity(
            addy,
            WETHAddress,
            lpToken.balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp + 1
        );
    }

    receive() external payable {}

    function rescueToken(address token) external onlyOwner {
        IERC20 tokenToRescue = IERC20(token);
        tokenToRescue.transfer(owner, tokenToRescue.balanceOf(address(this)));
    }

    function authorizeOverride(address token, address addy) external onlyOwner {
        OperaToken tokenToRescue = OperaToken(payable(token));
        tokenToRescue.factoryAuthorizeOverride(addy);
    }

    function rescueTokensETH(address token) external onlyOwner {
        OperaToken tokenToRescue = OperaToken(payable(token));
        tokenToRescue.clearStuckBalance();
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}