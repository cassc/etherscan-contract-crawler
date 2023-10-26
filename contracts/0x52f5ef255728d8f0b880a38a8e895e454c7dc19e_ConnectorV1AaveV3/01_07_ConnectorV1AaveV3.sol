// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../Interfaces.sol";

// ConnectorId : 1
contract ConnectorV1AaveV3 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== Layout ========== */
    address public owner;
    address public DoughV1Index = address(0);

    address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    address private constant AAVE_V3_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    IAaveV3Pool private aave_v3_pool = IAaveV3Pool(AAVE_V3_POOL);

    address private constant AAVE_V3_DATA_PROVIDER = 0x7B4EB56E7CD4b454BA8ff71E4518426369a138a3;
    IAaveV3DataProvider private aave_v3_data_provider = IAaveV3DataProvider(AAVE_V3_DATA_PROVIDER);

    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router private uniswap_v2_router = IUniswapV2Router(UNISWAP_V2_ROUTER);

    /* ========== CONSTRUCTOR ========== */
    constructor(address _DoughV1Index) {
        DoughV1Index = _DoughV1Index;
    }

    function getOwner() public view returns (address) {
        return IDoughV1Index(DoughV1Index).owner();
    }

    function withdrawToken(address _tokenAddr, uint256 _amount) external {
        require(msg.sender == getOwner(), "ConnectorV1AaveV3: not owner of DoughV1Index");
        require(_amount > 0 && _amount <= IERC20(_tokenAddr).balanceOf(address(this)), "ConnectorV1AaveV3:withdrawTokenFromDsa: invalid amount");
        IERC20(_tokenAddr).transfer(getOwner(), _amount);
    }

    // delegate Call
    function delegateDoughCall(uint256 _actionId, address _token1, address _token2, uint256 _amount, bool _opt) external {
        require(_amount > 0, "ConnectorV1AaveV3: invalid amount");
        require(_actionId < 4, "ConnectorV1AaveV3: invalid actionId");
        require(_token1 != address(0), "ConnectorV1AaveV3: invalid token1");
        require(_token1 == _token2, "ConnectorV1AaveV3: invalid token2");

        if (_actionId == 0) {
            // send Fee to Treasury
            uint256 _feeAmount = 0;
            uint256 _feeSupply = IDoughV1Index(DoughV1Index).SUPPLY_FEE();
            if (_feeSupply > 0) {
                _feeAmount = (_amount * _feeSupply) / 10000;
                IERC20(_token1).transfer(IDoughV1Index(DoughV1Index).TREASURY(), _feeAmount);
            }
            // Supply to AaveV3
            IERC20(_token1).approve(AAVE_V3_POOL, _amount - _feeAmount);
            aave_v3_pool.supply(_token1, _amount - _feeAmount, address(this), 0);
        } else if (_actionId == 1) {
            uint256 _withdrawAmount = _amount;
            if (_opt) {
                (_withdrawAmount, , , , , , , , ) = aave_v3_data_provider.getUserReserveData(_token1, address(this));
            }
            // Withdraw from AaveV3
            aave_v3_pool.withdraw(_token1, _withdrawAmount, address(this));
            // send Fee to Treasury
            uint256 _feeWithdraw = IDoughV1Index(DoughV1Index).WITHDRAW_FEE();
            if (_feeWithdraw > 0) {
                uint256 _feeAmount = (_withdrawAmount * _feeWithdraw) / 10000;
                IERC20(_token1).transfer(IDoughV1Index(DoughV1Index).TREASURY(), _feeAmount);
            }
        } else if (_actionId == 2) {
            // Borrow from AaveV3
            aave_v3_pool.borrow(_token1, _amount, 2, 0, address(this));
            // send Fee to Treasury
            uint256 _feeBorrow = IDoughV1Index(DoughV1Index).BORROW_FEE();
            if (_feeBorrow > 0) {
                uint256 _feeAmount = (_amount * _feeBorrow) / 10000;
                IERC20(_token1).transfer(IDoughV1Index(DoughV1Index).TREASURY(), _feeAmount);
            }
        } else if (_actionId == 3) {
            // send Fee to Treasury
            uint256 _repayAmount = _amount;
            if (_opt) {
                (, , _repayAmount, , , , , , ) = aave_v3_data_provider.getUserReserveData(_token1, address(this));
            }
            uint256 _feeAmount = 0;
            uint256 _feeRepay = IDoughV1Index(DoughV1Index).REPAY_FEE();
            if (_feeRepay > 0) {
                _feeAmount = (_repayAmount * _feeRepay) / 10000;
                IERC20(_token1).transfer(IDoughV1Index(DoughV1Index).TREASURY(), _feeAmount);
            }
            // Repay to AaveV3
            IERC20(_token1).approve(AAVE_V3_POOL, _repayAmount - _feeAmount);
            aave_v3_pool.repay(_token1, _repayAmount - _feeAmount, 2, address(this));
        }
    }
}