// SPDX-License-Identifier: UNLICENSED
// DELTA-BUG-BOUNTY
pragma abicoder v2;
import "../libs/SafeMath.sol";
import "../../interfaces/IUniswapV2Pair.sol";
import "../../interfaces/IDeltaToken.sol";
import "../../interfaces/IDeepFarmingVault.sol";

interface ICORE_VAULT {
    function addPendingRewards(uint256) external;
}

contract DELTA_Distributor {
    using SafeMath for uint256;

    // Immutableas and constants

    // defacto burn address, this one isnt used commonly so its easy to see burned amounts on just etherscan
    address constant internal DEAD_BEEF = 0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF;
    address constant public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant public CORE = 0x62359Ed7505Efc61FF1D56fEF82158CcaffA23D7;
    address constant public CORE_WETH_PAIR = 0x32Ce7e48debdccbFE0CD037Cc89526E4382cb81b;
    address constant public DELTA_MULTISIG = 0xB2d834dd31816993EF53507Eb1325430e67beefa;
    address constant public CORE_VAULT = 0xC5cacb708425961594B63eC171f4df27a9c0d8c9;
    // We sell 20% and distribute it thus
    uint256 constant public PERCENT_BURNED = 16;
    uint256 constant public PERCENT_DEV_FUND= 8;
    uint256 constant public PERCENT_DEEP_FARMING_VAULT = 56;
    uint256 constant public PERCENT_SOLD = 20;

    uint256 constant public PERCENT_OF_SOLD_DEV = 50;
    uint256 constant public PERCENT_OF_SOLD_CORE_BUY = 25;
    uint256 constant public PERCENT_OF_SOLD_DELTA_WETH_DEEP_FARMING_VAULT = 25;
    address constant public DELTA_WETH_PAIR_SUSHISWAP = 0x1498bd576454159Bb81B5Ce532692a8752D163e8;
    IDeltaToken constant public DELTA_TOKEN = IDeltaToken(0x9EA3b5b4EC044b70375236A281986106457b20EF);

    // storage variables
    address public deepFarmingVault; 
    uint256 public pendingBurn;
    uint256 public pendingDev;
    uint256 public pendingTotal;

    mapping(address => uint256) public pendingCredits;
    mapping(address => bool) public isApprovedLiquidator;

    receive() external payable {
        revert("ETH not allowed");
    }



    function distributeAndBurn() public {
        // Burn
        DELTA_TOKEN.transfer(DEAD_BEEF, pendingBurn);
        pendingTotal = pendingTotal.sub(pendingBurn);
        delete pendingBurn;
        // Transfer dev
        address deltaMultisig = DELTA_TOKEN.governance();
        DELTA_TOKEN.transfer(deltaMultisig, pendingDev);
        pendingTotal = pendingTotal.sub(pendingDev);
        delete pendingDev;
    }

    /// @notice a function that distributes pending to all the vaults etdc
    // This is able to be called by anyone.
    // And is simply just here to save gas on the distribution math
    function distribute() public {
        uint256 amountDeltaNow = DELTA_TOKEN.balanceOf(address(this));

        uint256 _pendingTotal = pendingTotal;

        uint256 amountAdded = amountDeltaNow.sub(_pendingTotal); // pendingSell stores in this variable and is not counted

        if(amountAdded < 1e18) { // We only add 1 DELTA + of rewards to save gas from the DFV calls.
            return;
        }

        uint256 toBurn = amountAdded.mul(PERCENT_BURNED).div(100);
        uint256 toDev = amountAdded.mul(PERCENT_DEV_FUND).div(100);
        uint256 toVault = amountAdded.mul(PERCENT_DEEP_FARMING_VAULT).div(100); // Not added to pending case we transfer it now

        pendingBurn = pendingBurn.add(toBurn);
        pendingDev = pendingDev.add(toDev);
        pendingTotal = _pendingTotal.add(amountAdded).sub(toVault);

        // We send to the vault and credit it
        IDeepFarmingVault(deepFarmingVault).addNewRewards(toVault, 0);
        // Reserve is how much we can sell thats remaining 20%
    }


    function setDeepFarmingVault(address _deepFarmingVault) public {
        onlyMultisig();
        deepFarmingVault = _deepFarmingVault;
        // set infinite approvals
        refreshApprovals();
        UserInformation memory ui = DELTA_TOKEN.userInformation(address(this));
        require(ui.noVestingWhitelisted, "DFV :: Set no vesting whitelist!");
        require(ui.fullSenderWhitelisted, "DFV :: Set full sender whitelist!");
        require(ui.immatureReceiverWhitelisted, "DFV :: Set immature whitelist!");
    }

    function refreshApprovals() public {
        DELTA_TOKEN.approve(deepFarmingVault, uint(-1));
        IERC20(WETH).approve(deepFarmingVault, uint(-1));
    }

    constructor () {
        // we check for a correct config
        require(PERCENT_SOLD + PERCENT_BURNED + PERCENT_DEV_FUND + PERCENT_DEEP_FARMING_VAULT == 100, "Amounts not proper");
        require(PERCENT_OF_SOLD_DEV + PERCENT_OF_SOLD_CORE_BUY + PERCENT_OF_SOLD_DELTA_WETH_DEEP_FARMING_VAULT == 100 , "Amount of weth split not proper");
    }   

    function getWETHForDeltaAndDistribute(uint256 amountToSellFullUnits, uint256 minAmountWETHForSellingDELTA, uint256 minAmountCOREUnitsPer1WETH) public {
        require(isApprovedLiquidator[msg.sender] == true, "!approved liquidator");
        distribute(); // we call distribute to get rid of all coins that are not supposed to be sold
        distributeAndBurn();
        // We swap and make sure we can get enough out
        // require(address(this) < wethAddress, "Invalid Token Address"); in DELTA token constructor
        IUniswapV2Pair pairDELTA = IUniswapV2Pair(DELTA_WETH_PAIR_SUSHISWAP);
        (uint256 reservesDELTA, uint256 reservesWETHinDELTA, ) = pairDELTA.getReserves();
        uint256 deltaUnitsToSell = amountToSellFullUnits * 1 ether;
        uint256 balanceDelta = DELTA_TOKEN.balanceOf(address(this));

        require(balanceDelta >= deltaUnitsToSell, "Amount is greater than reserves");
        uint256 amountETHOut = getAmountOut(deltaUnitsToSell, reservesDELTA, reservesWETHinDELTA);
        require(amountETHOut >= minAmountWETHForSellingDELTA * 1 ether, "Did not get enough ETH to cover min");

        // We swap for eth
        DELTA_TOKEN.transfer(DELTA_WETH_PAIR_SUSHISWAP, deltaUnitsToSell);
        pairDELTA.swap(0, amountETHOut, address(this), "");
        address dfv = deepFarmingVault;

        // We transfer the splits of WETH
        IERC20 weth = IERC20(WETH);
        weth.transfer(DELTA_MULTISIG, amountETHOut.div(2));
        IDeepFarmingVault(dfv).addNewRewards(0, amountETHOut.div(4));
        /// Transfer here doesnt matter cause its taken from reserves and this does nto update
        weth.transfer(CORE_WETH_PAIR, amountETHOut.div(4));
        // We swap WETH for CORE and send it to the vault and update the pending inside the vault
        IUniswapV2Pair pairCORE = IUniswapV2Pair(CORE_WETH_PAIR);

        (uint256 reservesCORE, uint256 reservesWETHCORE, ) = pairCORE.getReserves();
         // function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal  pure returns (uint256 amountOut) {

        uint256 coreOut = getAmountOut(amountETHOut.div(4), reservesWETHCORE, reservesCORE);
        uint256 coreOut1WETH = getAmountOut(1 ether, reservesWETHCORE, reservesCORE);

        require(coreOut1WETH >= minAmountCOREUnitsPer1WETH, "Did not get enough CORE check amountCOREUnitsBoughtFor1WETH() fn");
        pairCORE.swap(coreOut, 0, CORE_VAULT, "");
        // uint passed is deprecated
        ICORE_VAULT(CORE_VAULT).addPendingRewards(0);

        pendingTotal = pendingTotal.sub(deltaUnitsToSell); // we adjust the reserves // since we might had nto swapped everything
    }   

    function editApprovedLiquidator(address liquidator, bool isLiquidator) public {
        onlyMultisig();
        isApprovedLiquidator[liquidator] = isLiquidator;
    }

    function deltaGovernance() public view returns (address) {
        if(address(DELTA_TOKEN) == address(0)) {return address (0); }
        return DELTA_TOKEN.governance();
    }

    function onlyMultisig() private view {
        require(msg.sender == deltaGovernance(), "!governance");
    }
    
    function amountCOREUnitsBoughtFor1WETH() public view returns(uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(CORE_WETH_PAIR);
        // CORE is token0
        (uint256 reservesCORE, uint256 reservesWETH, ) = pair.getReserves();
        return getAmountOut(1 ether, reservesWETH, reservesCORE);
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal  pure returns (uint256 amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function rescueTokens(address token) public {
        onlyMultisig();
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    // Allows users to claim free credit
    function claimCredit() public {
        uint256 pending = pendingCredits[msg.sender];
        require(pending > 0, "Nothing to claim");
        pendingCredits[msg.sender] = 0;
        IDeepFarmingVault(deepFarmingVault).addPermanentCredits(msg.sender, pending);
    }

    /// Credits user for burning tokens
    // Can only be called by the delta token
    // Note this is a inherently trusted function that does not do balance checks.
    function creditUser(address user, uint256 amount) public {
        require(msg.sender == address(DELTA_TOKEN), "KNOCK KNOCK");
        pendingCredits[user] = pendingCredits[user].add(amount.mul(PERCENT_BURNED).div(100)); //  we add the burned amount to perma credit
    }

    function addDevested(address user, uint256 amount) public {
        require(DELTA_TOKEN.transferFrom(msg.sender, address(this), amount), "Did not transfer enough");
        pendingCredits[user] = pendingCredits[user].add(amount.mul(PERCENT_BURNED).div(100)); //  we add the burned amount to perma credit
    }
}