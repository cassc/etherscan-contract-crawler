// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

import './interfaces/ILaunchpad.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/interfaces/IERC20Metadata.sol';
import './interfaces/IDexRouter.sol';
import './interfaces/IDexFactory.sol';
import './interfaces/IDexPair.sol';
import './IQZoneNFT.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import './interfaces/IManager.sol';

/// @dev Helper methods for working with DEXes
/// @author gotbit
library DexRouterPairs {
    /// @dev Returns the address of the pair for `tokenA` and `tokenB` or address(0) if the pair doesn't exist
    /// @param router The DEX router
    /// @param tokenA One of the tokens in the pair
    /// @param tokenB One of the tokens in the pair
    function getPair(
        IDexRouter router,
        address tokenA,
        address tokenB
    ) internal view returns (address) {
        if (address(router).code.length == 0) return address(0);

        address factory;

        try router.factory() returns (address factory_) {
            factory = factory_;
        } catch {
            return address(0);
        }

        try IDexFactory(factory).getPair(tokenA, tokenB) returns (address pair) {
            return pair;
        } catch {
            return address(0);
        }
    }

    /// @dev Returns whether the pair for `tokenA` and `tokenB` is listed on the DEX
    /// @param router The DEX router
    /// @param tokenA One of the tokens in the pair
    /// @param tokenB One of the tokens in the pair
    function pairListed(
        IDexRouter router,
        address tokenA,
        address tokenB
    ) internal view returns (bool) {
        return getPair(router, tokenA, tokenB) != address(0);
    }

    /// @dev Returns the price of `tokenB` in `tokenA` in the DEX
    /// @param router The DEX router
    /// @param tokenA The token to get the price in
    /// @param tokenB The token to get the price of
    function price(
        IDexRouter router,
        address tokenA,
        address tokenB
    ) internal view returns (uint256) {
        address pair = getPair(router, tokenA, tokenB);
        if (pair == address(0)) return 0;

        uint256 reserve0;
        uint256 reserve1;

        try IDexPair(pair).getReserves() returns (uint112 reserve0_, uint112 reserve1_, uint32) {
            (reserve0, reserve1) = (reserve0_, reserve1_);
        } catch {
            return 0;
        }

        address token0;

        try IDexPair(pair).token0() returns (address token0_) {
            token0 = token0_;
        } catch {
            return 0;
        }

        uint256 reserveA = (tokenA == token0) ? reserve0 : reserve1;
        uint256 reserveB = (tokenB == token0) ? reserve0 : reserve1;

        uint256 oneTokenB = 10 ** IERC20Metadata(tokenB).decimals();
        return (reserveA * oneTokenB) / reserveB;
    }
}

/**
 * @title Launchpad
 * @author gotbit
 */

