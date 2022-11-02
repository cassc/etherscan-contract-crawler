// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../external/uniswap/IUniswapV3.sol";
import "../../../external/uniswap/IQuoter.sol";
import "../uniswapv3/ETHUniswapV3BaseStrategy.sol";

/// @title StakeWiseEthSeth23000Strategy
/// @notice Investment strategy for investing ETH via ETH-sETH-pool of StakeWise
/// @author Bank of Chain Protocol Inc
contract StakeWiseEthSeth23000Strategy is ETHUniswapV3BaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // https://info.uniswap.org/#/pools/0x7379e81228514a1d2a6cf7559203998e20598346
    address internal constant UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address internal constant SETH2 = 0xFe2e637202056d30016725477c5da089Ab0A043A;
    address internal constant RETH2 = 0x20BC832ca081b91433ff6c17f85701B6e92486c5;
    address internal constant SWISE = 0x48C3399719B582dD63eB5AADf12A40B4C3f52FA2;

    /// @notice Initialize this contract
    /// @param _vault The ETH vaults
    /// @param _name The name of strategy
    function initialize(address _vault, string memory _name) public initializer {
        uniswapV3Initialize(0x7379e81228514a1D2a6Cf7559203998E20598346, 60, 60, 41400, 0, 100, 60, 60);
        address[] memory _wants = new address[](2);
        _wants[0] = token0;
        _wants[1] = token1;
        super._initialize(_vault, uint16(ProtocolEnum.StakeWise), _name, _wants);
    }

    /// @inheritdoc ETHUniswapV3BaseStrategy
    function getOutputsInfo() external view virtual override returns (OutputInfo[] memory _outputsInfo){
        _outputsInfo = new OutputInfo[](1);
        _outputsInfo[0].outputTokens = wants;
    }

    /// @inheritdoc ETHUniswapV3BaseStrategy
    function claimRewards() internal override returns (bool _isWorth, address[] memory _assets, uint256[] memory _amounts) {
        (_isWorth, _assets, _amounts) = super.claimRewards();
        swapRewardsToWants();
    }

    /// @inheritdoc ETHUniswapV3BaseStrategy
    function swapRewardsToWants() internal override returns(address[] memory _wantTokens,uint256[] memory _wantAmounts){
        // fulfill 'SwapRewardsToWants' event data
        _wantTokens = new address[](2);
        _wantTokens[0] = SETH2;
        _wantTokens[1] = SETH2;
        _wantAmounts = new uint256[](2);

        uint256 _seth2BalanceInit = balanceOfToken(SETH2);
        uint256 _balanceOfRETH2 = balanceOfToken(RETH2);
        if (_balanceOfRETH2 > 0) {
            IERC20(RETH2).approve(UNISWAP_V3_ROUTER, _balanceOfRETH2);
            IUniswapV3(UNISWAP_V3_ROUTER).exactInputSingle(IUniswapV3.ExactInputSingleParams(RETH2, SETH2, 500, address(this), block.timestamp, _balanceOfRETH2, 0, 0));
        }
        uint256 _seth2BalanceAfterSellReth2 = balanceOfToken(SETH2);
        _wantAmounts[0] = _seth2BalanceAfterSellReth2 - _seth2BalanceInit;

        uint256 _balanceOfSwise = balanceOfToken(SWISE);
        if (_balanceOfSwise > 0) {
            IERC20(SWISE).approve(UNISWAP_V3_ROUTER, _balanceOfSwise);
            IUniswapV3(UNISWAP_V3_ROUTER).exactInputSingle(IUniswapV3.ExactInputSingleParams(SWISE, SETH2, 3000, address(this), block.timestamp, _balanceOfSwise, 0, 0));
        }
        _wantAmounts[1] = balanceOfToken(SETH2) - _seth2BalanceAfterSellReth2;

        address[] memory _rewardsTokens = new address[](2);
        _rewardsTokens[0] = RETH2;
        _rewardsTokens[1] = SWISE;
        uint256[] memory _claimAmounts = new uint256[](2);
        _claimAmounts[0] = _balanceOfRETH2;
        _claimAmounts[1] = _balanceOfSwise;

        emit SwapRewardsToWants(address(this), _rewardsTokens, _claimAmounts, _wantTokens, _wantAmounts);
    }
}