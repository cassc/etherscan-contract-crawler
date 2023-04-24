// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract DualSystem is Initializable {
    address public owner;
    token public BUSD;
    BUSDOneV3Interface public stakingContract;
    BUSDOneRaffleInterface public raffleContract;
    address public stakingAddress;

    mapping(address => address[]) public binaryDownlines;
    mapping(address => User) public users;
    mapping(uint16 => bool) public packageAvailable;

    address[] public userById;
    uint16[] public userClaimable;
    uint16[] public userUnilevelClaimable;
    uint16[] public unilevelCommissions;
    uint32[] public userVolLeft;
    uint32[] public userVolRight;

    uint16 public percentDivider;
    uint16 public binaryCommission;

    address public raffleAddress;
    address public genesis;

    Deductor[] public deductors;
    DeductorProperties[] public deductorProperties;
    mapping(address => uint256) public deductorIndex;

    mapping(address => uint256) public totalEarnings;

    struct DeductorProperties {
        bool deducting;
        uint96 claimable;
    }

    struct Deductor {
        address addr;
        uint16 percent;
    }

    struct User {
        address binaryUpline;
        bool isRight;
        uint24 id;
        uint16 maxEarningPerDay;
        uint16 lastEarningDay;
        uint16 lastEarningAmount;
        uint16 lastPurchaseDay;
    }

    function initialize(
        address _busd,
        address _raffleContract,
        address _stakingContract,
        address _genesis
    ) external initializer {
        owner = msg.sender;
        raffleContract = BUSDOneRaffleInterface(_raffleContract);
        stakingContract = BUSDOneV3Interface(_stakingContract);
        stakingAddress = _stakingContract;
        raffleAddress = _raffleContract;
        genesis = _genesis;
        BUSD = token(_busd);

        packageAvailable[10] = true;
        packageAvailable[20] = true;
        packageAvailable[50] = true;
        packageAvailable[100] = true;
        packageAvailable[500] = true;
        packageAvailable[1000] = true;
        packageAvailable[2000] = true;
        packageAvailable[3000] = true;
        packageAvailable[5000] = true;

        userById.push(genesis);
        userClaimable.push(0);
        userUnilevelClaimable.push(0);
        userVolLeft.push(0);
        userVolRight.push(0);
        users[genesis].lastPurchaseDay = 1;

        percentDivider = 100_0;
        unilevelCommissions = [5_0, 2_0, 5, 5, 5, 5, 5, 5];
        binaryCommission = 10;
    }

    // Externals

    function purchasePack(uint16 amount, address upline) external {
        require(packageAvailable[amount], "Package not available");

        uint256 weiAmount = uint256(amount) * 1 ether;
        BUSD.transferFrom(msg.sender, address(this), weiAmount);

        User storage user = users[msg.sender];
        if (genesis != msg.sender && user.id == 0) registerUser(msg.sender);

        address stakeUpline = getUserReferrer(msg.sender);
        if (stakeUpline != address(0)) {
            upline = stakeUpline;
        } else if (user.id > 0) {
            require(users[upline].lastPurchaseDay > 0, "Invalid upline");
            stakingContract.registerStaker(msg.sender, upline);
        }

        bool repeat = user.lastPurchaseDay > 0;

        user.lastPurchaseDay = uint16(block.timestamp / 1 days);
        if (user.maxEarningPerDay < amount) user.maxEarningPerDay = amount;

        if (!repeat) {
            User storage loopingUser = user;
            address loopingAddress = msg.sender;
            address loopingUpline = upline;
            while (
                loopingUser.binaryUpline == address(0) && loopingUser.id > 0
            ) {
                loopingUser.binaryUpline = getAvailableSlot(loopingUpline);
                binaryDownlines[loopingUser.binaryUpline].push(loopingAddress);
                if (binaryDownlines[loopingUser.binaryUpline].length == 2) {
                    loopingUser.isRight = true;
                }
                if (loopingUpline == genesis) break;
                loopingUser = users[loopingUpline];
                if (loopingUser.id == 0) registerUser(loopingUpline);
                else break;
                loopingAddress = loopingUpline;
                loopingUpline = getUserReferrer(loopingUpline);
            }
        }

        propagateBinaryEarning(
            repeat ? msg.sender : user.binaryUpline,
            amount,
            repeat ? userVolLeft[user.id] > userVolRight[user.id] : user.isRight
        );

        propagateUnilevelEarning(getUserReferrer(msg.sender), amount);

        BUSD.transfer(raffleAddress, weiAmount / 2);

        raffleContract.receiveDualIncome(
            msg.sender,
            getUserReferrer(msg.sender),
            amount / 10,
            weiAmount / 2
        );
    }

    function setAddress(uint256 index, address addr) external {
        require(msg.sender == owner, "Not owner");

        if (index == 1) {
            stakingAddress = addr;
            stakingContract = BUSDOneV3Interface(addr);
        } else if (index == 2) {
            raffleAddress = addr;
            raffleContract = BUSDOneRaffleInterface(addr);
        }
    }

    function deductorClaim() external {
        uint256 index = deductorIndex[msg.sender];
        require(deductors[index].addr == msg.sender, "Not a deductor");

        DeductorProperties storage deductor = deductorProperties[index];

        require(deductor.claimable > 0, "Nothing to claim");
        uint256 amount = deductor.claimable;
        deductor.claimable = 0;

        totalEarnings[msg.sender] += amount;

        BUSD.transfer(msg.sender, uint256(amount));
    }

    function addDeductor(
        address addr,
        uint16 percent,
        bool deducting
    ) external {
        require(msg.sender == owner, "Not owner");
        deductors.push(Deductor(addr, percent));
        deductorProperties.push(DeductorProperties(deducting, 0));
        deductorIndex[addr] = deductors.length - 1;
    }

    function resetDeductors() external {
        require(msg.sender == owner, "Not owner");
        deductors = new Deductor[](0);
        deductorProperties = new DeductorProperties[](0);
    }

    function changeDeductor(
        uint256 index,
        uint16 percent,
        bool deducting
    ) external {
        require(msg.sender == owner, "Not owner");
        deductors[index].percent = percent;
        deductorProperties[index].deducting = deducting;
    }

    function removeDeductor(uint256 index) external {
        require(msg.sender == owner, "Not owner");
        deductorIndex[deductors[index].addr] = 0;
        deductors[index] = deductors[deductors.length - 1];
        deductorProperties[index] = deductorProperties[
            deductorProperties.length - 1
        ];

        deductors.pop();
        deductorProperties.pop();
    }

    function claimUnilevelCommissions() external {
        User storage user = users[msg.sender];
        uint16 amount = userUnilevelClaimable[user.id];

        require(amount > 0, "No commissions available");

        userUnilevelClaimable[user.id] = 0;

        uint256 deductedAmount = deduct((uint256(amount) * 1 ether) / 20);

        totalEarnings[msg.sender] += deductedAmount;

        BUSD.transfer(msg.sender, deductedAmount);
    }

    function claimBinaryCommissions() external {
        User storage user = users[msg.sender];
        uint16 amount = userClaimable[user.id];

        require(amount > 0, "No commissions available");

        userClaimable[user.id] = 0;

        uint256 deductedAmount = deduct((uint256(amount) * 1 ether) / 2);

        totalEarnings[msg.sender] += deductedAmount;

        BUSD.transfer(msg.sender, deductedAmount);
    }

    function getUserInfo(
        address wallet
    ) external view returns (User memory, uint16, uint16, uint32, uint32) {
        return (
            users[wallet],
            userClaimable[users[wallet].id],
            userUnilevelClaimable[users[wallet].id],
            userVolLeft[users[wallet].id],
            userVolRight[users[wallet].id]
        );
    }

    function getDeductors()
        external
        view
        returns (
            address[] memory addrs,
            uint16[] memory percents,
            bool[] memory deducting,
            uint96[] memory claimable
        )
    {
        uint256 length = deductors.length;
        addrs = new address[](length);
        percents = new uint16[](length);
        deducting = new bool[](length);
        claimable = new uint96[](length);
        for (uint256 i = 0; i < length; i++) {
            addrs[i] = deductors[i].addr;
            percents[i] = deductors[i].percent;
            deducting[i] = deductorProperties[i].deducting;
            claimable[i] = deductorProperties[i].claimable;
        }
    }

    function getDownlines(
        address wallet
    ) external view returns (address[] memory) {
        return binaryDownlines[wallet];
    }

    // Internals

    function deduct(uint256 amount) internal returns (uint256 remainingAmount) {
        remainingAmount = amount;
        uint256 length = deductors.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 deductAmount = (amount * deductors[i].percent) / 1000;
            deductorProperties[i].claimable += uint96(deductAmount);
            if (deductorProperties[i].deducting) {
                remainingAmount -= deductAmount;
            }
        }
    }

    function propagateBinaryEarning(
        address userAddress,
        uint16 amount,
        bool isRight
    ) internal {
        User storage user;
        uint16 commission;
        uint32 bigger;
        uint32 smaller;
        uint16 currentday = uint16(block.timestamp / 1 days);
        while (userAddress != address(0)) {
            user = users[userAddress];

            if (
                currentday - user.lastPurchaseDay > 90 &&
                user.maxEarningPerDay > 10
            ) {
                user.maxEarningPerDay = 10;
            }

            commission = amount / binaryCommission;

            if (userVolLeft[user.id] > userVolRight[user.id]) {
                bigger = userVolLeft[user.id];
                smaller = userVolRight[user.id];
                if (isRight) {
                    if (smaller + amount > bigger) {
                        commission =
                            uint16(bigger - smaller) /
                            binaryCommission;
                    }
                } else {
                    commission = 0;
                }
            } else {
                bigger = userVolRight[user.id];
                smaller = userVolLeft[user.id];
                if (!isRight) {
                    if (smaller + amount > bigger) {
                        commission =
                            uint16(bigger - smaller) /
                            binaryCommission;
                    }
                } else {
                    commission = 0;
                }
            }

            if (isRight) {
                userVolRight[user.id] += amount;
            } else {
                userVolLeft[user.id] += amount;
            }

            if (commission > 0) {
                if (user.lastEarningDay == uint16(block.timestamp / 1 days)) {
                    if (
                        user.lastEarningAmount + commission >
                        (user.maxEarningPerDay * 2)
                    ) {
                        commission =
                            (user.maxEarningPerDay * 2) -
                            user.lastEarningAmount;
                    }
                    user.lastEarningAmount += commission;
                } else {
                    if (commission > (user.maxEarningPerDay * 2)) {
                        commission = (user.maxEarningPerDay * 2);
                    }
                    user.lastEarningDay = uint16(block.timestamp / 1 days);
                    user.lastEarningAmount = commission;
                }
                userClaimable[user.id] += commission;
            }

            userAddress = user.binaryUpline;
            isRight = user.isRight;
        }
    }

    function propagateUnilevelEarning(
        address userAddress,
        uint256 amount
    ) internal {
        amount *= 10;
        User memory user;
        uint256 length = unilevelCommissions.length;
        uint16 currentday = uint16(block.timestamp / 1 days);
        uint16 commission;
        for (uint256 i = 0; i < length; i++) {
            if (userAddress == address(0)) break;
            user = users[userAddress];

            if (user.lastPurchaseDay == 0) break;

            if (currentday - user.lastPurchaseDay > 30) {
                userAddress = getUserReferrer(userAddress);
                i--;
                continue;
            }
            commission = uint16(
                (amount * unilevelCommissions[i]) / percentDivider
            );

            userUnilevelClaimable[user.id] += commission;
            if (userAddress == getUserReferrer(userAddress)) break;
            userAddress = getUserReferrer(userAddress);
        }
    }

    function getUserReferrer(address wallet) internal view returns (address) {
        (address referrer, , , , , , , , , , , , ) = stakingContract.users(
            wallet
        );
        return referrer;
    }

    function getAvailableSlot(address upline) internal view returns (address) {
        uint24 id;
        while (binaryDownlines[upline].length == 2) {
            id = users[upline].id;
            if (userVolLeft[id] > userVolRight[id]) {
                upline = binaryDownlines[upline][1];
            } else {
                upline = binaryDownlines[upline][0];
            }
        }
        return upline;
    }

    function registerUser(address wallet) internal {
        if (users[wallet].id == 0) {
            users[wallet].id = uint24(userClaimable.length);
            userById.push(msg.sender);
            userClaimable.push(0);
            userUnilevelClaimable.push(0);
            userVolLeft.push(0);
            userVolRight.push(0);
        }
    }
}

interface BUSDOneV3Interface {
    function users(
        address addr
    )
        external
        view
        returns (
            address referrer,
            uint32 lastClaim,
            uint32 startIndex,
            uint128 bonusClaimed,
            uint96 bonus_0,
            uint32 downlines_0,
            uint96 bonus_1,
            uint32 downlines_1,
            uint96 bonus_2,
            uint32 downlines_2,
            uint96 leftOver,
            uint32 lastWithdraw,
            uint96 totalStaked
        );

    function registerStaker(address addr, address upline) external;
}

interface BUSDOneRaffleInterface {
    function receiveDualIncome(
        address wallet,
        address upline,
        uint256 tickets,
        uint256 totalAmount
    ) external;
}

interface token {
    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}