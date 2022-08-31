// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../interfaces/external/lido/IWstETH.sol";
import "./VesperMakerStrategy.sol";

/// @title This strategy will receive stETH, wraps it and deposit wstETH token in Maker, borrow Dai and
/// deposit borrowed DAI in Vesper DAI pool to earn interest.
contract MakerVesperStETH is VesperMakerStrategy {
    using SafeERC20 for IERC20;

    address internal constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    IWstETH internal constant WSTETH = IWstETH(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);

    constructor(
        address _pool,
        address _cm,
        address _swapManager,
        address _vPool,
        bytes32 _collateralType,
        uint256 _highWater,
        uint256 _lowWater,
        string memory _name
    ) VesperMakerStrategy(_pool, _cm, _swapManager, _vPool, _collateralType, _highWater, _lowWater, _name) {
        require(address(IVesperPool(_pool).token()) == STETH, "not-a-valid-steth-pool");
    }

    function _approveToken(uint256 _amount) internal override {
        super._approveToken(_amount);
        IERC20(STETH).safeApprove(address(WSTETH), _amount);
        IERC20(WSTETH).safeApprove(address(cm), _amount);
    }

    function _convertToWrapped(uint256 _amount) internal override returns (uint256) {
        return WSTETH.getWstETHByStETH(_amount);
    }

    function _unwrap(uint256 _amount) internal override returns (uint256 _unwrappedAmount) {
        _unwrappedAmount = WSTETH.unwrap(_amount);
    }

    function _wrap(uint256 _amount) internal override returns (uint256 _wrappedAmount) {
        _wrappedAmount = WSTETH.wrap(_amount);
    }
}