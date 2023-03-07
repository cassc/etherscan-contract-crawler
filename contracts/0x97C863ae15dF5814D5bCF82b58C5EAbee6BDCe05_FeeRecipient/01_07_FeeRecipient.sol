// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.11;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import "./lib/interfaces/IGlobalPool.sol";
import "./lib/interfaces/IFeeRecipient.sol";

/*
 * Contract which can receive EL (tips/mev) rewards and send them to GlobalPool
 */
contract FeeRecipient is IFeeRecipient, ReentrancyGuardUpgradeSafe, OwnableUpgradeSafe {

    event Received(address indexed sender, uint256 amount);

    event CommissionChanged(uint16 prevValue, uint16 newValue);

    event TreasuryChanged(address prevValue, address newValue);

    event PoolChanged(address prevValue, address newValue);

    uint16 public constant MAX_COMMISSION = uint16(1e4); // 100.00

    address public treasury;

    uint16 public commission;

    IGlobalPool internal _pool;

    function initialize(IGlobalPool pool, address _treasury, uint16 _commission) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        _pool = pool;
        emit PoolChanged(address(0), address(pool));

        treasury = _treasury;
        emit TreasuryChanged(address(0), _treasury);

        commission = _commission;
        emit CommissionChanged(0, _commission);
    }

    /*
     * @notice staking rewards
     */
    function getRewards() external view returns (uint256) {
        (,uint256 rewards) = _takeFee(address(this).balance);
        return rewards;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /*
     * @notice claim EL rewards to staking pool
     */
    function claim() external override nonReentrant {
        uint256 balance = address(this).balance;
        // min balance to withdraw is max commission
        if (balance >= MAX_COMMISSION) {
            (uint256 fee, uint256 rewardsWithoutCommission) = _takeFee(balance);
            _pool.restake{value: rewardsWithoutCommission}();
            require(payable(treasury).send(fee), "FeeRecipient: could not transfer fee");
        }
    }

    function _takeFee(uint256 amount) internal view returns (uint256 fee, uint256 rewards) {
        fee = amount * commission / MAX_COMMISSION;
        rewards = amount - fee;
    }

    function changeCommission(uint16 newValue) external onlyOwner {
        require(newValue < MAX_COMMISSION, "FeeRecipient: commission is too big");
        emit CommissionChanged(commission, newValue);
        commission = newValue;
    }

    function changeTreasury(address newValue) external onlyOwner {
        require(newValue != address(0), "FeeRecipient: address is zero");
        emit TreasuryChanged(treasury, newValue);
        treasury = newValue;
    }

    function changePool(address newValue) external onlyOwner {
        require(newValue != address(0), "FeeRecipient: address is zero");
        emit PoolChanged(address(_pool), newValue);
        _pool = IGlobalPool(newValue);
    }
}