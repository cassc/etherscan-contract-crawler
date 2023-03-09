// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

// import "./interfaces/IHook.sol";
// import "./interfaces/ICommunityCoin.sol";

// import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

// import "./interfaces/IERC20Dpl.sol";

// import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777RecipientUpgradeable.sol";

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

    mapping(address => mapping(uint256 => address)) public override getInstance;

    address public implementation;

    address public creator;

    address[] private _instances;
    InstanceType[] private _instanceTypes;
    InstanceType internal typeProducedByFactory;
    mapping(address => uint256) private _instanceIndexes;
    mapping(address => address) private _instanceCreators;

    mapping(address => InstanceInfo) public _instanceInfos;

    function initialize(address impl) external initializer {
        // setup swap addresses
        (uniswapRouter, uniswapRouterFactory) = SwapSettingsLib.netWorkSettings();

        implementation = impl;
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

    function getInstanceInfo(
        address tokenErc20,
        uint64 duration
    ) public view returns (InstanceInfo memory) {
        address instance = getInstance[tokenErc20][duration];
        return _instanceInfos[instance];
    }

    function produce(
        address tokenErc20,
        uint64 duration,
        uint64 bonusTokenFraction,
        address popularToken,
        IStructs.StructAddrUint256[] memory donations,
        uint64 rewardsRateFraction,
        uint64 numerator,
        uint64 denominator
    ) external returns (address instance) {
        require(msg.sender == creator);

        _createInstanceValidate(tokenErc20, duration, bonusTokenFraction);

        address instanceCreated = _createInstance(
            tokenErc20,
            duration,
            bonusTokenFraction,
            popularToken,
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
            tokenErc20,
            popularToken,
            donations,
            rewardsRateFraction
        );
        // }

        //Ownable(instanceCreated).transferOwnership(_msgSender());
        instance = instanceCreated;
    }

    function _createInstanceValidate(
        address tokenErc20,
        uint64 duration,
        uint64 /*bonusTokenFraction*/
    ) internal view {
        address instance = getInstance[tokenErc20][duration];
        require(instance == address(0), "CommunityCoin: PAIR_ALREADY_EXISTS");
        require(
            typeProducedByFactory == InstanceType.NONE || typeProducedByFactory == InstanceType.ERC20,
            "CommunityCoin: INVALID_INSTANCE_TYPE"
        );
    }

    function _createInstance(
        address tokenErc20,
        uint64 duration,
        uint64 bonusTokenFraction,
        address popularToken,
        uint64 rewardsRateFraction,
        uint64 numerator,
        uint64 denominator
    ) internal returns (address instance) {
        instance = implementation.clone();

        getInstance[tokenErc20][duration] = instance;

        _instanceIndexes[instance] = _instances.length;
        _instances.push(instance);

        _instanceTypes.push(InstanceType.ERC20);

        _instanceCreators[instance] = msg.sender; // real sender or trusted forwarder need to store?
        _instanceInfos[instance] = InstanceInfo(
            tokenErc20,
            duration,
            true,
            bonusTokenFraction,
            popularToken,
            rewardsRateFraction,
            numerator,
            denominator
        );
        if (typeProducedByFactory == InstanceType.NONE) {
            typeProducedByFactory = InstanceType.ERC20;
        }
        emit InstanceCreated(tokenErc20, instance, _instances.length);
    }
}