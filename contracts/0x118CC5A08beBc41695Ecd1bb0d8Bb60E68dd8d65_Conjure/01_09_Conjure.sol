// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IOpenOracleFramework} from "./interfaces/IOpenOracleFramework.sol";
import "./lib/FixedPoint.sol";
import "./interfaces/IEtherCollateral.sol";

/// @author Conjure Finance Team
/// @title Conjure
/// @notice Contract to define and track the price of an arbitrary synth
contract Conjure is IERC20, ReentrancyGuard {

    // using Openzeppelin contracts for SafeMath and Address
    using SafeMath for uint256;
    using Address for address;
    using FixedPoint for FixedPoint.uq112x112;
    using FixedPoint for FixedPoint.uq144x112;

    // presenting the total supply
    uint256 internal _totalSupply;

    // representing the name of the token
    string internal _name;

    // representing the symbol of the token
    string internal _symbol;

    // representing the decimals of the token
    uint8 internal constant DECIMALS = 18;

    // a record of balance of a specific account by address
    mapping(address => uint256) private _balances;

    // a record of allowances for a specific address by address to address mapping
    mapping(address => mapping(address => uint256)) private _allowances;

    // the owner of the contract
    address payable public _owner;

    // the type of the arb asset (single asset, arb asset)
    // 0... single asset     (uses median price)
    // 1... basket asset     (uses weighted average price)
    // 2... index asset      (uses token address and oracle to get supply and price and calculates supply * price / divisor)
    // 3 .. sqrt index asset (uses token address and oracle to get supply and price and calculates sqrt(supply * price) / divisor)
    uint256 public _assetType;

    // the address of the collateral contract factory
    address public _factoryContract;

    // the address of the collateral contract
    address public _collateralContract;

    // struct for oracles
    struct _oracleStruct {
        address oracleaddress;
        address tokenaddress;
        // 0... chainLink, 1... UniSwap T-wap, 2... custom
        uint256 oracleType;
        string signature;
        bytes calldatas;
        uint256 weight;
        uint256 decimals;
        uint256 values;
    }

    // array for oracles
    _oracleStruct[] public _oracleData;

    // number of oracles
    uint256 public _numoracles;

    // the latest observed price
    uint256 internal _latestobservedprice;

    // the latest observed price timestamp
    uint256 internal _latestobservedtime;

    // the divisor for the index
    uint256 public _indexdivisor;

    // the modifier if the asset type is an inverse type
    bool public _inverse;

    // shows the init state of the contract
    bool public _inited;

    // the modifier if the asset type is an inverse type
    uint256 public _deploymentPrice;

    // maximum decimal size for the used prices
    uint256 private constant MAXIMUM_DECIMALS = 18;

    // The number representing 1.0
    uint256 private constant UNIT = 10**18;

    // the eth usd price feed oracle address
    address public ethUsdOracle;

    // lower boundary for inverse assets (10% of deployment price)
    uint256 public inverseLowerCap;

    // ========== EVENTS ==========
    event NewOwner(address newOwner);
    event Issued(address indexed account, uint256 value);
    event Burned(address indexed account, uint256 value);
    event AssetTypeSet(uint256 value);
    event IndexDivisorSet(uint256 value);
    event PriceUpdated(uint256 value);
    event InverseSet(bool value);
    event NumOraclesSet(uint256 value);

    // only owner modifier
    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    // only owner view
    function _onlyOwner() private view {
        require(msg.sender == _owner, "Only the contract owner may perform this action");
    }

    constructor() {
        // Don't allow implementation to be initialized.
        _factoryContract = address(1);
    }

    /**
     * @dev initializes the clone implementation and the Conjure contract
     *
     * @param nameSymbol array holding the name and the symbol of the asset
     * @param conjureAddresses array holding the owner, indexed UniSwap oracle and ethUsdOracle address
     * @param factoryAddress_ the address of the factory
     * @param collateralContract the EtherCollateral contract of the asset
    */
    function initialize(
        string[2] memory nameSymbol,
        address[] memory conjureAddresses,
        address factoryAddress_,
        address collateralContract
    ) external
    {
        require(_factoryContract == address(0), "already initialized");
        require(factoryAddress_ != address(0), "factory can not be null");
        require(collateralContract != address(0), "collateralContract can not be null");

        _owner = payable(conjureAddresses[0]);
        _name = nameSymbol[0];
        _symbol = nameSymbol[1];

        ethUsdOracle = conjureAddresses[1];
        _factoryContract = factoryAddress_;

        // mint new EtherCollateral contract
        _collateralContract = collateralContract;

        emit NewOwner(_owner);
    }

    /**
     * @dev inits the conjure asset can only be called by the factory address
     *
     * @param inverse_ indicated it the asset is an inverse asset or not
     * @param divisorAssetType array containing the divisor and the asset type
     * @param oracleAddresses_ the array holding the oracle addresses 1. address to call,
     *        2. address of the token for supply if needed
     * @param oracleTypesValuesWeightsDecimals array holding the oracle types,values,weights and decimals
     * @param signatures_ array holding the oracle signatures
     * @param callData_ array holding the oracle callData
    */
    function init(
        bool inverse_,
        uint256[2] memory divisorAssetType,
        address[][2] memory oracleAddresses_,
        uint256[][4] memory oracleTypesValuesWeightsDecimals,
        string[] memory signatures_,
        bytes[] memory callData_
    ) external {
        require(msg.sender == _factoryContract, "can only be called by factory contract");
        require(!_inited, "Contract already inited");
        require(divisorAssetType[0] != 0, "Divisor should not be 0");

        _assetType = divisorAssetType[1];
        _numoracles = oracleAddresses_[0].length;
        _indexdivisor = divisorAssetType[0];
        _inverse = inverse_;
        
        emit AssetTypeSet(_assetType);
        emit IndexDivisorSet(_indexdivisor);
        emit InverseSet(_inverse);
        emit NumOraclesSet(_numoracles);

        uint256 weightCheck;

        // push the values into the oracle struct for further processing
        for (uint i = 0; i < oracleAddresses_[0].length; i++) {
            require(oracleTypesValuesWeightsDecimals[3][i] <= 18, "Decimals too high");
            _oracleData.push(_oracleStruct({
                oracleaddress: oracleAddresses_[0][i],
                tokenaddress: oracleAddresses_[1][i],
                oracleType: oracleTypesValuesWeightsDecimals[0][i],
                signature: signatures_[i],
                calldatas: callData_[i],
                weight: oracleTypesValuesWeightsDecimals[2][i],
                values: oracleTypesValuesWeightsDecimals[1][i],
                decimals: oracleTypesValuesWeightsDecimals[3][i]
            }));

            weightCheck += oracleTypesValuesWeightsDecimals[2][i];
        }

        // for basket assets weights must add up to 100
        if (_assetType == 1) {
            require(weightCheck == 100, "Weights not 100");
        }

        updatePrice();
        _deploymentPrice = getLatestPrice();

        // for inverse assets set boundaries
        if (_inverse) {
            inverseLowerCap = _deploymentPrice.div(10);
        }

        _inited = true;
    }

    /**
     * @dev lets the EtherCollateral contract instance burn synths
     *
     * @param account the account address where the synths should be burned to
     * @param amount the amount to be burned
    */
    function burn(address account, uint amount) external {
        require(msg.sender == _collateralContract, "Only Collateral Contract");
        _internalBurn(account, amount);
    }

    /**
     * @dev lets the EtherCollateral contract instance mint new synths
     *
     * @param account the account address where the synths should be minted to
     * @param amount the amount to be minted
    */
    function mint(address account, uint amount) external {
        require(msg.sender == _collateralContract, "Only Collateral Contract");
        _internalIssue(account, amount);
    }

    /**
     * @dev Internal function to mint new synths
     *
     * @param account the account address where the synths should be minted to
     * @param amount the amount to be minted
    */
    function _internalIssue(address account, uint amount) internal {
        _balances[account] = _balances[account].add(amount);
        _totalSupply = _totalSupply.add(amount);

        emit Transfer(address(0), account, amount);
        emit Issued(account, amount);
    }

    /**
     * @dev Internal function to burn synths
     *
     * @param account the account address where the synths should be burned to
     * @param amount the amount to be burned
    */
    function _internalBurn(address account, uint amount) internal {
        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);
        emit Burned(account, amount);
    }

    /**
     * @dev lets the owner change the contract owner
     *
     * @param _newOwner the new owner address of the contract
    */
    function changeOwner(address payable _newOwner) external onlyOwner {
        require(_newOwner != address(0), "_newOwner can not be null");
    
        _owner = _newOwner;
        emit NewOwner(_newOwner);
    }

    /**
     * @dev lets the owner collect the fees accrued
    */
    function collectFees() external onlyOwner {
        _owner.transfer(address(this).balance);
    }

    /**
     * @dev gets the latest price of an oracle asset
     * uses chainLink oracles to get the price
     *
     * @return the current asset price
    */
    function getLatestPrice(AggregatorV3Interface priceFeed) internal view returns (uint) {
        (
        ,
        int price,
        ,
        ,
        ) = priceFeed.latestRoundData();

        return uint(price);
    }

    /**
     * @dev gets the latest ETH USD Price from the given oracle OOF contract
     * getFeed 0 signals the ETH/USD feed
     *
     * @return the current eth usd price
    */
    function getLatestETHUSDPrice() public view returns (uint) {
        (
        uint price,
        ,
        ) = IOpenOracleFramework(ethUsdOracle).getFeed(0);

        return price;
    }

    /**
    * @dev implementation of a quicksort algorithm
    *
    * @param arr the array to be sorted
    * @param left the left outer bound element to start the sort
    * @param right the right outer bound element to stop the sort
    */
    function quickSort(uint[] memory arr, int left, int right) internal pure {
        int i = left;
        int j = right;
        if (i == j) return;
        uint pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(arr, left, j);
        if (i < right)
            quickSort(arr, i, right);
    }

    /**
    * @dev implementation to get the average value of an array
    *
    * @param arr the array to be averaged
    * @return the (weighted) average price of an asset
    */
    function getAverage(uint[] memory arr) internal view returns (uint) {
        uint sum = 0;

        // do the sum of all array values
        for (uint i = 0; i < arr.length; i++) {
            sum += arr[i];
        }
        // if we dont have any weights (single asset with even array members)
        if (_assetType == 0) {
            return (sum / arr.length);
        }
        // index pricing we do division by divisor
        if ((_assetType == 2) || (_assetType == 3)) {
            return sum / _indexdivisor;
        }
        // divide by 100 cause the weights sum up to 100 and divide by the divisor if set (defaults to 1)
        return ((sum / 100) / _indexdivisor);
    }

    /**
    * @dev sort implementation which calls the quickSort function
    *
    * @param data the array to be sorted
    * @return the sorted array
    */
    function sort(uint[] memory data) internal pure returns (uint[] memory) {
        quickSort(data, int(0), int(data.length - 1));
        return data;
    }

    /**
    * @dev implementation of a square rooting algorithm
    * babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    *
    * @param y the value to be square rooted
    * @return z the square rooted value
    */
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = (y + 1) / 2;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        else {
            z = 0;
        }
    }

    /**
     * @dev gets the latest recorded price of the synth in USD
     *
     * @return the last recorded synths price
    */
    function getLatestPrice() public view returns (uint) {
        return _latestobservedprice;
    }

    /**
     * @dev gets the latest recorded price time
     *
     * @return the last recorded time of a synths price
    */
    function getLatestPriceTime() external view returns (uint) {
        return _latestobservedtime;
    }

    /**
     * @dev gets the latest price of the synth in USD by calculation and write the checkpoints for view functions
    */
    function updatePrice() public {
        uint256 returnPrice = updateInternalPrice();
        bool priceLimited;

        // if it is an inverse asset we do price = _deploymentPrice - (current price - _deploymentPrice)
        // --> 2 * deployment price - current price
        // but only if the asset is inited otherwise we return the normal price calculation
        if (_inverse && _inited) {
            if (_deploymentPrice.mul(2) <= returnPrice) {
                returnPrice = 0;
            } else {
                returnPrice = _deploymentPrice.mul(2).sub(returnPrice);

                // limit to lower cap
                if (returnPrice <= inverseLowerCap) {
                    priceLimited = true;
                }
            }
        }

        _latestobservedprice = returnPrice;
        _latestobservedtime = block.timestamp;

        emit PriceUpdated(_latestobservedprice);

        // if price reaches 0 we close the collateral contract and no more loans can be opened
        if ((returnPrice <= 0) || (priceLimited)) {
            IEtherCollateral(_collateralContract).setAssetClosed(true);
        } else {
            // if the asset was set closed we open it again for loans
            if (IEtherCollateral(_collateralContract).getAssetClosed()) {
                IEtherCollateral(_collateralContract).setAssetClosed(false);
            }
        }
    }

    /**
     * @dev gets the latest price of the synth in USD by calculation --> internal calculation
     *
     * @return the current synths price
    */
    function updateInternalPrice() internal returns (uint) {
        require(_oracleData.length > 0, "No oracle feeds supplied");
        // storing all in an array for further processing
        uint[] memory prices = new uint[](_oracleData.length);

        for (uint i = 0; i < _oracleData.length; i++) {

            // chainLink oracle
            if (_oracleData[i].oracleType == 0) {
                AggregatorV3Interface priceFeed = AggregatorV3Interface(_oracleData[i].oracleaddress);
                prices[i] = getLatestPrice(priceFeed);

                // norming price
                if (MAXIMUM_DECIMALS != _oracleData[i].decimals) {
                    prices[i] = prices[i] * 10 ** (MAXIMUM_DECIMALS - _oracleData[i].decimals);
                }
            }

            // custom oracle and UniSwap
            else {
                string memory signature = _oracleData[i].signature;
                bytes memory callDatas = _oracleData[i].calldatas;

                bytes memory callData;

                if (bytes(signature).length == 0) {
                    callData = callDatas;
                } else {
                    callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), callDatas);
                }

                (bool success, bytes memory data) = _oracleData[i].oracleaddress.call{value:_oracleData[i].values}(callData);
                require(success, "Call unsuccessful");

                // UniSwap V2 use NDX Custom Oracle call
                if (_oracleData[i].oracleType == 1) {
                    FixedPoint.uq112x112 memory price = abi.decode(data, (FixedPoint.uq112x112));

                    // since this oracle is using token / eth prices we have to norm it to usd prices
                    prices[i] = price.mul(getLatestETHUSDPrice()).decode144();
                }
                else {
                    prices[i] = abi.decode(data, (uint));

                    // norming price
                    if (MAXIMUM_DECIMALS != _oracleData[i].decimals) {
                        prices[i] = prices[i] * 10 ** (MAXIMUM_DECIMALS - _oracleData[i].decimals);
                    }
                }
            }

            // for market cap and sqrt market cap asset types
            if (_assetType == 2 || _assetType == 3) {
                // get total supply for indexes
                uint tokenTotalSupply = IERC20(_oracleData[i].tokenaddress).totalSupply();
                uint tokenDecimals = IERC20(_oracleData[i].tokenaddress).decimals();

                // norm total supply
                if (MAXIMUM_DECIMALS != tokenDecimals) {
                    require(tokenDecimals <= 18, "Decimals too high");
                    tokenTotalSupply = tokenTotalSupply * 10 ** (MAXIMUM_DECIMALS - tokenDecimals);
                }

                // index use market cap
                if (_assetType == 2) {
                    prices[i] = (prices[i].mul(tokenTotalSupply) / UNIT);
                }

                // sqrt market cap
                if (_assetType == 3) {
                    // market cap
                    prices[i] =prices[i].mul(tokenTotalSupply) / UNIT;
                    // sqrt market cap
                    prices[i] = sqrt(prices[i]);
                }
            }

            // if we have a basket asset we use weights provided
            if (_assetType == 1) {
                prices[i] = prices[i] * _oracleData[i].weight;
            }
        }

        uint[] memory sorted = sort(prices);

        /// for single assets return median
        if (_assetType == 0) {

            // uneven so we can take the middle
            if (sorted.length % 2 == 1) {
                uint sizer = (sorted.length + 1) / 2;

                return sorted[sizer-1];
            // take average of the 2 most inner numbers
            } else {
                uint size1 = (sorted.length) / 2;
                uint[] memory sortedMin = new uint[](2);

                sortedMin[0] = sorted[size1-1];
                sortedMin[1] = sorted[size1];

                return getAverage(sortedMin);
            }
        }

        // else return average for arb assets
        return getAverage(sorted);
    }

    /**
     * ERC 20 Specific Functions
    */

    /**
    * receive function to receive funds
    */
    receive() external payable {}

    /**
     * @dev Returns the name of the token.
     */
    function name() external override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external override pure returns (uint8) {
        return DECIMALS;
    }

    /**
    * @dev See {IERC20-totalSupply}.
    */
    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev See {IERC20-balanceOf}. Uses burn abstraction for balance updates without gas and universally.
    */
    function balanceOf(address account) external override view returns (uint256) {
        return _balances[account];
    }

    /**
    * @dev See {IERC20-transfer}.
    *
    * Requirements:
    *
    * - `recipient` cannot be the zero address.
    * - the caller must have a balance of at least `amount`.
    */
    function transfer(address dst, uint256 rawAmount) external override returns (bool) {
        uint256 amount = rawAmount;
        _transfer(msg.sender, dst, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
    external
    override
    view
    returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
    external
    override
    returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address src, address dst, uint256 rawAmount) external override returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = _allowances[src][spender];
        uint256 amount = rawAmount;

        if (spender != src && spenderAllowance != uint256(-1)) {
            uint256 newAllowance = spenderAllowance.sub(
                amount,
                    "CONJURE::transferFrom: transfer amount exceeds spender allowance"
            );

            _allowances[src][spender] = newAllowance;
        }

        _transfer(src, dst, amount);
        return true;
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    )
        internal
    {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    )
        internal
    {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
}