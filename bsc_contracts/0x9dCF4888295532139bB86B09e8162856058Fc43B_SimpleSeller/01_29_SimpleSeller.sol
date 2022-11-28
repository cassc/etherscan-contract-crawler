// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;
import "./interfaces/Interfaces.sol";

/// @title Simple Seller
/// @author dannydoritoeth
/// @notice The central contract for deploying and managing option collateral vaults.
contract SimpleSeller is IFeeCalcs, IStructs, Context {

    // properties
    mapping(uint => mapping(IOracle => uint256[])) public callPeriods; //vaultId -> oracle -> array of periods
    mapping(uint => mapping(IOracle => mapping (uint256 => IStructs.PricePoint[]))) public callPrices; //vaultId -> oracle -> period -> array of prices at strikes
    mapping(uint => mapping(IOracle => uint256[])) public callFactor; //vaultId -> oracle -> 10000 = 100%
    mapping(uint => mapping(IOracle => uint256[])) public putPeriods;
    mapping(uint => mapping(IOracle => mapping (uint256 => IStructs.PricePoint[]))) public putPrices;
    mapping(uint => mapping(IOracle => uint256[])) public putFactor;
    mapping(uint => uint256) public dutchAuctionStartTime;
    mapping(uint => uint256) public dutchAuctionWindow;
    mapping(uint => uint256) public dutchAuctionStartMultiplier;

    // constants
    IOptionsVaultFactory public immutable factory;

    // events

    /// @notice The factors for a vault, oracle, optionType have changed
    /// @param byAccount The account making the change
    /// @param vaultId Vault id
    /// @param oracle Oracle address
    /// @param optionType Call or Put option type
    event SetFactors(address indexed byAccount, uint indexed vaultId, IOracle oracle, OptionType optionType);

    /// @notice The price points for a vault, oracle have been deleted
    /// @param byAccount The account making the change
    /// @param vaultId Vault id
    /// @param oracle Oracle address
    event DeletePricePoints(address indexed byAccount, uint indexed vaultId, IOracle oracle);

    /// @notice The price points for a vault, oracle, optionType have been set
    /// @param byAccount The account making the change
    /// @param vaultId Vault id
    /// @param oracle Oracle address
    /// @param optionType Call or Put option type
    event SetPricePoints(address indexed byAccount, uint indexed vaultId, IOracle oracle, OptionType optionType);

    /// @notice The dutch auction parameters have be changed
    /// @param byAccount The account making the change
    /// @param dutchAuctionStartTime The time in seconds when the dutch auction starts
    /// @param dutchAuctionWindow The time in seconds that dutch auction should run for
    /// @param dutchAuctionStartMultiplier The starting multiplier
    event SetDutchAuctionParams(address indexed byAccount, uint indexed vaultId, uint256 dutchAuctionStartTime, uint256 dutchAuctionWindow,  uint256 dutchAuctionStartMultiplier);

    // functions

    /// @notice Contract constructor
    /// @param _factory The factory the simple seller is providing prices for
    constructor(IOptionsVaultFactory _factory){
        factory = _factory;
    }

    /// @notice Implements the pricing function. Denomiated in the collateral token.
    /// @param inParams the parameters passed to the premium function in a struct
    /// @return fees_ a struct of the premium to be charged
    function getFees(IStructs.InputParams memory inParams)
        override
        external
        view
        returns (Fees memory fees_)
    {
        require (inParams.optionType == OptionType.Call || inParams.optionType == OptionType.Put,"SimpleSeller: Must be put or call");
        require (inParams.currentPrice > 0,"SimpleSeller: Current price cannot be 0");

        if (inParams.strike < inParams.currentPrice && inParams.optionType == OptionType.Call)
                fees_.intrinsicFee = (inParams.currentPrice-inParams.strike)*inParams.optionSize/inParams.currentPrice;
        if (inParams.strike > inParams.currentPrice && inParams.optionType == OptionType.Put)
                fees_.intrinsicFee = (inParams.strike-inParams.currentPrice)*inParams.optionSize/inParams.currentPrice;

        fees_.extrinsicFee = getExtrinsicFee(inParams);
        fees_.vaultFee = inParams.vault.vaultFee()*inParams.optionSize/1e4;
    }

    /// @notice Calculates the intrinsic fee for the option
    /// @param inParams the parameters passed to the premium function in a struct
    /// @return fee the calculated premium
    function getExtrinsicFee(IStructs.InputParams memory inParams) internal view returns (uint256) {
        if(inParams.optionType == OptionType.Call){
            require (callPeriods[inParams.vaultId][inParams.oracle].length>0,"SimpleSeller: No periods for this vault->oracle");
        }
        if(inParams.optionType == OptionType.Put){
            require (putPeriods[inParams.vaultId][inParams.oracle].length>0,"SimpleSeller: No periods for this vault->oracle");
        }
        CalcParams memory cParams;

        findStrike(inParams,cParams);
        matchPeriod(inParams,cParams);
        matchFee(inParams,cParams);
        relativeStrikeFee(inParams,cParams);
        relativePeriodFee(inParams,cParams);


        int adjustedFee = (SafeCast.toInt256(cParams.matchFee) + cParams.relativeStrikeFee + cParams.relativePeriodFee)*SafeCast.toInt256(inParams.optionSize)/SafeCast.toInt256(inParams.currentPrice);
        require(adjustedFee>0,"SimpleSeller: Adjusted fee can't be <0");

        uint256 reserveFee;
        if(inParams.optionType == OptionType.Call){
            reserveFee = SafeCast.toUint256(adjustedFee) * getFactor(inParams.vaultId, callFactor[inParams.vaultId][inParams.oracle], inParams.optionSize)/1e4;
        }
        if(inParams.optionType == OptionType.Put){
            reserveFee = SafeCast.toUint256(adjustedFee) * getFactor(inParams.vaultId, putFactor[inParams.vaultId][inParams.oracle], inParams.optionSize)/1e4;
        }
        uint256 dutchFee = dutchAuctionFee(inParams,reserveFee);
        return (dutchFee>reserveFee) ? dutchFee : reserveFee;
    }

    /// @notice Calculate the strike to search for. 0 is at the money, moving away in basis point percents. eg. 1000 is 10% out of the money
    /// @param _inParams the parameters passed to the premium function in a struct
    /// @param calcParams_ a struct of calculated parameters to be used between functions
    function findStrike(InputParams memory _inParams, CalcParams memory calcParams_) internal pure{
        if(_inParams.optionType == OptionType.Call){
            calcParams_.findStrike = (SafeCast.toInt256(_inParams.strike)-SafeCast.toInt256(_inParams.currentPrice))*1e4/SafeCast.toInt256(_inParams.currentPrice);
        }

        if(_inParams.optionType == OptionType.Put){
            calcParams_.findStrike = (SafeCast.toInt256(_inParams.currentPrice)-SafeCast.toInt256(_inParams.strike))*1e4/SafeCast.toInt256(_inParams.currentPrice);
        }
    }

    /// @notice Match the expiry date to search for.
    /// @param _inParams the parameters passed to the premium function in a struct
    /// @param calcParams_ a struct of calculated parameters to be used between functions
    function matchPeriod(InputParams memory _inParams, CalcParams memory calcParams_) internal view{
        uint256[] memory p;
        if(_inParams.optionType == OptionType.Call){
                p = callPeriods[_inParams.vaultId][_inParams.oracle];
        }
        if(_inParams.optionType == OptionType.Put){
                p = putPeriods[_inParams.vaultId][_inParams.oracle];
        }

        require((_inParams.period >= p[0]) && (_inParams.period <= p[p.length-1]),"SimpleSeller: No matched period");

        for(uint i=p.length-1; i>=0; i--){
            if (_inParams.period >= p[i]){
                calcParams_.matchPeriod = p[i];
                calcParams_.matchPeriodPos = i;
                break;
            }
        }

        require (calcParams_.matchPeriod>0,"No matched period");
    }

    /// @notice Calculate the fee that matches the closest expiry/strike
    /// @param _inParams the parameters passed to the premium function in a struct
    /// @param calcParams_ a struct of calculated parameters to be used between functions
    function matchFee(InputParams memory _inParams, CalcParams memory calcParams_) internal view {
        IStructs.PricePoint[] memory pp;

        if(_inParams.optionType == OptionType.Call){
            pp = callPrices[_inParams.vaultId][_inParams.oracle][calcParams_.matchPeriod];
        }
        if(_inParams.optionType == OptionType.Put){
            pp = putPrices[_inParams.vaultId][_inParams.oracle][calcParams_.matchPeriod];
        }
        require((calcParams_.findStrike >= pp[0].strike) && (calcParams_.findStrike <= pp[pp.length-1].strike),"SimpleSeller: No matched strike");
        for(uint i=pp.length-1; i>=0; i--){

            if (calcParams_.findStrike >= pp[i].strike){
                calcParams_.matchStrikePos = i;
                calcParams_.matchFee = pp[i].fee;
                return;
            }
        }
        revert ("SimpleSeller: No matched strike");
    }

    /// @notice Calculates an adjusted strike fee based on where the strike is between two strike price points
    /// @param _inParams the parameters passed to the premium function in a struct
    /// @param _calcParams A struct of the parameters passed to the option creation
    function relativeStrikeFee(InputParams memory _inParams, CalcParams memory _calcParams) internal view {
        //Relative Strike Fee = (findStrike-matchStrike)*(strikeFeeDiff/strikeDiff)
        IStructs.PricePoint[] memory pp;

        if(_inParams.optionType == OptionType.Call){
            pp = callPrices[_inParams.vaultId][_inParams.oracle][_calcParams.matchPeriod];
        }
        if(_inParams.optionType == OptionType.Put){
            pp = putPrices[_inParams.vaultId][_inParams.oracle][_calcParams.matchPeriod];
        }

        if(_calcParams.matchStrikePos+1>=pp.length){
            return;
        }

        int strikeFeeDiff = 0;
        if ( SafeCast.toInt256(pp[_calcParams.matchStrikePos].fee) > SafeCast.toInt256(pp[_calcParams.matchStrikePos+1].fee)){
            strikeFeeDiff = SafeCast.toInt256(pp[_calcParams.matchStrikePos].fee) - SafeCast.toInt256(pp[_calcParams.matchStrikePos+1].fee);
        }
        else{
            strikeFeeDiff = SafeCast.toInt256(pp[_calcParams.matchStrikePos+1].fee) - SafeCast.toInt256(pp[_calcParams.matchStrikePos].fee);
        }
        int strikeDiff = pp[_calcParams.matchStrikePos].strike - pp[_calcParams.matchStrikePos+1].strike;
        int rsf = (_calcParams.findStrike-pp[_calcParams.matchStrikePos].strike)*strikeFeeDiff/strikeDiff;

        if (pp[_calcParams.matchStrikePos].fee > pp[_calcParams.matchStrikePos+1].fee){
            _calcParams.relativeStrikeFee = rsf;
        }
        else{
            _calcParams.relativeStrikeFee = -rsf;
        }
    }

    /// @notice Calculates the an adjusted period fee based on where the period is between two period price points
    /// @param _inParams the parameters passed to the premium function in a struct
    /// @param _calcParams A struct of the parameters passed to the option creation
    function relativePeriodFee(InputParams memory _inParams, CalcParams memory _calcParams) internal view {
        //Relative Period Fee = (findPeriod-matchPeriod)*(periodFeeDiff/periodDiff)
        uint256[] memory periods;

        IStructs.PricePoint[] memory pp;
        IStructs.PricePoint[] memory ppNext;

        if(_inParams.optionType == OptionType.Call){
            periods = callPeriods[_inParams.vaultId][_inParams.oracle];
            pp = callPrices[_inParams.vaultId][_inParams.oracle][_calcParams.matchPeriod];
            if(_calcParams.matchPeriodPos+1>=periods.length){
                return;
            }
            ppNext = callPrices[_inParams.vaultId][_inParams.oracle][periods[_calcParams.matchPeriodPos+1]];
        }
        if(_inParams.optionType == OptionType.Put){
            periods = putPeriods[_inParams.vaultId][_inParams.oracle];
            pp = putPrices[_inParams.vaultId][_inParams.oracle][_calcParams.matchPeriod];
            if(_calcParams.matchPeriodPos+1>=periods.length){
                return;
            }
            ppNext = putPrices[_inParams.vaultId][_inParams.oracle][periods[_calcParams.matchPeriodPos+1]];
        }

        int periodFeeDiff = 0;
        if (pp[_calcParams.matchStrikePos].fee > ppNext[_calcParams.matchStrikePos].fee){
            periodFeeDiff =  SafeCast.toInt256(pp[_calcParams.matchStrikePos].fee) - SafeCast.toInt256(ppNext[_calcParams.matchStrikePos].fee);
        }
        else{
            periodFeeDiff = SafeCast.toInt256(ppNext[_calcParams.matchStrikePos].fee) - SafeCast.toInt256(pp[_calcParams.matchStrikePos].fee);
        }

        int periodDiff = SafeCast.toInt256(periods[_calcParams.matchPeriodPos+1]) - SafeCast.toInt256(periods[_calcParams.matchPeriodPos]);
        int rpf = SafeCast.toInt256(_inParams.period-_calcParams.matchPeriod)*periodFeeDiff/periodDiff;

        if (pp[_calcParams.matchStrikePos].fee > ppNext[_calcParams.matchStrikePos].fee){
            _calcParams.relativePeriodFee = -rpf;
        }
        else{
            _calcParams.relativePeriodFee = rpf;
        }
    }

    /// @notice Calculates what factor to apply based on the utilisation of the vault and how much of the vault this option purchased will use.
    /// @param vaultId Vault id
    /// @param factorArray The factor array for the vault
    /// @param optionSize A struct of the parameters passed to the option creation
    function getFactor(uint vaultId, uint256[] memory factorArray, uint256 optionSize) public view returns(uint){
        if(factorArray.length==0){
            return 1e4;
        }

        uint startUtil=factory.vaults(vaultId).vaultUtilization(0);
        uint endUtil=factory.vaults(vaultId).vaultUtilization(optionSize);

        uint factorSum;
        uint factorCnt;
        for(uint256 i; i<factorArray.length; i++){
            if((i*1e4>=startUtil*(factorArray.length-1))){
                factorSum += factorArray[i];
                factorCnt += 1;
                if (i*1e4>endUtil*(factorArray.length-1))
                    break;
            }
        }
        return factorSum/factorCnt;
    }

    /// @notice Calculate the dutch auction fee
    /// The reserve price is the base. The start price is a multiple of the base price.
    /// The amount is reduced until the window passes then repeats.
    /// @param _inParams The parameters passed to the premium function in a struct
    /// @param reservePrice A struct of the parameters passed to the option creation
    /// @return fee The dutch auction fee
    function dutchAuctionFee (InputParams memory _inParams, uint256 reservePrice) internal view returns(uint) {

        //poor mans dutch auction
        //startPrice - ((start price-reserve price)/(end time-start time)*time in window)
        uint256 dast = dutchAuctionStartTime[_inParams.vaultId];
        uint256 daw = dutchAuctionWindow[_inParams.vaultId];
        if(dast==0 || dast>=block.timestamp){
            return 0;
        }

        uint startPrice = reservePrice * dutchAuctionStartMultiplier[_inParams.vaultId] / 1e4;
        uint256 timeInWindow =  (block.timestamp - dast) % daw;
        return startPrice-(timeInWindow*(startPrice-reservePrice)/(daw));
    }

    /// @notice Set the parameters to be used for the dutch auction
    /// @param vaultId Vault id
    /// @param _dutchAuctionStartTime The time in seconds when the dutch auction starts
    /// @param _dutchAuctionWindow The time in seconds that dutch auction should run for
    /// @param _dutchAuctionStartMultiplier The starting multiplier
    function setDutchAuctionParams(uint vaultId, uint256 _dutchAuctionStartTime, uint256 _dutchAuctionWindow,  uint256 _dutchAuctionStartMultiplier) external {
        require(_dutchAuctionStartMultiplier>10000,"SimpleSeller: multiplier must be more than 10000");
        require(_dutchAuctionWindow>1 hours,"SimpleSeller: window must be more than 1hr");
        require(factory.vaults(vaultId).hasRoleVaultOwnerOrOperator(_msgSender()),"SimpleSeller: must hold owner or operator role");

        dutchAuctionStartTime[vaultId] = _dutchAuctionStartTime;
        dutchAuctionWindow[vaultId] = _dutchAuctionWindow;
        dutchAuctionStartMultiplier[vaultId] = _dutchAuctionStartMultiplier;
        emit SetDutchAuctionParams(_msgSender(), vaultId, _dutchAuctionStartTime, _dutchAuctionWindow, _dutchAuctionStartMultiplier);
    }

    /// @notice Set the factors for the vault, oracle, option type. Factors increase the price based on the utilisation of the vault.
    /// @param vaultId Vault id
    /// @param oracle Oracle address
    /// @param optionType Call or Put option type
    /// @param factors A struct of the parameters passed to the option creation
    function setFactor(uint vaultId, IOracle oracle, OptionType optionType, uint256[] memory factors) public {
        require(factory.vaults(vaultId).hasRoleVaultOwnerOrOperator(_msgSender()),"SimpleSeller: must hold owner or operator role");
        require (optionType == OptionType.Call || optionType == OptionType.Put,"SimpleSeller: Must be put or call");

        uint lastFactor=0;
        for(uint i=0; i<factors.length; i++){
           require(factors[i]>lastFactor,"SimpleSeller: factors must be in ascending order");
           lastFactor = factors[i];
        }

        if (optionType == OptionType.Call){
            callFactor[vaultId][oracle] = factors;
        }
        if(optionType == OptionType.Put){
            putFactor[vaultId][oracle] = factors;
        }
        emit SetFactors(_msgSender(), vaultId, oracle, optionType);
    }

    /// @notice Delete the price points for a vault, oracle.
    /// @param vaultId Vault id
    /// @param oracle Oracle address
    function deletePricePoints(uint vaultId, IOracle oracle) external {
        require(factory.vaults(vaultId).hasRoleVaultOwnerOrOperator(_msgSender()),"SimpleSeller: must hold owner or operator role");
        delete callPeriods[vaultId][oracle];
        delete putPeriods[vaultId][oracle];
        emit DeletePricePoints(_msgSender(), vaultId, oracle);
    }

    /// @notice Set the price points for the vault, oracle, optionType. Periods are in seconds from now(ie. 1 day is 86400) & strikes are relative basis percentages (ie. 1000 is 10%). Fees are denominated in the collateral token. Periods & strikes must be in ascending order.
    /// @param vaultId Vault id
    /// @param oracle Oracle address
    /// @param optionType Call or Put option type
    /// @param periods An array of the periods for the price points in seconds from now
    /// @param strikes An array of the st
    /// @param fees A struct of the parameters passed to the option creation
    function setPricePoints(uint vaultId, IOracle oracle, OptionType optionType, uint[] memory periods, int[] memory strikes, uint[] memory fees) external {
        require(periods.length>0,"SimpleSeller: must have some price points");
        require(periods.length==strikes.length,"SimpleSeller: periods & strikes lengths must be the same");
        require(periods.length==fees.length,"SimpleSeller: periods & fees lengths must be the same");
        require(factory.vaults(vaultId).hasRoleVaultOwnerOrOperator(_msgSender()),"SimpleSeller: must hold owner or operator role");
        require(optionType == OptionType.Call || optionType == OptionType.Put,"SimpleSeller: Must be put or call");

        uint lastPeriod = 0;
        int lastStrike = -1e4;

        if (optionType == OptionType.Call){
            delete callPeriods[vaultId][oracle];
            for(uint i=0; i<periods.length; i++){
                require(periods[i]!=0,"SimpleSeller: period must not be 0");
                if (lastPeriod != periods[i]){
                    require(periods[i]>lastPeriod,"SimpleSeller: periods must be in ascending order");
                    callPeriods[vaultId][oracle].push(periods[i]);
                    lastPeriod = periods[i];
                    delete callPrices[vaultId][oracle][lastPeriod];
                    lastStrike = -1e4;
                }
                require(strikes[i]>=-1e4,"SimpleSeller: strikes must be >= -10000");
                require(strikes[i]>=lastStrike,"SimpleSeller: strikes must be in ascending order");
                callPrices[vaultId][oracle][lastPeriod].push(PricePoint(strikes[i],fees[i]));
                lastStrike = strikes[i];

                uint256[] memory p = callPeriods[vaultId][oracle];
                if(p.length>1){
                    IStructs.PricePoint[] memory pp = callPrices[vaultId][oracle][p[p.length-1]];
                    IStructs.PricePoint[] memory pp2 = callPrices[vaultId][oracle][p[p.length-2]];
                    require(pp[pp.length-1].strike==pp2[pp.length-1].strike,"SimpleSeller: price points must form a grid");
                }
            }
        }

        if (optionType == OptionType.Put){
            delete putPeriods[vaultId][oracle];

            for(uint i=0; i<periods.length; i++){
                require(periods[i]!=0,"SimpleSeller: period must not be 0");
                if (lastPeriod != periods[i]){
                    require(periods[i]>lastPeriod,"SimpleSeller: periods must be in ascending order");
                    putPeriods[vaultId][oracle].push(periods[i]);
                    lastPeriod = periods[i];
                    delete putPrices[vaultId][oracle][lastPeriod];
                    lastStrike = -1e4;
                }
                require(strikes[i]>=-1e4,"SimpleSeller: strikes must be >= -10000");
                require(strikes[i]>=lastStrike,"SimpleSeller: strikes must be in ascending order");
                putPrices[vaultId][oracle][lastPeriod].push(PricePoint(strikes[i],fees[i]));
                lastStrike = strikes[i];

                uint256[] memory p = putPeriods[vaultId][oracle];
                if(p.length>1){
                    IStructs.PricePoint[] memory pp = putPrices[vaultId][oracle][p[p.length-1]];
                    IStructs.PricePoint[] memory pp2 = putPrices[vaultId][oracle][p[p.length-2]];
                    require(pp[pp.length-1].strike==pp2[pp.length-1].strike,"SimpleSeller: price points must form a grid");
                }
            }
        }
        // validatePricePoints(vaultId,oracle,optionType);
        emit SetPricePoints(_msgSender(),vaultId, oracle, optionType);
    }

    /// @notice A helper function to return the length of the callPeriods array
    /// @param vaultId Vault id
    /// @param oracle Oracle address
    function callPeriodsLength(uint vaultId, IOracle oracle) public view returns (uint256){
        return callPeriods[vaultId][oracle].length;
    }

    /// @notice A helper function to return the length of the callPrices array
    /// @param vaultId Vault id
    /// @param oracle Oracle address
    /// @param period The period
    function callPricesLength(uint vaultId, IOracle oracle, uint256 period) public view returns (uint256){
        return callPrices[vaultId][oracle][period].length;
    }

    /// @notice A helper function to return the length of the callFactor array
    /// @param vaultId Vault id
    /// @param oracle Oracle address
    function callFactorLength(uint vaultId, IOracle oracle) public view returns (uint256){
        return callFactor[vaultId][oracle].length;
    }

    /// @notice A helper function to return the length of the putPeriods array
    /// @param vaultId Vault id
    /// @param oracle Oracle address
    function putPeriodsLength(uint vaultId, IOracle oracle) public view returns (uint256){
        return putPeriods[vaultId][oracle].length;
    }

    /// @notice A helper function to return the length of the putPrices array
    /// @param vaultId Vault id
    /// @param oracle Oracle address
    /// @param period The period
    function putPricesLength(uint vaultId, IOracle oracle, uint256 period) public view returns (uint256){
        return putPrices[vaultId][oracle][period].length;
    }

    /// @notice A helper function to return the length of the putFactor array
    /// @param vaultId Vault id
    /// @param oracle Oracle address
    function putFactorLength(uint vaultId, IOracle oracle) public view returns (uint256){
        return putFactor[vaultId][oracle].length;
    }
}