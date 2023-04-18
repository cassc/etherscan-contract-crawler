// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - [email protected]
    - [email protected]

    contributors:
    - [email protected]

**************************************/

// OpenZeppelin
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// Uniswap
import { OracleLibrary } from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

// ABDK
import { ABDKMath64x64 } from "abdk-libraries-solidity/ABDKMath64x64.sol";

// Local
import { Configurable } from "../utils/Configurable.sol";
import { INFTDataOperator } from "../interfaces/INFTDataOperator.sol";
import { ITholosStaking } from "../interfaces/ITholosStaking.sol";

contract NFTDataOperator is Ownable, Configurable, INFTDataOperator {

    // -----------------------------------------------------------------------
    //                             Library usage
    // -----------------------------------------------------------------------

    using ABDKMath64x64 for int128;

    // -----------------------------------------------------------------------
    //                             State variables
    // -----------------------------------------------------------------------

    /// @dev Staking contract address.
    address public immutable staking; 
    /// @dev Address authorized to provide data. 
    address public dataProvider;
    /// @dev Uniswap V3 THOL-WETH pool address.
    address public tholWethPool;
    /// @dev WETH token address.
    address public weth;
    /// @dev THOL token address.
    address public thol;

    /// @dev 400% as 64.64-bit fixed point number
    int128 public localMaxPercentage;
    /// @dev 25% as 64.64-bit fixed point number
    int128 public localMinPercentage;

    // -----------------------------------------------------------------------
    //                             Modifiers
    // -----------------------------------------------------------------------

    /// @dev Verify if current 'msg.sender' is data provider.
    modifier onlyDataProvider() {
        if (msg.sender != dataProvider) revert Unauthorized();
        _;
    }

    // -----------------------------------------------------------------------
    //                             Setup
    // -----------------------------------------------------------------------

    constructor(bytes memory _arguments) {

        // decode arguments
        (
            address staking_
        ) = abi.decode(
            _arguments,
            (
                address
            )
        );
        
        // storage
        staking = staking_;

        // event
        emit Initialised(_arguments);

    }

    /**
     * @dev Allows to set configure contract.
     *
     * @dev Parameters
     * @param _arguments - all function arguments encoded to bytes
     *
     * @dev Validations :
     * - Only contract owner can perform this function.
     * - This function can be performed only once.
     *
     * @dev Events :
     * - {Configured}
     */
    function configure(
        bytes memory _arguments
    ) external override
    onlyOwner
    onlyInState(State.UNCONFIGURED) {

        // decode arguments
        (
            address dataProvider_,
            address tholWethPool_,
            address weth_,
            address thol_,
            Request memory request_
        ) = abi.decode(
            _arguments,
            (
                address,
                address,
                address,
                address,
                Request
            )
        );

        // storage
        dataProvider = dataProvider_;
        tholWethPool = tholWethPool_;
        weth = weth_;
        thol = thol_;

        // set local max and min cap
        localMaxPercentage = 73786976294838206464;
        localMinPercentage = 4611686018427387904;

        // first fulfill
        _fulfillTholPerNft(request_);

        // state
        state = State.CONFIGURED;

        // event
        emit Configured(_arguments);

    }

    // -----------------------------------------------------------------------
    //                             External
    // -----------------------------------------------------------------------

    /**
     * @dev Allows to set new local max percentage value.
     *
     * @dev Parameters :
     * @param _value - new local max percentage value.
     *
     * @dev Validations :
     * - Only contract owner can perform this function.
     * - New local max percentage must be greater than current local min percentage.
     *
     * @dev Events :
     * - {LocalMaxPercentageUpdated}
     */
    function updateLocalMaxPercentage(int128 _value) external
    onlyOwner {

        // assert
        if (_value <= localMinPercentage) revert MaxCapMustBeGreaterThanMinCap();

        // storage
        localMaxPercentage = _value;

        // event
        emit LocalMaxPercentageUpdated(_value);

    }

    /**
     * @dev Allows to set new local min percentage value.
     *
     * @dev Parameters :
     * @param _value - new local min percentage value.
     *
     * @dev Validations :
     * - Only contract owner can perform this function.
     * - New local min percentage must be lower than current local max percentage.
     *
     * @dev Events :
     * - {LocalMinPercentageUpdated}
     */
    function updateLocalMinPercentage(int128 _value) external
    onlyOwner {

        // assert
        if (_value >= localMaxPercentage) revert MinCapMustBeLowerThanMaxCap();

        // storage
        localMinPercentage = _value;

        // event
        emit LocalMinPercentageUpdated(_value);

    }

    /**
     * @dev Allows to calculate new 'tholPerNft' value which is send and set in the staking contract.
     *
     * @dev Parameters :
     * @param _request - all function arguments packed in the 'Request' struct.
     *
     * @dev Validations :
     * - Only data provider can perform this function.
     */
    function fulfillTholPerNft(Request memory _request) external override
    onlyDataProvider {

        // fulfill
        _fulfillTholPerNft(_request);

    }
    // -----------------------------------------------------------------------
    //                             Public
    // -----------------------------------------------------------------------

    /**
     * @dev Calculate amount of THOL for the given amount of WETH
     *
     * @dev Parameters :
     * @param _currentFloorPrice - amount of WETH which should be calculated to THOL
     *
     * @return tholAmount_ - amount of THOL for the given amount of WETH
     */
    function calculateWethToThol(uint128 _currentFloorPrice) public virtual override view
    returns (uint256 tholAmount_) {

        // consult
        (int24 tick_,) = OracleLibrary.consult(tholWethPool, 1);

        // get and return quote
        tholAmount_ = OracleLibrary.getQuoteAtTick(tick_, _currentFloorPrice, weth, thol);

    }

    // -----------------------------------------------------------------------
    //                             Private
    // -----------------------------------------------------------------------

    function _fulfillTholPerNft(Request memory _request) private {

        // calculate amount of THOL for given WETH amount
        uint96 floorPriceInThol_ = uint96(calculateWethToThol(_request.currentFloorPrice));

        // calculate ratio for the current and previous volume
        int128 volumeRatio_ = ABDKMath64x64.divu(
            _request.currentVolume,
            _request.previousVolume
        );

        // calculate ratio for the current and previous floor price
        int128 floorPriceRatio_ = ABDKMath64x64.divu(
            _request.currentFloorPrice,
            _request.previousFloorPrice
        );

        // calculate total ratio for volume and floor price
        int128 totalRatio_ = volumeRatio_.mul(floorPriceRatio_);

        // calculate THOL per NFT value
        uint96 tholPerNft_ = uint96(totalRatio_.mulu(floorPriceInThol_));

        // verify calculate THOL per NFT value with local cap
        tholPerNft_ = _compareWithLocalCap(tholPerNft_, floorPriceInThol_);

        // update THOL per NFT value in the staking contract
        ITholosStaking(staking).setTholPerNft(tholPerNft_);

        // event
        emit TholPerNftFulfilled(tholPerNft_, block.timestamp);

    }

    /**
     * @dev Allows to compare calculate THOL per NFT value is between max and min cap and set if
     *      necessary if value is out of cap range.
     *
     * @dev Parameters :
     * @param _tholPerNft - calculated THOL per NFT value.
     * @param _floorPriceInThol - current NFT collection floor price in THOL.
     *
     * @return uint96 - THOL per NFT including local cap.
     */
    function _compareWithLocalCap(
        uint96 _tholPerNft,
        uint96 _floorPriceInThol
    ) private view
    returns (uint96) {

        // calculate local max cap (400% of current floor price)
        uint96 max_ = uint96(localMaxPercentage.mulu(_floorPriceInThol));
        // calculate local min cap (25% of current floor price)
        uint96 min_ = uint96(localMinPercentage.mulu(_floorPriceInThol));

        // verify if calculated THOL per NFT is in the local cap range
        if (_tholPerNft <= max_ && _tholPerNft >= min_) {
            // case when THOL per NFT is in range
            return _tholPerNft;
        } else if (_tholPerNft < min_) {
            // case when THOL per NFT is less than min cap
            return min_;
        } else {
            // case when THOL per NFT is greater than local max cap
            return max_;
        }

    }

}