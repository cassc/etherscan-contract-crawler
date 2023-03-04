// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/*
  ______                     ______                                 
 /      \                   /      \                                
|  ▓▓▓▓▓▓\ ______   ______ |  ▓▓▓▓▓▓\__   __   __  ______   ______  
| ▓▓__| ▓▓/      \ /      \| ▓▓___\▓▓  \ |  \ |  \|      \ /      \ 
| ▓▓    ▓▓  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\\▓▓    \| ▓▓ | ▓▓ | ▓▓ \▓▓▓▓▓▓\  ▓▓▓▓▓▓\
| ▓▓▓▓▓▓▓▓ ▓▓  | ▓▓ ▓▓    ▓▓_\▓▓▓▓▓▓\ ▓▓ | ▓▓ | ▓▓/      ▓▓ ▓▓  | ▓▓
| ▓▓  | ▓▓ ▓▓__/ ▓▓ ▓▓▓▓▓▓▓▓  \__| ▓▓ ▓▓_/ ▓▓_/ ▓▓  ▓▓▓▓▓▓▓ ▓▓__/ ▓▓
| ▓▓  | ▓▓ ▓▓    ▓▓\▓▓     \\▓▓    ▓▓\▓▓   ▓▓   ▓▓\▓▓    ▓▓ ▓▓    ▓▓
 \▓▓   \▓▓ ▓▓▓▓▓▓▓  \▓▓▓▓▓▓▓ \▓▓▓▓▓▓  \▓▓▓▓▓\▓▓▓▓  \▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓ 
         | ▓▓                                             | ▓▓      
         | ▓▓                                             | ▓▓      
          \▓▓                                              \▓▓         
 * App:             https://ApeSwap.finance
 * Medium:          https://ape-swap.medium.com
 * Twitter:         https://twitter.com/ape_swap
 * Telegram:        https://t.me/ape_swap
 * Announcements:   https://t.me/ape_swap_news
 * Discord:         https://discord.com/ApeSwap
 * Reddit:          https://reddit.com/r/ApeSwap
 * Instagram:       https://instagram.com/ApeSwap.finance
 * GitHub:          https://github.com/ApeSwapFinance
 */

import "@ape.swap/contracts/contracts/v0.8/token/SweeperUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./lib/IMasterApeV2.sol";
import "./lib/IAnyswapV4Router.sol";

