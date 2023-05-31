// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IContractsRegistry.sol";
import "./interfaces/IYieldGenerator.sol";
import "./interfaces/IDefiProtocol.sol";
import "./interfaces/ICapitalPool.sol";

import "./abstract/AbstractDependant.sol";

import "./Globals.sol";

contract YieldGenerator is IYieldGenerator, OwnableUpgradeable, AbstractDependant {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;
    using Math for uint256;

    uint256 public constant ETH_PROTOCOLS_NUMBER = 3;
    uint256 public constant BSC_PROTOCOLS_NUMBER = 0;
    uint256 public constant POL_PROTOCOLS_NUMBER = 0;

    ERC20 public stblToken;
    ICapitalPool public capitalPool;

    uint256 public override totalDeposit;
    uint256 public whitelistedProtocols;

    // index => defi protocol
    mapping(uint256 => DefiProtocol) internal defiProtocols;
    // index => defi protocol addresses
    mapping(uint256 => address) public defiProtocolsAddresses;
    // available protcols to deposit/withdraw (weighted and threshold is true)
    uint256[] internal availableProtocols;
    // selected protocols for multiple deposit/withdraw
    uint256[] internal _selectedProtocols;

    uint256 public override protocolsNumber;

    event DefiDeposited(
        uint256 indexed protocolIndex,
        uint256 amount,
        uint256 depositedPercentage
    );
    event DefiWithdrawn(uint256 indexed protocolIndex, uint256 amount, uint256 withdrawPercentage);

    modifier onlyCapitalPool() {
        require(_msgSender() == address(capitalPool), "YG: Not a capital pool contract");
        _;
    }

    modifier updateDefiProtocols(uint256 amount, bool isDeposit) {
        _updateDefiProtocols(amount, isDeposit);
        _;
    }

    function __YieldGenerator_init(Networks _network) external initializer {
        __Ownable_init();

        uint256 networkIndex = uint256(_network);
        if (networkIndex == uint256(Networks.ETH)) {
            protocolsNumber = ETH_PROTOCOLS_NUMBER;
        } else if (networkIndex == uint256(Networks.BSC)) {
            protocolsNumber = BSC_PROTOCOLS_NUMBER;
        } else if (networkIndex == uint256(Networks.POL)) {
            protocolsNumber = POL_PROTOCOLS_NUMBER;
        }
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        stblToken = ERC20(_contractsRegistry.getUSDTContract());
        capitalPool = ICapitalPool(_contractsRegistry.getCapitalPoolContract());
        if (protocolsNumber >= 1) {
            defiProtocolsAddresses[uint256(DefiProtocols.DefiProtocol1)] = _contractsRegistry
                .getDefiProtocol1Contract();
        }
        if (protocolsNumber >= 2) {
            defiProtocolsAddresses[uint256(DefiProtocols.DefiProtocol2)] = _contractsRegistry
                .getDefiProtocol2Contract();
        }
        if (protocolsNumber >= 3) {
            defiProtocolsAddresses[uint256(DefiProtocols.DefiProtocol3)] = _contractsRegistry
                .getDefiProtocol3Contract();
        }
    }

    /// @notice deposit stable coin into multiple defi protocols using formulas, access: capital pool
    /// @param amount uint256 the amount of stable coin to deposit
    function deposit(uint256 amount) external override onlyCapitalPool returns (uint256) {
        if (amount == 0 && _getCurrentvSTBLVolume() == 0) return 0;
        return _aggregateDepositWithdrawFunction(amount, true);
    }

    /// @notice withdraw stable coin from mulitple defi protocols using formulas, access: capital pool
    /// @param amount uint256 the amount of stable coin to withdraw
    function withdraw(uint256 amount) external override onlyCapitalPool returns (uint256) {
        if (amount == 0 && _getCurrentvSTBLVolume() == 0) return 0;
        return _aggregateDepositWithdrawFunction(amount, false);
    }

    function updateProtocolNumbers(uint256 _protocolsNumber) external onlyOwner {
        require(_protocolsNumber > 0 && _protocolsNumber <= 5, "YG: protocol number is invalid");

        protocolsNumber = _protocolsNumber;
    }

    /// @notice set the protocol settings for each defi protocol (allocations, whitelisted, depositCost), access: owner
    /// @param whitelisted bool[] list of whitelisted values for each protocol
    /// @param allocations uint256[] list of allocations value for each protocol
    /// @param depositCost uint256[] list of depositCost values for each protocol
    function setProtocolSettings(
        bool[] calldata whitelisted,
        uint256[] calldata allocations,
        uint256[] calldata depositCost
    ) external override onlyOwner {
        require(
            whitelisted.length == protocolsNumber &&
                allocations.length == protocolsNumber &&
                depositCost.length == protocolsNumber,
            "YG: Invlaid arr length"
        );

        whitelistedProtocols = 0;
        bool _whiteListed;
        for (uint256 i = 0; i < protocolsNumber; i++) {
            _whiteListed = whitelisted[i];

            if (_whiteListed) {
                whitelistedProtocols = whitelistedProtocols.add(1);
            }

            defiProtocols[i].targetAllocation = allocations[i];

            defiProtocols[i].whiteListed = _whiteListed;
            defiProtocols[i].depositCost = depositCost[i];
        }
    }

    /// @notice claim rewards for all defi protocols and send them to reinsurance pool, access: owner
    function claimRewards() external override onlyOwner {
        for (uint256 i = 0; i < protocolsNumber; i++) {
            IDefiProtocol(defiProtocolsAddresses[i]).claimRewards();
        }
    }

    /// @notice returns defi protocol APR by its index
    /// @param index uint256 the index of the defi protocol
    function getOneDayGain(uint256 index) public view returns (uint256) {
        return IDefiProtocol(defiProtocolsAddresses[index]).getOneDayGain();
    }

    /// @notice returns defi protocol info by its index
    /// @param index uint256 the index of the defi protocol
    function defiProtocol(uint256 index)
        external
        view
        override
        returns (
            uint256 _targetAllocation,
            uint256 _currentAllocation,
            uint256 _rebalanceWeight,
            uint256 _depositedAmount,
            bool _whiteListed,
            bool _threshold,
            uint256 _totalValue,
            uint256 _depositCost
        )
    {
        _targetAllocation = defiProtocols[index].targetAllocation;
        _currentAllocation = _calcProtocolCurrentAllocation(index);
        _rebalanceWeight = defiProtocols[index].rebalanceWeight;
        _depositedAmount = defiProtocols[index].depositedAmount;
        _whiteListed = defiProtocols[index].whiteListed;
        _threshold = defiProtocols[index].threshold;
        _totalValue = IDefiProtocol(defiProtocolsAddresses[index]).totalValue();
        _depositCost = defiProtocols[index].depositCost;
    }

    function _aggregateDepositWithdrawFunction(uint256 amount, bool isDeposit)
        internal
        updateDefiProtocols(amount, isDeposit)
        returns (uint256 _actualAmount)
    {
        if (availableProtocols.length == 0) {
            return _actualAmount;
        }

        uint256 _protocolsNo = _howManyProtocols(amount, isDeposit);
        if (_protocolsNo == 1) {
            _actualAmount = _aggregateDepositWithdrawFunctionForOneProtocol(amount, isDeposit);
        } else if (_protocolsNo > 1) {
            delete _selectedProtocols;

            uint256 _totalWeight = _calcTotalWeight(_protocolsNo, isDeposit);

            if (_selectedProtocols.length > 0) {
                for (uint256 i = 0; i < _selectedProtocols.length; i++) {
                    _actualAmount = _actualAmount.add(
                        _aggregateDepositWithdrawFunctionForMultipleProtocol(
                            isDeposit,
                            amount,
                            i,
                            _totalWeight
                        )
                    );
                }
            }
        }
    }

    function _aggregateDepositWithdrawFunctionForOneProtocol(uint256 amount, bool isDeposit)
        internal
        returns (uint256 _actualAmount)
    {
        uint256 _protocolIndex;
        if (isDeposit) {
            _protocolIndex = _getProtocolOfMaxWeight();
            // deposit 100% to this protocol
            _depoist(_protocolIndex, amount, PERCENTAGE_100);
            _actualAmount = amount;
        } else {
            _protocolIndex = _getProtocolOfMinWeight();
            // withdraw 100% from this protocol
            _actualAmount = _withdraw(_protocolIndex, amount, PERCENTAGE_100);
        }
    }

    function _aggregateDepositWithdrawFunctionForMultipleProtocol(
        bool isDeposit,
        uint256 amount,
        uint256 index,
        uint256 _totalWeight
    ) internal returns (uint256 _actualAmount) {
        uint256 _protocolRebalanceAllocation =
            _calcRebalanceAllocation(_selectedProtocols[index], _totalWeight);

        if (isDeposit) {
            // deposit % allocation to this protocol
            uint256 _depoistedAmount =
                amount.mul(_protocolRebalanceAllocation).div(PERCENTAGE_100);
            _depoist(_selectedProtocols[index], _depoistedAmount, _protocolRebalanceAllocation);
            _actualAmount = _depoistedAmount;
        } else {
            _actualAmount = _withdraw(
                _selectedProtocols[index],
                amount.mul(_protocolRebalanceAllocation).div(PERCENTAGE_100),
                _protocolRebalanceAllocation
            );
        }
    }

    function _calcTotalWeight(uint256 _protocolsNo, bool isDeposit)
        internal
        returns (uint256 _totalWeight)
    {
        uint256 _protocolIndex;
        for (uint256 i = 0; i < _protocolsNo; i++) {
            if (availableProtocols.length == 0) {
                break;
            }
            if (isDeposit) {
                _protocolIndex = _getProtocolOfMaxWeight();
            } else {
                _protocolIndex = _getProtocolOfMinWeight();
            }
            _totalWeight = _totalWeight.add(defiProtocols[_protocolIndex].rebalanceWeight);
            _selectedProtocols.push(_protocolIndex);
        }
    }

    /// @notice deposit into defi protocols
    /// @param _protocolIndex uint256 the predefined index of the defi protocol
    /// @param _amount uint256 amount of stable coin to deposit
    /// @param _depositedPercentage uint256 the percentage of deposited amount into the protocol
    function _depoist(
        uint256 _protocolIndex,
        uint256 _amount,
        uint256 _depositedPercentage
    ) internal {
        // should approve yield to transfer from the capital pool
        stblToken.safeTransferFrom(_msgSender(), defiProtocolsAddresses[_protocolIndex], _amount);

        IDefiProtocol(defiProtocolsAddresses[_protocolIndex]).deposit(_amount);

        defiProtocols[_protocolIndex].depositedAmount = defiProtocols[_protocolIndex]
            .depositedAmount
            .add(_amount);

        totalDeposit = totalDeposit.add(_amount);

        emit DefiDeposited(_protocolIndex, _amount, _depositedPercentage);
    }

    /// @notice withdraw from defi protocols
    /// @param _protocolIndex uint256 the predefined index of the defi protocol
    /// @param _amount uint256 amount of stable coin to withdraw
    /// @param _withdrawnPercentage uint256 the percentage of withdrawn amount from the protocol
    function _withdraw(
        uint256 _protocolIndex,
        uint256 _amount,
        uint256 _withdrawnPercentage
    ) internal returns (uint256) {
        uint256 _actualAmountWithdrawn;
        uint256 allocatedFunds = defiProtocols[_protocolIndex].depositedAmount;

        if (allocatedFunds == 0) return _actualAmountWithdrawn;

        if (allocatedFunds < _amount) {
            _amount = allocatedFunds;
        }

        _actualAmountWithdrawn = IDefiProtocol(defiProtocolsAddresses[_protocolIndex]).withdraw(
            _amount
        );

        defiProtocols[_protocolIndex].depositedAmount = defiProtocols[_protocolIndex]
            .depositedAmount
            .sub(_actualAmountWithdrawn);

        totalDeposit = totalDeposit.sub(_actualAmountWithdrawn);

        emit DefiWithdrawn(_protocolIndex, _actualAmountWithdrawn, _withdrawnPercentage);

        return _actualAmountWithdrawn;
    }

    /// @notice get the number of protocols need to rebalance
    /// @param rebalanceAmount uint256 the amount of stable coin will depsoit or withdraw
    function _howManyProtocols(uint256 rebalanceAmount, bool isDeposit)
        internal
        view
        returns (uint256)
    {
        uint256 _no1;
        if (isDeposit) {
            _no1 = whitelistedProtocols.mul(rebalanceAmount);
        } else {
            _no1 = protocolsNumber.mul(rebalanceAmount);
        }

        uint256 _no2 = _getCurrentvSTBLVolume();

        return _no1.add(_no2 - 1).div(_no2);
        //return _no1.div(_no2).add(_no1.mod(_no2) == 0 ? 0 : 1);
    }

    /// @notice update defi protocols rebalance weight and threshold status
    /// @param isDeposit bool determine the rebalance is for deposit or withdraw
    function _updateDefiProtocols(uint256 amount, bool isDeposit) internal {
        delete availableProtocols;

        for (uint256 i = 0; i < protocolsNumber; i++) {
            uint256 _targetAllocation = defiProtocols[i].targetAllocation;
            uint256 _currentAllocation = _calcProtocolCurrentAllocation(i);
            uint256 _diffAllocation;

            if (isDeposit) {
                if (_targetAllocation > _currentAllocation) {
                    // max weight
                    _diffAllocation = _targetAllocation.sub(_currentAllocation);
                } else if (_currentAllocation >= _targetAllocation) {
                    _diffAllocation = 0;
                }
                _reevaluateThreshold(i, _diffAllocation.mul(amount).div(PERCENTAGE_100));
            } else {
                if (_currentAllocation > _targetAllocation) {
                    // max weight
                    _diffAllocation = _currentAllocation.sub(_targetAllocation);
                    defiProtocols[i].withdrawMax = true;
                } else if (_targetAllocation >= _currentAllocation) {
                    // min weight
                    _diffAllocation = _targetAllocation.sub(_currentAllocation);
                    defiProtocols[i].withdrawMax = false;
                }
            }

            // update rebalance weight
            defiProtocols[i].rebalanceWeight = _diffAllocation.mul(_getCurrentvSTBLVolume()).div(
                PERCENTAGE_100
            );

            if (
                isDeposit
                    ? defiProtocols[i].rebalanceWeight > 0 &&
                        defiProtocols[i].whiteListed &&
                        defiProtocols[i].threshold
                    : _currentAllocation > 0
            ) {
                availableProtocols.push(i);
            }
        }
    }

    /// @notice get the defi protocol has max weight to deposit
    /// @dev only select the positive weight from largest to smallest
    function _getProtocolOfMaxWeight() internal returns (uint256) {
        uint256 _largest;
        uint256 _protocolIndex;
        uint256 _indexToDelete;

        for (uint256 i = 0; i < availableProtocols.length; i++) {
            if (defiProtocols[availableProtocols[i]].rebalanceWeight > _largest) {
                _largest = defiProtocols[availableProtocols[i]].rebalanceWeight;
                _protocolIndex = availableProtocols[i];
                _indexToDelete = i;
            }
        }

        availableProtocols[_indexToDelete] = availableProtocols[availableProtocols.length - 1];
        availableProtocols.pop();

        return _protocolIndex;
    }

    /// @notice get the defi protocol has min weight to deposit
    /// @dev only select the negative weight from smallest to largest
    function _getProtocolOfMinWeight() internal returns (uint256) {
        uint256 _maxWeight;
        for (uint256 i = 0; i < availableProtocols.length; i++) {
            if (defiProtocols[availableProtocols[i]].rebalanceWeight > _maxWeight) {
                _maxWeight = defiProtocols[availableProtocols[i]].rebalanceWeight;
            }
        }

        uint256 _smallest = _maxWeight;
        uint256 _largest;
        uint256 _maxProtocolIndex;
        uint256 _maxIndexToDelete;
        uint256 _minProtocolIndex;
        uint256 _minIndexToDelete;

        for (uint256 i = 0; i < availableProtocols.length; i++) {
            if (
                defiProtocols[availableProtocols[i]].rebalanceWeight <= _smallest &&
                !defiProtocols[availableProtocols[i]].withdrawMax
            ) {
                _smallest = defiProtocols[availableProtocols[i]].rebalanceWeight;
                _minProtocolIndex = availableProtocols[i];
                _minIndexToDelete = i;
            } else if (
                defiProtocols[availableProtocols[i]].rebalanceWeight > _largest &&
                defiProtocols[availableProtocols[i]].withdrawMax
            ) {
                _largest = defiProtocols[availableProtocols[i]].rebalanceWeight;
                _maxProtocolIndex = availableProtocols[i];
                _maxIndexToDelete = i;
            }
        }
        if (_largest > 0) {
            availableProtocols[_maxIndexToDelete] = availableProtocols[
                availableProtocols.length - 1
            ];
            availableProtocols.pop();
            return _maxProtocolIndex;
        } else {
            availableProtocols[_minIndexToDelete] = availableProtocols[
                availableProtocols.length - 1
            ];
            availableProtocols.pop();
            return _minProtocolIndex;
        }
    }

    /// @notice calc the current allocation of defi protocol against current vstable volume
    /// @param _protocolIndex uint256 the predefined index of defi protocol
    function _calcProtocolCurrentAllocation(uint256 _protocolIndex)
        internal
        view
        returns (uint256 _currentAllocation)
    {
        uint256 _depositedAmount = defiProtocols[_protocolIndex].depositedAmount;
        uint256 _currentvSTBLVolume = _getCurrentvSTBLVolume();
        if (_currentvSTBLVolume > 0) {
            _currentAllocation = _depositedAmount.mul(PERCENTAGE_100).div(_currentvSTBLVolume);
        }
    }

    /// @notice calc the rebelance allocation % for one protocol for deposit/withdraw
    /// @param _protocolIndex uint256 the predefined index of defi protocol
    /// @param _totalWeight uint256 sum of rebelance weight for all protocols which avaiable for deposit/withdraw
    function _calcRebalanceAllocation(uint256 _protocolIndex, uint256 _totalWeight)
        internal
        view
        returns (uint256)
    {
        return defiProtocols[_protocolIndex].rebalanceWeight.mul(PERCENTAGE_100).div(_totalWeight);
    }

    function _getCurrentvSTBLVolume() internal view returns (uint256) {
        return
            capitalPool.virtualUsdtAccumulatedBalance().sub(capitalPool.liquidityCushionBalance());
    }

    function _reevaluateThreshold(uint256 _protocolIndex, uint256 depositAmount) internal {
        uint256 _protocolOneDayGain = getOneDayGain(_protocolIndex);

        uint256 _oneDayReturn = _protocolOneDayGain.mul(depositAmount).div(PRECISION);

        uint256 _depositCost = defiProtocols[_protocolIndex].depositCost;

        if (_oneDayReturn < _depositCost) {
            defiProtocols[_protocolIndex].threshold = false;
        } else if (_oneDayReturn >= _depositCost) {
            defiProtocols[_protocolIndex].threshold = true;
        }
    }

    function reevaluateDefiProtocolBalances()
        external
        override
        returns (uint256 _totalDeposit, uint256 _lostAmount)
    {
        _totalDeposit = totalDeposit;

        uint256 _totalValue;
        uint256 _depositedAmount;
        for (uint256 index = 0; index < protocolsNumber; index++) {
            // this case apply for compound only in ETH
            if (index == uint256(DefiProtocols.DefiProtocol2)) {
                IDefiProtocol(defiProtocolsAddresses[index]).updateTotalValue();
            }

            _totalValue = IDefiProtocol(defiProtocolsAddresses[index]).totalValue();
            _depositedAmount = defiProtocols[index].depositedAmount;

            if (_totalValue < _depositedAmount) {
                _lostAmount = _lostAmount.add((_depositedAmount.sub(_totalValue)));
            }
        }
    }

    function defiHardRebalancing() external override onlyCapitalPool {
        uint256 _totalValue;
        uint256 _depositedAmount;
        uint256 _lostAmount;
        uint256 _totalLostAmount;
        for (uint256 index = 0; index < protocolsNumber; index++) {
            _totalValue = IDefiProtocol(defiProtocolsAddresses[index]).totalValue();

            _depositedAmount = defiProtocols[index].depositedAmount;

            if (_totalValue < _depositedAmount) {
                _lostAmount = _depositedAmount.sub(_totalValue);
                defiProtocols[index].depositedAmount = _depositedAmount.sub(_lostAmount);
                IDefiProtocol(defiProtocolsAddresses[index]).updateTotalDeposit(_lostAmount);
                _totalLostAmount = _totalLostAmount.add(_lostAmount);
            }
        }

        totalDeposit = totalDeposit.sub(_totalLostAmount);
    }

    function withdrawFromYearnProtocol() external onlyOwner {
        uint256 _protocolIndex = 2;
        // withdraw all funds
        (uint256 _actualAmountWithdrawn, uint256 accumaltedAmount) =
            IDefiProtocol(defiProtocolsAddresses[_protocolIndex]).withdrawAll();

        // update the YG and CP state
        defiProtocols[_protocolIndex].depositedAmount = defiProtocols[_protocolIndex]
            .depositedAmount
            .sub(_actualAmountWithdrawn);

        totalDeposit = totalDeposit.sub(_actualAmountWithdrawn);

        //updayte total reward

        capitalPool.addWithdrawalHardSTBL(_actualAmountWithdrawn, accumaltedAmount);

        emit DefiWithdrawn(_protocolIndex, _actualAmountWithdrawn.add(accumaltedAmount), 0);
    }
}