//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;
import { BancorFormula } from "./core/Bancor/BancorFormula.sol";
import { NibblVault } from "./core/NibblVault.sol";
import { Twav } from "./core/Twav/Twav.sol";
import { NibblVaultFactory } from "./core/NibblVaultFactory.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
    
contract NibblUIHelper is BancorFormula {

    uint256 public constant CURVE_FEE_AMT = 4_000;
    uint256 public constant SCALE = 1_000_000;
    uint32 public constant PRIMARY_RESERVE_RATIO = 300_000;
    uint8 private constant TWAV_BLOCK_NUMBERS = 6;
    address public immutable basketImplementation;
    address payable public immutable factory;
    event BasketCreated(address indexed _curator, address indexed _basket);
    constructor (address _basketImplementation, address payable _factory) {
        basketImplementation = _basketImplementation;
        factory = _factory;
    }

    function getVaultDetails(NibblVault _vault) public view returns (
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
                                                        ) {
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

    function getMaxSecondaryCurveBalance(NibblVault _vault) public view returns(uint256){
        uint256 _secondaryReserveRatio = _vault.secondaryReserveRatio();
        uint256 _initialTokenSupply = _vault.initialTokenSupply();
        uint256 _initialTokenPrice = _vault.initialTokenPrice();
        return ((_secondaryReserveRatio * _initialTokenSupply * _initialTokenPrice) / (1e18 * SCALE));
    }

    function chargeFee(uint _amount, NibblVault _vault) public view returns(uint256 _totalAmt, uint256 _feeAdmin, uint256 _feeCurator, uint256 _feeCurve) {
        NibblVaultFactory _factory = NibblVaultFactory(factory);
        uint256 _adminFeeAmt = _factory.feeAdmin();
        uint256 _curatorFee = _vault.curatorFee();
        _feeAdmin = (_amount * _adminFeeAmt) / SCALE ;
        _feeCurator = (_amount * _curatorFee) / SCALE ;
        _feeCurve = (_amount * CURVE_FEE_AMT) / SCALE ;
        uint256 _fictitiousPrimaryReserveBalance = (PRIMARY_RESERVE_RATIO * _vault.initialTokenSupply() * _vault.initialTokenPrice()) / (SCALE * 1e18);
        uint256 _secondaryReserveBalance = _vault.secondaryReserveBalance();
        uint256 _maxSecondaryBalanceIncrease = _fictitiousPrimaryReserveBalance - _secondaryReserveBalance;
        _feeCurve = _maxSecondaryBalanceIncrease > _feeCurve ? _feeCurve : _maxSecondaryBalanceIncrease; // the curve fee is capped so that secondaryReserveBalance <= fictitiousPrimaryReserveBalance
        _totalAmt = (_amount - (_feeAdmin + _feeCurator + _feeCurve));
    }
    function getPurchaseReturn(NibblVault _vault, uint256 _amount) public view returns(uint256 _purchaseReturn, uint256 _feeAdmin, uint256 _feeCurator, uint256 _feeCurve){
        // ;
        NibblVault _nibblVault = NibblVault(_vault);
        uint256 _initialTokenSupply = _nibblVault.initialTokenSupply();
        uint256 _totalSupply = _nibblVault.totalSupply();
        uint256 _primaryReserveBalance = _vault.primaryReserveBalance();
        uint256 _secondaryReserveBalance = _vault.secondaryReserveBalance();
        uint32 _secondaryReserveRatio = _vault.secondaryReserveRatio();
        if (_totalSupply >= _initialTokenSupply) {
            (_purchaseReturn, _feeAdmin, _feeCurator, _feeCurve) = chargeFee(_amount, _vault);
            _purchaseReturn = _calculatePurchaseReturn(_totalSupply, _primaryReserveBalance, PRIMARY_RESERVE_RATIO, _purchaseReturn);
        } else {
            uint256 _lowerCurveDiff = getMaxSecondaryCurveBalance(_vault) - _secondaryReserveBalance;
            if (_lowerCurveDiff >= _amount) {
                _purchaseReturn = _calculatePurchaseReturn(_totalSupply, _secondaryReserveBalance, _secondaryReserveRatio, _amount);
            } else {
                //Gas Optimization
                _purchaseReturn = _initialTokenSupply - _totalSupply;
                uint256 _totalAmt;
                (_totalAmt, _feeAdmin, _feeCurator, _feeCurve) = chargeFee(_amount - _lowerCurveDiff, _vault);
                _purchaseReturn += _calculatePurchaseReturn(_totalSupply + _purchaseReturn, _primaryReserveBalance, PRIMARY_RESERVE_RATIO, _totalAmt);
            } 
        }
    }


    function getSaleReturn(NibblVault _vault, uint256 _amount) public view returns(uint256 _saleReturn, uint256 _feeAdmin, uint256 _feeCurator, uint256 _feeCurve){
        NibblVault _nibblVault = NibblVault(_vault);
        uint256 _initialTokenSupply = _nibblVault.initialTokenSupply();
        uint256 _initialTokenPrice = _vault.initialTokenPrice();
        uint256 _totalSupply = _nibblVault.totalSupply();
        uint256 _primaryReserveBalance = _vault.primaryReserveBalance();
        uint256 _secondaryReserveBalance = _vault.secondaryReserveBalance();
        // uint32 _secondaryReserveRatio = _vault.secondaryReserveRatio();
        uint256 _fictitiousPrimaryReserveBalance = (PRIMARY_RESERVE_RATIO * _initialTokenSupply * _initialTokenPrice) / (SCALE * 1e18);

        if(_totalSupply > _initialTokenSupply) {
            if ((_initialTokenSupply + _amount) <= _totalSupply) {
                _saleReturn = _calculateSaleReturn(_totalSupply, _primaryReserveBalance, PRIMARY_RESERVE_RATIO, _amount);
                (_saleReturn,_feeAdmin, _feeCurator, _feeCurve ) = chargeFee(_saleReturn, _vault);
            } else {
                //Gas Optimization
                _saleReturn = _primaryReserveBalance - _fictitiousPrimaryReserveBalance;
                (_saleReturn, _feeAdmin, _feeCurator, _feeCurve) = chargeFee(_saleReturn, _vault);
                _amount = _amount - (_totalSupply - _initialTokenSupply);
                _secondaryReserveBalance = _secondaryReserveBalance + _feeCurve;
                // _secondaryReserveRatio = uint32((_secondaryReserveBalance * SCALE * 1e18) / (_initialTokenSupply * _initialTokenPrice)); //updating secondaryReserveRatio
                _saleReturn += _calculateSaleReturn(_initialTokenSupply, _secondaryReserveBalance, uint32((_secondaryReserveBalance * SCALE * 1e18) / (_initialTokenSupply * _initialTokenPrice)), _amount);
            } } else {
                _saleReturn = _calculateSaleReturn(_totalSupply, _secondaryReserveBalance, _vault.secondaryReserveRatio(), _amount);
        }
    }

    function getCurrentValuation(NibblVault _vault)  public view returns (uint256) {
        return _vault.totalSupply() < _vault.initialTokenSupply() ? (_vault.secondaryReserveBalance() * SCALE /_vault.secondaryReserveRatio()) : ((_vault.primaryReserveBalance()) * SCALE  / PRIMARY_RESERVE_RATIO);
    }

    function predictTwav(NibblVault _vault, uint256 _timeAfter) external view returns(uint256 _twav){
        Twav.TwavObservation[TWAV_BLOCK_NUMBERS] memory _twavObservations = _vault.getTwavObservations();
        uint256 _currentValuation = getCurrentValuation(_vault);
        uint256 _twavObservationsIndex = _vault.twavObservationsIndex();
        uint32 _timeElapsed; 
        uint32 _blockTimeStamp = uint32((block.timestamp + _timeAfter) % 2**32);
        unchecked {         
            _timeElapsed = _blockTimeStamp - _vault.lastBlockTimeStamp();
        }
        uint256 _prevCumulativeValuation = _twavObservations[((_twavObservationsIndex + TWAV_BLOCK_NUMBERS) - 1) % TWAV_BLOCK_NUMBERS].cumulativeValuation;
        _twavObservations[_twavObservationsIndex] = Twav.TwavObservation(_blockTimeStamp, _prevCumulativeValuation + (_currentValuation * _timeElapsed)); //add the previous observation to make it cumulative
        _twavObservationsIndex = (_twavObservationsIndex + 1) % TWAV_BLOCK_NUMBERS;
        
        if (_twavObservations[TWAV_BLOCK_NUMBERS - 1].timestamp != 0) {
            uint8 _index = uint8(((_twavObservationsIndex + TWAV_BLOCK_NUMBERS) - 1) % TWAV_BLOCK_NUMBERS);
            Twav.TwavObservation memory _twavObservationCurrent = _twavObservations[(_index)];
            Twav.TwavObservation memory _twavObservationPrev = _twavObservations[(_index + 1) % TWAV_BLOCK_NUMBERS];
            _twav = (_twavObservationCurrent.cumulativeValuation - _twavObservationPrev.cumulativeValuation) / (_twavObservationCurrent.timestamp - _twavObservationPrev.timestamp);
        }

    }
}