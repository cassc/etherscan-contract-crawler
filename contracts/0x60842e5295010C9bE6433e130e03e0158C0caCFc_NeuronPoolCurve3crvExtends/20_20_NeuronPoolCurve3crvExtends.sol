// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ICurveFi_2, ICurveFi_3 } from "../../interfaces/ICurve.sol";
import { NeuronPoolBaseInitialize } from "../NeuronPoolBaseInitialize.sol";

contract NeuronPoolCurve3crvExtends is NeuronPoolBaseInitialize {
    using SafeERC20 for IERC20Metadata;

    ICurveFi_2 internal BASE_POOL;

    ICurveFi_3 internal constant THREE_POOL = ICurveFi_3(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);

    IERC20Metadata internal FIRST_TOKEN_IN_BASE_POOL;
    IERC20Metadata internal constant CRV3 = IERC20Metadata(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
    IERC20Metadata internal constant DAI = IERC20Metadata(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20Metadata internal constant USDT = IERC20Metadata(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    function initialize(
        address _token,
        address _governance,
        address _controller,
        address _basePool,
        address _firstTokenInBasePool
    ) external initializer {
        __NeuronPoolBaseInitialize_init(_token, _governance, _controller);
        BASE_POOL = ICurveFi_2(_basePool);
        FIRST_TOKEN_IN_BASE_POOL = IERC20Metadata(_firstTokenInBasePool);
    }

    function getSupportedTokens() external view override returns (address[] memory tokens) {
        tokens = new address[](6);
        tokens[0] = address(token);
        tokens[1] = address(FIRST_TOKEN_IN_BASE_POOL);
        tokens[2] = address(CRV3);
        tokens[3] = address(DAI);
        tokens[4] = address(USDC);
        tokens[5] = address(USDT);
    }

    function deposit(address _enterToken, uint256 _amount) public payable override nonReentrant returns (uint256) {
        require(_amount > 0, "!_amount");

        address self = address(this);
        IERC20Metadata enterToken = IERC20Metadata(_enterToken);
        IERC20Metadata _token = token;

        uint256 _balance = balance();

        if (enterToken == _token) {
            _token.safeTransferFrom(msg.sender, self, _amount);
        } else {
            _amount = depositBaseToken(enterToken, _amount);
        }

        return _mintShares(_amount, _balance);
    }

    function deposit3poolToken(
        IERC20Metadata _enterToken,
        uint256 _amount,
        uint256[3] memory _addLiquidityPayload
    ) internal returns (uint256 crv3amount) {
        address self = address(this);

        _enterToken.safeApprove(address(THREE_POOL), 0);
        _enterToken.safeApprove(address(THREE_POOL), _amount);

        uint256 initial3crvBalance = CRV3.balanceOf(self);

        THREE_POOL.add_liquidity(_addLiquidityPayload, 0);

        uint256 result3crvTokenBalance = CRV3.balanceOf(self);

        require(result3crvTokenBalance > initial3crvBalance, "Tokens were not received from the 3pool");

        return result3crvTokenBalance - initial3crvBalance;
    }

    function depositBaseToken(IERC20Metadata _enterToken, uint256 _amount) internal returns (uint256) {
        address self = address(this);
        IERC20Metadata _token = token;

        _enterToken.safeTransferFrom(msg.sender, self, _amount);

        if (_enterToken == DAI) {
            _amount = deposit3poolToken(_enterToken, _amount, [_amount, 0, 0]);
            _enterToken = CRV3;
        } else if (_enterToken == USDC) {
            _amount = deposit3poolToken(_enterToken, _amount, [0, _amount, 0]);
            _enterToken = CRV3;
        } else if (_enterToken == USDT) {
            _amount = deposit3poolToken(_enterToken, _amount, [0, 0, _amount]);
            _enterToken = CRV3;
        }

        uint256[2] memory addLiquidityPayload;
        if (_enterToken == FIRST_TOKEN_IN_BASE_POOL) {
            addLiquidityPayload[0] = _amount;
        } else if (_enterToken == CRV3) {
            addLiquidityPayload[1] = _amount;
        } else {
            revert("!token");
        }

        ICurveFi_2 BASE_POOL_MEM = BASE_POOL;
        _enterToken.safeApprove(address(BASE_POOL_MEM), 0);
        _enterToken.safeApprove(address(BASE_POOL_MEM), _amount);

        uint256 initialLpTokenBalance = _token.balanceOf(self);

        BASE_POOL_MEM.add_liquidity(addLiquidityPayload, 0);

        uint256 resultLpTokenBalance = _token.balanceOf(self);

        require(resultLpTokenBalance > initialLpTokenBalance, "Tokens were not received from the base pool");

        return resultLpTokenBalance - initialLpTokenBalance;
    }

    function withdraw(address _withdrawableToken, uint256 _shares) public override nonReentrant {
        uint256 amount = _withdrawLpTokens(_shares);

        IERC20Metadata withdrawableToken = IERC20Metadata(_withdrawableToken);

        if (withdrawableToken != token) {
            amount = withdrawBaseToken(address(_withdrawableToken), amount);
        }

        require(amount > 0, "!amount");

        withdrawableToken.safeTransfer(msg.sender, amount);
    }

    function withdrawBaseToken(address _withdrawableToken, uint256 _userLpTokensAmount) internal returns (uint256) {
        address self = address(this);
        IERC20Metadata withdrawableToken = IERC20Metadata(_withdrawableToken);

        int128 firstLevelTokenIndex;
        int128 secondLevelTokenIndex = -1;

        if (withdrawableToken == DAI) {
            secondLevelTokenIndex = 0;
        } else if (withdrawableToken == USDC) {
            secondLevelTokenIndex = 1;
        } else if (withdrawableToken == USDT) {
            secondLevelTokenIndex = 2;
        } else if (withdrawableToken == FIRST_TOKEN_IN_BASE_POOL) {
            firstLevelTokenIndex = 0;
        } else if (withdrawableToken == CRV3) {
            firstLevelTokenIndex = 1;
        } else {
            revert("!token");
        }

        bool isTwoLevel = secondLevelTokenIndex > -1;

        IERC20Metadata firstLevelToken = isTwoLevel ? CRV3 : withdrawableToken;
        uint256 initialFirstLevelTokenBalance = firstLevelToken.balanceOf(self);
        BASE_POOL.remove_liquidity_one_coin(_userLpTokensAmount, isTwoLevel ? int128(1) : firstLevelTokenIndex, 0);
        uint256 resultFirstLevelTokenBalance = firstLevelToken.balanceOf(self);

        require(resultFirstLevelTokenBalance > initialFirstLevelTokenBalance, "!firstLevelTokensAmount");

        uint256 withdrawAmount = resultFirstLevelTokenBalance - initialFirstLevelTokenBalance;

        if (isTwoLevel) {
            uint256 initialSecondLevelTokenBalance = withdrawableToken.balanceOf(self);
            THREE_POOL.remove_liquidity_one_coin(withdrawAmount, secondLevelTokenIndex, 0);
            uint256 resultSecondLevelTokenBalance = withdrawableToken.balanceOf(self);

            require(resultSecondLevelTokenBalance > initialSecondLevelTokenBalance, "!secondLevelTokensAmount");

            withdrawAmount = resultSecondLevelTokenBalance - initialSecondLevelTokenBalance;
        }
        return withdrawAmount;
    }
}