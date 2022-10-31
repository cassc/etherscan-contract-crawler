pragma solidity 0.6.12;

import "../libraries/SafeMath.sol";
import "../interfaces/IERC20.sol";
import "../libraries/TransferHelper.sol";

contract PublicIDO {
    using SafeMath for uint256;

    address public immutable dev;
    address public immutable usdt;
    address public plexus;
    uint256 public price;
    uint256 public priceP2;
    uint256 public idoStartTime;
    uint256 public idoEndTime;
    uint256 public idoStartTimeP2;
    uint256 public idoEndTimeP2;
    uint256 public lockupBlock;
    uint256 public claimDuringBlock;
    uint256 public plexusTotalValue;
    uint256 public plexusTotalValueP2;
    uint256 public usdtHardCap;
    uint256 public usdtSoftCap;
    uint256 public userHardCap;
    uint256 public userSoftCap;
    uint256 public usdtHardCapP2;
    uint256 public usdtSoftCapP2;
    uint256 public userHardCapP2;
    uint256 public userSoftCapP2;
    uint256 public usdtTotalReciveAmount;
    uint256 public usdtTotalReciveAmountP2;
    address[] public userAddress;
    address[] public userAddressP2;
    uint256 public USDT_ACC_PRECESION = 1e6;
    uint256 public PLX_ACC_PRECESION = 1e18;
    struct UserInfo {
        uint256 amount;
        uint256 amountP2;
        uint256 totalReward;
        uint256 lastRewardBlock;
        uint256 recivePLX;
    }

    mapping(address => UserInfo) public userInfo;
    mapping(address => uint256) public userId;
    mapping(address => uint256) public userIdP2;
    event Deposit(address user, uint256 userDepositAmount, uint256 userPLXTotalReward);
    event Claim(address user, uint256 userClaimAmount, uint256 userRecivePLX);
    event refund(address user, uint256 refundAmount);

    constructor(address _usdt, address _plexus) public {
        usdt = _usdt;
        plexus = _plexus;
        claimDuringBlock = 518400;
        dev = msg.sender;
    }

    function init(
        uint256 _plxTotalValue,
        uint256 _usdtHardCap,
        uint256 _usdtSoftCap,
        uint256 _userHardCap,
        uint256 _userSoftCap
    ) public {
        require(msg.sender == dev);
        plexusTotalValue = _plxTotalValue;
        usdtHardCap = _usdtHardCap;
        usdtSoftCap = _usdtSoftCap;
        userHardCap = _userHardCap;
        userSoftCap = _userSoftCap;
        price = (usdtHardCap / (plexusTotalValue / PLX_ACC_PRECESION));
        IERC20(plexus).transferFrom(msg.sender, address(this), plexusTotalValue);
    }

    function initP2(
        uint256 _plxTotalValueP2,
        uint256 _usdtHardCapP2,
        uint256 _usdtSoftCapP2,
        uint256 _userHardCapP2,
        uint256 _userSoftCapP2
    ) public {
        require(msg.sender == dev);
        plexusTotalValueP2 = _plxTotalValueP2;
        usdtHardCapP2 = _usdtHardCapP2;
        usdtSoftCapP2 = _usdtSoftCapP2;
        userHardCapP2 = _userHardCapP2;
        userSoftCapP2 = _userSoftCapP2;
        priceP2 = (usdtHardCapP2 / (plexusTotalValueP2 / PLX_ACC_PRECESION));
        IERC20(plexus).transferFrom(msg.sender, address(this), plexusTotalValueP2);
    }

    function userLength() public view returns (uint256 user) {
        return userAddress.length;
    }

    function userP2Length() public view returns (uint256 user) {
        return userAddressP2.length;
    }

    function deposit(uint256 _userDepositAmount) public {
        require(block.timestamp >= idoStartTime && block.timestamp <= idoEndTime, "PLEXUS : This is not IDO time.");
        require(IERC20(usdt).balanceOf(msg.sender) >= _userDepositAmount, "PLEXUS : Insufficient amount.");

        require(
            _userDepositAmount >= userSoftCap && _userDepositAmount <= userHardCap,
            "PLEXUS : The amount is less than softcap. or The amount exceeds your personal hardcap. "
        );

        uint256 userDepositAmountInt = (_userDepositAmount / price) * price;

        require(
            usdtHardCap.sub(usdtTotalReciveAmount).sub(userDepositAmountInt) >= 0,
            "PLEXUS : The deposit amount exceeds the hardcap."
        );

        IERC20(usdt).transferFrom(msg.sender, address(this), userDepositAmountInt);
        if (userAddress.length == 0 || (userId[msg.sender] == 0 && userAddress[0] != msg.sender)) {
            userAddress.push(msg.sender);
            userId[msg.sender] = userAddress.length - 1;
        }
        UserInfo memory user = userInfo[msg.sender];
        user.amount += userDepositAmountInt;

        require(user.amount <= userHardCap, "PLEXUS : The deposit amount exceeds the hardcap.");

        usdtTotalReciveAmount += userDepositAmountInt;
        user.totalReward += (userDepositAmountInt)
            .div((usdtHardCap / USDT_ACC_PRECESION).mul(USDT_ACC_PRECESION) / (plexusTotalValue / PLX_ACC_PRECESION))
            .mul(PLX_ACC_PRECESION);
        userInfo[msg.sender] = user;

        emit Deposit(msg.sender, user.amount, user.totalReward);
    }

    function depositP2(uint256 _userDepositAmount) public {
        require(block.timestamp >= idoStartTimeP2 && block.timestamp <= idoEndTimeP2, "PLEXUS : This is not IDO time.");
        require(IERC20(usdt).balanceOf(msg.sender) >= _userDepositAmount, "PLEXUS : Insufficient amount.");
        require(
            usdtHardCapP2.sub(usdtTotalReciveAmountP2) >= _userDepositAmount,
            "PLEXUS : The deposit amount exceeds the hardcap."
        );
        require(
            _userDepositAmount >= userSoftCapP2 && _userDepositAmount <= userHardCapP2,
            "PLEXUS : The amount is less than softcap. or The amount exceeds your personal hardcap. "
        );
        uint256 userDepositAmountInt = (_userDepositAmount / priceP2) * priceP2;

        require(
            usdtHardCapP2.sub(usdtTotalReciveAmountP2).sub(userDepositAmountInt) >= 0,
            "PLEXUS : The deposit amount exceeds the hardcap."
        );

        IERC20(usdt).transferFrom(msg.sender, address(this), userDepositAmountInt);
        if (userAddressP2.length == 0 || (userIdP2[msg.sender] == 0 && userAddressP2[0] != msg.sender)) {
            userAddressP2.push(msg.sender);
            userIdP2[msg.sender] = userAddressP2.length - 1;
        }
        UserInfo memory user = userInfo[msg.sender];
        user.amountP2 += userDepositAmountInt;

        require(user.amountP2 <= userHardCapP2);
        usdtTotalReciveAmountP2 += userDepositAmountInt;
        user.totalReward += (userDepositAmountInt)
            .div(
                (usdtHardCapP2 / USDT_ACC_PRECESION).mul(USDT_ACC_PRECESION) / (plexusTotalValueP2 / PLX_ACC_PRECESION)
            )
            .mul(PLX_ACC_PRECESION);
        userInfo[msg.sender] = user;

        emit Deposit(msg.sender, user.amountP2, user.totalReward);
    }

    function pendingClaim(address _user) public view returns (uint256 pendingAmount) {
        UserInfo memory user = userInfo[_user];
        if (block.number > lockupBlock && lockupBlock != 0) {
            uint256 claimBlock;
            if (block.number > lockupBlock.add(claimDuringBlock)) {
                if (user.lastRewardBlock <= lockupBlock.add(claimDuringBlock)) {
                    pendingAmount = user.totalReward.sub(user.recivePLX);
                } else pendingAmount = 0;
            } else {
                if (userInfo[_user].lastRewardBlock < lockupBlock) {
                    claimBlock = block.number.sub(lockupBlock);
                } else {
                    claimBlock = block.number.sub(user.lastRewardBlock);
                }
                uint256 perBlock = (user.totalReward.mul(PLX_ACC_PRECESION)) / claimDuringBlock;
                pendingAmount = claimBlock.mul(perBlock) / PLX_ACC_PRECESION;
            }
        } else pendingAmount = 0;
    }

    function claim(address _user) public {
        require(block.number >= lockupBlock && lockupBlock != 0, "PLEXUS : lockupBlock not set.");
        UserInfo memory user = userInfo[_user];

        uint256 claimAmount = pendingClaim(_user);
        require(claimAmount != 0, "PLEXUS : There is no claimable amount.");
        if (IERC20(plexus).balanceOf(address(this)) <= claimAmount) {
            claimAmount = IERC20(plexus).balanceOf(address(this));
        }
        TransferHelper.safeTransfer(plexus, _user, claimAmount);
        user.lastRewardBlock = block.number;
        user.recivePLX += claimAmount;
        userInfo[_user] = user;

        emit Claim(_user, claimAmount, user.recivePLX);
    }

    function close(uint256 roopStart, uint256 roopEnd) public {
        require(msg.sender == dev);
        require(block.timestamp > idoEndTime);
        uint256 usdtSoftCapInt = (usdtSoftCap / price) * price;
        if (usdtTotalReciveAmount < usdtSoftCapInt) {
            if (roopEnd >= userAddress.length) {
                roopEnd = userAddress.length;
            }
            for (roopStart; roopStart < roopEnd; roopStart++) {
                UserInfo memory user = userInfo[userAddress[roopStart]];
                if (user.amount != 0) {
                    TransferHelper.safeTransfer(usdt, userAddress[roopStart], user.amount);

                    user.totalReward -= user
                        .amount
                        .div(
                            (usdtHardCap / USDT_ACC_PRECESION).mul(USDT_ACC_PRECESION) /
                                (plexusTotalValue / PLX_ACC_PRECESION)
                        )
                        .mul(PLX_ACC_PRECESION);
                    emit refund(userAddress[roopStart], user.amount);
                    usdtTotalReciveAmount -= user.amount;
                    user.amount = 0;
                    userInfo[userAddress[roopStart]] = user;
                }
            }
        } else {
            TransferHelper.safeTransfer(usdt, dev, usdtTotalReciveAmount);
        }
    }

    function closeP2(uint256 roopStart, uint256 roopEnd) public {
        require(msg.sender == dev);
        require(block.timestamp > idoEndTime);
        uint256 usdtSoftCapInt = (usdtSoftCapP2 / priceP2) * priceP2;
        if (usdtTotalReciveAmountP2 < usdtSoftCapInt) {
            if (roopEnd >= userAddressP2.length) {
                roopEnd = userAddressP2.length;
            }
            for (roopStart; roopStart < roopEnd; roopStart++) {
                if (userInfo[userAddressP2[roopStart]].amountP2 != 0) {
                    UserInfo memory user = userInfo[userAddressP2[roopStart]];
                    TransferHelper.safeTransfer(usdt, userAddressP2[roopStart], user.amountP2);
                    user.totalReward -= user
                        .amountP2
                        .div(
                            (usdtHardCapP2 / USDT_ACC_PRECESION).mul(USDT_ACC_PRECESION) /
                                (plexusTotalValueP2 / PLX_ACC_PRECESION)
                        )
                        .mul(PLX_ACC_PRECESION);
                    emit refund(userAddressP2[roopStart], user.amountP2);
                    usdtTotalReciveAmountP2 -= user.amountP2;
                    user.amountP2 = 0;
                    userInfo[userAddressP2[roopStart]] = user;
                }
            }
        } else {
            TransferHelper.safeTransfer(usdt, dev, usdtTotalReciveAmountP2);
        }
    }

    function emergencyWithdraw() public {
        require(msg.sender == dev);
        TransferHelper.safeTransfer(plexus, dev, IERC20(plexus).balanceOf(address(this)));
        TransferHelper.safeTransfer(usdt, dev, IERC20(usdt).balanceOf(address(this)));
    }

    function setLockupBlock(uint256 _launchingBlock) public {
        require(msg.sender == dev);
        // ( lunchingBlock + 1month)
         lockupBlock = _launchingBlock.add(172800);
    }

    function setIdoTime(uint256 _startTime, uint256 _endTime) public {
        require(msg.sender == dev);
        idoStartTime = _startTime;
        idoEndTime = _endTime;
    }

    function setIdoTimeP2(uint256 _startTime, uint256 _endTime) public {
        require(msg.sender == dev);
        idoStartTimeP2 = _startTime;
        idoEndTimeP2 = _endTime;
    }

    function idoClosePlxWithdraw() public {
        require(msg.sender == dev);
        uint256 plxWithdrawAmount = plexusTotalValue.sub((usdtTotalReciveAmount / price) * PLX_ACC_PRECESION);
        TransferHelper.safeTransfer(plexus, dev, plxWithdrawAmount);
    }

    function idoClosePlxWithdrawP2() public {
        require(msg.sender == dev);
        uint256 plxWithdrawAmount = plexusTotalValueP2.sub((usdtTotalReciveAmountP2 / priceP2) * PLX_ACC_PRECESION);
        TransferHelper.safeTransfer(plexus, dev, plxWithdrawAmount);
    }
}