contract LaunchpadProxy is ILaunchpad2, Initializable, AccessControlUpgradeable {
    using SafeERC20 for IERC20Metadata;
    using DexRouterPairs for IDexRouter;

    bytes32 public constant VESTING_ROLE = keccak256('VESTING');
    bytes32 public constant MANAGER_ROLE = keccak256('MANAGER');
    uint256 public constant ROUND_TYPES = 3;

    uint256 public projectId;
    uint256 public roundType;
    uint256 public hardCap;
    uint256 public softCap;
    uint256 public maxVentureAllocation;
    uint256 public startTime;
    uint256 public launchpadKickback;
    IERC20Metadata public stableToken;
    IERC20Metadata public nativeToken;
    address public kickbackWallet;
    IDexRouter public dexRouter;
    IQZoneNFT public nft;
    uint64 public duration;
    uint256 public price;

    uint256 public raised;
    mapping(address => uint256) public invested;
    address public vestingContract;
    address[] public investors;
    address public manager;

    mapping(address => bool) public paidBack;

    uint256 public returnedProjectTokens = 0;

    IERC20Metadata public projectToken;

    constructor() {
        _disableInitializers();
    }

    // TODO: store the Launch struct
    function initialize(
        uint256 projectId_,
        uint256 roundType_,
        Launch calldata launchData_,
        uint256 launchpadKickback_,
        address stableToken_,
        address nativeToken_,
        address kickbackWallet_,
        address dexRouter_,
        address nft_
    ) external initializer {
        require(launchData_.startTime > block.timestamp, 'bad start time');
        require(
            launchData_.hardCap >= launchData_.softCap,
            'hardcap should be >= softcap'
        );

        projectId = projectId_;
        roundType = roundType_;
        hardCap = launchData_.hardCap;
        softCap = launchData_.softCap;
        maxVentureAllocation = launchData_.maxVentureAllocation;
        startTime = launchData_.startTime;
        duration = launchData_.duration;
        price = launchData_.price;
        launchpadKickback = launchpadKickback_;
        stableToken = IERC20Metadata(stableToken_);
        nativeToken = IERC20Metadata(nativeToken_);
        kickbackWallet = kickbackWallet_;
        dexRouter = IDexRouter(dexRouter_);
        nft = IQZoneNFT(nft_);
        manager = msg.sender;
        projectToken = IERC20Metadata(IManager(msg.sender).projectToken(projectId_));
        _grantRole(MANAGER_ROLE, msg.sender);
    }

    function projectTokensAmount() external view returns (uint256) {
        return (hardCap * oneProjectToken()) / price;
    }

    function projectTokensToDistribute() public view returns (uint256) {
        require(block.timestamp > startTime + duration, 'round in progress');
        return (raisedCapped() * oneProjectToken()) / price;
    }

    function transferProjectToken(
        uint256 amount,
        address to
    ) external onlyRole(VESTING_ROLE) {
        require(tokensTransferred, 'tokens not transferred yet');
        projectToken.safeTransfer(to, amount);
    }

    function transferStableToken(
        uint256 amount,
        address to
    ) external onlyRole(VESTING_ROLE) {
        stableToken.safeTransfer(to, amount);
    }

    function setVestingContract(
        address vestingContract_
    ) external onlyRole(MANAGER_ROLE) {
        require(vestingContract_ != address(0), 'zero address');
        vestingContract = vestingContract_;
        _grantRole(VESTING_ROLE, vestingContract_);
    }

    /// @dev Returns whether `amount` is within the allocation limit of `user` given his NFTs.
    /// @param amount The amount the user wants to invest
    /// @param user The investor
    /// @param data Data for the NFT oracle used on secondary chains
    /// @param signature Signature of `data`
    function meetsAllocationLimit(
        uint256 amount,
        address user,
        bytes memory data,
        bytes memory signature
    ) public view returns (bool) {
        uint256[] memory balances = IManager(manager).shouldUseOracle()
            ? IManager(manager).nftBalancesOracle(user, data, signature)
            : nft.balanceOfAllBatch(user);

        uint256 roundType_ = roundType;

        for (uint256 i; i < balances.length; ) {
            IQZoneNFT.Property memory props = nft.getProperties(i);
            if (!props.allowedRounds[roundType_]) {
                unchecked {
                    ++i;
                }
                continue;
            }

            uint256 padDecimals = 10 ** (stableToken.decimals() - 2);

            uint256 maxAllocationSize = (i == 4 && roundType_ <= 1)
                ? maxVentureAllocation
                : (
                  props.maxAllocationSize <= type(uint256).max / 100
                    ? props.maxAllocationSize * padDecimals
                    : type(uint256).max
                );

            if (
                balances[i] > 0 &&
                amount <= maxAllocationSize * balances[i] &&
                amount >= props.minAllocationSize * padDecimals
            ) return true;

            unchecked {
                ++i;
            }
        }

        return false;
    }

    function invest(
        address investor,
        uint256 stableAmount,
        bytes memory data,
        bytes memory signature
    ) external onlyRole(MANAGER_ROLE) {
        uint256 startTime_ = startTime;
        require(block.timestamp > startTime_, 'the launch has not been started yet');

        uint256 roundEndTime = startTime_ + duration;
        require(block.timestamp < roundEndTime, 'the launch has already ended');

        uint256 totalAmount = invested[investor] + stableAmount;
        require(
            meetsAllocationLimit(totalAmount, investor, data, signature),
            'amount does not meet the allocation limit'
        );

        require(stableToken.balanceOf(address(this)) >= raised + stableAmount);

        if (invested[investor] == 0) investors.push(investor);

        invested[investor] = totalAmount;
        raised += stableAmount;
        emit Invested(investor, stableAmount);
    }

    function raisedCapped() public view returns (uint256) {
        uint256 raised_ = raised;
        uint256 hardCap_ = hardCap;
        return raised_ > hardCap_ ? hardCap_ : raised_;
    }

    function launchFailed() public view returns (bool) {
        return ((block.timestamp > startTime + duration) && (softCap > raised));
    }

    function _oneUsd() internal view returns (uint256) {
        return 10 ** stableToken.decimals();
    }

    function oneProjectToken() public view returns (uint256) {
        return 10 ** (address(projectToken) == address(0) ? 18 : projectToken.decimals());
    }

    function _oneNative() internal view returns (uint256) {
        return 10 ** nativeToken.decimals();
    }

    function _vestingOver() internal view returns (bool) {
        return block.timestamp >= IVesting(vestingContract).vestingEndTime();
    }

    function _userShare(address user) internal view returns (uint256) {
        return (invested[user] * 1 ether) / raised;
    }

    function userTotal(address user) external view returns (uint256) {
        return (projectTokensToDistribute() * invested[user]) / raised;
    }

    function payBackOnPrice(address investor) external onlyRole(MANAGER_ROLE) {
        require(!paidBack[investor], 'already paid back');
        require(startTime + duration < block.timestamp, 'ido not over yet');
        require(IVesting(vestingContract).schedule(0).datetime < block.timestamp, 'vesting not started yet');
        address projToken = address(projectToken);

        bool listedStable = dexRouter.pairListed(
            address(stableToken),
            address(projectToken)
        );
        bool listedNative = dexRouter.pairListed(
            address(nativeToken),
            address(projectToken)
        );

        require(!listedStable && !listedNative || !_vestingOver(), 'vesting already over');

        uint256 currentPrice = listedNative
            ? (dexRouter.price(address(nativeToken), address(projectToken)) *
                _oneUsd()) /
                dexRouter.price(address(nativeToken), address(stableToken))
            : listedStable ? dexRouter.price(address(stableToken), address(projectToken))
            : 0;

        uint256 price_ = price;

        require((price_ > currentPrice), 'ido price <= dex price');

        paidBack[investor] = true;

        uint256 claimed = IVesting(vestingContract).claimed(investor);
        uint256 claimedInUsd = claimed == 0 ? 0 : (claimed * price_) /
            oneProjectToken();
        uint256 amount = (raisedCapped() * _userShare(investor)) /
            (1 ether) -
            claimedInUsd;

        emit PayBackInvestor(investor, amount);
        stableToken.safeTransfer(investor, amount);

        uint256 returnAmount = (projectTokensToDistribute() * amount) / raised;
        if (tokensTransferred) {
            IERC20Metadata(projToken).safeTransfer(projectWallet(), returnAmount);
        } else {
            returnedProjectTokens += returnAmount;
        }
    }

    function payBack(address investor) external onlyRole(MANAGER_ROLE) {
        require(launchFailed(), 'softcap met');
        require(!paidBack[investor], 'already paid back');

        paidBack[investor] = true;

        uint256 claimed = IVesting(vestingContract).claimed(investor);
        uint256 claimedInUsd = claimed == 0 ? 0 : (claimed * price) /
            oneProjectToken();
        uint256 amount = (raisedCapped() * _userShare(investor)) /
            (1 ether) -
            claimedInUsd;

        emit PayBackInvestor(investor, amount);
        stableToken.safeTransfer(investor, amount);
    }

    uint256 public overcapOffset = 0;

    function airdropOvercap(uint256 size) external onlyRole(MANAGER_ROLE) {
        require(block.timestamp > startTime + duration, 'ido not over yet');

        uint256 total = raised;
        require(total > hardCap, 'no overcap');

        uint256 amount = total - hardCap;
        address[] memory _investors = investors;
        require(_investors.length > overcapOffset, 'overcap airdrop already done');

        uint256 limit = Math.min(_investors.length, overcapOffset + size);
        uint256 i;

        for (i = overcapOffset; i < limit; ) {
            stableToken.safeTransfer(
                _investors[i],
                (amount * _userShare(_investors[i])) / 1 ether
            );
            unchecked {
                ++i;
            }
        }

        overcapOffset = i;
    }

    function investorsLength() external view returns (uint256) {
        return investors.length;
    }

    bool public tokensTransferred = false;

    function setTokensTransferred() external {
        require(!launchFailed(), 'softcap met');
        require(
            projectToken.balanceOf(address(this)) >=
                projectTokensToDistribute() - returnedProjectTokens,
            'not enough tokens'
        );
        tokensTransferred = true;
    }

    function setRoundType(uint256 roundType_) external onlyRole(MANAGER_ROLE) {
        require(startTime > block.timestamp, 'round has already started');
        require(roundType >= 0 && roundType < 3, 'bad round type');
        roundType = roundType_;
    }

    function setRoundData(Launch memory launchData_, address stableToken_) external onlyRole(MANAGER_ROLE) {
        require(startTime > block.timestamp, 'round has already started');
        hardCap = launchData_.hardCap;
        softCap = launchData_.softCap;
        maxVentureAllocation = launchData_.maxVentureAllocation;
        startTime = launchData_.startTime;
        duration = launchData_.duration;
        price = launchData_.price;
        stableToken = IERC20Metadata(stableToken_);
    }

    function projectWallet() public view returns (address) {
        return IManager(manager).projectWallet(projectId);
    }

    function setDexRouter(address dexRouter_) external onlyRole(MANAGER_ROLE) {
        require(startTime > block.timestamp, 'round has already started');
        dexRouter = IDexRouter(dexRouter_);
    }

    function setProjectToken() external onlyRole(MANAGER_ROLE) {
        require(!tokensTransferred, 'tokens already transferred');
        projectToken = IERC20Metadata(IManager(msg.sender).projectToken(projectId));
    }
}