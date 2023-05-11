// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./../interfaces/IXswapFarm.sol";
import "./../interfaces/IXRouter01.sol";

interface IWFTM is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

abstract contract Strategy is Ownable, Pausable {
    using SafeERC20 for IERC20;

    bool public isSingleVault;
    bool public isAutoComp;

    address public farmContractAddress; // address of farm, eg, PCS, Thugs etc.
    uint256 public pid; // pid of pool in farmContractAddress
    address public wantAddress;
    address public token0Address;
    address public token1Address;
    address public earnedAddress;
    address public uniRouterAddress; // uniswap, pancakeswap etc
    address public buybackRouterAddress; // uniswap, pancakeswap etc
    uint256 public routerDeadlineDuration = 300;  // Set on global level, could be passed to functions via arguments

    address public wftmAddress;
    address public vault;
    address public govAddress; // timelock contract

    uint256 public lastEarnBlock = 0;

    uint256 public controllerFee = 200;
    uint256 public constant controllerFeeMax = 10000; // 100 = 1%
    uint256 public constant controllerFeeUL = 2500; // 25%

    uint256 public partnerFee;
    address public partnerFeeAddress;
    uint256 public voterFee = 2500; // 25% of controllerFee
    address public voterFeeAddress;

    uint256 public withdrawFeeFactor;
    uint256 public constant withdrawFeeFactorMax = 10000;
    uint256 public constant withdrawFeeFactorLL = 9950;

    uint256 public slippageFactor = 950; // 5% default slippage tolerance
    uint256 public constant slippageFactorUL = 995;

    address[] public earnedToToken0Path;
    address[] public earnedToToken1Path;
    address[] public token0ToEarnedPath;
    address[] public token1ToEarnedPath;

    modifier onlyAllowGov() {
        require(msg.sender == govAddress, "Not authorised");
        _;
    }

    function balanceOf() public view returns (uint256) {
        return balanceOfWant() + balanceOfStakedWant();
    }

    function balanceOfWant() public view returns (uint256) {
        return IERC20(wantAddress).balanceOf(address(this));
    }

    function balanceOfStakedWant() public view returns (uint256) {
        if (farmContractAddress != address(0)) {
            (uint256 _amount,) = IXswapFarm(farmContractAddress).userInfo(pid, address(this));
            return _amount;
        } else {
            return 0;
        }
    }

    // Receives new deposits from user
    function deposit()
        public
        virtual
        whenNotPaused
    {
        uint256 wantBal = IERC20(wantAddress).balanceOf(address(this));
        if (isAutoComp && wantBal > 0) {
            _farm();
        }
    }

    function farm() public virtual {
        _farm();
    }

    function _farm() internal virtual {
        require(isAutoComp, "!isAutoComp");
        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        IERC20(wantAddress).safeIncreaseAllowance(farmContractAddress, wantAmt);

        IXswapFarm(farmContractAddress).deposit(pid, wantAmt);
    }

    function _unfarm(uint256 _wantAmt) internal virtual {
        IXswapFarm(farmContractAddress).withdraw(pid, _wantAmt);
    }

    function withdraw(uint256 _wantAmt)
        external
        virtual
    {
        require(msg.sender == vault, "!vault");
        require(_wantAmt > 0, "_wantAmt <= 0");

        uint256 wantBal = balanceOfWant();
        if (isAutoComp && wantBal < _wantAmt) {
            _unfarm(_wantAmt - wantBal);
            wantBal = balanceOfWant();
        }

        if (_wantAmt > wantBal) {
            _wantAmt = wantBal;
        }

        if (withdrawFeeFactor < withdrawFeeFactorMax) {
            _wantAmt = _wantAmt * withdrawFeeFactor / withdrawFeeFactorMax;
        }

        IERC20(wantAddress).safeTransfer(vault, _wantAmt);
    }

    function _harvest() internal virtual {
        _unfarm(0);
    }

    // 1. Harvest farm tokens
    // 2. Converts farm tokens into want tokens
    // 3. Deposits want tokens
    function earn() public virtual whenNotPaused {
        require(isAutoComp, "!isAutoComp");

        // Harvest farm tokens
        _harvest();

        // Converts farm tokens into want tokens
        uint256 earnedAmt = IERC20(earnedAddress).balanceOf(address(this));

        earnedAmt = distributeFees(earnedAmt);

        if (isSingleVault) {
            if (earnedAddress != wantAddress) {
                IERC20(earnedAddress).safeIncreaseAllowance(
                    uniRouterAddress,
                    earnedAmt
                );

                // Swap earned to want
                _safeSwap(
                    uniRouterAddress,
                    earnedAmt,
                    slippageFactor,
                    earnedToToken0Path,
                    address(this),
                    block.timestamp + routerDeadlineDuration
                );
            }
            lastEarnBlock = block.number;
            _farm();
            return;
        }

        IERC20(earnedAddress).safeIncreaseAllowance(
            uniRouterAddress,
            earnedAmt
        );

        if (earnedAddress != token0Address) {
            // Swap half earned to token0
            _safeSwap(
                uniRouterAddress,
                earnedAmt / 2,
                slippageFactor,
                earnedToToken0Path,
                address(this),
                block.timestamp + routerDeadlineDuration
            );
        }

        if (earnedAddress != token1Address) {
            // Swap half earned to token1
            _safeSwap(
                uniRouterAddress,
                earnedAmt / 2,
                slippageFactor,
                earnedToToken1Path,
                address(this),
                block.timestamp + routerDeadlineDuration
            );
        }

        // Get want tokens, ie. add liquidity
        uint256 token0Amt = IERC20(token0Address).balanceOf(address(this));
        uint256 token1Amt = IERC20(token1Address).balanceOf(address(this));
        if (token0Amt > 0 && token1Amt > 0) {
            IERC20(token0Address).safeIncreaseAllowance(
                uniRouterAddress,
                token0Amt
            );
            IERC20(token1Address).safeIncreaseAllowance(
                uniRouterAddress,
                token1Amt
            );
            IXRouter01(uniRouterAddress).addLiquidity(
                token0Address,
                token1Address,
                token0Amt,
                token1Amt,
                0,
                0,
                address(this),
                block.timestamp + routerDeadlineDuration
            );
        }

        lastEarnBlock = block.number;

        _farm();
    }

    function distributeFees(uint256 _earnedAmt) internal virtual returns (uint256) {
        if (_earnedAmt > 0) {
            // Performance fee
            if (controllerFee > 0) {
                uint256 fee = _earnedAmt * controllerFee / controllerFeeMax;
                uint256 controllerAmt = fee;
                uint256 voterAmt;
                uint256 partnerAmt;

                if (voterFee > 0) {
                    voterAmt = fee * voterFee / 10_000;
                    // handle possible rounding error
                    if (voterAmt > controllerAmt) {
                        voterAmt = controllerAmt;
                    }
                    controllerAmt -= voterAmt;
                    IERC20(earnedAddress).safeTransfer(voterFeeAddress, voterAmt); 
                }

                if (partnerFee > 0) {
                    partnerAmt = fee * partnerFee / 10_000;
                    // handle possible rounding error
                    if (partnerAmt > controllerAmt) {
                        partnerAmt = controllerAmt;
                    }
                    controllerAmt -= partnerAmt;
                    IERC20(earnedAddress).safeTransfer(partnerFeeAddress, partnerAmt); 
                }

                if (controllerAmt > 0) { 
                    IERC20(earnedAddress).safeTransfer(govAddress, controllerAmt); 
                }

                _earnedAmt = _earnedAmt - fee;
            }
        }

        return _earnedAmt;
    }

    function convertDustToEarned() public virtual whenNotPaused {
        require(isAutoComp, "!isAutoComp");
        require(!isSingleVault, "isSingleVault");

        // Converts dust tokens into earned tokens, which will be reinvested on the next earn().

        // Converts token0 dust (if any) to earned tokens
        uint256 token0Amt = IERC20(token0Address).balanceOf(address(this));
        if (token0Address != earnedAddress && token0Amt > 0) {
            IERC20(token0Address).safeIncreaseAllowance(
                uniRouterAddress,
                token0Amt
            );

            // Swap all dust tokens to earned tokens
            _safeSwap(
                uniRouterAddress,
                token0Amt,
                slippageFactor,
                token0ToEarnedPath,
                address(this),
                block.timestamp + routerDeadlineDuration
            );
        }

        // Converts token1 dust (if any) to earned tokens
        uint256 token1Amt = IERC20(token1Address).balanceOf(address(this));
        if (token1Address != earnedAddress && token1Amt > 0) {
            IERC20(token1Address).safeIncreaseAllowance(
                uniRouterAddress,
                token1Amt
            );

            // Swap all dust tokens to earned tokens
            _safeSwap(
                uniRouterAddress,
                token1Amt,
                slippageFactor,
                token1ToEarnedPath,
                address(this),
                block.timestamp + routerDeadlineDuration
            );
        }
    }

    function pause() public virtual onlyAllowGov {
        _pause();
    }

    function unpause() external virtual onlyAllowGov {
        _unpause();
    }

    function setControllerFee(uint256 _controllerFee) public onlyAllowGov{
        require(_controllerFee <= controllerFeeUL, "too high");
        controllerFee = _controllerFee;
    }

    function setVoterFee(uint256 _voterFee, address _voterFeeAddress) public onlyAllowGov{
        require(_voterFee + partnerFee <= 10_000, "too high");
        require(_voterFeeAddress != address(0), "Zero address not allowed");
        voterFee = _voterFee;
        voterFeeAddress = _voterFeeAddress;
    }

    function setPartnerFee(uint256 _partnerFee, address _partnerFeeAddress) public onlyAllowGov{
        require(_partnerFee + voterFee <= 10_000, "too high");
        require(_partnerFeeAddress != address(0), "Zero address not allowed");
        partnerFee = _partnerFee;
        partnerFeeAddress = _partnerFeeAddress;
    }

    function setGov(address _govAddress) public virtual onlyAllowGov {
        govAddress = _govAddress;
    }

    function setWithdrawFeeFactor(uint256 _withdrawFeeFactor) public onlyAllowGov {
        require(_withdrawFeeFactor > withdrawFeeFactorLL, "!safe - too low");
        require(_withdrawFeeFactor <= withdrawFeeFactorMax, "!safe - too high");
        withdrawFeeFactor = _withdrawFeeFactor;
    }

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) public virtual onlyAllowGov {
        require(_token != earnedAddress, "!safe");
        require(_token != wantAddress, "!safe");
        IERC20(_token).safeTransfer(_to, _amount);
    }

    function _wrapFTM() internal virtual onlyAllowGov {
        // FTM -> WFTM
        uint256 ftmBal = address(this).balance;
        if (ftmBal > 0) {
            IWFTM(wftmAddress).deposit{value: ftmBal}(); // FTM -> WFTM
        }
    }

    function _safeSwap(
        address _uniRouterAddress,
        uint256 _amountIn,
        uint256 _slippageFactor,
        address[] memory _path,
        address _to,
        uint256 _deadline
    ) internal virtual {
        uint256[] memory amounts =
            IXRouter01(_uniRouterAddress).getAmountsOut(_amountIn, _path);
        uint256 amountOut = amounts[amounts.length - 1];

        IXRouter01(_uniRouterAddress)
            .swapExactTokensForTokens(
            _amountIn,
            amountOut * _slippageFactor / 1000,
            _path,
            _to,
            _deadline
        );
    }
}