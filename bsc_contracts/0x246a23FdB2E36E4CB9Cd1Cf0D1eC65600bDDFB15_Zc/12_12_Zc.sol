// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interface/IPancakePair.sol";
import "./Rel.sol";
import "./library/Utility.sol";

contract Zc {
    using SafeERC20 for ERC20;
    using BitMaps for BitMaps.BitMap;
    using Address for address;

    event NewPool(uint256 indexed id, uint256 cap, uint64 start);
    event BuyPoints(
        address indexed user,
        uint256 amount,
        uint256 price,
        uint256 points
    );
    event NetAddPoints(
        address indexed user,
        address indexed buyer,
        uint256 tier,
        uint256 points
    );
    event Deposit(address indexed user, uint256 amount);
    event SwapPoints(
        address indexed user,
        uint256 amount,
        uint256 points,
        uint256 presentPoints
    );
    event SwapPoints2(
        address indexed user,
        uint256 amount,
        uint256 price,
        uint256 points
    );
    event StakeSubPoints(
        address indexed user,
        uint256 indexed poolId,
        uint256 indexed issue,
        uint256 points,
        uint256 luckyPoints
    );
    event NetSubPoints(
        address indexed user,
        address stakeUser,
        uint256 indexed poolId,
        uint256 indexed issue,
        uint256 tier,
        uint256 points,
        uint256 luckyPoints
    );
    event Stake(
        address indexed user,
        uint256 indexed poolId,
        uint256 indexed issue,
        uint256 amount
    );
    event Save(
        uint256 indexed poolId,
        uint128 indexed issueNo,
        address indexed safe,
        uint256 amount
    );
    event NewIssue(
        uint256 indexed poolId,
        uint128 indexed issueNo,
        uint256 issueCap,
        uint256 totalAmount
    );
    event Withdraw(address indexed user, uint256 amount, uint256 actualAmount);
    event WithdrawToken(
        address indexed user,
        uint256 amount,
        uint256 actualAmount
    );
    event Withdraw2(address indexed safe, uint256 amount);

    event WriteOff(address indexed user, uint256 amount, uint256 luckyPoint);

    event Checkout(
        address indexed buyer,
        uint256 indexed orderNo,
        address seller,
        uint256 amount,
        uint256 luckyPointAmount
    );
    event Confirm(
        address indexed buyer,
        uint256 indexed orderNo,
        address seller,
        uint256 amount,
        uint256 luckyPointAmount
    );
    event Refund(
        address indexed buyer,
        uint256 indexed orderNo,
        address seller,
        uint256 amount,
        uint256 luckyPointAmount
    );

    struct Pool {
        uint256 initCap;
        uint64 startTime;
        uint128 currIssue;
        bool blowUp;
        uint256 currCap;
        uint256 currIssueAmount;
        uint256 totalAmount;
    }
    struct Order {
        address buyer;
        address seller;
        uint64 status;
        uint256 amount;
        uint256 luckyPointAmount;
    }

    uint64 public constant ISSUE_PERIOD = 1 hours;
    uint32 public constant ISSUE_PER_ROUND = 7;
    uint256 public constant ROUND_RATE = 25;
    uint256 public constant INTEREST_RATE = 98;
    uint256 public constant MIN_AMOUNT = 0.5 ether;
    Rel public rel;
    ERC20 public pointToken;
    IPancakePair public pair;
    ERC20 public usdtToken;
    Pool[] public pools;
    address public pja;
    address public pjb;
    address public pjc;
    address private adm;
    address public safeAddress;
    address public colSafeAddress;
    mapping(address => uint256) balancePerUser;
    mapping(address => uint256) pointsPerUser;
    mapping(address => uint256) luckyPointsPerUser;
    BitMaps.BitMap private firstPerIssue;
    mapping(address => mapping(uint256 => mapping(uint128 => uint256)))
        public amountPerUser;
    mapping(address => mapping(uint256 => uint256)) public stakingPerUser;
    mapping(address => mapping(uint256 => mapping(uint128 => uint256)))
        public netInterestPerUser;
    mapping(address => mapping(uint256 => uint128))
        public lastIssueUpdatePerUser;
    mapping(uint256 => uint128) public lastSaveIssuePerPool;
    mapping(address => uint256) public tokenPerUser;
    mapping(address => uint256) public unwithdrawPerUser;
    BitMaps.BitMap private userSwaped;
    mapping(uint256 => Order) public orders;

    constructor(
        address r,
        address t,
        address pr,
        address a,
        address b,
        address c,
        address ad,
        address s,
        address s2
    ) {
        rel = Rel(r);
        rel.setPool(address(this));
        pointToken = ERC20(t);
        pair = IPancakePair(pr);
        usdtToken = ERC20(0x55d398326f99059fF775485246999027B3197955);
        pja = a;
        pjb = b;
        pjc = c;
        adm = ad;
        safeAddress = s;
        colSafeAddress = s2;
        uint256 cap = 10 ether;
        Pool memory p = Pool(cap, 1679479200, 1, false, cap, 0, 0);
        pools.push(p);
        emit NewPool(0, cap, 1679479200);
    }

    function newPool(uint256 cap, uint64 start) external {
        require(msg.sender == adm, "not allowed");
        Pool memory p = Pool(cap, start, 1, false, cap, 0, 0);
        pools.push(p);
        emit NewPool(pools.length - 1, cap, start);
    }

    function buyPoints(uint256 amount) external {
        require(!msg.sender.isContract(), "can't be contract");
        require(rel.parents(msg.sender) != address(0), "not bind");
        checkPoolBlowUp();
        require(
            pointToken.balanceOf(msg.sender) >= amount,
            "balance not enough"
        );
        uint256 a = amount / 10;
        tokenPerUser[pja] += a;
        tokenPerUser[pjb] += a * 5;
        uint256 cost = a + a * 5;
        a = a / 10;
        address p = msg.sender;
        for (uint256 i = 1; i <= 10; ++i) {
            p = rel.parents(p);
            if (p != address(0) && p != address(1)) {
                uint256 t = Utility.netPoints(i, a);
                tokenPerUser[p] += t;
                emit NetAddPoints(p, msg.sender, i, t);
                cost += t;
            } else {
                break;
            }
        }
        pointToken.safeTransferFrom(msg.sender, address(this), cost);
        if (amount > cost) {
            pointToken.safeTransferFrom(msg.sender, address(1), amount - cost);
        }
        uint256 level = rel.levelPerUser(msg.sender);
        if (level == 0) {
            rel.setLevel(msg.sender, 1);
            p = rel.parents(msg.sender);
            if (p != address(0) && p != address(1)) {
                rel.updateCountPerLevel(p, 0, 1);
                if (
                    rel.levelPerUser(p) == 1 &&
                    rel.countPerLevelPerUser(p, 1) >= 5
                ) {
                    rel.setLevel(p, 2);
                    p = rel.parents(p);
                    if (p != address(0) && p != address(1)) {
                        rel.updateCountPerLevel(p, 1, 2);
                        if (
                            rel.levelPerUser(p) == 2 &&
                            rel.countPerLevelPerUser(p, 2) >= 5
                        ) {
                            rel.setLevel(p, 3);
                            p = rel.parents(p);
                            if (p != address(0) && p != address(1)) {
                                rel.updateCountPerLevel(p, 2, 3);
                                if (
                                    rel.levelPerUser(p) == 3 &&
                                    rel.countPerLevelPerUser(p, 3) >= 3
                                ) {
                                    rel.setLevel(p, 4);
                                    p = rel.parents(p);
                                    if (p != address(0) && p != address(1)) {
                                        rel.updateCountPerLevel(p, 3, 4);
                                        if (
                                            rel.levelPerUser(p) == 4 &&
                                            rel.countPerLevelPerUser(p, 4) >= 3
                                        ) {
                                            rel.setLevel(p, 5);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 price = (reserve0 * 1 ether) / reserve1;
        uint256 points = (price * amount * 4) / 1 ether;
        pointsPerUser[msg.sender] += points;
        emit BuyPoints(msg.sender, amount, price, points);
        fullToSafe();
    }

    function deposit(uint256 amount) external {
        require(!msg.sender.isContract(), "can't be contract");
        require(rel.parents(msg.sender) != address(0), "not bind");
        checkPoolBlowUp();
        usdtToken.safeTransferFrom(msg.sender, address(this), amount);
        (
            uint256 balance,
            uint256 luckyPoints,
            uint256[] memory stakingAmount,
            uint128[] memory lastUpdate
        ) = calBalance(msg.sender);
        updateLast(msg.sender, stakingAmount, lastUpdate);
        updateBalanceLuckyPoints(msg.sender, balance + amount, luckyPoints);
        unwithdrawPerUser[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
        fullToSafe();
    }

    function amountByIssue(
        uint256 poolId,
        uint256 issueNo
    ) public view returns (uint256) {
        Pool memory pool = pools[poolId];
        uint256 m = issueNo / ISSUE_PER_ROUND;
        if (issueNo % ISSUE_PER_ROUND == 0 && m > 0) {
            --m;
        }
        uint256 amount = pool.initCap;
        for (uint256 i = 0; i < m; ++i) {
            amount += (amount * ROUND_RATE) / 100;
        }
        return amount;
    }

    function checkPoolBlowUp() private {
        uint256 issue = block.timestamp / ISSUE_PERIOD;
        if (!firstPerIssue.get(issue)) {
            for (uint256 i = 0; i < pools.length; ++i) {
                Pool memory p = pools[i];
                if (p.startTime <= block.timestamp && !p.blowUp) {
                    uint256 actualIssue = (block.timestamp - p.startTime) /
                        ISSUE_PERIOD +
                        1;
                    if (actualIssue > p.currIssue) {
                        pools[i].blowUp = true;
                    }
                }
            }
            firstPerIssue.set(issue);
        }
    }

    function checkLevelCap(
        address user,
        uint256[] memory stakingAmount,
        uint256 amount
    ) public view returns (bool result) {
        uint256 staking = amount;
        for (uint256 i = 0; i < stakingAmount.length; ++i) {
            staking += stakingAmount[i];
        }
        uint256 level = rel.levelPerUser(user);
        result = Utility.checkLevelCap(level, staking);
    }

    function calInterest(uint256 amount) private pure returns (uint256) {
        return (amount * INTEREST_RATE) / 1000;
    }

    function calBlowUpFirst(uint256 amount) private pure returns (uint256) {
        return (amount * 7) / 10;
    }

    function calBlowUpFirstLucky(
        uint256 amount
    ) private pure returns (uint256) {
        return (amount * 12) / 10;
    }

    function blowUpCal(
        address user,
        uint256 i,
        Pool memory p
    ) private view returns (uint256 sum, uint256 lucky) {
        uint256 last4sum;
        uint256 last4total = p.currIssueAmount;
        for (uint256 k = 0; k <= 6 && p.currIssue > k; ++k) {
            if (k <= 3) {
                sum += amountPerUser[user][i][uint128(p.currIssue - k)];
                last4sum += amountPerUser[user][i][uint128(p.currIssue - k)];
                if (k != 0) {
                    last4total += amountByIssue(i, p.currIssue - k);
                }
            } else {
                sum += calBlowUpFirst(
                    amountPerUser[user][i][uint128(p.currIssue - k)]
                );
                lucky += calBlowUpFirstLucky(
                    amountPerUser[user][i][uint128(p.currIssue - k)]
                );
            }
        }
        if (last4total > 0) {
            lucky +=
                (last4sum * p.totalAmount * INTEREST_RATE) /
                1000 /
                4 /
                last4total;
        }
        if (p.currIssue > 7) {
            for (
                uint256 j = lastIssueUpdatePerUser[user][i] + 1;
                j <= p.currIssue - 7;
                ++j
            ) {
                uint256 sa = amountPerUser[user][i][uint128(j)];
                sum += sa;
                sum += calInterest(sa);
                sum += netInterestPerUser[user][i][uint128(j)];
            }
        }
    }

    function userBalance(
        address user
    )
        public
        view
        returns (
            uint256 balance,
            uint256 points,
            uint256 luckyPoints,
            uint256 stakingAmount
        )
    {
        uint256 sum;
        uint256 lucky;
        for (uint256 i = 0; i < pools.length; ++i) {
            Pool memory p = pools[i];
            if (block.timestamp < p.startTime) {
                continue;
            }
            uint128 actualIssue = uint128(
                (uint64(block.timestamp) - p.startTime) / ISSUE_PERIOD + 1
            );
            bool blowUp = p.blowUp;
            if (p.startTime <= block.timestamp && !blowUp) {
                if (actualIssue > p.currIssue) {
                    blowUp = true;
                }
            }
            if (blowUp && lastIssueUpdatePerUser[user][i] < p.currIssue) {
                (uint256 sum1, uint256 lucky1) = blowUpCal(user, i, p);
                sum += sum1;
                lucky += lucky1;
            } else {
                if (
                    actualIssue > 8 &&
                    lastIssueUpdatePerUser[user][i] + 1 <= actualIssue - 8
                ) {
                    uint256 sa;
                    for (
                        uint256 j = lastIssueUpdatePerUser[user][i] + 1;
                        j <= actualIssue - 8;
                        ++j
                    ) {
                        sa += amountPerUser[user][i][uint128(j)];
                        sum += sa;
                        sum += calInterest(sa);
                        sum += netInterestPerUser[user][i][uint128(j)];
                    }
                    stakingAmount += stakingPerUser[user][i] - sa;
                } else {
                    stakingAmount += stakingPerUser[user][i];
                }
            }
        }
        balance = balancePerUser[user] + sum;
        points = pointsPerUser[user];
        luckyPoints = luckyPointsPerUser[user] + lucky;
    }

    function calBalance(
        address user
    )
        private
        view
        returns (
            uint256 balance,
            uint256 luckyPoints,
            uint256[] memory stakingAmount,
            uint128[] memory lastUpdate
        )
    {
        uint256 sum;
        uint256 lucky;
        lastUpdate = new uint128[](pools.length);
        stakingAmount = new uint256[](pools.length);
        for (uint256 i = 0; i < pools.length; ++i) {
            Pool memory p = pools[i];
            if (block.timestamp < p.startTime) {
                continue;
            }
            uint128 actualIssue = uint128(
                (uint64(block.timestamp) - p.startTime) / ISSUE_PERIOD + 1
            );
            if (p.blowUp && lastIssueUpdatePerUser[user][i] < p.currIssue) {
                (uint256 sum1, uint256 lucky1) = blowUpCal(user, i, p);
                sum += sum1;
                lucky += lucky1;
                stakingAmount[i] = 0;
                lastUpdate[i] = p.currIssue;
            } else {
                if (
                    actualIssue > 8 &&
                    lastIssueUpdatePerUser[user][i] + 1 <= actualIssue - 8
                ) {
                    uint256 sa;
                    for (
                        uint256 j = lastIssueUpdatePerUser[user][i] + 1;
                        j <= actualIssue - 8;
                        ++j
                    ) {
                        sa += amountPerUser[user][i][uint128(j)];
                        sum += sa;
                        sum += calInterest(sa);
                        sum += netInterestPerUser[user][i][uint128(j)];
                        lastUpdate[i] = uint128(j);
                    }
                    stakingAmount[i] = stakingPerUser[user][i] - sa;
                } else {
                    stakingAmount[i] = stakingPerUser[user][i];
                }
            }
        }
        balance = balancePerUser[user] + sum;
        luckyPoints = luckyPointsPerUser[user] + lucky;
    }

    function stake(uint256 poolId, uint256 amount) external {
        require(!msg.sender.isContract(), "can't be contract");
        checkPoolBlowUp();
        require(poolId < pools.length, "poolId error");
        Pool storage pool = pools[poolId];
        require(
            pool.startTime <= block.timestamp && !pool.blowUp,
            "unavailabled"
        );
        uint256 rest = pool.currCap - pool.currIssueAmount;
        require(amount <= rest, "amount exceeds");
        if (rest < MIN_AMOUNT) {
            require(rest == amount, "amount error");
        } else {
            require(amount % MIN_AMOUNT == 0, "amount must 50x");
        }
        (
            uint256 balance,
            uint256 luckyPoints,
            uint256[] memory stakingAmount,
            uint128[] memory lastUpdate
        ) = calBalance(msg.sender);
        require(balance >= amount, "balance not enough");
        uint256 needPoints = (amount * INTEREST_RATE) / 1000;
        require(
            pointsPerUser[msg.sender] + luckyPoints >= needPoints,
            "points not enough"
        );
        require(
            checkLevelCap(msg.sender, stakingAmount, amount),
            "exceeds level cap"
        );
        for (uint256 i = 0; i < stakingAmount.length; ++i) {
            stakingPerUser[msg.sender][i] = stakingAmount[i];
        }
        if (pointsPerUser[msg.sender] >= needPoints) {
            pointsPerUser[msg.sender] -= needPoints;
            luckyPointsPerUser[msg.sender] = luckyPoints;
            emit StakeSubPoints(
                msg.sender,
                poolId,
                pool.currIssue,
                needPoints,
                0
            );
        } else {
            emit StakeSubPoints(
                msg.sender,
                poolId,
                pool.currIssue,
                pointsPerUser[msg.sender],
                needPoints - pointsPerUser[msg.sender]
            );
            luckyPointsPerUser[msg.sender] =
                luckyPoints -
                (needPoints - pointsPerUser[msg.sender]);
            pointsPerUser[msg.sender] = 0;
        }

        amountPerUser[msg.sender][poolId][pool.currIssue] += amount;
        balancePerUser[msg.sender] = balance - amount;
        stakingPerUser[msg.sender][poolId] += amount;
        for (uint256 i = 0; i < lastUpdate.length; ++i) {
            if (
                lastUpdate[i] > 0 &&
                lastIssueUpdatePerUser[msg.sender][i] != lastUpdate[i]
            ) {
                lastIssueUpdatePerUser[msg.sender][i] = lastUpdate[i];
            }
        }
        emit Stake(msg.sender, poolId, pool.currIssue, amount);
        if (unwithdrawPerUser[msg.sender] >= amount) {
            unwithdrawPerUser[msg.sender] -= amount;
        } else {
            unwithdrawPerUser[msg.sender] = 0;
        }

        subNet(needPoints, poolId, pool);

        pool.currIssueAmount += amount;
        pool.totalAmount += amount;
        fullToSafe();
        if (pool.currIssueAmount == pool.currCap) {
            pool.currIssue++;
            if (pool.currIssue % 7 == 1) {
                pool.currCap += (pool.currCap * 25) / 100;
            }
            pool.currIssueAmount = 0;
            emit NewIssue(
                poolId,
                pool.currIssue,
                pool.currCap,
                pool.totalAmount
            );
        }
    }

    function subNet(
        uint256 needPoints,
        uint256 poolId,
        Pool memory pool
    ) private {
        address p = rel.parents(msg.sender);
        for (
            uint256 i = 1;
            i <= 10 && p != address(0) && p != address(1);
            ++i
        ) {
            uint256 level = rel.levelPerUser(p);
            uint256 np;
            if (level == 0) {
                p = rel.parents(p);
                continue;
            } else if (level == 1) {
                if (i == 1) {
                    np = (needPoints * 15) / 100;
                } else if (i == 2) {
                    np = (needPoints * 5) / 100;
                } else {
                    p = rel.parents(p);
                    continue;
                }
            } else if (level == 2) {
                if (i == 1) {
                    np = (needPoints * 15) / 100;
                } else if (i >= 2 && i <= 4) {
                    np = (needPoints * 5) / 100;
                } else {
                    p = rel.parents(p);
                    continue;
                }
            } else if (level == 3) {
                if (i == 1) {
                    np = (needPoints * 15) / 100;
                } else if (i >= 2 && i <= 6) {
                    np = (needPoints * 5) / 100;
                } else {
                    p = rel.parents(p);
                    continue;
                }
            } else if (level == 4) {
                if (i == 1) {
                    np = (needPoints * 15) / 100;
                } else if (i >= 2 && i <= 8) {
                    np = (needPoints * 5) / 100;
                } else {
                    p = rel.parents(p);
                    continue;
                }
            } else if (level == 5) {
                if (i == 1) {
                    np = (needPoints * 15) / 100;
                } else if (i >= 2 && i <= 10) {
                    np = (needPoints * 5) / 100;
                } else {
                    p = rel.parents(p);
                    continue;
                }
            }
            (
                uint256 balance1,
                uint256 luckyPoints1,
                uint256[] memory stakingAmount1,
                uint128[] memory lastUpdate1
            ) = calBalance(p);
            balancePerUser[p] = balance1;
            updateLast(p, stakingAmount1, lastUpdate1);
            uint256 ap = pointsPerUser[p] + luckyPoints1 >= np
                ? np
                : pointsPerUser[p] + luckyPoints1;
            if (pointsPerUser[p] >= ap) {
                pointsPerUser[p] -= ap;
                luckyPointsPerUser[p] = luckyPoints1;
                emit NetSubPoints(
                    p,
                    msg.sender,
                    poolId,
                    pool.currIssue,
                    i,
                    ap,
                    0
                );
            } else {
                uint256 d = pointsPerUser[p];
                uint256 c = ap - d;
                emit NetSubPoints(
                    p,
                    msg.sender,
                    poolId,
                    pool.currIssue,
                    i,
                    d,
                    c
                );
                luckyPointsPerUser[p] = luckyPoints1 - c;
                pointsPerUser[p] = 0;
            }
            netInterestPerUser[p][poolId][pool.currIssue] += ap;
            p = rel.parents(p);
        }
    }

    function swapPoints(uint256 amount) external {
        require(rel.parents(msg.sender) != address(0), "not bind");
        bool al = userSwaped.get(uint256(uint160(msg.sender)));
        uint256 presentPoints;
        if (!al) {
            require(amount >= 10 ether, "min 10u");
            presentPoints = 40 ether;
            userSwaped.set(uint256(uint160(msg.sender)));
        }
        checkPoolBlowUp();
        (
            uint256 balance,
            uint256 luckyPoints,
            uint256[] memory stakingAmount,
            uint128[] memory lastUpdate
        ) = calBalance(msg.sender);
        require(balance >= amount, "balance not enough");
        updateLast(msg.sender, stakingAmount, lastUpdate);
        updateBalanceLuckyPoints(msg.sender, balance - amount, luckyPoints);
        pointsPerUser[msg.sender] += amount * 4 + presentPoints;
        if (unwithdrawPerUser[msg.sender] >= amount) {
            unwithdrawPerUser[msg.sender] -= amount;
        } else {
            unwithdrawPerUser[msg.sender] = 0;
        }
        emit SwapPoints(msg.sender, amount, amount * 4, presentPoints);
        fullToSafe();
    }

    function swapPoints2(uint256 amount) external {
        require(rel.parents(msg.sender) != address(0), "not bind");
        checkPoolBlowUp();
        (
            uint256 balance,
            uint256 luckyPoints,
            uint256[] memory stakingAmount,
            uint128[] memory lastUpdate
        ) = calBalance(msg.sender);
        require(tokenPerUser[msg.sender] >= amount, "balance not enough");
        updateLast(msg.sender, stakingAmount, lastUpdate);
        updateBalanceLuckyPoints(msg.sender, balance, luckyPoints);
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 price = (reserve0 * 1 ether) / reserve1;
        uint256 points = (price * amount * 4) / 1 ether;
        tokenPerUser[msg.sender] -= amount;
        pointsPerUser[msg.sender] += points;
        emit SwapPoints2(msg.sender, amount, price, points);
        fullToSafe();
    }

    function withdraw(uint256 amount) external {
        checkPoolBlowUp();
        (
            uint256 balance,
            uint256 luckyPoints,
            uint256[] memory stakingAmount,
            uint128[] memory lastUpdate
        ) = calBalance(msg.sender);
        require(balance >= amount, "balance not enough");
        require(
            balance - amount >= unwithdrawPerUser[msg.sender],
            "exceeds available"
        );
        updateLast(msg.sender, stakingAmount, lastUpdate);
        uint256 actualAmount = amount - amount / 100;
        updateBalanceLuckyPoints(msg.sender, balance - amount, luckyPoints);
        usdtToken.safeTransfer(msg.sender, actualAmount);
        usdtToken.safeTransfer(pjc, amount / 100);
        emit Withdraw(msg.sender, amount, actualAmount);
        fullToSafe();
    }

    function withdrawToken(uint256 amount) external {
        require(rel.parents(msg.sender) != address(0), "not bind");
        checkPoolBlowUp();
        require(tokenPerUser[msg.sender] >= amount, "balance not enough");
        uint256 actualAmount = amount - amount / 100;
        pointToken.safeTransfer(msg.sender, actualAmount);
        pointToken.safeTransfer(pjc, amount / 100);
        tokenPerUser[msg.sender] -= amount;
        emit WithdrawToken(msg.sender, amount, actualAmount);
        (
            uint256 balance,
            uint256 luckyPoints,
            uint256[] memory stakingAmount,
            uint128[] memory lastUpdate
        ) = calBalance(msg.sender);
        updateLast(msg.sender, stakingAmount, lastUpdate);
        updateBalanceLuckyPoints(msg.sender, balance, luckyPoints);
        fullToSafe();
    }

    function fullToSafe() private {
        for (uint256 poolId = 0; poolId < pools.length; ++poolId) {
            Pool memory pool = pools[poolId];
            if (block.timestamp < pool.startTime) {
                continue;
            }
            uint128 actualIssue = uint128(
                (uint64(block.timestamp) - pool.startTime) / ISSUE_PERIOD + 1
            );
            if (actualIssue <= pool.currIssue) {
                uint256 last = (actualIssue == pool.currIssue &&
                    pool.currCap > pool.currIssueAmount)
                    ? actualIssue - 1
                    : actualIssue;
                for (
                    uint256 i = lastSaveIssuePerPool[poolId] + 1;
                    i <= last;
                    ++i
                ) {
                    uint256 a = amountByIssue(poolId, i);
                    if (i > ISSUE_PER_ROUND) {
                        a -= amountByIssue(poolId, i - ISSUE_PER_ROUND);
                    }
                    usdtToken.safeTransfer(colSafeAddress, a);
                    lastSaveIssuePerPool[poolId] = uint128(i);
                    emit Save(poolId, uint128(i), colSafeAddress, a);
                }
            }
        }
    }

    function withdraw2(uint256 amount) external {
        checkPoolBlowUp();
        require(msg.sender == safeAddress, "not allowed");
        usdtToken.safeTransfer(msg.sender, amount);
        emit Withdraw2(msg.sender, amount);
    }

    function poolsInfo()
        external
        view
        returns (Pool[] memory ps, uint256[] memory actualIssues)
    {
        ps = new Pool[](pools.length);
        actualIssues = new uint256[](pools.length);
        for (uint256 i = 0; i < pools.length; ++i) {
            ps[i] = pools[i];
            if (ps[i].startTime <= block.timestamp && !ps[i].blowUp) {
                uint256 actualIssue = (block.timestamp - ps[i].startTime) /
                    ISSUE_PERIOD +
                    1;
                actualIssues[i] = actualIssue;
                if (actualIssue > ps[i].currIssue) {
                    ps[i].blowUp = true;
                }
            }
        }
    }

    function updateLast(
        address user,
        uint256[] memory stakingAmount,
        uint128[] memory lastUpdate
    ) private {
        for (uint256 i = 0; i < stakingAmount.length; ++i) {
            stakingPerUser[user][i] = stakingAmount[i];
        }
        for (uint256 i = 0; i < lastUpdate.length; ++i) {
            if (
                lastUpdate[i] > 0 &&
                lastIssueUpdatePerUser[user][i] != lastUpdate[i]
            ) {
                lastIssueUpdatePerUser[user][i] = lastUpdate[i];
            }
        }
    }

    function checkout(
        uint256 orderNo,
        address seller,
        uint256 amount
    ) external {
        checkPoolBlowUp();
        (
            uint256 balance,
            uint256 luckyPoints,
            uint256[] memory stakingAmount,
            uint128[] memory lastUpdate
        ) = calBalance(msg.sender);
        uint256 luckyPointAmount = amount * 4;
        require(luckyPoints >= luckyPointAmount, "not enough");
        updateLast(msg.sender, stakingAmount, lastUpdate);
        updateBalanceLuckyPoints(
            msg.sender,
            balance,
            luckyPoints - luckyPointAmount
        );
        require(orders[orderNo].buyer == address(0), "order existed");
        orders[orderNo] = Order(
            msg.sender,
            seller,
            0,
            amount,
            luckyPointAmount
        );
        emit Checkout(msg.sender, orderNo, seller, amount, luckyPointAmount);
    }

    function confirm(uint256 orderNo) external {
        Order memory order = orders[orderNo];
        require(order.buyer == msg.sender, "order buyer error");
        require(order.status == 0, "status error");
        orders[orderNo].status = 1;
        checkPoolBlowUp();
        (
            uint256 balance,
            uint256 luckyPoints,
            uint256[] memory stakingAmount,
            uint128[] memory lastUpdate
        ) = calBalance(order.seller);
        updateLast(order.seller, stakingAmount, lastUpdate);
        updateBalanceLuckyPoints(
            order.seller,
            balance,
            luckyPoints + order.luckyPointAmount
        );
        emit Confirm(
            msg.sender,
            orderNo,
            order.seller,
            order.amount,
            order.luckyPointAmount
        );
    }

    function updateBalanceLuckyPoints(
        address user,
        uint256 balance,
        uint256 luckyPoints
    ) private {
        luckyPointsPerUser[user] = luckyPoints;
        balancePerUser[user] = balance;
    }

    function refund(uint256 orderNo) external {
        checkPoolBlowUp();
        (
            uint256 balance,
            uint256 luckyPoints,
            uint256[] memory stakingAmount,
            uint128[] memory lastUpdate
        ) = calBalance(msg.sender);
        Order memory order = orders[orderNo];
        require(order.seller == msg.sender, "seller error");
        require(order.status == 1, "status error");
        require(luckyPoints >= order.luckyPointAmount, "not enough");
        orders[orderNo].status = 2;
        updateLast(order.seller, stakingAmount, lastUpdate);
        updateBalanceLuckyPoints(
            order.seller,
            balance,
            luckyPoints - order.luckyPointAmount
        );
        (
            uint256 balance1,
            uint256 luckyPoints1,
            uint256[] memory stakingAmount1,
            uint128[] memory lastUpdate1
        ) = calBalance(order.buyer);
        updateLast(order.buyer, stakingAmount1, lastUpdate1);
        updateBalanceLuckyPoints(
            order.buyer,
            balance1,
            luckyPoints1 + order.luckyPointAmount
        );
        emit Refund(
            msg.sender,
            orderNo,
            order.seller,
            order.amount,
            order.luckyPointAmount
        );
    }

    function writeOff(uint256 amount) external {
        checkPoolBlowUp();
        (
            uint256 balance,
            uint256 luckyPoints,
            uint256[] memory stakingAmount,
            uint128[] memory lastUpdate
        ) = calBalance(msg.sender);
        require(luckyPoints >= amount, "not enough");
        updateLast(msg.sender, stakingAmount, lastUpdate);
        luckyPointsPerUser[msg.sender] = luckyPoints - amount;
        balancePerUser[msg.sender] = balance;
        emit WriteOff(msg.sender, amount, luckyPoints - amount);
    }
}