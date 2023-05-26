// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;


import "./Interfaces/IWETH.sol";
import "./Interfaces/IToken.sol";
import "./Interfaces/IWHAsset.sol";
import "./Interfaces/IWhiteUSDCPool.sol";
import "./Interfaces/IWhiteOptionsPricer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

interface IKeep3r {
    function getRequestedPayment() external view returns (uint);
}

/**
 * @author jmonteer
 * @title Whiteheart's Hedge Contract
 * @notice WHAsset implementation. Hedge contract: Wraps an amount of the underlying asset with an ATM put option (or other protection instrument)
 */
abstract contract WHAssetv2 is ERC721, IWHAssetv2, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint;
    using SafeMath for uint48;

    uint256 internal constant PRICE_DECIMALS = 1e8;
    uint256 public optionCollateralizationRatio = 100;
    address[] public underlyingToStableSwapPath;

    Counters.Counter private _tokenIds;
    IWhiteUSDCPool public immutable pool;
    IWhiteOptionsPricer public whiteOptionsPricer;
    IUniswapV2Router02 public immutable swapRouter;
    AggregatorV3Interface public immutable priceProvider;

    address public keep3r;

    address public router;
    uint internal immutable DECIMALS;
    IERC20 public immutable stablecoin;

    mapping(uint => Underlying) public underlying;
    mapping(address => bool) public autoUnwrapDisabled;

    constructor(
            IUniswapV2Router02 _swapRouter,
            IToken _stablecoin,
            IToken _token,
            AggregatorV3Interface _priceProvider,
            IWhiteUSDCPool _pool,
            IWhiteOptionsPricer _whiteOptionsPricer,
            string memory _name,
            string memory _symbol) public ERC721(_name, _symbol)
    {
        uint _DECIMALS = 10 ** (uint(IToken(_token).decimals()).sub(uint(IToken(_stablecoin).decimals()))) * PRICE_DECIMALS;
        DECIMALS = _DECIMALS;

        address[] memory _underlyingToStableSwapPath = new address[](2);
        _underlyingToStableSwapPath[0] = address(_token);
        _underlyingToStableSwapPath[1] = address(_stablecoin);

        underlyingToStableSwapPath = _underlyingToStableSwapPath;

        swapRouter = _swapRouter;
        whiteOptionsPricer = _whiteOptionsPricer;
        priceProvider = _priceProvider;
        stablecoin = _stablecoin;
        pool = _pool;
    }

    modifier onlyKeep3r {
        require(msg.sender == address(this) || msg.sender == keep3r, "!not allowed");
        _;
    }

    modifier onlyTokenOwner(uint tokenId) {
        require(underlying[tokenId].owner == msg.sender, "msg.sender != owner");
        _;
    }

    modifier onlyRouter {
        require(msg.sender == router, "!not allowed");
        _;
    }

    /**
     * @notice Sets swap router to swap underlying into USDC to pay for the protection
     * @param newRouter address of swapRouter contract
     */
    function setRouter(address newRouter) external onlyOwner {
        router = newRouter;
    }

    /**
     * @notice Sets the Keep3r contract address. Keep3r is in charge of auto unwrapping a HedgeContract when it is in owner's best interest
     * @param newKeep3r address of Keep3r contract
     */
    function setKeep3r(address newKeep3r) external onlyOwner {
        keep3r = newKeep3r;
    }

    /**
     * @notice Returns cost of certain protection
     * @param amount amount to be protected
     * @param period duration of quoted protection
     * @return cost of protection
     */
    function wrapCost(uint amount, uint period) view external returns (uint cost){
        uint strike = _currentPrice();
        return whiteOptionsPricer.getOptionPrice(period, amount, strike);
    }

    /**
     * @notice Wraps an amount of principal into a HedgeContract
     * @param amount amount to be protected (principal)
     * @param period duration of protection
     * @param to recipient of WHAsset (onBehalfOf)
     * @param _mintToken boolean telling the function to mint a new ERC721 token representing this Hedge Contract or not
     * @param minPremiumUSDC param to protect against DEX slippage and front-running txs
     * @return newTokenId ID of new HedgeContract and its token if minted
     */
    function wrap(uint128 amount, uint period, address to, bool _mintToken, uint minPremiumUSDC) payable public override virtual returns (uint newTokenId) {
        newTokenId = _wrap(uint(amount), period, to, true, _mintToken, minPremiumUSDC);
    }

    /**
     * @notice Mints a token of an existing hedge contract
     * @param tokenId hedge contract id to mint a token for
     */
    function mintToken(uint tokenId) external {
        require(underlying[tokenId].active && underlying[tokenId].owner == msg.sender, "!not-tokenizable");
        _mint(msg.sender, tokenId);
    }

    /**
     * @notice Unwraps an active or inactive Hedge Contract, receiving back the principal amount
     * @param tokenId hedge contract id to be unwrapped
     */
    function unwrap(uint tokenId) external override onlyTokenOwner(tokenId) {
        _unwrap(tokenId);
    }

    /**
     * @notice Returns a list of autounwrappable hedge contracts. To be called off-chain
     * @return list of autounwrappable hedge contracts
     */
    function listAutoUnwrapable() external view returns (uint[] memory list) {
        uint counter = 0;
        for(uint i = 0; i <= _tokenIds.current() ; i++) {
            if(isAutoUnwrapable(i)) counter++;
        }
        list = new uint[](counter);
        uint index = 0;
        for(uint i = 0; i <= _tokenIds.current() ; i++) {
            if(isAutoUnwrapable(i)){
                list[index] = i;
                index++;
            }
            if(index>=counter) return list;
        }
    }

    /**
     * @notice Unwraps a list of autoUnwrappable hedge contracts in exchange for a fee (if called by Keep3r)
     * @param list list of hedge contracts to be unwrapped
     * @param rewardRecipient address of the recipient of the fees in exchange of autoExercise
     * @return reward that keep3r will receive
     */
    function autoUnwrapAll(uint[] calldata list, address rewardRecipient) external override returns (uint reward) {
        for(uint i = 0; i < list.length; i++){
            if(isAutoUnwrapable(list[i])) {
                _unwrap(list[i]);
            }
        }

        if(address(msg.sender).isContract() && msg.sender == keep3r) reward = pool.payKeep3r(rewardRecipient);
    }

    /**
     * @notice Unwraps a autoUnwrappable hedge contracts in exchange for a fee (if called by Keep3r)
     * @param tokenId HedgeContract to be unwrapped
     * @param rewardRecipient address of the recipient of the fees in exchange of autoExercise
     * @return reward that keep3r will receive
     */
    function autoUnwrap(uint tokenId, address rewardRecipient) public override returns (uint reward) {
        require(isAutoUnwrapable(tokenId), "!not-unwrapable");
        _unwrap(tokenId);

        if(address(msg.sender).isContract() && msg.sender == keep3r) reward = pool.payKeep3r(rewardRecipient);
    }

    /**
     * @notice Disables (or enables) autounwrapping for caller. If set to true, keep3rs wont be able to unwrap this user's WHAssets
     * @param disabled true to disable autounwrapping, false to re-enable autounwrapping
     */
    function setAutoUnwrapDisabled(bool disabled) external {
        autoUnwrapDisabled[msg.sender] = disabled;
    }

    /**
     * @notice Answers the question: is this hedge contract Auto unwrappable?
     * @param tokenId HedgeContract to be unwrapped
     * @return answer to the question: is this hedge contract Auto unwrappable
     */
    function isAutoUnwrapable(uint tokenId) public view returns (bool) {
        Underlying memory _underlying = underlying[tokenId];
        if(autoUnwrapDisabled[_underlying.owner]) return false;
        if(!_underlying.active) return false;

        bool ITM = false;
        uint currentPrice = _currentPrice();

        ITM = currentPrice < _underlying.strike;

        // if option is In The Money and the option is going to expire in the next minutes
        if (ITM && ((_underlying.expiration.sub(30 minutes) <= block.timestamp) && (_underlying.expiration >= block.timestamp))) {
            return true;
        }

        return false;
    }

    /**
     * @notice Internal function that wraps a hedge contract
     * @param amount amount
     * @param period period
     * @param to address that will receive the hedgecontract
     * @param receiveAsset whether or not require asset from sender
     * @param _mintToken whether or not to mint a token representing the hedge contract
     * @return newTokenId new token id
     */
    function _wrap(uint amount, uint period, address to, bool receiveAsset, bool _mintToken, uint minPremiumUSDC) internal returns (uint newTokenId){
        // new tokenId
        _tokenIds.increment();
        newTokenId = _tokenIds.current();

        // get cost of option
        uint strike = _currentPrice();

        uint total = whiteOptionsPricer.getOptionPrice(period, amount, strike);

        // receive asset + cost of hedge
        if(receiveAsset) _receiveAsset(msg.sender, amount, total);
        // buy option
        _createHedge(newTokenId, total, period, amount, strike, to, minPremiumUSDC);

        // mint ERC721 token
        if(_mintToken) _mint(to, newTokenId);

        emit Wrap(to, uint32(newTokenId), uint88(total), uint88(amount), uint48(strike), uint32(block.timestamp+period));
    }

    /**
     * @notice Internal function that creates the option protecting it
     * @param tokenId hedge contract id
     * @param totalFee total fee to be paid for the option
     * @param period seconds of duration of protection
     * @param amount amount to be protected
     * @param strike price at which the asset is protected
     * @param owner address of the owner of the hedge contract
     */
    function _createHedge(uint tokenId, uint totalFee, uint period, uint amount, uint strike, address owner, uint minPremiumUSDC) internal {
        uint collateral = amount.mul(strike).mul(optionCollateralizationRatio).div(100).div(DECIMALS);

        underlying[tokenId] = Underlying(
            bool(true),
            address(owner),
            uint88(amount),
            uint48(block.timestamp + period),
            uint48(strike)
        );

        uint[] memory amounts = swapRouter.swapExactTokensForTokens(
            totalFee,
            minPremiumUSDC,
            underlyingToStableSwapPath,
            address(pool),
            block.timestamp
        );
        uint totalStablecoin = amounts[amounts.length - 1];

        pool.lock(tokenId, collateral, totalStablecoin);
    }

    /**
     * @notice Exercises an option. only callable when unwrapping a hedge contract
     * @param tokenId id of hedge contract
     * @param owner owner of contract
     * @return optionProfit profit of exercised option
     * @return amount principal amount that was protected by it
     */
    function _exercise(uint tokenId, address owner) internal returns (uint optionProfit, uint amount, uint underlyingCurrentPrice) {
        Underlying storage _underlying = underlying[tokenId];
        amount = _underlying.amount;
        underlyingCurrentPrice = _currentPrice();

        if(_underlying.expiration < block.timestamp){
            pool.unlock(tokenId);
            optionProfit = 0;
        } else {
            (optionProfit) = _payProfit(owner, tokenId, _underlying.strike, _underlying.amount, underlyingCurrentPrice);
        }
    }

    /**
     * @notice Pays profit (if any) of underlying option
     * @param owner address of owner
     * @param tokenId tokenId
     * @param strike price at which the asset was protected
     * @param amount principal amount that was protected
     * @return profit profit of exercised option
     */
    function _payProfit(address owner, uint tokenId, uint strike, uint amount, uint underlyingCurrentPrice)
        internal
        returns (uint profit)
    {
        if(strike <= underlyingCurrentPrice){
            profit = 0;
        } else {
            profit = strike.sub(underlyingCurrentPrice).mul(amount).div(DECIMALS);
        }

        address _keep3r = address(msg.sender).isContract() ? keep3r : address(0);
        uint payKeep3r = _keep3r != address(0) ? IKeep3r(_keep3r).getRequestedPayment() : 0;

        require(payKeep3r <= profit, "!keep3r-requested-too-much");

        pool.send(tokenId, payable(owner), profit, payKeep3r);
    }

    /**
     * @notice Unwraps hedge contract
     * @param tokenId tokenId
     * @return owner address of hedge contract address
     * @return optionProfit profit of exercised option
     */
    function _unwrap(uint tokenId) internal returns (address owner, uint optionProfit) {
        Underlying storage _underlying = underlying[tokenId];
        owner = _underlying.owner;

        require(owner != address(0), "!tokenId-does-not-exist");
        require(_underlying.active, "!tokenId-does-not-exist");

        // exercise option
        (uint profit, uint amount, uint underlyingCurrentPrice) = _exercise(tokenId, owner);

        // burn token
        if(_exists(tokenId)) _burn(tokenId);
        _underlying.active = false;

        _sendTotal(payable(owner), amount);
        optionProfit = profit;

        emit Unwrap(owner, uint32(tokenId), uint128(underlyingCurrentPrice), uint128(profit));
    }

    /**
     * @notice changes hedge contract owner using HedgeContract underlying
     * @param from sender
     * @param to recipient
     * @param tokenId tokenId
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        if(from != address(0) && to != address(0)){
            require(underlying[tokenId].owner == from, "!sth-went-wrong");
            underlying[tokenId].owner = to;
        }
    }

    function _receiveAsset(address from, uint amount, uint hedgeCost) internal virtual;

    function _sendTotal(address payable from, uint amount) internal virtual;

    function _currentPrice() internal view returns (uint) {
        (
            ,
            int price,
            ,
            ,

        ) = priceProvider.latestRoundData();

        return uint(price);
    }
}