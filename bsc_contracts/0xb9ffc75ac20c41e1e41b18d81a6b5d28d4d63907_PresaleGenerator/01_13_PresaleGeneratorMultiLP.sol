// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./PresaleMultiLP.sol";
import "./libraries/Ownable.sol";
import "./libraries/SafeMath.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/IPresaleFactory.sol";
import "./interfaces/IPresaleSettings.sol";
import "./interfaces/IERC20.sol";

contract PresaleGenerator is Ownable {
    using SafeMath for uint256;
    
    IPresaleFactory public PRESALE_FACTORY;
    IPresaleSettings public PRESALE_SETTINGS;
    
    struct PresaleParams {
        uint256 amount;
        uint256 tokenPrice;
        uint256 minSpendPerBuyer;
        uint256 maxSpendPerBuyer;
        uint256 hardcap;
        uint256 softcap;
        uint256 earlyAllowanceRate;
        uint256 liquidityPercent;
        uint256 liquidityPercentPYE;
        uint256 liquidityPercentCAKE;
        uint256 listingRate; // sale token listing price on PYESwap
        uint256 startTime;
        uint256 endTime;
        uint256 lockPeriod;
    }
    
    constructor() {
        PRESALE_FACTORY = IPresaleFactory(0xC212bb6Cb68Cc2104166CDBE57cee1bD61ace065);
        PRESALE_SETTINGS = IPresaleSettings(0xecE51eDf17E116D2a1D19c2fAEF23b5D21049BcC);
    }

    function calculateAmountRequired (uint256 _amount, uint256 _tokenPrice, uint256 _listingRate, uint256 _liquidityPercent, uint256 _tokenFee) public pure returns (uint256) {
        uint256 listingRatePercent = _listingRate.mul(1000).div(_tokenPrice);
        uint256 pyeLABTokenFee = _amount.mul(_tokenFee).div(1000);
        uint256 amountMinusFee = _amount.sub(pyeLABTokenFee);
        uint256 liquidityRequired = amountMinusFee.mul(_liquidityPercent).mul(listingRatePercent).div(1000000);
        uint256 tokensRequiredForPresale = _amount.add(liquidityRequired).add(pyeLABTokenFee);
        return tokensRequiredForPresale;
    }
    
    /**
     * @notice Creates a new Presale contract and registers it in the PresaleFactory.sol.
     */
    function createPresale (
      address payable _presaleOwner,
      IERC20 _presaleToken,
      IERC20 _baseToken,
      bytes32 _referralCode,
      uint256[14] memory uint_params
      ) public payable {
        
        PresaleParams memory params;
        params.amount = uint_params[0];
        params.tokenPrice = uint_params[1];
        params.minSpendPerBuyer = uint_params[2];
        params.maxSpendPerBuyer = uint_params[3];
        params.hardcap = uint_params[4];
        params.softcap = uint_params[5];
        params.earlyAllowanceRate = uint_params[6];
        params.liquidityPercent = uint_params[7];
        params.liquidityPercentPYE = uint_params[8];
        params.liquidityPercentCAKE = uint_params[9];
        params.listingRate = uint_params[10];
        params.startTime = uint_params[11];
        params.endTime = uint_params[12];
        params.lockPeriod = uint_params[13];
        
        if (params.lockPeriod < 4 weeks) {
            params.lockPeriod = 4 weeks;
        }
        
        // Charge ETH fee for contract creation
        require(msg.value == PRESALE_SETTINGS.getEthCreationFee(), 'FEE NOT MET');
        PRESALE_SETTINGS.getEthAddress().transfer(PRESALE_SETTINGS.getEthCreationFee());
        
        require(params.amount >= 10000, 'MIN DIVIS'); // minimum divisibility
        require(params.endTime.sub(params.startTime) <= PRESALE_SETTINGS.getMaxPresaleLength());
        require(params.tokenPrice.mul(params.hardcap) > 0, 'INVALID PARAMS'); // ensure no overflow for future calculations
        require(params.softcap >= params.hardcap.mul(PRESALE_SETTINGS.getMinSoftcapRate()).div(10000), 'Invalid Softcap Amount');
        require(params.minSpendPerBuyer < params.maxSpendPerBuyer, 'Invalid Spend Limits');
        require(params.liquidityPercent >= 300 && params.liquidityPercent <= 1000, 'MIN LIQUIDITY'); // 30% minimum liquidity lock
        require(params.liquidityPercentPYE >= PRESALE_SETTINGS.getMinimumPercentToPYE() && params.liquidityPercentPYE + params.liquidityPercentCAKE == 1000, 'Invalid Liquidity Split');
        require(PRESALE_SETTINGS.baseTokenIsValid(address(_baseToken))); // Base Token Must be Allowed
        require(params.earlyAllowanceRate >= PRESALE_SETTINGS.getMinEarlyAllowance(), 'Invalid Early Access Allowance');
        
        uint256 tokensRequiredForPresale = calculateAmountRequired(params.amount, params.tokenPrice, params.listingRate, params.liquidityPercent, PRESALE_SETTINGS.getTokenFee());
      
        PresaleMultiLP newPresale = new PresaleMultiLP(address(this));
        TransferHelper.safeTransferFrom(address(_presaleToken), address(msg.sender), address(newPresale), tokensRequiredForPresale);
        require(IERC20(_presaleToken).balanceOf(address(newPresale)) == tokensRequiredForPresale, 'Wrong Token Amount Received');
        newPresale.init1(
            _presaleOwner, 
            params.amount, 
            params.tokenPrice, 
            params.minSpendPerBuyer, 
            params.maxSpendPerBuyer, 
            params.hardcap, 
            params.softcap, 
            params.liquidityPercentPYE * params.liquidityPercent / 1000, 
            params.liquidityPercentCAKE * params.liquidityPercent / 1000, 
            params.listingRate, 
            params.startTime, 
            params.endTime, 
            params.lockPeriod
        );
        address payable _referralAddress;
        uint256 _referralIndex;
        if (_referralCode != 0) {
            bool _referrerIsValid;
            (_referrerIsValid, _referralAddress, _referralIndex) = PRESALE_SETTINGS.addReferral(_referralCode, address(_presaleToken), address(newPresale), address(_baseToken));
            require(_referrerIsValid, 'INVALID REFERRAL');
        }
        newPresale.init2(
            _baseToken, 
            _presaleToken, 
            PRESALE_SETTINGS.getBaseFee(), 
            PRESALE_SETTINGS.getTokenFee(), 
            PRESALE_SETTINGS.getReferralFee(), 
            PRESALE_SETTINGS.getEthAddress(), 
            PRESALE_SETTINGS.getTokenAddress(), 
            _referralAddress,
            _referralCode,
            _referralIndex
        );
        newPresale.initEarlyAllowance(params.earlyAllowanceRate);
        PRESALE_FACTORY.registerPresale(address(newPresale));
    }
    
}