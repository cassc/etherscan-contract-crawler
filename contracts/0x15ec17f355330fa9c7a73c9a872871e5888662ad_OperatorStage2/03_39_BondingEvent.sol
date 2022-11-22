// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import "contracts/uniswap/INonfungiblePositionManager.sol";
import "contracts/Stage2/BondStorage.sol";
import "contracts/interfaces/API.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BondingEvent is AccessControl {
    int24 private constant MAX_TICK = 887270;
    int24 private constant MIN_TICK = -MAX_TICK;
    uint128 private constant MAX_UINT_128 = 2 ** 128 - 1;

    // sEUR: the main leg of the currency pair
    address public immutable SEURO_ADDRESS;
    // other: the other ERC-20 token
    address public immutable OTHER_ADDRESS;
    uint24 public immutable FEE;
    // bond storage contract
    address public bondStorageAddress;
    // controls the bonding event and manages the rates and maturities
    address public operatorAddress;
    // receives any excess USDT from the bonding event
    address public excessCollateralWallet;
    // calculates ratio required to add liquidity to a pool
    IRatioCalculator public ratioCalculator;
    IUniswapV3Pool public pool;
    INonfungiblePositionManager public manager;

    Position[] private positions;

    // https://docs.uniswap.org/protocol/reference/core/libraries/Tick
    int24 public lowerTickDefault;
    int24 public upperTickDefault;
    int24 public tickSpacing;

    // Emitted when a user adds liquidity.
    event LiquidityAdded(address user, uint256 tokenId, uint256 seuroAmount, uint256 otherAmount, uint128 liquidity);

    event LiquidityCollected(uint256 tokenId, uint256 retractedAmount0, uint256 retractedAmount1, uint256 feesCollected0, uint256 feesCollected1, uint256 collectedTotal0, uint256 collectedTotal1);

    struct Position { uint256 tokenId; int24 lowerTick; int24 upperTick; uint128 liquidity; }

    struct Pair { address token0; address token1; }

    struct AddLiquidityParams { address token0; address token1; int24 lowerTick; int24 upperTick; uint256 amount0Desired; uint256 amount1Desired; uint256 amount0Min; uint256 amount1Min; }

    struct AddedLiquidityResponse { uint256 tokenId; uint128 liquidity; uint256 seuroAmount; uint256 otherAmount; }

    // only contract owner can add the other currency leg
    bytes32 public constant WHITELIST_BONDING_EVENT = keccak256("WHITELIST_BONDING_EVENT");

    /// @param _seuroAddress address of sEURO token
    /// @param _otherAddress address of token to bond with sEURO
    /// @param _manager address of Uniswap NonfungiblePositionManager contract
    /// @param _bondStorageAddress address of Bond Storage contract
    /// @param _operatorAddress address of operator contract
    /// @param _ratioCalculatorAddress address of ratio calculator contract
    /// @param _initialPrice initial price of liquidity pool for sEURO / other, as a sqrtPriceX96 (https://docs.uniswap.org/sdk/guides/fetching-prices#understanding-sqrtprice)
    /// @param _lowerTickDefault default lower tick value for liquidity positions
    /// @param _upperTickDefault default upper tick value for liquidity positions (https://docs.uniswap.org/protocol/concepts/V3-overview/concentrated-liquidity#ticks)
    /// @param _fee the fee amount for the pool you are initialising (https://docs.uniswap.org/protocol/concepts/V3-overview/fees#swap-fees)
    constructor(address _seuroAddress, address _otherAddress, address _manager, address _bondStorageAddress, address _operatorAddress, address _ratioCalculatorAddress, uint160 _initialPrice, int24 _lowerTickDefault, int24 _upperTickDefault, uint24 _fee) {
        _setupRole(WHITELIST_BONDING_EVENT, msg.sender);
        SEURO_ADDRESS = _seuroAddress;
        OTHER_ADDRESS = _otherAddress;
        bondStorageAddress = _bondStorageAddress;
        operatorAddress = _operatorAddress;
        lowerTickDefault = _lowerTickDefault;
        upperTickDefault = _upperTickDefault;
        FEE = _fee;
        manager = INonfungiblePositionManager(_manager);
        ratioCalculator = IRatioCalculator(_ratioCalculatorAddress);
        initialisePool(_initialPrice, _fee);
    }

    modifier onlyPoolOwner() { require(hasRole(WHITELIST_BONDING_EVENT, msg.sender), "invalid-pool-owner"); _; }

    modifier onlyOperator() { require(msg.sender == operatorAddress, "err-not-operator"); _; }

    modifier validAddress(address _newAddress) { require(_newAddress != address(0), "err-invalid-addr"); _; }

    modifier validTicks(int24 _newLower, int24 _newHigher) {
        require(_newLower % tickSpacing == 0 && _newHigher % tickSpacing == 0, "tick-mod-spacing-nonzero");
        require(_newHigher <= MAX_TICK, "tick-max-exceeded");
        require(_newLower >= MIN_TICK, "tick-min-exceeded"); _;
    }

    // Sets address of Bond Storage contract, which manages customer bonds
    function setStorageContract(address _newAddress) external onlyPoolOwner validAddress(_newAddress) { bondStorageAddress = _newAddress; }

    // Sets address of operator contract, the key dependent of this contract
    function setOperator(address _newAddress) external onlyPoolOwner validAddress(_newAddress) { operatorAddress = _newAddress; }

    // Sets address of wallet, which will receive excess bonding collateral
    function setExcessCollateralWallet(address _newAddress) external onlyPoolOwner validAddress(_newAddress) { excessCollateralWallet = _newAddress; }

    function setRatioCalculator(address _newAddress) external onlyPoolOwner validAddress(_newAddress) { ratioCalculator = IRatioCalculator(_newAddress); }

    // Sets default lower and upper tick for liquidity positions, if valid
    function adjustTickDefaults(int24 _newLower, int24 _newHigher) external onlyPoolOwner validTicks(_newLower, _newHigher) {
        lowerTickDefault = _newLower;
        upperTickDefault = _newHigher;
    }

    // Compares the Standard Euro token to another token and returns them in ascending order
    function getAscendingPair() public view returns (Pair memory pair) { return SEURO_ADDRESS < OTHER_ADDRESS ? Pair(SEURO_ADDRESS, OTHER_ADDRESS) : Pair(OTHER_ADDRESS, SEURO_ADDRESS); }

    function initialisePool(uint160 _price, uint24 _fee) private {
        Pair memory pair = getAscendingPair();
        address poolAddress = manager.createAndInitializePoolIfNecessary(pair.token0, pair.token1, _fee, _price);
        pool = IUniswapV3Pool(poolAddress);
        tickSpacing = pool.tickSpacing();
    }

    // Gets all the Uniswap liquidity pool token IDs that this pool manages
    function getPositions() external view returns (Position[] memory) { return positions; }

    // Gets data for the given position token ID
    /// @param _tokenId the ID of the position token
    function getPositionByTokenId(uint256 _tokenId) public view returns (Position memory position, uint256 index) {
        for (index = 0; index < positions.length; index++) if (positions[index].tokenId == _tokenId) return (positions[index], index);
    }

    function getPositionIdByTicks(int24 _lowerTick, int24 _upperTick) private view returns (uint256 positionId) {
        for (uint256 i = 0; i < positions.length; i++) if (positions[i].lowerTick == _lowerTick && positions[i].upperTick == _upperTick) return positions[i].tokenId;
    }

    function mintLiquidityPosition(AddLiquidityParams memory params) private returns (AddedLiquidityResponse memory) {
        // provide liquidity to the pool
        (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) = manager.mint(INonfungiblePositionManager.MintParams(
            params.token0, params.token1, FEE, params.lowerTick, params.upperTick, params.amount0Desired, params.amount1Desired, params.amount0Min, params.amount1Min, address(this), block.timestamp));

        positions.push(Position(tokenId, params.lowerTick, params.upperTick, liquidity));

        return params.token0 == SEURO_ADDRESS ? AddedLiquidityResponse(tokenId, liquidity, amount0, amount1) : AddedLiquidityResponse(tokenId, liquidity, amount1, amount0);
    }

    function increasePositionLiquidity(uint256 _tokenId, uint128 _liquidity) private {
        (Position memory position, uint256 index) = getPositionByTokenId(_tokenId);
        if (position.tokenId == _tokenId) positions[index].liquidity = position.liquidity + _liquidity;
    }

    function increaseExistingLiquidity(AddLiquidityParams memory params, uint256 tokenId) private returns (AddedLiquidityResponse memory) {
        (uint128 liquidity, uint256 amount0, uint256 amount1) = manager.increaseLiquidity(INonfungiblePositionManager.IncreaseLiquidityParams(
                    tokenId, params.amount0Desired, params.amount1Desired, params.amount0Min, params.amount1Min, block.timestamp));

        increasePositionLiquidity(tokenId, liquidity);

        return params.token0 == SEURO_ADDRESS ? AddedLiquidityResponse(tokenId, liquidity, amount0, amount1) : AddedLiquidityResponse(tokenId, liquidity, amount1, amount0);
    }

    function transferExcessToWallet(uint256 _addedAmount, uint256 _desiredAmount, address _token) private {
        uint256 excess = _desiredAmount - _addedAmount;
        if (excess > 0 && excessCollateralWallet != address(0)) TransferHelper.safeTransfer(_token, excessCollateralWallet, excess);
    }

    function approveAndTransfer(Pair memory _pair, address _user, uint256 _amount0Desired, uint256 _amount1Desired) private {
        // approve the position manager
        TransferHelper.safeApprove(_pair.token0, address(manager), _amount0Desired);
        TransferHelper.safeApprove(_pair.token1, address(manager), _amount1Desired);

        // send the tokens from the user to the contract
        TransferHelper.safeTransferFrom(_pair.token0, _user, address(this), _amount0Desired);
        TransferHelper.safeTransferFrom(_pair.token1, _user, address(this), _amount1Desired);
    }

    function ninetyNineNineNinePc(uint256 _amount) private pure returns (uint256) { return _amount * 9999 / 10000; }

    function addLiquidity(address _user, uint256 _amountSEuro) private returns (AddedLiquidityResponse memory added) {
        Pair memory pair = getAscendingPair();
        (uint256 otherAmount, int24 lowerTick, int24 upperTick) = getOtherAmount(_amountSEuro);

        // Gives a 0.01 slippage tolerance to sEURO
        // Due to the possible difference in accuracy between sEURO (18dec) and another token (possible 6dec)
        (uint256 amount0Desired, uint256 amount1Desired, uint256 amount0Min, uint256 amount1Min) = 
            pair.token0 == SEURO_ADDRESS ? (_amountSEuro, otherAmount, ninetyNineNineNinePc(_amountSEuro), uint256(0)) : (otherAmount, _amountSEuro, uint256(0), ninetyNineNineNinePc(_amountSEuro));

        approveAndTransfer(pair, _user, amount0Desired, amount1Desired);

        AddLiquidityParams memory params = AddLiquidityParams(pair.token0, pair.token1, lowerTick, upperTick, amount0Desired, amount1Desired, amount0Min, amount1Min);

        uint256 positionId = getPositionIdByTicks(lowerTick, upperTick);
        added = positionId > 0 ? increaseExistingLiquidity(params, positionId) : mintLiquidityPosition(params);

        emit LiquidityAdded(_user, added.tokenId, added.seuroAmount, added.otherAmount, added.liquidity);
        transferExcessToWallet(added.seuroAmount, _amountSEuro, SEURO_ADDRESS);
        transferExcessToWallet(added.otherAmount, otherAmount, OTHER_ADDRESS);
    }

    // We assume that there is a higher layer solution which helps to fetch the latest price as a quote.
    // This quote is being used to supply the two amounts to the function.
    // The reason for this is because of the explicit discouragement of doing this on-chain
    // due to the high gas costs (see https://docs.uniswap.org/protocol/reference/periphery/lens/Quoter).
    /// @param _user The address of the bonding user (assuming higher layer contract which calls this function)
    /// @param _amountSeuro The amount of sEURO token to bond
    /// @param _maturity The amount of seconds a bond is active.
    ///                          At the end of maturity, the principal + accrued interest is paid out all at once in TST.
    /// @param _rate The rate is represented as a 10,000-factor of each basis point so the most stable fee is 500 (= 0.05 pc)
    function _bond(address _user, uint256 _amountSeuro, uint256 _maturity, uint256 _rate) private onlyOperator {
        // information about the liquidity position after it has been successfully added
        AddedLiquidityResponse memory added = addLiquidity(_user, _amountSeuro);

        // begin bonding event
        IBondStorage(bondStorageAddress).startBond(_user, _amountSeuro, added.otherAmount, _rate, _maturity, added.tokenId, added.liquidity);
    }

    // For interface purposes due to modifiers above
    function bond(address _user, uint256 _amountSeuro, uint256 _maturity, uint256 _rate) external { _bond(_user, _amountSeuro, _maturity, _rate); }

    function priceInMiddleTwentyPC(int24 _currentPriceTick, int24 _lowerTick, int24 _upperTick) private pure returns (bool) {
        // checks that the current pool price sits between 40th + 60th percentile of given tick range
        // this should ensure a decent enough liquidity ratio for bonding
        int24 lowerToPriceDiff = _currentPriceTick - _lowerTick;
        int24 priceToUpperDiff = _upperTick - _currentPriceTick;
        return lowerToPriceDiff * 3 / 2 >= priceToUpperDiff && priceToUpperDiff * 3 / 2 >= lowerToPriceDiff;
    }

    function ticksAtLimits(int24 _lowerTick, int24 _upperTick) private pure returns (bool) { return _lowerTick == MIN_TICK && _upperTick == MAX_TICK; }

    function viableTickPriceRatio(int24 _currentPriceTick, int24 _lowerTick, int24 _upperTick) private pure returns (bool) {
        return priceInMiddleTwentyPC(_currentPriceTick, _lowerTick, _upperTick) || ticksAtLimits(_lowerTick, _upperTick);
    }

    function increaseTicks(int24 _lower, int24 _upper, int24 magnitude) private pure returns (int24 lower, int24 upper) {
        lower = _lower - magnitude;
        upper = _upper + magnitude;
        if (lower < MIN_TICK) lower = MIN_TICK;
        if (upper > MAX_TICK) upper = MAX_TICK;
    }

    function increaseMagnitude(int24 _magnitude) private pure returns (int24 magnitude, uint8 i) { magnitude = _magnitude * 10; i=0; }

    function getViableTickRange(uint160 _price) private view returns (int24 lowerTick, int24 upperTick) {
        lowerTick = lowerTickDefault;
        upperTick = upperTickDefault;
        int24 currentPriceTick = ratioCalculator.getTickAt(_price);
        int24 magnitude = 100; uint8 i;
        // expand tick range by magnitude 100 ticks ten times, then by magnitude 1000 ticks ten times etc. until a viable ratio is found
        while (!viableTickPriceRatio(currentPriceTick, lowerTick, upperTick)) {
            if (i == 10) (magnitude, i) = increaseMagnitude(magnitude); i++;
            (lowerTick, upperTick) = increaseTicks(lowerTick, upperTick, magnitude);
        }
    }

    // Calculates how much of other token is required to bond with given amount of sEURO
    // Calculates the required ratio of other token to add to the liquidity pool
    // Calculated given the current price, lower and upper ticks, and amount of sEURO
    // The lower and upper ticks used for the range are the default ones from the contract, if viable
    // A tick range is considered viable for the bonding if the current price is within 40th and 60th percentile of tick range
    // If these ticks would not give us a viable ratio for bonding, we expand the tick range
    // Expanded by a magnitude of 100 ticks (ten times), then 1,000 ticks (ten times), then 10,000 etc, until viable
    /// @param _amountSEuro The amount of sEURO token to bond
    /// @return amountOther The required amount of other token to bond with given sEURO amount
    /// @return lowerTick The lower tick of the viable price range
    /// @return upperTick The upper tick of the viable price range
    function getOtherAmount(uint256 _amountSEuro) public view returns (uint256 amountOther, int24 lowerTick, int24 upperTick) {
        (uint160 price,,,,,,) = pool.slot0();
        bool seuroIsToken0 = getAscendingPair().token0 == SEURO_ADDRESS;
        (lowerTick, upperTick) = getViableTickRange(price);
        amountOther = ratioCalculator.getRatioForSEuro(_amountSEuro, price, lowerTick, upperTick, seuroIsToken0);
    }

    function retractLiquidity(uint256 _tokenId, uint128 _liquidity) private returns (uint256 retractedLiquidity0, uint256 retractedLiquidity1) {
        (retractedLiquidity0, retractedLiquidity1) = manager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_tokenId, _liquidity, 0, 0, block.timestamp));
    }

    function collectAll(uint256 _tokenId) private returns (uint256 collectedFees0, uint256 collectedFees1) {
        (collectedFees0, collectedFees1) = manager.collect(INonfungiblePositionManager.CollectParams(_tokenId, excessCollateralWallet, MAX_UINT_128, MAX_UINT_128));
    }

    function burnToken(uint256 _tokenId) private { manager.burn(_tokenId); }

    function deletePositionFromArray(uint256 index) private {
        for (uint256 i = index; i < positions.length - 1; i++) positions[i] = positions[i+1]; positions.pop();
    }

    function deletePosition(uint256 _tokenId) private {
        for (uint256 i = 0; i < positions.length; i++) if (positions[i].tokenId == _tokenId) deletePositionFromArray(i);
    }

    function getLiquidityOfPosition(uint256 _tokenId) private view returns(uint128 liquidity) { (,,,,,,,liquidity,,,,) = manager.positions(_tokenId); }

    function clearPositionAndBurn(uint256 _tokenId) external onlyPoolOwner {
        require(excessCollateralWallet != address(0), "err-no-wallet-assigned");
        (uint256 retractedAmount0, uint256 retractedAmount1) = retractLiquidity(_tokenId, getLiquidityOfPosition(_tokenId));
        (uint256 collectedAmount0, uint256 collectedAmount1) = collectAll(_tokenId);
        burnToken(_tokenId); 
        deletePosition(_tokenId);
        emit LiquidityCollected(_tokenId, retractedAmount0, retractedAmount1, collectedAmount0 - retractedAmount0, collectedAmount1 - retractedAmount1, collectedAmount0, collectedAmount1);
    }
}