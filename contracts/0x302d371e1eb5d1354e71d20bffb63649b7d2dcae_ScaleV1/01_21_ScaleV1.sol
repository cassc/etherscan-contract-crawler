// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

import {OFTCoreUpgradeable} from "@layerzerolabs/solidity-examples/contracts/contracts-upgradable/token/oft/OFTCoreUpgradeable.sol";
import {IOFTUpgradeable} from "@layerzerolabs/solidity-examples/contracts/contracts-upgradable/token/oft/IOFTUpgradeable.sol";
import {ILayerZeroEndpoint} from "@layerzerolabs/solidity-examples/contracts/interfaces/ILayerZeroEndpoint.sol";

import {SingleLinkedList, SingleLinkedListLib} from "../utils/SingleLinkedList.sol";

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
    returns (uint amountToken, uint amountETH, uint liquidity);

    function getAmountsOut(uint amountIn, address[] memory path)
        external
        view
    returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] memory path)
        external
        view
    returns (uint[] memory amounts);
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address);
}

interface IUniswapV2Pair {
    function sync() external;
}

contract ScaleV1 is OFTCoreUpgradeable, IERC20Upgradeable {
    using SingleLinkedListLib for SingleLinkedList;

    /* -------------------------------------------------------------------------- */
    /*                                   events                                   */
    /* -------------------------------------------------------------------------- */
    error InvalidParameters();
    error RemoteStateOutOfSync(uint remoteState);
    error ERC20InsufficientAllowance(address, address, uint);
    error InsuffcientBalance(uint);
    error OFTCoreUnknownPacketType();
    error MaxTransaction();
    error MaxWallet();
    error TransfersDisabled();

    event Reflect(uint256 baseAmountReflected, uint256 totalReflected);
    event LaunchFee(address user, uint amount);

    event TransmitToRemote(
        uint16 indexed destinationChain,
        uint totalReflections
    );
    event AnswerToRemote(uint16 indexed remoteChainId, uint answer);
    event RequestRemoteState(uint16 indexed requestedChain);
    event ReceiveRemoteState(
        uint16 indexed sourceChain,
        uint receivedRemoteState
    );
    event XReflect(uint256 baseAmountReflected, uint256 totalReflected);

    /* -------------------------------------------------------------------------- */
    /*                                  constants                                 */
    /* -------------------------------------------------------------------------- */
    string constant _name = "ScaleX.gg | Scale";
    string constant _symbol = "S";

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IUniswapV2Router02 public immutable UNISWAP_V2_ROUTER;

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;

    // supplies
    uint256 constant TOTAL_SUPPLY = 1_000_000 ether;
    uint256 constant PRESALE_SUPPLY = TOTAL_SUPPLY * 5_257 / MAX_BP;
    uint256 constant TREASURY_VESTING = 200_000 ether;
    uint256 constant TREASURY_LOCKED = 100_000 ether;

    uint256 constant LZ_GAS_USAGE_LIMIT = 1_000_000;
    uint256 constant MAX_BP = 10_000;
    
    // fees
    uint256 constant MAX_FEE = 1_500; /* 15% */
    uint256 constant LAUNCH_FEE = 1_500; /* 15% */
    uint256 constant LAUNCH_FEE_DURATION = 1 days;

    // reflections
    uint256 constant REFLECTION_GROWTH_FACTOR = 12;
    uint256 constant MAX_BURN_REWARD_RATE = MAX_BP;
    uint256 constant ASYMPTOTE = 10;

    uint256 private constant MIN_MAX_WALLET = (TOTAL_SUPPLY * 160) / MAX_BP; // 1.6%
    uint256 private constant MIN_MAX_TX = TOTAL_SUPPLY / 100;

    uint16 public constant PT_TRANSMIT_AND_REQUEST = 1;
    uint16 public constant PT_TRANSMIT = 2;
    uint16 public constant PT_RESPONSE = 3;

    /* -------------------------------------------------------------------------- */
    /*                                   states                                   */
    /* -------------------------------------------------------------------------- */

    struct Fee {
        // not to be swapped to native
        uint8 reflection;
        // sent off
        uint8 marketing;
        // to be swapped to native
        uint8 omnichain /* used to cover gas for transmitting reflections across chains */;
        uint8 treasury;
        uint8 referral /* 50% user buying free reduction & 50% to referrer */;
        uint8 lp /* local LP + chain expansion */;
        uint8 buyback;
        uint8 burn;
        uint128 total;
    }

    struct EmissionRateChange {
        uint256 startingTime;
        uint256 duration;
        uint256 targetValue;
    }

    // L0 chain IDs sorted by avg gas costs in decreasing order
    SingleLinkedList public chains;
    uint16 private lzChainId;
    bool private liquidityInitialised;

    uint256 public feesEnabled;
    uint256 public swapThreshold; // denominated as reflected amount
    uint256 public totalReflected;

    uint256 private launchTime;
    uint256 private isInSwap;
    uint256 private isLowGasChain;

    // wallet limits
    uint256 private limitsEnabled;
    uint256 private maxWallet;
    uint256 private maxTx;

    // for auto lp burn
    uint256 private lastBurnTime;
    uint256 private burnRewardRate;
    uint256 private lpBurnRatePerDay;
    uint256 private burnTimeDiffCap; // after this time, pending burn amount does not increase anymore

    address private _uniswapPair;

    address private marketingFeeReceiver;
    address private lpFeeReceiver;
    address private buybackFeeReceiver;
    address private treasuryReceiver;
    address private lpBurnReceiver;

    Fee public buyFee;
    Fee public sellFee;

    mapping(address => uint256) private isRegistredPool;
    mapping(address => uint256) private _baseBalance;
    mapping(address => uint256) private txLimitsExcluded;

    mapping(address => mapping(address => uint256)) private _allowances;

    // --- V1 

    uint256 public crossChainReflectionsEnabled;
    uint256 public transfersEnabled;

    EmissionRateChange private erc;

    mapping(address => uint256) private isEcosystemContract;

    // --- Constructor

    /// @custom:oz-upgrades-unsafe-allow constructor state-variable-immutable
    constructor(address router) {
        UNISWAP_V2_ROUTER = IUniswapV2Router02(router);
    }

    receive() external payable {}

    function initialize(
        address _lzEndpoint,
        address newMarketingFeeReceiver,
        address newLPfeeReceiver,
        address newBuyBackFeeReceiver,
        address newTreasuryReceiver,
        address newLPBurnReceiver
    ) public payable initializer {

        // initialise parents
        __Ownable_init_unchained();
        __LzAppUpgradeable_init_unchained(_lzEndpoint);

        // set variables
        swapThreshold = (TOTAL_SUPPLY * 20) / MAX_BP; /* 0.2% of total supply */

        // limits
        limitsEnabled = 1;
        maxWallet = TOTAL_SUPPLY * 160 / MAX_BP;
        maxTx = maxWallet;

        // LZ setup
        lzChainId = ILayerZeroEndpoint(_lzEndpoint).getChainId() + 100;
        chains.addNode(lzChainId, 0);

        marketingFeeReceiver = newMarketingFeeReceiver;
        lpFeeReceiver = newLPfeeReceiver;
        buybackFeeReceiver = newBuyBackFeeReceiver;
        treasuryReceiver = newTreasuryReceiver;
        lpBurnReceiver = newLPBurnReceiver;

        // exclude project wallets from limits
        txLimitsExcluded[address(this)] = 1;
        txLimitsExcluded[treasuryReceiver] = 1;
        txLimitsExcluded[marketingFeeReceiver] = 1;
        txLimitsExcluded[lpFeeReceiver] = 1;
        txLimitsExcluded[buybackFeeReceiver] = 1;
        txLimitsExcluded[lpBurnReceiver] = 1;

        buyFee = Fee({
            reflection: 100,
            omnichain: 100,
            buyback: 0,
            marketing: 100,
            lp: 100,
            treasury: 100,
            referral: 0,
            burn: 0,
            total: 500
        });
        sellFee = Fee({
            reflection: 100,
            omnichain: 100,
            buyback: 0,
            marketing: 100,
            lp: 100,
            treasury: 100,
            referral: 0,
            burn: 0,
            total: 500
        });

        // mint presale supply to treasury
        // if (block.chainid == 1) {
        //     // only on Ethereum main net
        //     _baseBalance[treasuryReceiver] = PRESALE_SUPPLY;
        //     emit Transfer(address(0), treasuryReceiver, PRESALE_SUPPLY);
        // }
    }

    function addLiquidity(uint sharesForChain, address vestingWallet, address multisig) external payable onlyOwner {

        if (liquidityInitialised) revert();
        liquidityInitialised = true;

        if(block.chainid == 1) { // only on Ethereum main net

            // cross chain liquidity supply is vesting linearly over 180d
            _baseBalance[vestingWallet] = _baseBalance[vestingWallet] + TREASURY_VESTING/2;
            emit Transfer(address(0), vestingWallet, TREASURY_VESTING/2);

            // liquidity farming rewards go to multisig
            _baseBalance[multisig] = _baseBalance[multisig] + TREASURY_VESTING/2;
            emit Transfer(address(0), multisig, TREASURY_VESTING/2);

            // will be manually deposited in lock contract that lets only reflections out
            _baseBalance[treasuryReceiver] = _baseBalance[treasuryReceiver] + TREASURY_LOCKED;
            emit Transfer(address(0), treasuryReceiver, TREASURY_LOCKED);

            buyFee = Fee({
                reflection: 100,
                omnichain: 100,
                buyback: 0,
                marketing: 100,
                lp: 100,
                treasury: 100,
                referral: 0,
                burn: 0,
                total: 500
            });
            sellFee = Fee({
                reflection: 100,
                omnichain: 100,
                buyback: 0,
                marketing: 100,
                lp: 100,
                treasury: 100,
                referral: 0,
                burn: 0,
                total: 500
            });
        }

        uint liquiditySupply = TOTAL_SUPPLY - PRESALE_SUPPLY - TREASURY_VESTING - TREASURY_LOCKED;
        uint tokensForLiquidity = (liquiditySupply * sharesForChain) / MAX_BP;

        // fund address(this) with desired amount of liquidity tokens
        _baseBalance[address(this)] = _baseBalance[address(this)] + tokensForLiquidity;
        emit Transfer(address(0), address(this), tokensForLiquidity);

        // create uniswap pair
        _uniswapPair = IUniswapV2Factory(UNISWAP_V2_ROUTER.factory())
            .createPair(address(this), UNISWAP_V2_ROUTER.WETH());

        // set unlimited allowance for uniswap router
        _allowances[address(this)][address(UNISWAP_V2_ROUTER)] = type(uint256).max;

        // add desired amount of liquidity to pair
        UNISWAP_V2_ROUTER.addLiquidityETH{value: msg.value}(
            address(this), // address token,
            tokensForLiquidity, // uint amountTokenDesired,
            tokensForLiquidity, // uint amountTokenMin,
            msg.value, // uint amountETHMin,
            treasuryReceiver, // address to,
            block.timestamp // uint deadline
        );

        // set fee variables
        isRegistredPool[_uniswapPair] = 1;
        feesEnabled = 1;
        launchTime = block.timestamp;

        // auto LP burn
        lastBurnTime = block.timestamp;
        lpBurnRatePerDay = 2_000; 
        burnRewardRate = 0;
        burnTimeDiffCap = 1 days;
    }

    function manuallyBurnLP() public payable onlyOwner {
        _burnLP();
    }

    /* -------------------------------------------------------------------------- */
    /*                                    ERC20                                   */
    /* -------------------------------------------------------------------------- */

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            if (_allowances[sender][msg.sender] < amount)
                revert ERC20InsufficientAllowance(
                    sender,
                    recipient,
                    _allowances[sender][msg.sender]
                );
            _allowances[sender][msg.sender] =
                _allowances[sender][msg.sender] -
                amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    /* -------------------------------------------------------------------------- */
    /*                                     OFT                                    */
    /* -------------------------------------------------------------------------- */

    function token() external view override returns (address) {
        return address(this);
    }

    function _debitFrom(
        address _from,
        uint16 /* dst chain id */,
        bytes memory /* toAddress */,
        uint _amount
    ) internal override returns (uint) {

        if(transfersEnabled == 0 && txLimitsExcluded[_from] == 0) revert TransfersDisabled();

        if (_from != msg.sender) {
            if (_allowances[_from][msg.sender] < _amount)
                revert ERC20InsufficientAllowance(_from, msg.sender, _amount);

            unchecked {
                _allowances[_from][msg.sender] =
                    _allowances[_from][msg.sender] -
                    _amount;
            }
        }

        if (_baseBalance[_from] < _amount) revert InsuffcientBalance(_amount);

        unchecked {
            // burn
            _baseBalance[_from] = _baseBalance[_from] - _amount;
        }
        return _amount;
    }

    function _creditTo(
        uint16 /* src chain id */,
        address _toAddress,
        uint _amount
    ) internal override returns (uint) {
        if(transfersEnabled == 0 && txLimitsExcluded[_toAddress] == 0) revert TransfersDisabled();
        // mint
        _baseBalance[_toAddress] = _baseBalance[_toAddress] + _amount;
        return _amount;
    }

    /* -------------------------------------------------------------------------- */
    /*                                    Views                                   */
    /* -------------------------------------------------------------------------- */

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(OFTCoreUpgradeable) returns (bool) {
        return
            interfaceId == type(IOFTUpgradeable).interfaceId ||
            interfaceId == type(IERC20Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function totalSupply() external pure override returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return baseToReflectionAmount(_baseBalance[account]);
    }

    function baseBalanceOf(address account) public view returns(uint256) {
        return _baseBalance[account];
    }

    function allowance(
        address holder,
        address spender
    ) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function baseToReflectionAmount(
        uint256 baseAmount
    ) public view returns (uint256) {
        // ASYMPTOTE = N = post reflection supply approaches total supply * N
        // REFLECTION_GROWTH_FACTOR = M = speed of reflections
        uint numerator = (ASYMPTOTE - 1) * ASYMPTOTE * TOTAL_SUPPLY * baseAmount;
        uint denominator = (REFLECTION_GROWTH_FACTOR * totalReflected) + (ASYMPTOTE * TOTAL_SUPPLY);
        return ASYMPTOTE * baseAmount - (numerator / denominator);
    }

    function reflectionToBaseAmount(
        uint reflectionAmount
    ) public view returns (uint) {
        uint numerator = reflectionAmount * ((TOTAL_SUPPLY * ASYMPTOTE) + (REFLECTION_GROWTH_FACTOR * totalReflected));
        uint denominator = ASYMPTOTE * (TOTAL_SUPPLY + (REFLECTION_GROWTH_FACTOR * totalReflected));
        return numerator / denominator;
    }

    function circulatingSupply() public view returns (uint256) {
        return baseToReflectionAmount(TOTAL_SUPPLY - balanceOf(DEAD) - balanceOf(ZERO) - totalReflected);
    }

    function circulatingBaseSupply() public view returns (uint256) {
        return TOTAL_SUPPLY - balanceOf(DEAD) - balanceOf(ZERO) - totalReflected;
    }

    function getMaxWalletAndTx() external view returns (bool, uint, uint) {
        return (
            feesEnabled != 0,
            baseToReflectionAmount(maxWallet),
            baseToReflectionAmount(maxTx)
        );
    }

    function getLPBurnInfo() external view returns (uint, uint, uint, uint) {
        return (lpBurnRatePerDay, lastBurnTime, burnRewardRate, burnTimeDiffCap);
    }

    /* -------------------------------------------------------------------------- */
    /*                               Access restricted                            */
    /* -------------------------------------------------------------------------- */

    function clearStuckBalance() external payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function clearStuckToken() external payable onlyOwner {
        _transferFrom(address(this), msg.sender, balanceOf(address(this)));
    }

    function setRegistredPool(
        address pool,
        uint state
    ) external payable onlyOwner {
        isRegistredPool[pool] = state;
    }

    function setIsEcosystemContract(
        address addr,
        uint256 state
    ) public payable onlyOwner {
        isEcosystemContract[addr] = state;
    }

    // --- Swap & fee settings (& cross chain reflections)

    function setSwapSettings(
        uint256 newtransfersEnabled,
        uint256 newFeesEnabled,
        uint256 newSwapThreshold,
        uint256 newCrossChainReflectionsEnabled,
        uint256 newLimitsEnabled,
        uint256 newMaxWallet,
        uint256 newMaxTx
    ) external payable onlyOwner {

        // only able to disable transfers if something goes wrong durting launch
        if(block.timestamp > launchTime + 1 days) {
            transfersEnabled = 1;
        } else {
            transfersEnabled = newtransfersEnabled;
        }
        feesEnabled = newFeesEnabled;
        limitsEnabled = newLimitsEnabled;
        crossChainReflectionsEnabled = newCrossChainReflectionsEnabled;

        swapThreshold = newSwapThreshold;
        
        require(newMaxWallet >= MIN_MAX_WALLET && newMaxTx >= MIN_MAX_TX);
        maxWallet = newMaxWallet;
        maxTx = newMaxTx;
    }

    function changeFees(
        Fee calldata _buyFee,
        Fee calldata _sellFee
    ) external payable onlyOwner {
        // can cast all numbers, or just the first to save gas I think, not sure what the saving differences are like
        uint128 totalBuyFee = uint128(_buyFee.reflection) +
            _buyFee.marketing +
            _buyFee.omnichain +
            _buyFee.treasury +
            _buyFee.referral +
            _buyFee.lp +
            _buyFee.buyback +
            _buyFee.burn;

        uint128 totalSellFee = uint128(_sellFee.reflection) +
            _sellFee.marketing +
            _sellFee.omnichain +
            _sellFee.treasury +
            _sellFee.referral +
            _sellFee.lp +
            _sellFee.buyback +
            _sellFee.burn;

        if (
            totalBuyFee != _buyFee.total ||
            totalSellFee != _sellFee.total ||
            totalBuyFee > MAX_FEE ||
            totalSellFee > MAX_FEE
        ) revert InvalidParameters();

        buyFee = _buyFee;
        sellFee = _sellFee;
    }

    function setFeeReceivers(
        address newMarketingFeeReceiver,
        address newLPfeeReceiver,
        address newBuybackFeeReceiver,
        address newTreasuryReceiver,
        address newLPBurnReceiver
    ) external payable onlyOwner {
        if(newMarketingFeeReceiver != address(0))
            marketingFeeReceiver = newMarketingFeeReceiver;
        if(newLPfeeReceiver != address(0))
            lpFeeReceiver = newLPfeeReceiver;
        if(newBuybackFeeReceiver != address(0))
            buybackFeeReceiver = newBuybackFeeReceiver;
        if(newTreasuryReceiver != address(0))
            treasuryReceiver = newTreasuryReceiver;
        if(newLPBurnReceiver != address(0))
            lpBurnReceiver = newLPBurnReceiver;
    }

    // --- Cross chain setup

    function setTrustedRemoteWithInfo(
        uint16 _remoteChainId,
        bytes calldata _remoteAddress,
        uint8 chainListPosition
    ) external payable onlyOwner {
        // we only add the chain to the list of lower gas chains if it actually is a lower gas chain
        if (chainListPosition != 0) {
            chains.addNode(_remoteChainId, chainListPosition);
        }
        trustedRemoteLookup[_remoteChainId] = abi.encodePacked(
            _remoteAddress,
            address(this)
        );
        emit SetTrustedRemoteAddress(_remoteChainId, _remoteAddress);
    }

    function removeChain(uint data) external payable onlyOwner {
        chains.removeNode(data);
    }

    // --- Wallet & Transaction limits

    function setExcludeFromLimits(
        address toExclude,
        uint256 targetValue
    ) public payable onlyOwner {
        txLimitsExcluded[toExclude] = targetValue;
    }

    // --- LP burns

    function setLPBurnData(
        uint256 newBurnRewardRate,
        uint256 newBurnTimeDiffCap,
        address receiver
    ) public payable onlyOwner {
        if (newBurnRewardRate > MAX_BURN_REWARD_RATE)
            revert InvalidParameters();
        burnRewardRate = newBurnRewardRate;
        lpBurnReceiver = receiver;
        burnTimeDiffCap = newBurnTimeDiffCap;
    }

    function setEmissionRateChange(
        uint256 newStartingTime,
        uint256 newDuration,
        uint256 newTargetValue
    ) public payable onlyOwner {
        erc = EmissionRateChange(
            newStartingTime,
            newDuration,
            newTargetValue
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                                   Internal                                 */
    /* -------------------------------------------------------------------------- */

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {

        bool senderIsPool = isRegistredPool[sender] != 0; // = buy
        bool recipientIsPool = isRegistredPool[recipient] != 0; // = sell

        if(
            transfersEnabled == 0 && !(
                txLimitsExcluded[sender] != 0 ||
                (senderIsPool && txLimitsExcluded[recipient] != 0)
            )          
        ) revert TransfersDisabled();

        // take launch fee first
        uint baseLaunchFeeAmount;

        // take launch fee
        if (
            feesEnabled != 0 &&
            !senderIsPool &&
            isInSwap == 0 &&
            block.timestamp - launchTime < LAUNCH_FEE_DURATION
        ) {
            isInSwap = 1;

            // swap back
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = UNISWAP_V2_ROUTER.WETH();

            uint reflectedLaunchFeeAmount = (amount *
                LAUNCH_FEE *
                (LAUNCH_FEE_DURATION - (block.timestamp - launchTime))) /
                LAUNCH_FEE_DURATION /
                MAX_BP;

            baseLaunchFeeAmount = reflectionToBaseAmount(
                reflectedLaunchFeeAmount
            );

            _baseBalance[address(this)] =
                _baseBalance[address(this)] +
                baseLaunchFeeAmount;
            emit Transfer(sender, address(this), reflectedLaunchFeeAmount);
            emit LaunchFee(sender, reflectedLaunchFeeAmount);

            UNISWAP_V2_ROUTER
                .swapExactTokensForETHSupportingFeeOnTransferTokens(
                    reflectedLaunchFeeAmount,
                    0,
                    path,
                    treasuryReceiver,
                    block.timestamp
                );

            isInSwap = 0;
        }

        // Swap own token balance against pool if conditions are fulfilled
        // this has to be done before calculating baseAmount since it shifts
        // the balance in the liquidity pool, thus altering the result
        {
            if (
                isInSwap == 0 &&
                // this only swaps if it's not a buy, amplifying impacts of sells and
                // leaving buys untouched but also shifting gas costs of this to sellers only
                isRegistredPool[msg.sender] == 0 &&
                feesEnabled != 0 &&
                _baseBalance[address(this)] >= swapThreshold
            ) {
                isInSwap = 1;

                Fee memory memorySellFee = sellFee;

                uint256 stack_SwapThreshold = swapThreshold;
                uint256 amountToBurn = (stack_SwapThreshold *
                    memorySellFee.burn) / memorySellFee.total;
                uint256 amountToSwap = stack_SwapThreshold - amountToBurn;

                // burn, no further checks needed here
                uint256 baseAmountToBurn = reflectionToBaseAmount(amountToBurn);
                _baseBalance[address(this)] =
                    _baseBalance[address(this)] -
                    baseAmountToBurn;
                _baseBalance[DEAD] = _baseBalance[DEAD] + baseAmountToBurn;

                // swap non-burned tokens to ETH
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = UNISWAP_V2_ROUTER.WETH();

                UNISWAP_V2_ROUTER
                    .swapExactTokensForETHSupportingFeeOnTransferTokens(
                        amountToSwap,
                        0,
                        path,
                        address(this),
                        block.timestamp
                    );

                uint256 amountETH = address(this).balance;

                // share of fees that should be swapped to ETH
                uint256 totalSwapShare = memorySellFee.total -
                    memorySellFee.reflection -
                    memorySellFee.burn;

                /*
                 * Send proceeds to respective wallets, except for omnichain which remains in contract.
                 *
                 * We don't need to use return values of low level calls here since we can just manually withdraw
                 * funds in case of failure; receiver wallets are owner supplied though and should only be EOAs
                 * anyway
                 */

                // marketing
                payable(marketingFeeReceiver).call{
                    value: (amountETH * memorySellFee.marketing) /
                        totalSwapShare
                }("");
                // LP
                payable(lpFeeReceiver).call{
                    value: (amountETH * memorySellFee.lp) / totalSwapShare
                }("");
                // buyback
                payable(buybackFeeReceiver).call{
                    value: (amountETH * memorySellFee.buyback) / totalSwapShare
                }("");
                // treasury
                payable(treasuryReceiver).call{
                    value: (amountETH * memorySellFee.treasury) / totalSwapShare
                }("");

                isInSwap = 0;
            }
        }

        uint maxRequiredBaseInput;
        if(
            recipientIsPool &&
            lpBurnRatePerDay != 0 &&
            block.timestamp > lastBurnTime
        ) {
            uint totalSellFee = sellFee.total; // gas savings

            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = UNISWAP_V2_ROUTER.WETH();
            uint outputIfSwappedBeforeBurn = UNISWAP_V2_ROUTER.getAmountsOut(
                feesEnabled != 0
                    ? amount * (MAX_BP - totalSellFee) / MAX_BP
                    : amount, 
                path
            )[1];

            _burnLP();
            
            // required input to receive correct output after paying fees
            maxRequiredBaseInput = reflectionToBaseAmount(
                UNISWAP_V2_ROUTER.getAmountsIn(
                    outputIfSwappedBeforeBurn, path
                )[0] * (
                    feesEnabled != 0 
                        ? MAX_BP / (MAX_BP - totalSellFee)
                        : 1
                )
            );
        }

        uint256 baseAmount = reflectionToBaseAmount(amount);

        if (_baseBalance[sender] < baseAmount)
            revert InsuffcientBalance(_baseBalance[sender]);

        /** 
         * If we burn before selling, the pool receives eg 10 tokens on 
         * 80 (+12.5%) instead of 10 tokens on 100 (+10%) and therefore 
         * creates a higher price to sell at.
         * 
         * We therefore tax the sold amount so that the received ETH amount
         * is the same as if the burn didn't happen beforehand, essentially
         * making the burn happen 'after' the swap.
         */
        uint256 postBurnFeeBaseAmount = baseAmount;
        if(maxRequiredBaseInput != 0 && maxRequiredBaseInput < baseAmount) {
            postBurnFeeBaseAmount = maxRequiredBaseInput;

            _baseBalance[address(this)] = _baseBalance[address(this)] + (baseAmount - maxRequiredBaseInput);
            emit Transfer(sender, address(this), baseAmount - maxRequiredBaseInput);
        }

        /**
         * @dev this modifies LP balance and thus also reflection amount that we
         * previously calculated, however the actually transferred amount will
         * still be based on the conversion from reflected amount to base amount
         * at the time of the transaction initiation and will NOT account for
         * changes made here
         */
        uint256 baseAmountReceived = feesEnabled != 0 && isInSwap == 0
            ? _performReflectionAndTakeFees(postBurnFeeBaseAmount, sender, senderIsPool)
            : postBurnFeeBaseAmount;

        if(limitsEnabled != 0) {
            if (
                !senderIsPool &&
                feesEnabled != 0 &&
                txLimitsExcluded[sender] == 0 &&
                baseAmount > maxTx
            ) revert MaxTransaction();

            if (
                feesEnabled != 0 &&
                !recipientIsPool &&
                txLimitsExcluded[recipient] == 0 &&
                _baseBalance[recipient] + baseAmountReceived > maxWallet
            ) revert MaxWallet();
        }

        _baseBalance[sender] = _baseBalance[sender] - baseAmount;
        _baseBalance[recipient] = _baseBalance[recipient] + baseAmountReceived;

        emit Transfer(sender, recipient, baseToReflectionAmount(baseAmountReceived));
        return true;
    }

    function _burnLP() internal {

        uint mem_lastBurnTime = lastBurnTime;
        uint256 pairBalance = _baseBalance[_uniswapPair]; // gas savings
        uint256 timeDelta = block.timestamp <= mem_lastBurnTime + burnTimeDiffCap
            ? (block.timestamp - mem_lastBurnTime)
            : 1 days;
        uint256 tokensToRemove = 
            pairBalance * 
            timeDelta * 
            lpBurnRatePerDay / 
            (1 days * MAX_BP);

        EmissionRateChange memory mem_erc = erc;
        uint256 emissionRate = burnRewardRate;
        if(
            mem_erc.startingTime != 0 && 
            mem_erc.startingTime <= block.timestamp
        ) {
            if(mem_erc.startingTime + mem_erc.duration > block.timestamp) {
                emissionRate = 
                    mem_erc.targetValue > emissionRate
                    ? emissionRate + ((block.timestamp - mem_erc.startingTime) * (mem_erc.targetValue - emissionRate) / mem_erc.duration)
                    : emissionRate - ((block.timestamp - mem_erc.startingTime) * (emissionRate - mem_erc.targetValue) / mem_erc.duration);
            } else {
                emissionRate = mem_erc.targetValue;
            }
        }

        uint256 tokensToReward = tokensToRemove * emissionRate / MAX_BP;
        uint256 tokensToBurn = tokensToRemove - tokensToReward;

        lastBurnTime = block.timestamp;

        _baseBalance[_uniswapPair] = pairBalance - tokensToRemove;

        if(tokensToBurn != 0) {
            emit Transfer( _uniswapPair, address(0), baseToReflectionAmount(tokensToBurn));
        }

        if(tokensToReward != 0) {
            _baseBalance[lpBurnReceiver] = _baseBalance[lpBurnReceiver] + tokensToReward;
            emit Transfer(_uniswapPair, lpBurnReceiver, baseToReflectionAmount(tokensToReward));
        }

        // Update the uniswap pair's reserves
        IUniswapV2Pair(_uniswapPair).sync();
    }

    function _performReflectionAndTakeFees(
        uint256 baseAmount,
        address sender,
        bool buying
    ) internal returns (uint256) {
        Fee memory memoryBuyFee = buyFee;
        Fee memory memorySellFee = sellFee;

        // amount of fees in base amount (non-reflection adjusted)
        uint256 baseFeeAmount = buying
            ? (baseAmount * memoryBuyFee.total) / MAX_BP
            : (baseAmount * memorySellFee.total) / MAX_BP;

        // reflect
        uint256 baseAmountReflected = buying
            ? (baseAmount * memoryBuyFee.reflection) / MAX_BP
            : (baseAmount * memorySellFee.reflection) / MAX_BP;

        /**
         * Omnichain
         *
         * - integrate local delta into state
         * - send local delta to lower gas chains
         * - request local state from lowest gas chain
         * - set local state to minimum (=most recent) of local state & remote state
         */
        totalReflected = totalReflected + baseAmountReflected;
        emit Reflect(baseAmountReflected, totalReflected);

        if(crossChainReflectionsEnabled != 0) 
            _transmitReflectionToOtherChainsAndFetchState();

        uint256 baseBalanceToContract = baseFeeAmount - baseAmountReflected;
        if (baseBalanceToContract != 0) {
            _baseBalance[address(this)] =
                _baseBalance[address(this)] +
                baseBalanceToContract;
            emit Transfer(
                sender,
                address(this),
                baseToReflectionAmount(baseBalanceToContract)
            );
        }
        return baseAmount - baseFeeAmount;
    }

    /* -------------------------------------------------------------------------- */
    /*                                     L0                                     */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Multicast reflection state change to all chains that are tendencially
     * cheaper than the local chain & fetch reflection state of cheapest chain to
     * integrate into local state
     */
    function _transmitReflectionToOtherChainsAndFetchState() internal {
        if (chains.length < 2) return;

        uint256[] memory lowerGasChains = chains.getBeheadedList();
        uint256 lowerGasChainsLen = lowerGasChains.length; // gas savings
        uint mem_totalReflected = totalReflected; // gas savings

        bytes memory lzPayload = abi.encode(PT_TRANSMIT, mem_totalReflected);

        for (uint iterator; iterator < lowerGasChainsLen - 1; ) {
            (uint gasRequired /* zroFee */, ) = lzEndpoint.estimateFees(
                uint16(lowerGasChains[iterator]),
                address(this),
                lzPayload,
                false,
                abi.encodePacked(uint16(1), LZ_GAS_USAGE_LIMIT)
            );

            if (address(this).balance > gasRequired) {
                _lzSend(
                    // cheapest chain = destination chainId
                    uint16(lowerGasChains[iterator]),
                    // abi.encode()d bytes
                    lzPayload,
                    // (msg.sender will be this contract) refund address
                    // (LayerZero will refund any extra gas back to caller of send()
                    payable(this),
                    // future param
                    address(0x0),
                    // v1 adapterParams, specify custom destination gas qty
                    abi.encodePacked(uint16(1), LZ_GAS_USAGE_LIMIT),
                    address(this).balance
                );
                emit TransmitToRemote(
                    uint16(lowerGasChains[iterator]),
                    mem_totalReflected
                );
                unchecked {
                    iterator = iterator + 1;
                }
            } else {
                // abort transmissions if gas is insufficient
                return;
            }
        }

        uint256 lowestGasChainId = lowerGasChains[lowerGasChainsLen - 1];
        if (lzChainId != lowestGasChainId) {
            lzPayload = abi.encode(PT_TRANSMIT_AND_REQUEST, mem_totalReflected);

            (uint gasRequired /* zroFee */, ) = lzEndpoint.estimateFees(
                uint16(lowestGasChainId),
                address(this),
                lzPayload,
                false,
                abi.encodePacked(uint16(1), LZ_GAS_USAGE_LIMIT)
            );

            if (address(this).balance > gasRequired) {
                // fetch the state from the lowest gas chain
                _lzSend(
                    // destination chainId
                    uint16(lowestGasChainId),
                    // abi.encoded bytes
                    lzPayload,
                    // refund address
                    payable(this),
                    // future param
                    address(0x0),
                    // v1 adapterParams, specify custom destination gas qty
                    abi.encodePacked(uint16(1), LZ_GAS_USAGE_LIMIT),
                    address(this).balance
                );
                emit TransmitToRemote(
                    uint16(lowestGasChainId),
                    mem_totalReflected
                );
                emit RequestRemoteState(uint16(lowestGasChainId));
            }
        }
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual override {
        uint16 packetType;
        assembly {
            packetType := mload(add(_payload, 32))
        }

        if (packetType == PT_SEND) {
            // token transfers between chains
            _sendAck(_srcChainId, _srcAddress, _nonce, _payload);
        } else if (packetType == PT_TRANSMIT_AND_REQUEST) {
            _receiveReflectionAndSendLocalState(
                _srcChainId,
                _payload,
                true /* is request? */
            );
        } else if (packetType == PT_TRANSMIT) {
            _receiveReflectionAndSendLocalState(
                _srcChainId,
                _payload,
                false /* is request? */
            );
        } else if (packetType == PT_RESPONSE) {
            _receiveRemoteReflectionState(_payload);
        } else {
            revert OFTCoreUnknownPacketType();
        }
    }

    function _receiveReflectionAndSendLocalState(
        uint16 _srcChainId,
        bytes memory _payload,
        bool isReq
    ) internal {
        (, /* packet type */ uint remoteState) = abi.decode(
            _payload,
            (uint16, uint)
        );

        // update local reflection data
        if (remoteState > totalReflected) {
            uint diff = remoteState - totalReflected;
            totalReflected = remoteState;
            emit XReflect(diff, totalReflected);
            emit ReceiveRemoteState(_srcChainId, remoteState);
        }

        // transmission comes from higher gas chain that wants to know local state
        if (isReq) {
            // pack payload AFTER integrating remote delta
            bytes memory lzPayload = abi.encode(PT_RESPONSE, totalReflected);

            // send response to origin chain
            _lzSend(
                _srcChainId, // destination chainId
                lzPayload, // abi.encode()'ed bytes
                payable(this), // (msg.sender will be this contract) refund address
                address(0x0), // future param, unused for this example
                abi.encodePacked(uint16(1), LZ_GAS_USAGE_LIMIT), // v1 adapterParams, specify custom destination gas qty
                address(this).balance
            );
            emit AnswerToRemote(_srcChainId, totalReflected);
        }
    }

    /**
     * @notice receive response to a request made to the lowest gas chain
     * @param _payload contains (uint16 packetType, uint256 remoteReflectionState)
     */
    function _receiveRemoteReflectionState(bytes memory _payload) internal {
        (, /* packet type */ uint remoteReflectionState) = abi.decode(
            _payload,
            (uint16, uint)
        );

        // if remote that is less recent than local state, we just ignore instead
        // of throwing so L0 does not have to store failed message
        if (remoteReflectionState > totalReflected) {
            // integrate remote changes if they are more recent than local state (=smaller value)
            uint reflectionStateDiff = remoteReflectionState - totalReflected;
            if (reflectionStateDiff != 0) {
                totalReflected = remoteReflectionState;
                emit XReflect(reflectionStateDiff, remoteReflectionState);
            }
        }
    }
}