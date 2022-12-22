// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IUniswapConnector.sol";
import "./interfaces/IAave.sol";
import "./interfaces/IS3Proxy.sol";
import "./interfaces/IS3Admin.sol";
import "./proxies/S3TokenAaveVesperFinanceDAIProxy.sol";


interface IFees {
    function feeCollector(uint256 _index) external view returns (address);
    function depositStatus(uint256 _index) external view returns (bool);
    function calcFee(
        uint256 _strategyId,
        address _user,
        address _feeToken
    ) external view returns (uint256);
    function whitelistedDepositCurrencies(uint256 _index, address _token) external view returns(bool);
}


contract S3TokenAaveVesperFinanceDAI {
    uint8 public constant strategyIndex = 12;
    address public s3Admin;
    address public feesAddress;
    address public uniswapConnector;
    address public wethAddress;
    address public daiAddress;
    
    // protocols
    address public vPoolDAI;
    address public vPoolRewardsDAI;
    address public vspToken;
    address public collateral;
    address public aCollateral;
    mapping(address => address) public depositors; 

    constructor(
        address _s3Admin,
        address _feesAddress,
        address _uniswapConnector,
        address _wethAddress,
        address _daiAddress,
        address _vPoolDAI,
        address _vPoolRewardsDAI,
        address _vspToken,
        address _collateral,
        address _aCollateral
    ) {
        s3Admin = _s3Admin;
        feesAddress = _feesAddress;
        uniswapConnector = _uniswapConnector;
        wethAddress = _wethAddress;
        daiAddress = _daiAddress;
        vPoolDAI = _vPoolDAI;
        vPoolRewardsDAI = _vPoolRewardsDAI;
        vspToken = _vspToken;
        collateral = _collateral; 
        aCollateral = _aCollateral;
    }

    event Deposit(address indexed _depositor, address indexed _token, uint256 _amountIn);

    event Withdraw(address indexed _depositor, uint8 _percentage, uint256 _amount, uint256 _fee);

    event WithdrawCollateral(address indexed _depositor, uint8 _percentage, uint256 _amount, uint256 _fee);

    event ClaimAdditionalTokens(address indexed _depositor, uint256 _amount0, uint256 _amount1, address indexed _swappedTo);

    // Get the current unclaimed VSP tokens amount
    function getPendingAdditionalTokenClaims(address _address) external view returns(address[] memory _rewardTokens, uint256[] memory _claimableAmounts) {
        return IVPoolRewards(vPoolRewardsDAI).claimable(depositors[_address]);
    }   
    
    // Get the current Vesper Finance deposit
    function getCurrentDeposit(address _address) external view returns(uint256, uint256) {
        uint256 vaDAIShare = IERC20(vPoolDAI).balanceOf(depositors[_address]);
        uint256 daiEquivalent;
        if (vaDAIShare > 0) {
            uint256 pricePerShare = IVPoolDAI(vPoolDAI).pricePerShare();
            daiEquivalent = (pricePerShare * vaDAIShare) / 10 ** 18;
        }
        
        return (vaDAIShare, daiEquivalent);
    }

    function getCurrentDebt(address _address) external view returns(uint256) {
        return IERC20(IS3Admin(s3Admin).interestTokens(strategyIndex)).balanceOf(depositors[_address]);
    }

    function getMaxUnlockedCollateral(address _address) external view returns(uint256) {
        (, uint256 totalDebtETH, , uint256 currentLiquidationThreshold, , ) = IAave(IS3Admin(s3Admin).aave()).getUserAccountData(depositors[_address]);
        uint256 maxAmountToBeWithdrawn;
        if (totalDebtETH > 0) {
            uint256 collateralPriceRatio = IPriceOracleGetter(IS3Admin(s3Admin).aavePriceOracle()).getAssetPrice(collateral);
            maxAmountToBeWithdrawn = (((10100 * totalDebtETH) / currentLiquidationThreshold) * 10 ** IERC20(collateral).decimals()) / collateralPriceRatio;
            maxAmountToBeWithdrawn = IERC20(aCollateral).balanceOf(depositors[_address]) - maxAmountToBeWithdrawn;
        } else {
            maxAmountToBeWithdrawn = IERC20(aCollateral).balanceOf(depositors[_address]);
        }

        return maxAmountToBeWithdrawn;
    }

    // Get the current Aave status
    function getAaveStatus(address _address) external view returns(uint256, uint256, uint256, uint256, uint256, uint256) {
        return IAave(IS3Admin(s3Admin).aave()).getUserAccountData(depositors[_address]); 
    }

    function depositToken(address _token, uint256 _amount, uint8 _borrowPercentage, bool _borrowAndDeposit) external {
        require(IFees(feesAddress).depositStatus(strategyIndex), "ERR: DEPOSITS_STOPPED");
        if (_borrowAndDeposit) {
            require(IS3Admin(s3Admin).whitelistedAaveBorrowPercAmounts(_borrowPercentage), "ERROR: INVALID_BORROW_PERC");
        }
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        if (depositors[msg.sender] == address(0)) {
            // deploy new proxy contract
            S3TokenAaveVesperFinanceDAIProxy s3proxy = new S3TokenAaveVesperFinanceDAIProxy(
                address(this),
                uniswapConnector,
                wethAddress,
                daiAddress,
                vPoolDAI,
                vPoolRewardsDAI,
                vspToken,
                IS3Admin(s3Admin).aave(),
                collateral,
                aCollateral
            );  
            s3proxy.setupAaveAddresses(
                IS3Admin(s3Admin).aavePriceOracle(),
                IS3Admin(s3Admin).interestTokens(strategyIndex)
            );
            depositors[msg.sender] = address(s3proxy);
            IERC20(_token).approve(depositors[msg.sender], 2**256 - 1);
            s3proxy.deposit(_token, _amount, _borrowPercentage, _borrowAndDeposit); 
        } else {
            // send the deposit to the existing proxy contract
            if (IERC20(_token).allowance(address(this), depositors[msg.sender]) == 0) {
                IERC20(_token).approve(depositors[msg.sender], 2**256 - 1); 
            }

            IS3Proxy(depositors[msg.sender]).deposit(_token, _amount, _borrowPercentage, _borrowAndDeposit);
        }

        emit Deposit(msg.sender, _token, _amount);
    }

    // claim VSP tokens and withdraw them
    function claimRaw() external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        uint256 truTokens = IS3Proxy(depositors[msg.sender]).claimToDepositor(msg.sender); 

        emit ClaimAdditionalTokens(msg.sender, truTokens, 0, address(0));
    }

    // claim VSP tokens, swap them for ETH and withdraw
    function claimInETH(uint256 _amountOutMin) external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        uint256 vspTokens = IS3Proxy(depositors[msg.sender]).claimToDeployer();

        if (IERC20(vspToken).allowance(address(this), uniswapConnector) == 0) {
            IERC20(vspToken).approve(uniswapConnector, 2**256 - 1);
        }
        uint256 wethAmount = IUniswapConnector(uniswapConnector).swapTokenForToken(
            vspToken,
            wethAddress,
            vspTokens,
            _amountOutMin,
            address(this)
        );

        // swap WETH for ETH
        IWETH(wethAddress).withdraw(wethAmount);
        // withdraw ETH
        (bool success, ) = payable(msg.sender).call{value: wethAmount}("");
        require(success, "ERR: FAIL_SENDING_ETH");

        emit ClaimAdditionalTokens(msg.sender, vspTokens, wethAmount, wethAddress);
    }

    // claim VSP tokens, swap them for _token and withdraw
    function claimInToken(address _token, uint256 _amountOutMin) external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR"); 

        uint256 vspTokens = IS3Proxy(depositors[msg.sender]).claimToDeployer();
        if (IERC20(vspToken).allowance(address(this), uniswapConnector) == 0) {
            IERC20(vspToken).approve(uniswapConnector, 2**256 - 1);
        }
        uint256 tokenAmount = IUniswapConnector(uniswapConnector).swapTokenForToken(
            vspToken, 
            _token,
            vspTokens, 
            _amountOutMin, 
            msg.sender
        );

        emit ClaimAdditionalTokens(msg.sender, vspTokens, tokenAmount, _token);
    } 

    function withdraw(uint8 _percentage, uint256 _amountInMaximum, uint256 _amountOutMin, address _feeToken) external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR"); 

        uint256 tokenAmountToBeWithdrawn = IS3Proxy(depositors[msg.sender]).withdraw(_percentage, _amountInMaximum); 
        tokenAmountToBeWithdrawn += _swapYieldProfitTo(depositors[msg.sender], _amountOutMin);

        uint256 fee = (tokenAmountToBeWithdrawn * IFees(feesAddress).calcFee(strategyIndex, msg.sender, _feeToken)) / 1000;
        if (fee > 0) { 
            IERC20(collateral).transfer(
                IFees(feesAddress).feeCollector(strategyIndex),
                fee
            );
        }
        IERC20(collateral).transfer(
            msg.sender,
            tokenAmountToBeWithdrawn - fee
        );

        emit Withdraw(msg.sender, _percentage, tokenAmountToBeWithdrawn, fee);
    }

    function withdrawCollateral(uint8 _percentage, address _feeToken) external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");

        uint256 tokenAmountToBeWithdrawn = IS3Proxy(depositors[msg.sender]).withdrawCollateral(_percentage);
        uint256 fee = (tokenAmountToBeWithdrawn * IFees(feesAddress).calcFee(strategyIndex, msg.sender, _feeToken)) / 1000;
        if (fee > 0) {
            IERC20(collateral).transfer(
                IFees(feesAddress).feeCollector(strategyIndex),
                fee
            );
        }
        IERC20(collateral).transfer(
            msg.sender,
            tokenAmountToBeWithdrawn - fee
        );

        emit WithdrawCollateral(msg.sender, _percentage, tokenAmountToBeWithdrawn, fee);
    }

    function emergencyWithdraw(address _token) external {
        require(!IFees(feesAddress).depositStatus(strategyIndex), "ERR: DEPOSITS_ARE_ON");
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");

        IS3Proxy(depositors[msg.sender]).emergencyWithdraw(_token, msg.sender);
    }

    function _swapYieldProfitTo(address _proxy, uint256 _amountOutMin) private returns(uint256) {
        if (IERC20(daiAddress).balanceOf(_proxy) > 0) {
            if (IERC20(daiAddress).allowance(address(this), uniswapConnector) == 0) {
                IERC20(daiAddress).approve(uniswapConnector, 2**256 - 1);
            }
            uint256 tokenAmount = IUniswapConnector(uniswapConnector).swapTokenForToken(
                daiAddress, 
                collateral,
                IERC20(daiAddress).balanceOf(address(this)), 
                _amountOutMin, 
                address(this)
            );
            
            return tokenAmount;
        } else {
            return 0;
        } 
    }

    receive() external payable {} 
}

// MN bby ¯\_(ツ)_/¯