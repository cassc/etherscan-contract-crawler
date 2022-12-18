// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import {IPiemeVault, IPiemeRewardVault, PiemeVault, PiemeRewardVault} from "./PiemeRewardVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {SignatureCheckerUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";

interface IERC20Meta {
    function decimals() external view returns (uint8);
}

contract PiemeStakingV2 is OwnableUpgradeable, EIP712Upgradeable {
    using Counters for Counters.Counter;

    IERC20 public token;
    IUniswapV2Pair public lppair;
    IUniswapV2Router02 public router;
    IERC20 public sttoken;
    address public treasure;

    string public constant NAME = "PIEME Staking";
    bytes32 public constant OPENREFERRAL_ENCODED_TYPE =
        0x9551f56e9560b130cd0177dabd295a0f56a7215d48d0827a4abdb8fe78363099;
    uint256 public constant ST_REF_MIN = 300;

    uint256 public constant MONTHS6 = 180 days;
    uint256 public constant MONTHS12 = 360 days;

    uint256 public constant HUNDRED = 100 * 1e16;
    uint256 public constant MONTHS0P = 96 * 1e16;
    uint256 public constant MONTHS6P = 12 * 1e16;
    uint256 public constant MONTHS12P = 6 * 1e16;

    uint256 public constant SWAPP = 30 * 1e16;
    uint256 public constant LIQP = 20 * 1e16;
    uint256 public constant BURNP = 35 * 1e16;
    uint256 public constant RWDP = 95 * 1e16;
    uint256 public constant RWDREF = 5 * 1e16;

    address private constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;
    address private constant PANCAKE_ROUTER =
        0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    //MAIN ROUTER:  0x10ED43C718714eb63d5aA57B78B54704E256024E;
    struct Position {
        uint256 amount;
        uint256 openCumulativeReward;
        address owner;
        uint48 opened;
        uint48 closed;
        uint256 returned;
        address referral;
        uint256 refreward;
    }

    mapping(bytes32 => Position) public positions;
    mapping(address => bytes32[]) public positionsOf;

    uint256 public staked;

    Counters.Counter private _posCounter;

    address public signer;
    IPiemeRewardVault public rewardVault;
    IPiemeVault public referralVault;
    bytes32[] public referrals;
    uint256 public refsum;

    //liquidity providers
    mapping(address => uint256) public liquidityProviders;
    uint256 public liquiditySum;

    //pie swappers
    mapping(address => uint256) public pieSwappers;

    event PositionOpened(bytes32, uint256, address, uint48);
    event PositionRefered(bytes32, address, address, uint256, uint256);
    event PositionClosed(
        bytes32,
        uint256,
        uint256,
        address,
        uint48,
        uint48,
        uint256
    );
    event FeeDistributed(uint256, uint256, uint256, uint256);
    event RewardClaimed(bytes32, address, uint256);
    event TreasureSet(address, address);
    event SetSigner(address, address);
    event RewardVaultChanged(address, address);

    /**
     * @dev See {__PiemeStaking_init}.
     */
    function initialize(
        address token_,
        address sttoken_,
        address treasure_,
        address signer_
    ) external virtual initializer {
        __PiemeStaking_init(
            token_,
            sttoken_,
            treasure_,
            signer_,
            PANCAKE_ROUTER
        );
    }

    /**
     * @dev See {__PiemeStaking_init_unchained}.
     */
    function __PiemeStaking_init(
        address token_,
        address sttoken_,
        address treasure_,
        address signer_,
        address router_
    ) internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __EIP712_init_unchained(NAME, "1");
        __PiemeStaking_init_unchained(
            token_,
            sttoken_,
            treasure_,
            signer_,
            router_
        );
    }

    /**
     * @dev Set the native and liquidity pool token addresses.
     */
    function __PiemeStaking_init_unchained(
        address token_,
        address sttoken_,
        address treasure_,
        address signer_,
        address router_
    ) internal onlyInitializing {
        require(
            token_ != address(0) &&
                sttoken_ != address(0) &&
                treasure_ != address(0),
            "!address"
        );
        router = IUniswapV2Router02(router_);
        token = IERC20(token_);
        sttoken = IERC20(sttoken_);
        lppair = IUniswapV2Pair(
            IUniswapV2Factory(router.factory()).getPair(token_, sttoken_)
        );
        setTreasure(treasure_);
        setSigner(signer_);
        rewardVault = new PiemeRewardVault(token_, treasure_);
        referralVault = new PiemeVault(token_, treasure_);
        //
    }

    /**
     * @dev Sets treasure address
     * @param treasure_ Treasure address
     */
    function setTreasure(address treasure_) public onlyOwner {
        require(treasure_ != address(0), "!address");
        treasure = treasure_;
        emit TreasureSet(_msgSender(), treasure_);
    }

    /**
     * @dev Admin adds those that have swapped
     * @param pieAmount amount they swapped
     * @param to Owner address
     */
    function addSwappers(
        uint256 pieAmount,
        address to
    ) external onlyOwner returns (bytes32) {
        return _openPosition(to, pieAmount, block.timestamp);
    }

    /**
     * @dev Updates signer address.
     *
     * @param signer_ A new signer address
     * Emits a {SetSigner} event.
     */
    function setSigner(address signer_) public onlyOwner {
        require(signer != signer_, "!address");
        signer = signer_;
        emit SetSigner(_msgSender(), signer_);
    }


     /**
     * @dev Withdraws funds.
     *
     * @param to Transfer funds to address
     * @param amount Transfer amount
     * Emits a {Withdrawn} event.
     */
    function withdraw(address to, uint256 amount) public onlyOwner {
        require(
            _msgSender() == owner() ,
            "!owner"
        );
        require(sttoken.transfer(to, amount), "!transfer");
        
    }

    /**
     * @dev Renew reward vault.
     *
     * Emits a {RewardVaultChanged} event.
     */
    function renewRewardVault() public onlyOwner {
        rewardVault = new PiemeRewardVault(address(token), treasure);
        emit RewardVaultChanged(_msgSender(), address(rewardVault));
    }

    /**
     * @dev Generate user positio id
     * @param to User address
     * @param cnt Inteterger
     * @return hash
     */
    function generateId(address to, uint256 cnt) public view returns (bytes32) {
        return keccak256(abi.encode(address(this), to, cnt));
    }

    /**
     * @dev Gets current reward balance
     * @return Amount
     */
    function rewards() public view returns (uint256) {
        return token.balanceOf(address(rewardVault));
    }

    function getSwapped(address from) external view returns (uint256) {
        return pieSwappers[from];
    }

    /**
     * @dev Gets staking summary of user opened positions
     * @param to User address
     * @return staked_
     */
    function stakedOf(address to) public view returns (uint256 staked_) {
        bytes32[] storage poss = positionsOf[to];
        for (uint256 i = 0; i < poss.length; ) {
            Position storage pos = positions[poss[i]];
            if (pos.closed == 0) {
                staked_ += pos.amount;
            }
            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev Gets user open position ids
     * @param to User address
     * @return ids
     */
    function openPositionsOf(
        address to
    ) external view returns (bytes32[] memory ids) {
        bytes32[] storage poss = positionsOf[to];
        uint256 count = _countPositions(poss, true);
        return _copyPositions(poss, true, count);
    }

    // /**
    //  * @dev Gets user close position ids
    //  * @param to User address
    //  * @return ids
    //  */
    // function closePositionsOf(
    //     address to
    // ) external view returns (bytes32[] memory ids) {
    //     bytes32[] storage poss = positionsOf[to];
    //     uint256 count = _countPositions(poss, false);
    //     return _copyPositions(poss, false, count);
    // }

    function _countPositions(
        bytes32[] memory poss,
        bool opened
    ) internal view returns (uint256 count) {
        for (uint256 i = 0; i < poss.length; ) {
            Position storage pos = positions[poss[i]];
            if (
                (opened && (pos.closed == 0)) || (!opened && !(pos.closed == 0))
            ) {
                unchecked {
                    count++;
                }
            }
            unchecked {
                i++;
            }
        }
    }

    function _copyPositions(
        bytes32[] memory poss,
        bool opened,
        uint256 count
    ) internal view returns (bytes32[] memory ids) {
        ids = new bytes32[](count);
        count = 0;
        for (uint256 i = 0; i < poss.length; ) {
            Position storage pos = positions[poss[i]];
            if (
                (opened && (pos.closed == 0)) || (!opened && !(pos.closed == 0))
            ) {
                ids[count] = poss[i];
                unchecked {
                    count++;
                }
            }
            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev Estimates user rewards
     * @param to User address
     * @return amount
     */
    function estimateRewards(
        address to,
        uint256 when
    ) external view returns (uint256 amount) {
        bytes32[] storage poss = positionsOf[to];
        for (uint256 i = 0; i < poss.length; ) {
            amount += estimateReward(poss[i], when);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev Estimates position return
     * @param id Hash
     * @return amount
     */
    function estimateReward(
        bytes32 id,
        uint256 when
    ) public view returns (uint256) {
        Position storage pos = positions[id];
        if (pos.opened == 0 || pos.closed != 0) return 0;
        return _estimateReward(pos.amount, pos.openCumulativeReward, when);
    }

    function _estimateReward(
        uint256 amount,
        uint256 openCumulativeReward,
        uint256 when
    ) internal view returns (uint256) {
        (, uint256 cumulativeReward) = rewardVault.estimate(staked, when);
        return
            ((cumulativeReward - openCumulativeReward) * amount * RWDP) /
            HUNDRED /
            1e18;
    }

    function _addCumulativeReward(uint256 rewardAmount) internal {
        require(
            token.transfer(address(rewardVault), rewardAmount),
            "!transfer"
        );
        rewardVault.update(staked > 0 ? staked : type(uint256).max);
    }

    function _subCumulativeReward(address to, uint256 rewardAmount) internal {
        rewardVault.withdraw(to, rewardAmount);
        rewardVault.update(staked > 0 ? staked : type(uint256).max);
    }

    /**
     * @dev Estimates user returns
     * @param to User address
     * @param when Timestamp
     * @return amount
     */
    function estimateReturns(
        address to,
        uint256 when
    ) external view returns (uint256 amount) {
        bytes32[] storage poss = positionsOf[to];
        for (uint256 i = 0; i < poss.length; ) {
            amount += estimateReturn(poss[i], when);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev Estimates position return
     * @param id Hash
     * @param when Timestamp
     * @return amount
     */
    function estimateReturn(
        bytes32 id,
        uint256 when
    ) public view returns (uint256) {
        Position storage pos = positions[id];
        if (pos.opened == 0 || pos.opened > when || pos.closed != 0) return 0;
        return estimateAmountReturn(pos.amount, when - pos.opened);
    }

    /**
     * @dev Estimates amount return
     * @param amount Token amount
     * @param duration In seconds
     * @return returned Amount
     */
    function estimateAmountReturn(
        uint256 amount,
        uint256 duration
    ) public pure returns (uint256 returned) {
        if (duration < MONTHS6) {
            returned = __estimateReturn(
                amount,
                duration,
                MONTHS6,
                MONTHS6P,
                MONTHS0P
            );
        } else if (duration < MONTHS12) {
            returned = __estimateReturn(
                amount,
                duration - MONTHS6,
                MONTHS6,
                MONTHS12P,
                MONTHS6P
            );
        } else {
            //logic for 20% for each month
            returned = (amount * (HUNDRED - MONTHS12P)) / 1e18;
        }
    }

    function __estimateReturn(
        uint256 amount,
        uint256 duration,
        uint256 period,
        uint256 percentMin,
        uint256 percentMax
    ) private pure returns (uint256) {
        uint256 percentFee = ((percentMax - percentMin) * (period - duration)) /
            period;
        return (amount * (HUNDRED - (percentMin + percentFee))) / 1e18;
    }

    /**
     * @dev Estimates user position closes
     * @param to User address
     * @param when Timestamp
     * @return amount
     */
    function estimateCloses(
        address to,
        uint256 when
    ) external view returns (uint256 amount) {
        bytes32[] storage poss = positionsOf[to];
        for (uint256 i = 0; i < poss.length; ) {
            amount += estimateClose(poss[i], when);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev Estimates position close
     * @param id Hash
     * @param when Timestamp
     * @return amount
     */
    function estimateClose(
        bytes32 id,
        uint256 when
    ) public view returns (uint256) {
        Position storage pos = positions[id];
        if (pos.opened == 0 || pos.opened > when || pos.closed != 0) return 0;
        (uint256 _return, uint256 _reward) = _estimateClose(
            pos.amount,
            pos.openCumulativeReward,
            pos.opened,
            when
        );
        return _return + _reward;
    }

    function _estimateClose(
        uint256 amount,
        uint256 openCumulativeReward,
        uint256 opened,
        uint256 closed
    ) internal view returns (uint256 _return, uint256 _reward) {
        _return = estimateAmountReturn(amount, closed - opened);
        _reward = _estimateReward(amount, openCumulativeReward, closed);
    }

    /**
     * @dev Opens user position
     * @param amount to be staked
     * @return Position id
     */
    function openPosition(uint256 amount) public returns (bytes32) {
        require(amount >= 1000, "!amount");
        return _openPositionN(_msgSender(), amount, block.timestamp);
    }

    function _openPositionN(
        address to,
        uint256 amount,
        uint256 when
    ) internal returns (bytes32 id) {
        uint256 cnt = _posCounter.current();
        _posCounter.increment();
        id = generateId(to, cnt);
        Position storage pos = positions[id];
        require(pos.opened == 0, "!id");
        staked += amount;
        rewardVault.update(staked);
        pos.amount = amount;
        pos.openCumulativeReward = rewardVault.cumulativeReward();
        pos.owner = to;
        pos.opened = uint48(when);
        positionsOf[to].push(id);
        require(token.transferFrom(to, address(this), amount), "!transfer");
        pieSwappers[to] += amount;
        emit PositionOpened(id, amount, to, pos.opened);
    }

    /**
     * @dev Gets Liquidity Balance
     */
    function _openPosition(
        address to,
        uint256 amount,
        uint256 when
    ) internal returns (bytes32 id) {
        uint256 cnt = _posCounter.current();
        _posCounter.increment();
        id = generateId(to, cnt);
        Position storage pos = positions[id];
        require(pos.opened == 0, "!id");
        staked += amount;
        rewardVault.update(staked);
        pos.amount = amount;
        pos.openCumulativeReward = rewardVault.cumulativeReward();
        pos.owner = to;
        pos.opened = uint48(when);
        positionsOf[to].push(id);

        //send the tokens to the contract
        // if (pay) {
        //     require(token.transferFrom(to, address(this), amount), "!transfer");
        // }
        pieSwappers[to] += amount;
        emit PositionOpened(id, amount, to, pos.opened);
    }

    /**
     * @dev Closes user positions
     */
    // function closePositions() external {
    //     bytes32[] storage poss = positionsOf[_msgSender()];
    //     bool closed = false;
    //     for (uint256 i = 0; i < poss.length; ) {
    //         if (positions[poss[i]].closed == 0) {
    //             _closePosition(_msgSender(), poss[i], block.timestamp);
    //             closed = true;
    //         }
    //         unchecked {
    //             i++;
    //         }
    //     }
    //     require(closed, "!nothing");
    // }

    // /**
    //  * @dev Closes user position
    //  * @param id Position id
    //  */
    // function closePosition(bytes32 id) external {
    //     _closePosition(_msgSender(), id, block.timestamp);
    // }

    // function _closePosition(address to, bytes32 id, uint256 when) internal {
    //     Position storage pos = positions[id];
    //     require(pos.owner == to, "!owner");
    //     require(pos.closed == 0, "!closed");
    //     pos.closed = uint48(when);
    //     (uint256 _return, uint256 _reward) = _estimateClose(
    //         pos.amount,
    //         pos.openCumulativeReward,
    //         pos.opened,
    //         pos.closed
    //     );
    //     pos.returned += _return + _reward;
    //     staked -= pos.amount;
    //     _subCumulativeReward(to, _reward);
    //     require(token.transfer(to, _return), "!transfer");
    //     if (pos.amount > pos.returned + 1000) {
    //         _distributeFee(pos.amount - pos.returned, when);
    //     }
    //     require(rewards() > 0, "!balance");
    //     emit PositionClosed(
    //         id,
    //         pos.amount,
    //         pos.openCumulativeReward,
    //         to,
    //         pos.opened,
    //         pos.closed,
    //         pos.returned
    //     );
    // }

    function _distributeFee(uint256 amount, uint256 when) internal {
        uint256 deadline = when + 1000;
        uint256 swapTreasureAmount = (amount * SWAPP) / HUNDRED; // 30% = 60% of 50%)
        uint256 liquidityAmount = (amount * LIQP) / HUNDRED; // 20% = 40% of 50%)
        require(
            token.approve(
                address(router),
                swapTreasureAmount + liquidityAmount
            ),
            "!approve"
        );
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(sttoken);
        uint256 swapAmount = swapTreasureAmount + liquidityAmount / 2;
        uint256[] memory amounts = router.swapExactTokensForTokens(
            swapAmount,
            1,
            path,
            address(this),
            deadline
        );
        require(amounts[0] == swapAmount && amounts[1] > 0, "!swap");
        uint256 transferTreasureAmount = (amounts[1] * swapTreasureAmount) /
            swapAmount;
        require(
            sttoken.transfer(treasure, transferTreasureAmount),
            "!transfer"
        );
        require(
            sttoken.approve(
                address(router),
                amounts[1] - transferTreasureAmount
            ),
            "!approve"
        );
        router.addLiquidity(
            path[0],
            path[1],
            liquidityAmount / 2,
            amounts[1] - transferTreasureAmount,
            1,
            1,
            treasure,
            deadline
        );
        uint256 burnAmount = (amount * BURNP) / HUNDRED; // 35% = 70% of 50%)
        require(token.transfer(BURN_ADDRESS, burnAmount), "!transfer");
        uint256 rewardAmount = amount -
            swapAmount -
            liquidityAmount -
            burnAmount;
        _addCumulativeReward(rewardAmount);
        emit FeeDistributed(
            swapAmount,
            liquidityAmount,
            burnAmount,
            rewardAmount
        );
    }

    /**
     * @dev Claim user rewards
     */
    function claimRewards() external {
        bytes32[] storage poss = positionsOf[_msgSender()];
        bool claimed = false;
        for (uint256 i = 0; i < poss.length; ) {
            if (positions[poss[i]].closed == 0) {
                uint256 reward = _claimReward(_msgSender(), poss[i]);
                if (reward > 0) claimed = true;
            }
            unchecked {
                i++;
            }
        }
        require(claimed, "!nothing");
    }

    /**
     * @dev Claim user position reward
     * @param id Position id
     */
    function claimReward(bytes32 id) external {
        require(_claimReward(_msgSender(), id) > 0, "!nothing");
    }

    function _claimReward(
        address to,
        bytes32 id
    ) internal returns (uint256 reward) {
        Position storage pos = positions[id];
        require(pos.owner == to, "!owner");
        require(pos.closed == 0, "!closed");
        reward = _estimateReward(
            pos.amount,
            pos.openCumulativeReward,
            block.timestamp
        );
        if (reward > 0) {
            _subCumulativeReward(to, reward);
            pos.openCumulativeReward = rewardVault.cumulativeReward();
            pos.returned += reward;
            emit RewardClaimed(id, to, reward);
        }
    }
}