// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

// import "./interfaces/IHook.sol";
// import "./interfaces/ICommunityCoin.sol";

// import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

// import "./interfaces/IERC20Dpl.sol";

// import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777RecipientUpgradeable.sol";
import "./interfaces/ICommunityStakingPoolErc20.sol";
import "./interfaces/ICommunityStakingPool.sol";
import "./interfaces/ICommunityStakingPoolFactory.sol";

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IStructs.sol";

//------------------------------------------------------------------------------
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "./interfaces/ICommunityStakingPoolFactory.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777Upgradeable.sol";
import "./libs/SwapSettingsLib.sol";

//------------------------------------------------------------------------------

// import "hardhat/console.sol";

contract CommunityStakingPoolFactory is Initializable, ICommunityStakingPoolFactory, IStructs {
    using ClonesUpgradeable for address;

    uint64 internal constant FRACTION = 100000; // fractions are expressed as portions of this

    // vars will setup in method `initialize`
    address internal uniswapRouter;
    address internal uniswapRouterFactory;

    mapping(address => mapping(address => mapping(uint256 => address))) public override getInstance;

    mapping(address => mapping(uint256 => address)) public override getInstanceErc20;

    address public implementation;
    address public implementationErc20;

    address public creator;

    address[] private _instances;
    InstanceType[] private _instanceTypes;
    InstanceType internal typeProducedByFactory;
    mapping(address => uint256) private _instanceIndexes;
    mapping(address => address) private _instanceCreators;

    mapping(address => InstanceInfo) public _instanceInfos;

    function initialize(address impl, address implErc20) external initializer {
        // setup swap addresses
        (uniswapRouter, uniswapRouterFactory) = SwapSettingsLib.netWorkSettings();

        implementation = impl;
        implementationErc20 = implErc20;
        creator = msg.sender;

        typeProducedByFactory = InstanceType.NONE;
    }

    function instancesByIndex(uint256 index) external view returns (address instance_) {
        return _instances[index];
    }

    function instances() external view returns (address[] memory instances_) {
        return _instances;
    }

    /**
     * @dev view amount of created instances
     * @return amount amount instances
     * @custom:shortd view amount of created instances
     */
    function instancesCount() external view override returns (uint256 amount) {
        amount = _instances.length;
    }

    /**
     * @dev note that `duration` is 365 and `LOCKUP_INTERVAL` is 86400 (seconds) means that tokens locked up for an year
     * @notice view instance info by reserved/traded tokens and duration
     * @param reserveToken address of reserve token. like a WETH, USDT,USDC, etc.
     * @param tradedToken address of traded token. usual it intercoin investor token
     * @param duration duration represented in amount of `LOCKUP_INTERVAL`
     * @custom:shortd view instance info
     */
    function getInstanceInfo(
        address reserveToken,
        address tradedToken,
        uint64 duration
    ) public view returns (InstanceInfo memory) {
        address instance = getInstance[reserveToken][tradedToken][duration];
        return _instanceInfos[instance];
    }

    function getInstanceInfoByPoolAddress(address addr) external view returns (InstanceInfo memory) {
        return _instanceInfos[addr];
    }

    function getInstancesInfo() external view returns (InstanceInfo[] memory) {
        InstanceInfo[] memory ret = new InstanceInfo[](_instances.length);
        for (uint256 i = 0; i < _instances.length; i++) {
            ret[i] = _instanceInfos[_instances[i]];
        }
        return ret;
    }

    function produce(
        address reserveToken,
        address tradedToken,
        uint64 duration,
        uint64 bonusTokenFraction,
        IStructs.StructAddrUint256[] memory donations,
        uint64 lpFraction,
        address lpFractionBeneficiary,
        uint64 rewardsRateFraction,
        uint64 numerator,
        uint64 denominator
    ) external returns (address instance) {
        require(msg.sender == creator);

        _createInstanceValidate(
            reserveToken,
            tradedToken,
            duration,
            bonusTokenFraction,
            lpFraction,
            lpFractionBeneficiary
        );

        address instanceCreated = _createInstance(
            reserveToken,
            tradedToken,
            duration,
            bonusTokenFraction,
            lpFraction,
            lpFractionBeneficiary,
            rewardsRateFraction,
            numerator,
            denominator
        );

        require(instanceCreated != address(0), "CommunityCoin: INSTANCE_CREATION_FAILED");
        require(duration != 0, "cant be zero duration");

        // if (duration == 0) {
        //     IStakingTransferRules(instanceCreated).initialize(
        //         reserveToken,  tradedToken, reserveTokenClaimFraction, tradedTokenClaimFraction, lpClaimFraction
        //     );
        // } else {
        ICommunityStakingPool(instanceCreated).initialize(
            creator,
            reserveToken,
            tradedToken,
            donations,
            lpFraction,
            lpFractionBeneficiary,
            rewardsRateFraction
        );
        // }

        //Ownable(instanceCreated).transferOwnership(_msgSender());
        instance = instanceCreated;
    }

    function produceErc20(
        address tokenErc20,
        uint64 duration,
        uint64 bonusTokenFraction,
        IStructs.StructAddrUint256[] memory donations,
        uint64 lpFraction,
        address lpFractionBeneficiary,
        uint64 rewardsRateFraction,
        uint64 numerator,
        uint64 denominator
    ) external returns (address instance) {
        require(msg.sender == creator);

        _createInstanceErc20Validate(tokenErc20, duration, bonusTokenFraction, lpFraction, lpFractionBeneficiary);

        address instanceCreated = _createInstanceErc20(
            tokenErc20,
            duration,
            bonusTokenFraction,
            lpFraction,
            lpFractionBeneficiary,
            rewardsRateFraction,
            numerator,
            denominator
        );

        require(instanceCreated != address(0), "CommunityCoin: INSTANCE_CREATION_FAILED");
        require(duration != 0, "cant be zero duration");

        // if (duration == 0) {
        //     IStakingTransferRules(instanceCreated).initialize(
        //         reserveToken,  tradedToken, reserveTokenClaimFraction, tradedTokenClaimFraction, lpClaimFraction
        //     );
        // } else {
        ICommunityStakingPoolErc20(instanceCreated).initialize(
            creator,
            tokenErc20,
            donations,
            lpFraction,
            lpFractionBeneficiary,
            rewardsRateFraction
        );
        // }

        //Ownable(instanceCreated).transferOwnership(_msgSender());
        instance = instanceCreated;
    }

    function _createInstanceValidate(
        address reserveToken,
        address tradedToken,
        uint64 duration,
        uint64 bonusTokenFraction,
        uint64 lpFraction,
        address lpFractionBeneficiary
    ) internal view {
        require(reserveToken != tradedToken, "CommunityCoin: IDENTICAL_ADDRESSES");
        require(reserveToken != address(0) && tradedToken != address(0), "CommunityCoin: ZERO_ADDRESS");
        require(lpFraction <= FRACTION, "CommunityCoin: WRONG_CLAIM_FRACTION");
        address instance = getInstance[reserveToken][tradedToken][duration];
        require(instance == address(0), "CommunityCoin: PAIR_ALREADY_EXISTS");
        require(
            typeProducedByFactory == InstanceType.NONE || typeProducedByFactory == InstanceType.USUAL,
            "CommunityCoin: INVALID_INSTANCE_TYPE"
        );
    }

    function _createInstanceErc20Validate(
        address tokenErc20,
        uint64 duration,
        uint64 bonusTokenFraction,
        uint64 lpFraction,
        address lpFractionBeneficiary
    ) internal view {
        address instance = getInstanceErc20[tokenErc20][duration];
        require(instance == address(0), "CommunityCoin: PAIR_ALREADY_EXISTS");
        require(lpFraction <= FRACTION, "CommunityCoin: WRONG_CLAIM_FRACTION");
        require(
            typeProducedByFactory == InstanceType.NONE || typeProducedByFactory == InstanceType.ERC20,
            "CommunityCoin: INVALID_INSTANCE_TYPE"
        );
    }

    function _createInstance(
        address reserveToken,
        address tradedToken,
        uint64 duration,
        uint64 bonusTokenFraction,
        uint64 lpFraction,
        address lpFractionBeneficiary,
        uint64 rewardsRateFraction,
        uint64 numerator,
        uint64 denominator
    ) internal returns (address instance) {
        instance = implementation.clone();

        getInstance[reserveToken][tradedToken][duration] = instance;

        _instanceIndexes[instance] = _instances.length;
        _instances.push(instance);

        _instanceTypes.push(InstanceType.USUAL);

        _instanceCreators[instance] = msg.sender; // real sender or trusted forwarder need to store?
        _instanceInfos[instance] = InstanceInfo(
            reserveToken,
            duration,
            bonusTokenFraction,
            tradedToken,
            lpFraction,
            lpFractionBeneficiary,
            rewardsRateFraction,
            numerator,
            denominator,
            true,
            uint8(InstanceType.USUAL),
            address(0)
        );

        if (typeProducedByFactory == InstanceType.NONE) {
            typeProducedByFactory = InstanceType.USUAL;
        }
        emit InstanceCreated(reserveToken, tradedToken, instance, _instances.length, address(0));
    }

    function _createInstanceErc20(
        address tokenErc20,
        uint64 duration,
        uint64 bonusTokenFraction,
        uint64 lpFraction,
        address lpFractionBeneficiary,
        uint64 rewardsRateFraction,
        uint64 numerator,
        uint64 denominator
    ) internal returns (address instance) {
        instance = implementationErc20.clone();

        getInstanceErc20[tokenErc20][duration] = instance;

        _instanceIndexes[instance] = _instances.length;
        _instances.push(instance);

        _instanceTypes.push(InstanceType.ERC20);

        _instanceCreators[instance] = msg.sender; // real sender or trusted forwarder need to store?
        _instanceInfos[instance] = InstanceInfo(
            address(0),
            duration,
            bonusTokenFraction,
            address(0),
            lpFraction,
            lpFractionBeneficiary,
            rewardsRateFraction,
            numerator,
            denominator,
            true,
            uint8(InstanceType.ERC20),
            tokenErc20
        );
        if (typeProducedByFactory == InstanceType.NONE) {
            typeProducedByFactory = InstanceType.ERC20;
        }
        emit InstanceCreated(address(0), address(0), instance, _instances.length, tokenErc20);
    }

    /**
     * @param instancesToRedeem instancesToRedeem
     * @param valuesToRedeem valuesToRedeem
     * @param swapPaths array of arrays uniswap swapPath
     */
    function amountAfterSwapLP(
        address[] memory instancesToRedeem,
        uint256[] memory valuesToRedeem,
        address[][] memory swapPaths
    ) external view returns (address finalToken, uint256 finalAmount) {
        uint256 tradedAmount;
        address tradedToken;
        uint256 reserveAmount;
        address reserveToken;

        uint256 adjusted;
        finalAmount = 0;
        for (uint256 i = 0; i < instancesToRedeem.length; i++) {
            //1 calculate  how much traded and reserve tokens we will obtain if redeem and remove liquidity from uniswap
            // take into account LpFraction
            adjusted = _instanceInfos[instancesToRedeem[i]].lpFraction != 0
                ? valuesToRedeem[i] - (valuesToRedeem[i] * _instanceInfos[instancesToRedeem[i]].lpFraction) / FRACTION
                : valuesToRedeem[i];
            (tradedAmount, tradedToken, reserveAmount, reserveToken) = getPairsAmount(
                instancesToRedeem[i],
                adjusted //valuesToRedeem[i]
            );

            uint256 amountTmp;
            address tokenTmp;

            // swap TradedToken to reverved
            (tokenTmp, amountTmp) = expectedAmount(
                tradedToken,
                tradedAmount,
                swapPaths,
                reserveToken,
                tradedAmount,
                reserveAmount
            );

            // swap total reverved token through swapPaths (in order)
            (tokenTmp, amountTmp) = expectedAmount(
                reserveToken,
                amountTmp + reserveAmount,
                swapPaths,
                address(0),
                0,
                0
            );

            finalAmount += amountTmp;
            finalToken = tokenTmp;
        }
    }

    function getPairsAmount(address poolAddress, uint256 amountLp)
        internal
        view
        returns (
            uint256 tradedAmount,
            address tradedToken,
            uint256 reserveAmount,
            address reserveToken
        )
    {
        tradedToken = _instanceInfos[poolAddress].tradedToken;
        reserveToken = _instanceInfos[poolAddress].reserveToken;
        require(tradedToken != address(0) && reserveToken != address(0), "addresses can not be empty");

        address pair = IUniswapV2Factory(uniswapRouterFactory).getPair(tradedToken, reserveToken);

        require(pair != address(0), "pair does not exists");
        uint256 balance0 = IERC777Upgradeable(reserveToken).balanceOf(pair);
        uint256 balance1 = IERC777Upgradeable(tradedToken).balanceOf(pair);
        //bool feeOn = _mintFee(_reserve0, _reserve1);
        // feeTo calculation (We skip for now), but totalSupply depend of fee that can be minted
        uint256 _totalSupply = IERC777Upgradeable(pair).totalSupply();
        reserveAmount = (amountLp * balance0) / _totalSupply;
        tradedAmount = (amountLp * balance1) / _totalSupply;
    }

    function expectedAmount(
        address tokenFrom,
        uint256 amount0,
        address[][] memory swapPaths,
        address forceTokenSwap,
        uint256 subReserveFrom,
        uint256 subReserveTo
    ) internal view returns (address, uint256) {
        if (forceTokenSwap == address(0)) {
            address tokenFromTmp;
            uint256 amount0Tmp;

            for (uint256 i = 0; i < swapPaths.length; i++) {
                if (tokenFrom == swapPaths[i][swapPaths[i].length - 1]) {
                    // if tokenFrom is already destination token
                    return (tokenFrom, amount0);
                }

                tokenFromTmp = tokenFrom;
                amount0Tmp = amount0;

                for (uint256 j = 0; j < swapPaths[i].length; j++) {
                    (bool success, uint256 amountOut) = _swap(
                        tokenFromTmp,
                        swapPaths[i][j],
                        amount0Tmp,
                        subReserveFrom,
                        subReserveTo
                    );
                    if (success) {
                        //ret = amountOut;
                    } else {
                        break;
                    }

                    // if swap didn't brake before last iteration then we think that swap is done
                    if (j == swapPaths[i].length - 1) {
                        return (swapPaths[i][j], amountOut);
                    } else {
                        tokenFromTmp = swapPaths[i][j];
                        amount0Tmp = amountOut;
                    }
                }
            }
            revert("paths invalid");
        } else {
            (bool success, uint256 amountOut) = _swap(tokenFrom, forceTokenSwap, amount0, subReserveFrom, subReserveTo);
            if (success) {
                return (forceTokenSwap, amountOut);
            }
            revert("force swap invalid");
        }
    }

    function _swap(
        address tokenFrom,
        address tokenTo,
        uint256 amountFrom,
        uint256 subReserveFrom,
        uint256 subReserveTo
    )
        internal
        view
        returns (
            bool success,
            uint256 ret //address pair
        )
    {
        success = false;
        address pair = IUniswapV2Factory(uniswapRouterFactory).getPair(tokenFrom, tokenTo);

        if (pair == address(0)) {
            //break;
            //revert("pair == address(0)");
        } else {
            (uint112 _reserve0, uint112 _reserve1, ) = IUniswapV2Pair(pair).getReserves();

            if (_reserve0 == 0 || _reserve1 == 0) {
                //break;
            } else {
                (_reserve0, _reserve1) = (tokenFrom == IUniswapV2Pair(pair).token0())
                    ? (_reserve0, _reserve1)
                    : (_reserve1, _reserve0);
                if (subReserveFrom >= _reserve0 || subReserveTo >= _reserve1) {
                    //break;
                } else {
                    _reserve0 -= uint112(subReserveFrom);
                    _reserve1 -= uint112(subReserveTo);
                    // amountin reservein reserveout
                    ret = IUniswapV2Router02(uniswapRouter).getAmountOut(amountFrom, _reserve0, _reserve1);

                    if (ret != 0) {
                        success = true;
                    }
                }
            }
        }
    }
}