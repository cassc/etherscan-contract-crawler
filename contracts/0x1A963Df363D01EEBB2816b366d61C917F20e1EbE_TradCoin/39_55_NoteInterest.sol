pragma solidity ^0.8.10;


import "./PriceOracle.sol";
import "./SafeMath.sol";
import "./CErc20.sol";
/**
  * @title note's interest rate model contract
  * @author canto
  */

contract NoteRateModel is InterestRateModel{

    using SafeMath for uint;
    
    /**
     * @notice The approximate number of blocks per year that is assumed by the interest rate model
     */
    uint public constant BlocksPerYear = 5256666;


    uint public constant BASE = 1e18;

    uint public decimals;

    uint public scale;

    /**
     * @notice The variable to keep track of the last update on Note's interest rate, initialized at the current block number
     */
    uint public lastUpdateBlock;

    /**
     * @notice baseRatePerYear The per year interest rate, as a mantissa (scaled by 1e18)
     */
    uint public baseRatePerYear;

    /**
     * @notice baseRatePerBlock The per block interest rate, as a mantissa (scaled by 1e18)
     */
    uint public baseRatePerBlock;

    /**
     * @notice The level of aggressiveness to adjust interest rate according to twap's deviation from the peg
     */
    uint public adjusterCoefficient; // set by admin, default 1
    /**
     * @notice The frequency of updating Note's base rate
     */
    uint public updateFrequency = 2160; // set by admin, default 6 hours = 216000 seconds / 6 secs per block

    PriceOracle public oracle;

    /**
     * @notice The CToken identifier for Note
     */
    CErc20 public cUsdc;

    /**
    * @notice administrator for this contract
    */
    address private admin;


    /// @notice Emitted when base rate is changed by admin
    event NewBaseRate(uint oldBaseRateMantissa, uint newBaseRateMantissa);

    /// @notice Emitted when adjuster coefficient is changed by admin
    event NewAdjusterCoefficient(uint oldAdjusterCoefficient, uint newAdjusterCoefficient);

    /// @notice Emitted when update frequency is changed by admin
    event NewUpdateFrequency(uint oldUpdateFrequency, uint newUpdateFrequency);

    /// @notice Emitted when new baserateperblock is set
    event NewInterestParams(uint baserateperblock);

    /// @notice Emitted when new PriceOracle is set
    event NewPriceOracle(address oldOracle, address newOracle);

    /// @notice Emitted when new admin is set
    event NewAdmin(address oldAdmin, address newAdmin);

    /// @notice reverted if the getUnderlying Price fails 
    error FailedPriceRetrieval(CToken ctoken);

    /// @notice reverted if sender is not admin
    error SenderNotAdmin(address sender);

    /**
     * @notice Construct an interest rate model
     * @param _baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18), set by admin, default 2%
     */
    constructor(uint _baseRatePerYear) {
        baseRatePerYear = _baseRatePerYear;
        baseRatePerBlock = _baseRatePerYear.div(BlocksPerYear);
        emit NewInterestParams(baseRatePerBlock);
        admin = msg.sender;
        lastUpdateBlock = block.number;
    }

    function initialize(address cUsdcAddr, address oracleAddress) external {
        require(address(oracle) == address(0) && address(cUsdc) == address(0));
        if (msg.sender != admin ) {
            revert SenderNotAdmin(msg.sender);
        }   
        address oldPriceOracle = address(oracle);
        cUsdc = CErc20(cUsdcAddr);
        decimals = EIP20Interface(cUsdc.underlying()).decimals();
        scale = (10) ** (18 - decimals);
        oracle = PriceOracle(oracleAddress);
        emit NewPriceOracle(oldPriceOracle, oracleAddress);
    }

    function setAdmin(address newAdmin) external {
        if (msg.sender != admin) {
            revert SenderNotAdmin(msg.sender);
        }
        admin = newAdmin;
    }

    function setOracle(address oracle_) external {
        if (msg.sender != admin) {
            revert SenderNotAdmin(msg.sender);
        }
        address oldPriceOracle = address(oracle);
        oracle = PriceOracle(oracle_);
        emit NewPriceOracle(oldPriceOracle, oracle_);
    }

    function getBorrowRate(uint cash, uint borrows, uint reserves) external view override returns(uint) {
        return baseRatePerBlock;
    }


    /**
     * @notice Calculates the current supply rate per block, which is the same as the borrow rate
     * @notice The following parameters are irrelevent for calculating Note's interest rate. They are passed in to align with the standard function definition `getSupplyRate` in InterestRateModel
     * @return Note's supply rate percentage per block as a mantissa (scaled by 1e18)
     */
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) external view override returns (uint) {
        return baseRatePerBlock;
    }

    /**
     * @notice Updates the Note's base rate per year at a given interval (Update Frequency)
     * @notice This interest rate is calculated as follows f(x) = max(0, (1 - $NOTE) * adjusterCoefficient + priorInterestRate ) 
     * @notice If Note is trading above 1$ then lower the interest rate to benefit suppliers
     * This function is called in accrue Interest by the cNote Contract 
     */
    function updateBaseRate() external {
        // check the current block number
        uint blockNumber = block.number;
        uint deltaBlocks = blockNumber - lastUpdateBlock;
        if (deltaBlocks > updateFrequency) {
            uint twapMantissa = oracle.getUnderlyingPrice(cUsdc) / scale; // returns price as mantissa / scale to 18 decimals, by (1e12)
            uint notePrice = BASE * BASE/ twapMantissa; // Price of Note in USDC is 1/ (PRice of UDSC in Note)

            uint diff = (BASE >= notePrice) ? BASE - notePrice : notePrice - BASE; //difference between price of USDC and expected Price (in note)
            uint interestAdjust = (diff * adjusterCoefficient)/BASE; // these values are both scaled by 1e18

            uint newBaseRatePerYear;
            if (notePrice > BASE) {
                // note is over-performing the dollar defer to borrowers: decrease borrowRate (have users borrow note, swap for usdc)
                newBaseRatePerYear = (interestAdjust <= baseRatePerYear) ? baseRatePerYear - interestAdjust : 0; 
            } else { 
                // note is under-performing the dollar, defer to suppliers: increase the supply rate (have users swap usdc for note to supply it)
                newBaseRatePerYear = interestAdjust + baseRatePerYear; 
            }

            baseRatePerYear = newBaseRatePerYear;
            // convert it to base rate per block
            baseRatePerBlock = baseRatePerYear.div(BlocksPerYear);
            lastUpdateBlock = blockNumber;
            emit NewInterestParams(baseRatePerYear);
        }
    }

    // Admin functions

    /**
      * @notice Sets the base interest rate for Note
      * @dev Admin function to set per-market base interest rate
      * @param newBaseRateMantissa The new base interest rate, scaled by 1e18
      */
    function _setBaseRatePerYear(uint newBaseRateMantissa) external {
        // Check caller is admin
        require(msg.sender == admin, "only the admin may set the base rate");
        uint oldBaseRatePerYear = baseRatePerYear;
        baseRatePerYear = newBaseRateMantissa;
        emit NewBaseRate(oldBaseRatePerYear, baseRatePerYear);
    }

    /**
      * @notice Sets the adjuster coefficient for Note
      * @dev Admin function to set per-market adjuster coefficient
      * @param newAdjusterCoefficient The new adjuster coefficient, scaled by 1e18
      */
    function _setAdjusterCoefficient(uint newAdjusterCoefficient) external {
        // Check caller is admin
        require(msg.sender == admin, "only the admin may set the adjuster coefficient");
        uint oldAdjusterCoefficient = adjusterCoefficient;
        adjusterCoefficient = newAdjusterCoefficient;
        emit NewAdjusterCoefficient(oldAdjusterCoefficient, adjusterCoefficient);
    }

    /**
      * @notice Sets the update frequency for Note's interest rate
      * @dev Admin function to set the update frequency
      * @param newUpdateFrequency The new update frequency, in blocks
      */
    function _setUpdateFrequency(uint newUpdateFrequency) external {
        // Check caller is admin
        require(msg.sender == admin, "only the admin may set the update frequency");
        uint oldUpdateFrequency = updateFrequency;
        updateFrequency = newUpdateFrequency;
        emit NewUpdateFrequency(oldUpdateFrequency, updateFrequency);
    }
}