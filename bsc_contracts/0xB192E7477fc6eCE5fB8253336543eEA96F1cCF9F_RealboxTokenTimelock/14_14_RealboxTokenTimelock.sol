// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import './RealboxTimelockController.sol';

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 */
contract RealboxTokenTimelock is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    enum Allocation {
        SEED_ROUND,
        PRIVATE_SALES_1,
        PRIVATE_SALES_2,
        PUBLIC_SALES,
        ADVISOR,
        CORE_TEAM,
        TREASURY,
        DEV_TEAM,
        MARKETING,
        RESERVE,
        FUTURE_ISSUING
    }

    event BeneficiaryUpdated(Allocation indexed allocation, address indexed newBeneficiary);

    // ERC20 basic token contract being held
    IERC20 public immutable token;
    // TGE timestamp
    uint256 public immutable tge;
    // Token total supply
    uint256 private immutable totalSupply;

    // beneficiary of tokens after they are released
    address[] public beneficiary;
    uint256[] public totalWithdrawn;

    /**
     * @param _controller: Timelock controller
     * @param _token: RealboxToken address
     * @param _tge: TGE timestamp (seconds)
     * @param _totalSupply: token total supply
     */
    constructor(
        RealboxTimelockController _controller,
        IERC20 _token,
        uint256 _tge,
        uint256 _totalSupply
    ) {
        token = _token;
        tge = _tge;
        totalSupply = _totalSupply;

        for (uint8 i = 0; i <= uint8(Allocation.FUTURE_ISSUING); i++) {
            beneficiary.push(address(0));
            totalWithdrawn.push(0);
        }

        transferOwnership(address(_controller));
    }

    // 4%: 5% at TGE, remaining lock 12 months, then vesting linear for 24 months
    function unlockedSeedRound(uint256 _timestamp) public view returns (uint256 _unlockedAmount) {
        return _monthlyUnlockedAt(40, 5, 12 * 30 days, 24, _timestamp);
    }

    // 8%: 5% at TGE, remaining lock 10 months, then vesting linear for 12 months
    function unlockedPrivateSales1(uint256 _timestamp) public view returns (uint256 _unlockedAmount) {
        return _monthlyUnlockedAt(80, 5, 10 * 30 days, 12, _timestamp);
    }

    // 6%: 5% at TGE, remaining lock 8 months, then vesting linear for 11 months
    function unlockedPrivateSales2(uint256 _timestamp) public view returns (uint256 _unlockedAmount) {
        return _monthlyUnlockedAt(60, 5, 8 * 30 days, 11, _timestamp);
    }

    // 0.2%: 50% at TGE, 50% next month
    function unlockedPublicSales(uint256 _timestamp) public view returns (uint256 _unlockedAmount) {
        if (_timestamp < tge) {
            return 0;
        }
        if (_timestamp < tge + 30 days) {
            return totalSupply.div(1000);
        }
        return totalSupply.mul(2).div(1000);
    }

    // 2%: 5% at TGE, remaining lock 12 months, then vesting linear for 12 months
    function unlockedAdvisor(uint256 _timestamp) public view returns (uint256 _unlockedAmount) {
        return _monthlyUnlockedAt(20, 5, 12 * 30 days, 12, _timestamp);
    }

    // 15%: 5% at TGE, remaining lock 24 months, then vesting linear for 12 months
    function unlockedCoreTeam(uint256 _timestamp) public view returns (uint256 _unlockedAmount) {
        return _monthlyUnlockedAt(150, 5, 24 * 30 days, 12, _timestamp);
    }

    // 25%: 100% at TGE
    function unlockedTreasury(uint256 _timestamp) public view returns (uint256 _unlockedAmount) {
        if (_timestamp < tge) {
            return 0;
        }
        return totalSupply.mul(250).div(1000);
    }

    // 10%: 5% at TGE, remaining lock 12 months, then vesting linear for 24 months
    function unlockedDevTeam(uint256 _timestamp) public view returns (uint256 _unlockedAmount) {
        return _monthlyUnlockedAt(100, 5, 12 * 30 days, 24, _timestamp);
    }

    // 6%: 100% at TGE
    function unlockedMarketing(uint256 _timestamp) public view returns (uint256 _unlockedAmount) {
        if (_timestamp < tge) {
            return 0;
        }

        return totalSupply.mul(60).div(1000);
    }

    // 3.8%: lock 3 months, then vesting linear for 36 months
    function unlockedReserve(uint256 _timestamp) public view returns (uint256 _unlockedAmount) {
        return _monthlyUnlockedAt(38, 0, 3 * 30 days, 36, _timestamp);
    }

    // 20%: lock 6 years
    function unlockedFutureIssuing(uint256 _timestamp) public view returns (uint256 _unlockedAmount) {
        if (_timestamp < tge + 6 * 365 days) {
            return 0;
        }
        return totalSupply.mul(200).div(1000);
    }

    function unlockedAmountAt(Allocation _allocation, uint256 _timestamp) public view returns (uint256) {
        if (_allocation == Allocation.SEED_ROUND) {
            return unlockedSeedRound(_timestamp);
        } else if (_allocation == Allocation.PRIVATE_SALES_1) {
            return unlockedPrivateSales1(_timestamp);
        } else if (_allocation == Allocation.PRIVATE_SALES_2) {
            return unlockedPrivateSales2(_timestamp);
        } else if (_allocation == Allocation.PUBLIC_SALES) {
            return unlockedPublicSales(_timestamp);
        } else if (_allocation == Allocation.ADVISOR) {
            return unlockedAdvisor(_timestamp);
        } else if (_allocation == Allocation.CORE_TEAM) {
            return unlockedCoreTeam(_timestamp);
        } else if (_allocation == Allocation.TREASURY) {
            return unlockedTreasury(_timestamp);
        } else if (_allocation == Allocation.DEV_TEAM) {
            return unlockedDevTeam(_timestamp);
        } else if (_allocation == Allocation.MARKETING) {
            return unlockedMarketing(_timestamp);
        } else if (_allocation == Allocation.RESERVE) {
            return unlockedReserve(_timestamp);
        } else if (_allocation == Allocation.FUTURE_ISSUING) {
            return unlockedFutureIssuing(_timestamp);
        }
        return 0;
    }

    function unlockedAmount(Allocation _allocation) public view returns (uint256) {
        return unlockedAmountAt(_allocation, block.timestamp);
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     * @param _allocation: token allocation
     */
    function withdraw(Allocation _allocation) public {
        require(
            beneficiary[uint8(_allocation)] != address(0),
            'RealboxTokenTimelock: beneficiary cannot be zero address'
        );

        uint256 _unlockedAmount = unlockedAmountAt(_allocation, block.timestamp);
        require(_unlockedAmount > totalWithdrawn[uint8(_allocation)], 'RealboxTokenTimelock: no tokens to release');
        uint256 amount = _unlockedAmount.sub(totalWithdrawn[uint8(_allocation)]);
        totalWithdrawn[uint8(_allocation)] = _unlockedAmount;
        token.safeTransfer(beneficiary[uint8(_allocation)], amount);
    }

    /**
     * @notice Set new beneficiary address.
     * @param _allocation: token allocation
     * @param _beneficiary: beneficiary address
     */
    function setBeneficiary(Allocation _allocation, address _beneficiary) public onlyOwner {
        if (beneficiary[uint8(_allocation)] != _beneficiary) {
            beneficiary[uint8(_allocation)] = _beneficiary;
            emit BeneficiaryUpdated(_allocation, _beneficiary);
        }
    }

    /**
     * @dev Calculate unlocked token in this format:
     * `_tgePercent`% token release at TGE, remaining lock `_lockTime` seconds,
     * then vesting linear for `_periods` months
     * @param _totalPermille: permille token of total supply
     * @param _tgePercent: percent token release at TGE
     * @param _lockTime: remaining token lock time (seconds)
     * @param _periods: number of periods
     * @param _timestamp: timestamp to query
     */
    function _monthlyUnlockedAt(
        uint256 _totalPermille,
        uint256 _tgePercent,
        uint256 _lockTime,
        uint256 _periods,
        uint256 _timestamp
    ) internal view returns (uint256 _unlockedAmount) {
        if (_timestamp < tge) {
            return 0;
        }

        uint256 totalAmount = totalSupply.mul(_totalPermille).div(1000);
        uint256 tgeAmount = totalAmount.mul(_tgePercent).div(100);
        if (_timestamp < tge + _lockTime) {
            return tgeAmount;
        }

        uint256 chunkAmount = totalAmount.sub(tgeAmount).div(_periods);
        _unlockedAmount = _timestamp
            .sub(tge + _lockTime)
            .div(30 days)
            .add(1) // the initial chunk will be unlocked right at the start
            .mul(chunkAmount)
            .add(tgeAmount);

        if (_unlockedAmount > totalAmount) {
            _unlockedAmount = totalAmount;
        }
    }
}