contract BananaAllocator is SweeperUpgradeable {
    using EnumerableSet for EnumerableSet.UintSet;

    IMasterApeV2 public masterApe;
    IERC20 public bananaToken;
    address public anyBanana;
    IAnyswapV4Router public anyswapRouter;

    struct BananaRoute {
        address toAddress;
        ActionId actionId;
        uint256 chainId;
        uint256 minimumBanana;
    }

    enum ActionId {
        SIMPLE,
        BRIDGE
    }

    mapping(uint256 => BananaRoute) public getBananaRouteFromPid;
    EnumerableSet.UintSet private bananaRoutesSet;

    event MovedBanana(uint256 pid, uint256 amount, address to, uint256 chainId);
    event AddedBananaRoute(
        uint256 farmPid,
        address toAddress,
        ActionId actionId,
        uint256 chainId,
        uint256 minimumBanana
    );
    event RemovedBananaRoute(uint256 pid);
    event ChangedBananaMinimum(uint256 pid, uint256 newMinimum);

    function initialize(
        IMasterApeV2 _masterApe,
        IERC20 _bananaToken,
        address _anyBanana,
        IAnyswapV4Router _anyswapRouter
    ) public initializer {
        initializeSweeper(new address[](0), true);
        masterApe = _masterApe;
        bananaToken = _bananaToken;
        anyBanana = _anyBanana;
        anyswapRouter = _anyswapRouter;
    }

    /// @notice Iterate through the BananaRoutes up to bananaRoutesLength
    /// @param index of bananaRoutes to pull
    /// @return pid MasterApe pid of this route
    /// @return bananaRoute BananaRoute struct details
    function getBananaRouteAtIndex(uint256 index) external view returns (uint256 pid, BananaRoute memory bananaRoute) {
        pid = bananaRoutesSet.at(index);
        bananaRoute = getBananaRouteFromPid[pid];
    }

    /// @notice Get the number of BananaRoutes stored in the EnumerableSet
    function bananaRoutesLength() public view returns (uint256) {
        return bananaRoutesSet.length();
    }

    /// @notice Move banana based on index
    /// @param index index of banana route to move banana
    function moveBananaIndex(uint256 index) external {
        uint256 _bananaRoutesLength = bananaRoutesLength();
        require(index < _bananaRoutesLength, "BananaAllocator: Index out of bounds");
        _moveBanana(bananaRoutesSet.at(index), true);
    }

    /// @notice Move banana for all banana routes
    /// @param revert_ revert if one fails
    function moveBananaAll(bool revert_) external {
        uint256 _bananaRoutesLength = bananaRoutesLength();
        for (uint256 index = 0; index < _bananaRoutesLength; index++) {
            _moveBanana(bananaRoutesSet.at(index), revert_);
        }
    }

    /// @notice Move banana based on farm pid
    /// @param pid farm pid of banana route to move banana
    function moveBananaPid(uint256 pid) external {
        _moveBanana(pid, true);
    }

    /// @notice Move banana based on multiple farm pids
    /// @param pids farm pids of banana route to move banana
    /// @param revert_ revert if one fails
    function moveBananaPids(uint256[] memory pids, bool revert_) external {
        for (uint256 index = 0; index < pids.length; index++) {
            _moveBanana(pids[index], revert_);
        }
    }

    function _moveBanana(uint256 pid, bool revert_) private {
        BananaRoute memory bananaRoute = getBananaRouteFromPid[pid];

        if (bananaRoute.toAddress == address(0)) {
            if (revert_) {
                revert("BananaAllocator: No configured route found");
            } else {
                return;
            }
        }

        uint256 pendingRewards = masterApe.pendingBanana(pid, address(this));
        if (pendingRewards < bananaRoute.minimumBanana) {
            if (revert_) {
                revert("BananaAllocator: not enough rewards");
            } else {
                return;
            }
        }

        uint256 balanceBefore = bananaToken.balanceOf(address(this));
        masterApe.deposit(pid, 0);
        uint256 newTokens = bananaToken.balanceOf(address(this)) - balanceBefore;

        if (bananaRoute.actionId == ActionId.SIMPLE) {
            //Simple transfer on same chain
            bananaToken.transfer(bananaRoute.toAddress, newTokens);
        } else if (bananaRoute.actionId == ActionId.BRIDGE) {
            //anyswap/multichain bridging to different address
            bananaToken.approve(address(anyswapRouter), newTokens);
            anyswapRouter.anySwapOutUnderlying(anyBanana, bananaRoute.toAddress, newTokens, bananaRoute.chainId);
        }
        emit MovedBanana(pid, newTokens, bananaRoute.toAddress, bananaRoute.chainId);
    }

    /// @notice Add a banana route
    /// @param farmPid farm pid
    /// @param toAddress address the banana should transfer to
    /// @param actionId action id
    /// @param chainId chain id for cross chain banana transfers
    /// @param minimumBanana minimum banana collected to activate banana transfer
    function addBananaRoute(
        uint256 farmPid,
        address toAddress,
        ActionId actionId,
        uint256 chainId,
        uint256 minimumBanana
    ) external onlyOwner {
        if (actionId == ActionId.BRIDGE)
            require(chainId != 0 && chainId != block.chainid, "BananaAllocator: wrong settings");

        require(toAddress != address(0), "BananaAllocator: Can't send to null address");
        BananaRoute memory tempRoute = getBananaRouteFromPid[farmPid];
        require(tempRoute.toAddress == address(0), "BananaAllocator: Banana route with this pid already exists");

        getBananaRouteFromPid[farmPid] = BananaRoute(toAddress, actionId, chainId, minimumBanana);
        bananaRoutesSet.add(farmPid);
        emit AddedBananaRoute(farmPid, toAddress, actionId, chainId, minimumBanana);
    }

    /// @notice remove a banana route by pid
    /// @param pid pid of banana route to remove
    function removeBananaRoutePid(uint256 pid) external onlyOwner {
        require(bananaRoutesSet.contains(pid), "BananaAllocator: pid not found");
        bananaRoutesSet.remove(pid);
        delete getBananaRouteFromPid[pid];
        emit RemovedBananaRoute(pid);
    }

    /// @notice stake into masterApe farm
    /// @param pid pid of farm to stake in
    function stakeFarm(uint256 pid) external onlyOwner {
        (address farmToken, , , , , , ) = masterApe.getPoolInfo(pid);
        uint256 balance = IERC20(farmToken).balanceOf(address(this));
        require(balance > 0, "BananaAllocator: no tokens to stake");
        IERC20(farmToken).approve(address(masterApe), balance);
        masterApe.deposit(pid, balance);
    }

    /// @notice unstake from masterApe farm
    /// @param pid pid of farm to unstake from
    function unstakeFarm(uint256 pid) external onlyOwner {
        (uint256 balance, ) = masterApe.userInfo(pid, address(this));
        masterApe.withdraw(pid, balance);
    }

    /// @notice emergency unstake from masterApe farm
    /// @param pid pid of farm to unstake from
    function emergencyUnstakeFarm(uint256 pid) external onlyOwner {
        masterApe.emergencyWithdraw(pid);
    }

    /// @notice Change the minimum banana that needs to be collected to active banana transfer
    /// @param pid pid of farm
    /// @param newMinimum new banana minimum
    function changeMinimumBanana(uint256 pid, uint256 newMinimum) external onlyOwner {
        BananaRoute storage bananaRoute = getBananaRouteFromPid[pid];
        bananaRoute.minimumBanana = newMinimum;
        emit ChangedBananaMinimum(pid, newMinimum);
    }
}