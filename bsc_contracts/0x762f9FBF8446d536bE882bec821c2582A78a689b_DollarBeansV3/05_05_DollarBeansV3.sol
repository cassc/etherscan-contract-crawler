// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract DollarBeansV3 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public devAddress;
    address public ceoAddress;
    address public marketingAddress;
    address public busdAddress;

    uint256 public constant DEV_ADDRESS = 10;
    uint256 public constant MARKETING_ADDRESS = 10;
    uint256 public constant CEO_ADDRESS = 10;

    uint256 private constant MIN_INVESTMENT = 10 ether;
    uint256 private constant TIME_STEP = 1 days;
    // uint256 private constant TIME_STEP = 1 minutes; //fast test mode
    uint256 private constant DAILY_INTEREST_RATE = 20;
    uint256 private constant PERCENTS_DIVIDER = 1000;
    uint256 private constant TOTAL_RETURN = 7300;
    uint256 private constant TOTAL_REF = 105;
    uint256[] private REFERRAL_PERCENTS = [50, 30, 15, 5, 5];

    mapping(address => uint256) public userReferral;

    uint256 public totalInvested;
    uint256 public totalWithdrawal;
    uint256 public totalReferralReward;

    struct Investor {
        address addr;
        address ref;
        uint256[5] refs;
        uint256 totalDeposit;
        uint256 totalWithdraw;
        uint256 dividends;
        uint256 totalRef;
        uint256 investmentCount;
        uint256 depositTime;
        uint256 lastWithdrawDate;
    }

    mapping(address => Investor) public investors;

    event OnInvest(address investor, uint256 amount);
    event OnWithdraw(address investor, uint256 amount);

    constructor(
        address _busdAddress,
        address _devAddress,
        address _ceoAddress,
        address _marketingAddress
    ) {
        require(_busdAddress != address(0), "BUSD address cannot be null");
        require(_devAddress != address(0), "Dev address cannot be null");
        require(_ceoAddress != address(0), "CEO address cannot be null");
        require(
            _marketingAddress != address(0),
            "Marketing address cannot be null"
        );

        busdAddress = _busdAddress;
        devAddress = _devAddress;
        ceoAddress = _ceoAddress;
        marketingAddress = _marketingAddress;
    }

    function changeBUSDAddress(address newAddress) public onlyOwner {
        require(newAddress != address(0), "Address cannot be null");
        busdAddress = newAddress;
    }

    function changeDevBenificiary(address newAddress) public onlyOwner {
        require(newAddress != address(0), "Address cannot be null");
        devAddress = newAddress;
    }

    function changeMarketingBenificiary(address newAddress) public onlyOwner {
        require(newAddress != address(0), "Address cannot be null");
        marketingAddress = newAddress;
    }

    function changeCeoBenificiary(address newAddress) public onlyOwner {
        require(newAddress != address(0), "Address cannot be null");
        ceoAddress = newAddress;
    }

    function invest(uint256 _amount, address _ref) public {
        if (_invest(msg.sender, _ref, _amount)) {
            emit OnInvest(msg.sender, _amount);
        }
    }

    function getBalance() public view returns (uint256) {
        return IERC20(busdAddress).balanceOf(address(this));
    }

    function _invest(
        address _addr,
        address _ref,
        uint256 _amount
    ) private returns (bool) {
        require(_amount >= MIN_INVESTMENT, "Minimum investment is 10 BUSD");
        if (_ref == _addr) {
            _ref = address(0);
        }

        IERC20(busdAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        Investor storage _investor = investors[_addr];
        uint256 referralAmount;
        if (_investor.addr == address(0)) {
            _investor.addr = _addr;
            _investor.depositTime = block.timestamp;
            _investor.lastWithdrawDate = block.timestamp;
        }

        if (_investor.ref == address(0)) {
            if (investors[_ref].totalDeposit > 0) {
                _investor.ref = _ref;
            }

            address upline = _investor.ref;
            for (uint256 i = 0; i < 5; i++) {
                if (upline != address(0)) {
                    investors[upline].refs[i] = investors[upline].refs[i].add(
                        1
                    );
                    upline = investors[upline].ref;
                } else break;
            }
        }

        if (_investor.ref != address(0)) {
            address upline = _investor.ref;
            for (uint256 i = 0; i < 5; i++) {
                if (upline != address(0)) {
                    uint256 amount = _amount.mul(REFERRAL_PERCENTS[i]).div(
                        PERCENTS_DIVIDER
                    );
                    investors[upline].totalRef = investors[upline].totalRef.add(
                        amount
                    );
                    totalReferralReward = totalReferralReward.add(amount);
                    IERC20(busdAddress).safeTransfer(upline, amount);
                    userReferral[upline] += amount;
                    referralAmount += amount;
                    upline = investors[upline].ref;
                } else break;
            }
        }

        _amount = _amount.sub(referralAmount);

        if (block.timestamp > _investor.depositTime) {
            _investor.dividends = getDividends(_addr);
        }
        _investor.depositTime = block.timestamp;
        _investor.investmentCount = _investor.investmentCount.add(1);
        _investor.totalDeposit = _investor.totalDeposit.add(_amount);
        totalInvested = totalInvested.add(_amount);

        _sendRewardOnInvestment(_amount);
        return true;
    }

    function _sendRewardOnInvestment(uint256 _amount) private {
        require(_amount > 0, "Amount must be greater than 0");

        uint256 devPart = _amount.mul(DEV_ADDRESS).div(PERCENTS_DIVIDER);
        uint256 ceoPart = _amount.mul(CEO_ADDRESS).div(PERCENTS_DIVIDER);
        uint256 marketingPart = _amount.mul(MARKETING_ADDRESS).div(
            PERCENTS_DIVIDER
        );

        IERC20(busdAddress).safeTransfer(devAddress, devPart);
        IERC20(busdAddress).safeTransfer(ceoAddress, ceoPart);
        IERC20(busdAddress).safeTransfer(marketingAddress, marketingPart);
    }

    function payoutOf(
        address _addr
    ) public view returns (uint256 payout, uint256 max_payout) {
        max_payout = investors[_addr].totalDeposit.mul(TOTAL_RETURN).div(
            PERCENTS_DIVIDER
        );

        if (
            investors[_addr].totalWithdraw < max_payout &&
            block.timestamp > investors[_addr].depositTime
        ) {
            payout = investors[_addr]
                .totalDeposit
                .mul(DAILY_INTEREST_RATE)
                .mul(block.timestamp.sub(investors[_addr].depositTime))
                .div(TIME_STEP.mul(PERCENTS_DIVIDER));
            payout = payout.add(investors[_addr].dividends);

            if (investors[_addr].totalWithdraw.add(payout) > max_payout) {
                payout = max_payout.subz(investors[_addr].totalWithdraw);
            }
        }
    }

    function getDividends(address addr) public view returns (uint256) {
        uint256 dividendAmount = 0;
        (dividendAmount, ) = payoutOf(addr);
        return dividendAmount;
    }

    function getContractInformation()
        public
        view
        returns (uint256, uint256, uint256, uint256)
    {
        uint256 contractBalance = getBalance();
        return (
            contractBalance,
            totalInvested,
            totalWithdrawal,
            totalReferralReward
        );
    }

    function withdraw() public {
        require(
            investors[msg.sender].lastWithdrawDate.add(TIME_STEP) <=
                block.timestamp,
            "Withdrawal limit is 1 withdrawal in 24 hours"
        );
        uint256 max_payout = investors[msg.sender]
            .totalDeposit
            .mul(TOTAL_RETURN)
            .div(PERCENTS_DIVIDER);
        uint256 dividendAmount = getDividends(msg.sender);

        if (
            investors[msg.sender].totalWithdraw.add(dividendAmount) > max_payout
        ) {
            dividendAmount = max_payout.subz(
                investors[msg.sender].totalWithdraw
            );
        }

        totalWithdrawal = totalWithdrawal.add(dividendAmount);

        if (dividendAmount > getBalance()) {
            dividendAmount = getBalance();
        }

        investors[msg.sender].totalWithdraw = investors[msg.sender]
            .totalWithdraw
            .add(dividendAmount);
        investors[msg.sender].lastWithdrawDate = block.timestamp;
        investors[msg.sender].depositTime = block.timestamp;
        investors[msg.sender].dividends = 0;

        IERC20(busdAddress).safeTransfer(msg.sender, dividendAmount);
        emit OnWithdraw(msg.sender, dividendAmount);
    }

    function getInvestorRefs(
        address addr
    ) public view returns (uint256, uint256, uint256, uint256, uint256) {
        Investor storage investor = investors[addr];
        return (
            investor.refs[0],
            investor.refs[1],
            investor.refs[2],
            investor.refs[3],
            investor.refs[4]
        );
    }

    function addFunds(uint256 _amount) external onlyOwner {
        IERC20(busdAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
    }

    function withdrawFunds(
        address _address,
        uint256 _amount
    ) external onlyOwner {
        uint256 balance = IERC20(_address).balanceOf(address(this));
        require(_amount <= balance, "Insufficient balance");
        IERC20(_address).safeTransfer(msg.sender, _amount);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function subz(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b >= a) {
            return 0;
        }
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
}