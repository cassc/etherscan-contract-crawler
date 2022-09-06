//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IStrategyToken.sol";
import "../refs/CoreRef.sol";

contract MultiStrategyToken is IMultiStrategyToken, ReentrancyGuard, CoreRef {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bytes32 public constant MASTER_ROLE = keccak256("MASTER_ROLE");

    address public override token;

    address[] public override strategies;

    mapping(address => uint256) public override ratios;

    uint256 public override ratioTotal;

    event RatioChanged(address strategyAddress, uint256 ratioBefore, uint256 ratioAfter);

    constructor(
        address _core,
        address _token,
        address[] memory _strategies,
        uint256[] memory _ratios
    ) public CoreRef(_core) {
        require(_strategies.length == _ratios.length, "array not match");

        token = _token;
        strategies = _strategies;

        for (uint256 i = 0; i < strategies.length; i++) {
            ratios[strategies[i]] = _ratios[i];
            ratioTotal = ratioTotal.add(_ratios[i]);
        }

        approveToken();
    }

    function approveToken() public override {
        for (uint256 i = 0; i < strategies.length; i++) {
            IERC20(token).safeApprove(strategies[i], uint256(-1));
        }
    }

    function deposit(uint256 _amount) public override {
        require(_amount != 0, "deposit must be greater than 0");
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        _deposit(_amount);
    }

    function _deposit(uint256 _amount) internal nonReentrant {
        updateAllStrategies();
        for (uint256 i = 0; i < strategies.length; i++) {
            uint256 amt = _amount.mul(ratios[strategies[i]]).div(ratioTotal);
            IStrategy(strategies[i]).deposit(amt);
        }
    }

    function withdraw() public override onlyRole(MASTER_ROLE) nonReentrant {
        updateAllStrategies();
        for (uint256 i = 0; i < strategies.length; i++) {
            IStrategy(strategies[i]).withdraw();
        }

        uint256 amt = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(msg.sender, amt);
    }

    function changeRatio(uint256 index, uint256 value) public override onlyTimelock {
        require(strategies.length > index, "invalid index");
        uint256 valueBefore = ratios[strategies[index]];
        ratios[strategies[index]] = value;
        ratioTotal = ratioTotal.sub(valueBefore).add(value);

        emit RatioChanged(strategies[index], valueBefore, value);
    }

    function strategyCount() public view override returns (uint256) {
        return strategies.length;
    }

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) public override onlyTimelock {
        require(_token != token, "!safe");
        IERC20(_token).safeTransfer(_to, _amount);
    }

    function updateAllStrategies() public override {
        for (uint256 i = 0; i < strategies.length; i++) {
            IStrategy(strategies[i]).updateStrategy();
        }
    }
}