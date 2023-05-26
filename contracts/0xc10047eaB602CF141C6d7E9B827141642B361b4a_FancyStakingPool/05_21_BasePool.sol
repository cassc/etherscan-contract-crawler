// SPDX-License-Identifier: MIT
// Forked from Merit Circle
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "../interfaces/IBasePool.sol";
import "../interfaces/IFancyStakingPool.sol";

import "./AbstractRewards.sol";
import "../interfaces/IMintableBurnableERC20.sol";

abstract contract BasePool is ERC20Votes, AbstractRewards, IBasePool {
    using SafeERC20 for IMintableBurnableERC20;
    using SafeCast for uint256;
    using SafeCast for int256;

    address public liquidityMiningManager;
    IMintableBurnableERC20 public immutable depositToken;
    IFancyStakingPool public immutable escrowPool;
    uint256 public immutable escrowDuration; // escrow duration in seconds
    bool public sFNCEnabled;

    event RewardsClaimed(
        address indexed _from,
        address indexed _receiver,
        uint256 _escrowedAmount,
        uint256 _sFNCAmount
    );

    constructor(
        string memory _name,
        string memory _symbol,
        address _depositToken,
        address _liquidityMiningManager,
        address _escrowPool,
        uint256 _escrowDuration
    ) ERC20Permit(_name) ERC20(_name, _symbol) AbstractRewards(balanceOf, totalSupply) {
        require(_depositToken != address(0), "BasePool.constructor: Deposit token must be set");
        require(_liquidityMiningManager != address(0), "BasePool.constructor: Liquidity mining manager must be set");
        require(_escrowPool != address(0), "BasePool.constructor: Escrow pool must be set");
        depositToken = IMintableBurnableERC20(_depositToken);
        escrowPool = IFancyStakingPool(_escrowPool);
        escrowDuration = _escrowDuration;
        liquidityMiningManager = _liquidityMiningManager;
    }

    function _mint(address _account, uint256 _amount) internal virtual override {
        super._mint(_account, _amount);
        _correctPoints(_account, -(_amount.toInt256()));
    }

    function _burn(address _account, uint256 _amount) internal virtual override {
        super._burn(_account, _amount);
        _correctPoints(_account, _amount.toInt256());
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal virtual override {
        revert("NON_TRANSFERABLE");
    }

    function distributeRewards(uint256 _amount) external override {
        require(msg.sender == liquidityMiningManager, "Only liquidity manager");
        _distributeRewards(_amount);
    }

    function setSFNCClaiming(bool _sFNCEnabled) external override {
        require(msg.sender == liquidityMiningManager, "sFNCClaiming: Only liquidity manager");
        sFNCEnabled = _sFNCEnabled;
    }

    function claimRewards(address _receiver, bool useEscrowPool) external {
        require(useEscrowPool || sFNCEnabled, "sFNC is not enabled");

        uint256 rewardAmount = _prepareCollect(_msgSender());

        if (useEscrowPool) {
            escrowPool.deposit(rewardAmount, escrowDuration, _receiver);

            emit RewardsClaimed(_msgSender(), _receiver, rewardAmount, 0);
        } else {
            emit RewardsClaimed(_msgSender(), _receiver, 0, rewardAmount);
        }
    }
}