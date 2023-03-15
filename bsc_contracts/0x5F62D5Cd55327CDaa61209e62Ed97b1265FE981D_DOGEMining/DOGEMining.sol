/**
 *Submitted for verification at BscScan.com on 2023-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {

        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

interface IBEP20 {

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract DOGEMining is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    
    IBEP20 public USDT = IBEP20(0x55d398326f99059fF775485246999027B3197955);
    IBEP20 public ASI = IBEP20(0x6A86f028dfE7e0dbC3F72993864126f3af5Ea2F3);
    IBEP20 public DOGE = IBEP20(0xbA2aE424d960c26247Dd6c32edC70B295c744C43);
    
    uint256 public asiPrice = 1;
    uint256 public decimalASIPrice = 1000;

    uint256 public dogePrice = 64;
    uint256 public decimalDOGEPrice = 1000;

    uint256 public PACKAGE_1 = 100;
    uint256 public PACKAGE_2 = 500;
    uint256 public PACKAGE_3 = 2000;
    uint256 public PACKAGE_4 = 5000;
    uint256 public PACKAGE_5 = 10000;
    uint256 public PACKAGE_6 = 20000;
    uint256 public PACKAGE_7 = 50000;

    uint256 public WITHDRAW_PERIOD_1 = 450 days;
    uint256 public WITHDRAW_PERIOD_2 = 450 days;
    uint256 public WITHDRAW_PERIOD_3 = 480 days;
    uint256 public WITHDRAW_PERIOD_4 = 480 days;
    uint256 public WITHDRAW_PERIOD_5 = 480 days;
    uint256 public WITHDRAW_PERIOD_6 = 510 days;
    uint256 public WITHDRAW_PERIOD_7 = 600 days;

    uint256 public PACKAGE_RATE_1 = 8;
    uint256 public PACKAGE_RATE_2 = 12;
    uint256 public PACKAGE_RATE_3 = 14;
    uint256 public PACKAGE_RATE_4 = 16;
    uint256 public PACKAGE_RATE_5 = 18;
    uint256 public PACKAGE_RATE_6 = 20;
    uint256 public PACKAGE_RATE_7 = 20;

    uint256 public PACKAGE_RATE_COMPANY_1 = 8;
    uint256 public PACKAGE_RATE_COMPANY_2 = 10;
    uint256 public PACKAGE_RATE_COMPANY_3 = 13;
    uint256 public PACKAGE_RATE_COMPANY_4 = 15;
    uint256 public PACKAGE_RATE_COMPANY_5 = 17;
    uint256 public PACKAGE_RATE_COMPANY_6 = 18;
    uint256 public PACKAGE_RATE_COMPANY_7 = 18;

    uint256 public CLAIM_FEE = 2;

    struct UserInfo {
        uint256 balanceCoinTop;
        uint256 packageCoinTop;
        uint256 miningCoinTopAt;
        bool isMiningCoinTop;
        uint256 bonusDebtCoinTop;
        bool isCompanyMiningCoinTop;
    }

    mapping(address => UserInfo) public userInfo;

    event RescueFundsUSDT(address indexed owner, address to);
    event RescueFundsASI(address indexed owner, address to);
    event RescueFundsDOGE(address indexed owner, address to);

    event BuyMiningPackage(address indexed owner, uint256 tokenType, uint256 packageType, uint256 amount, bool isCompany);
    event Withdraw(address indexed owner);
    event Claim(address indexed owner);
    event ClaimBonus(address indexed owner, uint256 tokenClaim);
    
    event AddUserMiningCoinTop(address indexed owner, address account, uint256 _balanceCoinTop, uint256 _miningCoinTopAt, bool _isMiningCoinTop,
    uint256 _packageCoinTop, uint256 _bonusDebtCoinTop, bool _isCompanyMiningCoinTop);
    
    event RemoveUserInfo(address indexed owner, address account);

    // VIEWS
    function balanceUSDT() public view returns(uint256) {
        return USDT.balanceOf(address(this));
    }

    function balanceASI() public view returns(uint256) {
        return ASI.balanceOf(address(this));
    }

    function balanceDOGE() public view returns(uint256) {
        return DOGE.balanceOf(address(this));
    }

    function balanceASIOfUser(address account) public view returns(uint256) {
        return ASI.balanceOf(account);
    }

    function balanceUSDTOfUser(address account) public view returns(uint256) {
        return USDT.balanceOf(account);
    }

    function calculateBonus(address account) public view returns(uint256) {
        UserInfo storage user = userInfo[account];

        if(user.balanceCoinTop > 0) {
            uint256 dayBonus = 0;
            uint256 timestampBonus = block.timestamp.sub(user.miningCoinTopAt);
            
            if(timestampBonus > 86400) {
                uint256 modBonus = timestampBonus.mod(86400);
                uint256 modBonusTimeStamp = timestampBonus.sub(modBonus);
                dayBonus = modBonusTimeStamp.div(86400);
            } else {
                return 0;
            }

            if(user.packageCoinTop == 1) {
                if(user.isCompanyMiningCoinTop == true) {
                    return user.balanceCoinTop.mul(PACKAGE_RATE_COMPANY_1).div(100).div(30).mul(dayBonus).sub(user.bonusDebtCoinTop);
                } else {
                    return user.balanceCoinTop.mul(PACKAGE_RATE_1).div(100).div(30).mul(dayBonus).sub(user.bonusDebtCoinTop);
                }
            } else if (user.packageCoinTop == 2) {
                if(user.isCompanyMiningCoinTop == true) {
                    return user.balanceCoinTop.mul(PACKAGE_RATE_COMPANY_2).div(100).div(30).mul(dayBonus).sub(user.bonusDebtCoinTop);
                } else {
                    return user.balanceCoinTop.mul(PACKAGE_RATE_2).div(100).div(30).mul(dayBonus).sub(user.bonusDebtCoinTop);
                }
            } else if (user.packageCoinTop == 3) {
                if(user.isCompanyMiningCoinTop == true) {
                    return user.balanceCoinTop.mul(PACKAGE_RATE_COMPANY_3).div(100).div(30).mul(dayBonus).sub(user.bonusDebtCoinTop);
                } else {
                    return user.balanceCoinTop.mul(PACKAGE_RATE_3).div(100).div(30).mul(dayBonus).sub(user.bonusDebtCoinTop);
                }
            } else if (user.packageCoinTop == 4) {
                if(user.isCompanyMiningCoinTop == true) {
                    return user.balanceCoinTop.mul(PACKAGE_RATE_COMPANY_4).div(100).div(30).mul(dayBonus).sub(user.bonusDebtCoinTop);
                } else {
                    return user.balanceCoinTop.mul(PACKAGE_RATE_4).div(100).div(30).mul(dayBonus).sub(user.bonusDebtCoinTop);
                }
            } else if (user.packageCoinTop == 5) {
                if(user.isCompanyMiningCoinTop == true) {
                    return user.balanceCoinTop.mul(PACKAGE_RATE_COMPANY_5).div(100).div(30).mul(dayBonus).sub(user.bonusDebtCoinTop);
                } else {
                    return user.balanceCoinTop.mul(PACKAGE_RATE_5).div(100).div(30).mul(dayBonus).sub(user.bonusDebtCoinTop);
                }
            } else if (user.packageCoinTop == 6) {
                if(user.isCompanyMiningCoinTop == true) {
                    return user.balanceCoinTop.mul(PACKAGE_RATE_COMPANY_6).div(100).div(30).mul(dayBonus).sub(user.bonusDebtCoinTop);
                } else {
                    return user.balanceCoinTop.mul(PACKAGE_RATE_6).div(100).div(30).mul(dayBonus).sub(user.bonusDebtCoinTop);
                }
            } else {
                if(user.isCompanyMiningCoinTop == true) {
                    return user.balanceCoinTop.mul(PACKAGE_RATE_COMPANY_7).div(100).div(30).mul(dayBonus).sub(user.bonusDebtCoinTop);
                } else {
                    return user.balanceCoinTop.mul(PACKAGE_RATE_7).div(100).div(30).mul(dayBonus).sub(user.bonusDebtCoinTop);
                }
            }
        } else {
            return 0;
        }
        
        
    }

    function checkWithdraw(address account) public view returns(bool) {
        UserInfo storage user = userInfo[account];

        if(user.packageCoinTop == 1) {
            if(user.miningCoinTopAt.add(WITHDRAW_PERIOD_1) > block.timestamp) {
                return false;
            }
        } else if (user.packageCoinTop == 2) {
            if(user.miningCoinTopAt.add(WITHDRAW_PERIOD_2) > block.timestamp) {
                return false;
            }
        } else if (user.packageCoinTop == 3) {
            if(user.miningCoinTopAt.add(WITHDRAW_PERIOD_3) > block.timestamp) {
                return false;
            }
        } else if (user.packageCoinTop == 4) {
            if(user.miningCoinTopAt.add(WITHDRAW_PERIOD_4) > block.timestamp) {
                return false;
            }
        } else if (user.packageCoinTop == 5) {
            if(user.miningCoinTopAt.add(WITHDRAW_PERIOD_5) > block.timestamp) {
                return false;
            }
        } else if (user.packageCoinTop == 6) {
            if(user.miningCoinTopAt.add(WITHDRAW_PERIOD_6) > block.timestamp) {
                return false;
            }
        } else {
            if(user.miningCoinTopAt.add(WITHDRAW_PERIOD_7) > block.timestamp) {
                return false;
            }
        }
        
        return true;
    }

    // OWNER

    function addUserMiningCoinTop(address account, uint256 _balanceCoinTop, uint256 _miningCoinTopAt,
    uint256 _packageCoinTop, bool _isCompanyMiningCoinTop, bool _isMiningCoinTop, uint256 _bonusDebtCoinTop) external onlyOwner {
        
        userInfo[account].balanceCoinTop = _balanceCoinTop;
        userInfo[account].packageCoinTop = _packageCoinTop;
        userInfo[account].miningCoinTopAt = _miningCoinTopAt;
        userInfo[account].isCompanyMiningCoinTop = _isCompanyMiningCoinTop;
        userInfo[account].isMiningCoinTop = _isMiningCoinTop;
        userInfo[account].bonusDebtCoinTop = _bonusDebtCoinTop;

        emit AddUserMiningCoinTop(msg.sender, account, _balanceCoinTop, _miningCoinTopAt, _isMiningCoinTop, _packageCoinTop, _bonusDebtCoinTop, _isCompanyMiningCoinTop);
    }

    function removeUserInfo(address account) external onlyOwner {
        delete userInfo[account];

        emit RemoveUserInfo(msg.sender, account);
    }

    function rescueFundsUSDT(address to) external onlyOwner {
        uint256 bal = balanceUSDT();
        require(bal > 0, "dont have a USDT");
        USDT.transfer(to, bal);

        emit RescueFundsUSDT(msg.sender, to);
    }

    function rescueFundsASI(address to) external onlyOwner {
        uint256 bal = balanceASI();
        require(bal > 0, "dont have a ASI");
        ASI.transfer(to, bal);

        emit RescueFundsASI(msg.sender, to);
    }

    function rescueFundsDOGE(address to) external onlyOwner {
        uint256 bal = balanceDOGE();
        require(bal > 0, "dont have a DOGE");
        DOGE.transfer(to, bal);

        emit RescueFundsDOGE(msg.sender, to);
    }

    function setToken(uint8 tag,address value) public onlyOwner returns(bool) {
        if(tag == 1) {
            USDT = IBEP20(value);
        } else if(tag == 2){
            ASI = IBEP20(value);
        }else if(tag == 3){
            DOGE = IBEP20(value);
        }
        
        return true;
    }

    function set(uint8 tag,uint256 value) public onlyOwner returns(bool) {
        if(tag == 1) {
            asiPrice = value;
        } else if(tag == 2){
            decimalASIPrice = value;
        }else if(tag == 3){
            dogePrice = value;
        }else if(tag == 4){
            decimalDOGEPrice = value;
        }else if(tag == 5){
            PACKAGE_1 = value;
        }else if(tag == 6){
            PACKAGE_2 = value;
        }else if(tag == 7){
            PACKAGE_3 = value;
        } else if (tag == 8) {
            PACKAGE_4 = value;
        } else if (tag == 9) {
            PACKAGE_5 = value;
        } else if (tag == 10) {
            PACKAGE_6 = value;
        } else if (tag == 11) {
            PACKAGE_7 = value;
        } else if (tag == 12) {
            PACKAGE_RATE_1 = value;
        } else if (tag == 13) {
            PACKAGE_RATE_2 = value;
        } else if (tag == 14) {
            PACKAGE_RATE_3 = value;
        } else if (tag == 15) {
            PACKAGE_RATE_4 = value;
        } else if (tag == 16) {
            PACKAGE_RATE_5 = value;
        } else if (tag == 17) {
            PACKAGE_RATE_6 = value;
        } else if (tag == 18) {
            PACKAGE_RATE_7 = value;
        } else if (tag == 19) {
            PACKAGE_RATE_COMPANY_1 = value;
        } else if (tag == 20) {
            PACKAGE_RATE_COMPANY_2 = value;
        } else if (tag == 21) {
            PACKAGE_RATE_COMPANY_3 = value;
        } else if (tag == 22) {
            PACKAGE_RATE_COMPANY_4 = value;
        } else if (tag == 23) {
            PACKAGE_RATE_COMPANY_5 = value;
        } else if (tag == 24) {
            PACKAGE_RATE_COMPANY_6 = value;
        } else if (tag == 25) {
            PACKAGE_RATE_COMPANY_7 = value;
        } else if (tag == 26) {
            WITHDRAW_PERIOD_1 = value;
        } else if (tag == 27) {
            WITHDRAW_PERIOD_2 = value;
        } else if (tag == 28) {
            WITHDRAW_PERIOD_3 = value;
        } else if (tag == 29) {
            WITHDRAW_PERIOD_4 = value;
        } else if (tag == 30) {
            WITHDRAW_PERIOD_5 = value;
        } else if (tag == 31) {
            WITHDRAW_PERIOD_6 = value;
        } else if (tag == 32) {
            WITHDRAW_PERIOD_7 = value;
        } else if (tag == 33) {
            CLAIM_FEE = value;
        }
        
        return true;
    }

    /* --EXTERNAL-- */

    function buyMiningPackage(uint256 tokenType, uint256 packageType, uint256 amount, bool isCompany) public nonReentrant returns(bool) {
        require(amount > 0, "amount must greater than zero");
        require(msg.sender != address(0), "account must not zero address");
        UserInfo storage user = userInfo[msg.sender];

        if(packageType == 1) {
            require(amount >= PACKAGE_1, "amout must greater than package amount");
        } else if (packageType == 2) {
            require(amount >= PACKAGE_2, "amout must greater than package amount");
        } else if (packageType == 3) {
            require(amount >= PACKAGE_3, "amout must greater than package amount");
        } else if (packageType == 4) {
            require(amount >= PACKAGE_4, "amout must greater than package amount");
        } else if (packageType == 5) {
            require(amount >= PACKAGE_5, "amout must greater than package amount");
        } else if (packageType == 6) {
            require(amount >= PACKAGE_6, "amout must greater than package amount");
        } else if (packageType == 7) {
            require(amount >= PACKAGE_7, "amout must greater than package amount");
        }

        if(tokenType == 1) { // ASI
            require(balanceASIOfUser(msg.sender) >= amount.mul(decimalASIPrice).div(asiPrice), "balance ASI is not enough");

            if(user.balanceCoinTop > 0) {
                uint256 oldBonus = calculateBonus(msg.sender);
                if(oldBonus > 0) {
                    DOGE.transfer(msg.sender, oldBonus);
                }
            }
            
            user.packageCoinTop = packageType;
            user.balanceCoinTop = user.balanceCoinTop.add(amount.div(10**18).mul(10**8).mul(decimalDOGEPrice).div(dogePrice));
            user.miningCoinTopAt = block.timestamp;
            user.bonusDebtCoinTop = 0;
            user.isMiningCoinTop = true;
            user.isCompanyMiningCoinTop = isCompany;
            
            
            ASI.transferFrom(msg.sender, address(this), amount.mul(decimalASIPrice).div(asiPrice));

        } else if (tokenType == 2) { // USDT
            require(balanceUSDTOfUser(msg.sender) >= amount, "balance USDT is not enough");

            if(user.balanceCoinTop > 0) {
                uint256 oldBonus = calculateBonus(msg.sender);
                if(oldBonus > 0) {
                    DOGE.transfer(msg.sender, oldBonus);
                }
            }

            user.packageCoinTop = packageType;
            user.balanceCoinTop = user.balanceCoinTop.add(amount.div(10**18).mul(10**8).mul(decimalDOGEPrice).div(dogePrice));
            user.miningCoinTopAt = block.timestamp;
            user.bonusDebtCoinTop = 0;
            user.isMiningCoinTop = true;
            user.isCompanyMiningCoinTop = isCompany;

            USDT.transferFrom(msg.sender, address(this), amount);
        }

        emit BuyMiningPackage(msg.sender, tokenType, packageType, amount, isCompany);
        return true;
    }

    function withdraw() public {
        _withdraw(msg.sender);
    }

    function claim() public {
        _claim(msg.sender);
    }

    /* --INTERNAL-- */

    function _withdraw(address account) private nonReentrant {
        UserInfo storage user = userInfo[account];
        require(account != address(0), "account must not zero address");
        require(user.balanceCoinTop > 0, "sender dont have a mining DOGE");
        if(checkWithdraw(account) == true) {
            uint256 amount = user.balanceCoinTop;
            uint256 balCoinTop = balanceDOGE();
            require(balCoinTop >= amount, "smartcontract is not enough DOGE");
            user.balanceCoinTop = 0;
            user.miningCoinTopAt = 0;
            user.bonusDebtCoinTop = 0;
            user.isMiningCoinTop = false;
            user.packageCoinTop = 0;
            DOGE.transfer(account, amount);
        }
        
        emit Withdraw(account);
    }

    function _claim(address account) private nonReentrant {
        uint256 bonus = 0;
        uint256 bonusReturn = 0;
        require(userInfo[msg.sender].balanceCoinTop > 0, "user is not mining");
        bonus = calculateBonus(account);
        require(bonus > 0, "bonus must be greater than zero");
        bonusReturn = bonus.sub(bonus.mul(CLAIM_FEE).div(100));
        userInfo[account].bonusDebtCoinTop = userInfo[account].bonusDebtCoinTop.add(bonus);

        DOGE.transfer(account, bonusReturn);
        
        emit Claim(account);
    }

}