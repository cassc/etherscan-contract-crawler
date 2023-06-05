//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;
import {BancorFormula} from "./core/Bancor/BancorFormula.sol";
import {NibblVault3} from "./core/NibblVault3.sol";
import {Twav3} from "./core/Twav/Twav3.sol";
import {NibblVaultFactory} from "./core/NibblVaultFactory.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NibblUIHelper is BancorFormula {
    uint256 public constant SCALE = 1_000_000;
    uint32 public constant PRIMARY_RESERVE_RATIO = 300_000;
    uint8 private constant TWAV_BLOCK_NUMBERS = 4;
    // address public immutable basketImplementation;
    address payable public immutable factory;
    uint256 private constant MAX_CURATOR_FEE = 15_000; //1.5%

    event BasketCreated(address indexed _curator, address indexed _basket);

    constructor(address payable _factory) {
        // basketImplementation = _basketImplementation;
        factory = _factory;
    }

    function getVaultDetails(NibblVault3 _vault)
        public
        view
        returns (
            address _curator,
            address _bidder,
            uint32 _secondaryReserveRatio,
            uint256 _totalSupply,
            uint256 _initialTokenSupply,
            uint256 _initialTokenPrice,
            uint256 _secondaryReserveBalance,
            uint256 _primaryReserveBalance,
            uint256 _currentValuation,
            uint256 _feeAccruedAcurator,
            uint256 _buyoutEndTime,
            uint256 _buyoutRejectionValuation,
            uint256 _buyoutBid
        )
    {
        _curator = _vault.curator();
        _bidder = _vault.bidder();
        _totalSupply = _vault.totalSupply();
        _initialTokenSupply = _vault.initialTokenSupply();
        _initialTokenPrice = _vault.initialTokenPrice();
        _secondaryReserveBalance = _vault.secondaryReserveBalance();
        _secondaryReserveRatio = _vault.secondaryReserveRatio();
        _primaryReserveBalance = _vault.primaryReserveBalance();
        _currentValuation = getCurrentValuation(_vault);
        _feeAccruedAcurator = _vault.feeAccruedCurator();
        _buyoutEndTime = _vault.buyoutEndTime();
        _buyoutRejectionValuation = _vault.buyoutRejectionValuation();
        _buyoutBid = _vault.buyoutBid();
    }

    function getMaxSecondaryCurveBalance(NibblVault3 _vault)
        public
        view
        returns (uint256)
    {
        uint256 _secondaryReserveRatio = _vault.secondaryReserveRatio();
        uint256 _initialTokenSupply = _vault.initialTokenSupply();
        uint256 _initialTokenPrice = _vault.initialTokenPrice();
        return ((_secondaryReserveRatio *
            _initialTokenSupply *
            _initialTokenPrice) / (1e18 * SCALE));
    }

    function _chargeFeeSecondaryCurve(uint256 _amount, NibblVault3 _vault)
        private
        view
        returns (
            uint256 _totalAmt,
            uint256 _feeAdmin,
            uint256 _feeCurator
        )
    {
        address payable _factory = factory;
        uint256 _adminFeeAmt = NibblVaultFactory(_factory).feeAdmin();
        _feeAdmin = (_amount * _adminFeeAmt) / SCALE;
        _feeCurator = (_amount * _vault.curatorFee()) / SCALE;

        _totalAmt = _amount - (_feeAdmin + _feeCurator);
    }

    function chargeFee(uint256 _amount, NibblVault3 _vault)
        public
        view
        returns (
            uint256 _totalAmt,
            uint256 _feeAdmin,
            uint256 _feeCurator,
            uint256 _feeCurve
        )
    {
        NibblVaultFactory _factory = NibblVaultFactory(factory);
        uint256 _adminFeeAmt = _factory.feeAdmin();
        uint256 _curatorFee = _vault.curatorFee();
        uint256 _curveFee = MAX_CURATOR_FEE - _curatorFee;
        _feeAdmin = (_amount * _adminFeeAmt) / SCALE;
        _feeCurator = (_amount * _curatorFee) / SCALE;
        _feeCurve = (_amount * _curveFee) / SCALE;
        uint256 _fictitiousPrimaryReserveBalance = (PRIMARY_RESERVE_RATIO *
            _vault.initialTokenSupply() *
            _vault.initialTokenPrice()) / (SCALE * 1e18);
        uint256 _secondaryReserveBalance = _vault.secondaryReserveBalance();
        uint256 _maxSecondaryBalanceIncrease = _fictitiousPrimaryReserveBalance -
                _secondaryReserveBalance;
        _feeCurve = _maxSecondaryBalanceIncrease > _feeCurve
            ? _feeCurve
            : _maxSecondaryBalanceIncrease; // the curve fee is capped so that secondaryReserveBalance <= fictitiousPrimaryReserveBalance
        _totalAmt = (_amount - (_feeAdmin + _feeCurator + _feeCurve));
    }

    function getPurchaseReturn(NibblVault3 _vault, uint256 _amount)
        public
        view
        returns (
            uint256 _purchaseReturn,
            uint256 _feeAdmin,
            uint256 _feeCurator,
            uint256 _feeCurve
        )
    {
        uint256 _initialTokenSupply = _vault.initialTokenSupply();
        uint256 _totalSupply = _vault.totalSupply();
        uint256 _primaryReserveBalance = _vault.primaryReserveBalance();
        uint256 _secondaryReserveBalance = _vault.secondaryReserveBalance();
        uint32 _secondaryReserveRatio = _vault.secondaryReserveRatio();
        if (_totalSupply >= _initialTokenSupply) {
            //
            (_purchaseReturn, _feeAdmin, _feeCurator, _feeCurve) = chargeFee(
                _amount,
                _vault
            );
            //
            _purchaseReturn = _calculatePurchaseReturn(
                _totalSupply,
                _primaryReserveBalance,
                PRIMARY_RESERVE_RATIO,
                _purchaseReturn
            );
        } else {
            uint256 _lowerCurveDiff = getMaxSecondaryCurveBalance(_vault) -
                _secondaryReserveBalance;
            //
            if (_lowerCurveDiff >= _amount) {
                uint256 _amtAfterFee;
                (
                    _amtAfterFee,
                    _feeAdmin,
                    _feeCurator
                ) = _chargeFeeSecondaryCurve(_amount, _vault);
                //
                _purchaseReturn = _calculatePurchaseReturn(
                    _totalSupply,
                    _secondaryReserveBalance,
                    _secondaryReserveRatio,
                    _amtAfterFee
                );
            } else {
                //Gas Optimization
                _purchaseReturn = _initialTokenSupply - _totalSupply;
                uint256 _totalAmt;
                (_totalAmt, _feeAdmin, _feeCurator, _feeCurve) = chargeFee(
                    _amount - _lowerCurveDiff,
                    _vault
                );
                _purchaseReturn += _calculatePurchaseReturn(
                    _totalSupply + _purchaseReturn,
                    _primaryReserveBalance,
                    PRIMARY_RESERVE_RATIO,
                    _totalAmt
                );
            }
        }
    }

    function getSaleReturn(NibblVault3 _vault, uint256 _amount)
        public
        view
        returns (
            uint256 _saleReturn,
            uint256 _feeAdmin,
            uint256 _feeCurator,
            uint256 _feeCurve
        )
    {
        uint256 _initialTokenSupply = _vault.initialTokenSupply();
        uint256 _totalSupply = _vault.totalSupply();
        uint256 _primaryReserveBalance = _vault.primaryReserveBalance();
        uint256 _secondaryReserveBalance = _vault.secondaryReserveBalance();
        // uint32 _secondaryReserveRatio = _vault.secondaryReserveRatio();

        if (_totalSupply > _initialTokenSupply) {
            if ((_initialTokenSupply + _amount) <= _totalSupply) {
                _saleReturn = _calculateSaleReturn(
                    _totalSupply,
                    _primaryReserveBalance,
                    PRIMARY_RESERVE_RATIO,
                    _amount
                );
                (_saleReturn, _feeAdmin, _feeCurator, _feeCurve) = chargeFee(
                    _saleReturn,
                    _vault
                );
            } else {
                //Gas Optimization
                _saleReturn =
                    _primaryReserveBalance -
                     _vault.fictitiousPrimaryReserveBalance();
                //
                (_saleReturn, _feeAdmin, _feeCurator, _feeCurve) = chargeFee(
                    _saleReturn,
                    _vault
                );
                _amount = _amount - (_totalSupply - _initialTokenSupply);
                _secondaryReserveBalance = _secondaryReserveBalance + _feeCurve;
                // _secondaryReserveRatio = uint32((_secondaryReserveBalance * SCALE * 1e18) / (_initialTokenSupply * _initialTokenPrice)); //updating secondaryReserveRatio
                uint256 _saleReturnSecondary;
                _saleReturnSecondary = _calculateSaleReturn(
                    _initialTokenSupply,
                    _secondaryReserveBalance,
                    getSecondayReserveRatio(_secondaryReserveBalance, _vault),
                    _amount
                );

                (
                    uint256 _saleReturnSecondaryAfterFee,
                    uint256 _feeAdminSecondary,
                    uint256 _feeCuratorSecondary
                ) = _chargeFeeSecondaryCurve(_saleReturnSecondary, _vault);
                _saleReturn += _saleReturnSecondaryAfterFee;
                _feeAdmin += _feeAdminSecondary;
                _feeCurator += _feeCuratorSecondary;
            }
        } else {
            _saleReturn = _calculateSaleReturn(
                _totalSupply,
                _secondaryReserveBalance,
                _vault.secondaryReserveRatio(),
                _amount
            );
            (_saleReturn, _feeAdmin, _feeCurator) = _chargeFeeSecondaryCurve(
                _saleReturn,
                _vault
            );
        }
    }

    function getSecondayReserveRatio(uint _resBal, NibblVault3 _vault) internal view returns(uint32) {
        return uint32(
                        (_resBal * SCALE * 1e18) /
                            (_vault.initialTokenSupply() * _vault.initialTokenPrice())
                    );
    }

    function getCurrentValuation(NibblVault3 _vault)
        public
        view
        returns (uint256)
    {
        return
            _vault.totalSupply() < _vault.initialTokenSupply()
                ? ((_vault.secondaryReserveBalance() * SCALE) /
                    _vault.secondaryReserveRatio())
                : (((_vault.primaryReserveBalance()) * SCALE) /
                    PRIMARY_RESERVE_RATIO);
    }

    function predictTwav(NibblVault3 _vault, uint256 _timeAfter)
        external
        view
        returns (uint256 _twav)
    {
        Twav3.TwavObservation[TWAV_BLOCK_NUMBERS]
            memory _twavObservations = _vault.getTwavObservations();
        uint256 _currentValuation = getCurrentValuation(_vault);
        uint256 _twavObservationsIndex = _vault.twavObservationsIndex();
        uint32 _timeElapsed;
        uint32 _blockTimeStamp = uint32((block.timestamp + _timeAfter) % 2**32);
        unchecked {
            _timeElapsed = _blockTimeStamp - _vault.lastBlockTimeStamp();
        }
        uint256 _prevCumulativeValuation = _twavObservations[
            ((_twavObservationsIndex + TWAV_BLOCK_NUMBERS) - 1) %
                TWAV_BLOCK_NUMBERS
        ].cumulativeValuation;
        _twavObservations[_twavObservationsIndex] = Twav3.TwavObservation(
            _blockTimeStamp,
            _prevCumulativeValuation + (_currentValuation * _timeElapsed)
        ); //add the previous observation to make it cumulative
        _twavObservationsIndex =
            (_twavObservationsIndex + 1) %
            TWAV_BLOCK_NUMBERS;

        if (_twavObservations[TWAV_BLOCK_NUMBERS - 1].timestamp != 0) {
            uint8 _index = uint8(
                ((_twavObservationsIndex + TWAV_BLOCK_NUMBERS) - 1) %
                    TWAV_BLOCK_NUMBERS
            );
            Twav3.TwavObservation
                memory _twavObservationCurrent = _twavObservations[(_index)];
            Twav3.TwavObservation
                memory _twavObservationPrev = _twavObservations[
                    (_index + 1) % TWAV_BLOCK_NUMBERS
                ];
            _twav =
                (_twavObservationCurrent.cumulativeValuation -
                    _twavObservationPrev.cumulativeValuation) /
                (_twavObservationCurrent.timestamp -
                    _twavObservationPrev.timestamp);
        }
    }
}