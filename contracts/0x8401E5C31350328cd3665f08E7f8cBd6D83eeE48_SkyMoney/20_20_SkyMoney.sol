//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract SkyMoney is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct User {
        address user;
        address referral;
        uint256 currentlvl;
        uint256 deposited;
        uint256 earned;
        uint256 countOfBuyingLevels;
        address[] referals;
        mapping(uint256 => uint256) countInLevel;
    }
    struct Level {
        uint256 numberLvl;
        uint256 priceToStart;
        uint256 refillCount;
        uint256 refillPercent;
        uint256 MaxCountToBuyLevelSingleAddress;
        uint256 currentSizeArray;
        address[] currentLvlLine;
    }
    IERC20Upgradeable public Token;
    mapping(address => User) public users;
    mapping(uint256 => Level) public levels;
    uint256 public ReferallBonusPercent;
    uint256 public TotalBoughtLevels;
    uint256 public TotalDepositToken;

    event CreatedNewLevel(
        uint256 LevelNumber,
        uint256 PriseToStart,
        uint256 RefillCount,
        uint256 RefillPercent,
        uint256 MaxCountForSingleAddress,
        uint256 Time
    );
    event LevelBought(uint256 LevelNumber, uint256 Time, address User);
    event ReferallGetBonus(
        address Referall,
        address User,
        uint256 Time,
        uint256 LevelNumber
    );
    event EmergencyWithdraw(
        address User,
        uint256 Time,
        uint256 amount,
        uint256 LevelNumber
    );

    function initialize(IERC20Upgradeable token_, address owner_)
        public
        initializer
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, owner_);
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        setPause(true);
        changeReferallPercent(10);
        changeToken(token_);
        createNewLvl(0, 40 * (10**6), 3, 200, 2);
        createNewLvl(1, 90 * (10**6), 4, 150, 1);
        createNewLvl(2, 170 * (10**6), 4, 175, 1); //
        createNewLvl(3, 270 * (10**6), 5, 200, 1); //
        createNewLvl(4, 500 * (10**6), 5, 225, 1);
        createNewLvl(5, 900 * (10**6), 5, 250, 1); //
        createNewLvl(6, 1500 * (10**6), 5, 275, 1);
        createNewLvl(7, 2000 * (10**6), 7, 300, 1);
        createNewLvl(8, 3000 * (10**6), 8, 325, 1);
        setPause(false);
    }

    fallback() external payable {}

    receive() external payable {}

    function getLevel(uint256 _level)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            address[] memory
        )
    {
        Level storage lvl = levels[_level];
        return (
            lvl.priceToStart,
            lvl.refillCount,
            lvl.refillPercent,
            lvl.MaxCountToBuyLevelSingleAddress,
            lvl.currentLvlLine
        );
    }

    function getUser(address _user)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            address[] memory
        )
    {
        User storage user = users[_user];
        return (
            user.referral,
            user.currentlvl,
            user.deposited,
            user.earned,
            user.countOfBuyingLevels,
            user.referals
        );
    }

    function setPause(bool _newPauseState) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _newPauseState ? _pause() : _unpause();
    }

    function currentQueueInLevel(uint256 levelNumber)
        public
        view
        returns (address[] memory)
    {
        Level storage lvl = levels[levelNumber];
        return lvl.currentLvlLine;
    }

    //set refill percent in actual percentage
    //refillcount set with active count of percent who will stand in queue for waiting last man
    function createNewLvl(
        uint256 _numberLvl,
        uint256 _priceStart,
        uint256 _refillCount,
        uint256 _refillPercent,
        uint256 _maxCount
    ) public whenPaused onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
        Level storage lvl = levels[_numberLvl];
        lvl.numberLvl = _numberLvl;
        lvl.priceToStart = _priceStart;
        lvl.refillCount = _refillCount;
        lvl.currentSizeArray = _refillCount;
        lvl.refillPercent = _refillPercent;
        lvl.MaxCountToBuyLevelSingleAddress = _maxCount;
        emit CreatedNewLevel(
            _numberLvl,
            _priceStart,
            _refillCount,
            _refillPercent,
            _maxCount,
            block.timestamp
        );
        return _numberLvl;
    }

    //require refferal is exist and buy some lvl
    function buyLevel(uint256 buyLvl, address _refferal)
        public
        nonReentrant
        whenNotPaused
    {
        User storage user = users[_msgSender()];
        Level storage lvl = levels[buyLvl];
        require(
            _refferal != 0x0000000000000000000000000000000000000000,
            "if you dont have refferal address use address owner"
        );
        user.referral = _refferal;
        require(user.currentlvl + 1 >= buyLvl, "You need to buy earlier level");
        IERC20Upgradeable(Token).safeTransferFrom(
            _msgSender(),
            address(this),
            lvl.priceToStart
        );
        user.currentlvl = buyLvl;
        user.deposited += lvl.priceToStart;
        user.user = _msgSender();
        user.countOfBuyingLevels++;
        user.countInLevel[buyLvl]++;
        TotalDepositToken = TotalDepositToken + lvl.priceToStart;
        //Cant buy one level more then twice
        require(
            user.countInLevel[buyLvl] <= lvl.MaxCountToBuyLevelSingleAddress,
            "You cant buy more this level yet"
        );
        address[] storage current = lvl.currentLvlLine;
        if (lvl.currentSizeArray == current.length) {
            _sendPaymentAndPushInQueue(
                lvl.currentLvlLine,
                _msgSender(),
                buyLvl
            );
            lvl.currentSizeArray = lvl.currentSizeArray + lvl.refillCount;
        } else {
            lvl.currentLvlLine.push(_msgSender());
        }
        TotalBoughtLevels++;
        emit LevelBought(buyLvl, block.timestamp, _msgSender());
    }

    function changeToken(IERC20Upgradeable _token)
        public
        whenPaused
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        Token = _token;
    }

    /////////////////////////////////////////////////////////////////////////
    function closeLevelAndSendReward(uint256 _level)
        public
        whenPaused
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        Level storage level = levels[_level];
        address currentUserAddress;
        address[] storage usersArray = level.currentLvlLine;
        for (uint256 i = 0; i < usersArray.length; i++) {
            currentUserAddress = usersArray[i];
            IERC20Upgradeable(Token).safeTransfer(
                currentUserAddress,
                level.priceToStart
            );
            emit EmergencyWithdraw(
                currentUserAddress,
                block.timestamp,
                level.priceToStart,
                level.numberLvl
            );
        }
        delete level.currentLvlLine;
    }

    ///////////////////////////////////////////////////////////////////////
    function _sendPaymentAndPushInQueue(
        address[] storage array,
        address newUser,
        uint256 _lvle
    ) internal {
        Level storage lvl = levels[_lvle];
        address paymentToUser = array[0];
        User storage user = users[paymentToUser];
        uint256 amountForlvl = (lvl.priceToStart / 100) * lvl.refillPercent;
        user.earned = user.earned + amountForlvl;
        IERC20Upgradeable(Token).safeTransfer(paymentToUser, amountForlvl);
        array = _remove(array, 0);
        array.push(newUser);
        _sendToRefferalPercent(paymentToUser);
        user.countInLevel[_lvle]--;
        lvl.currentLvlLine = array;
        emit ReferallGetBonus(
            user.referral,
            user.user,
            block.timestamp,
            lvl.numberLvl
        );
    }

    /////////////////////////////////////////////////////
    function _sendToRefferalPercent(address _user) internal {
        User storage user = users[_user];
        address reseiver = user.referral;
        uint256 lvlCurrentUser = user.currentlvl;
        Level storage lvl = levels[lvlCurrentUser];
        uint256 amountBonus = (lvl.priceToStart / 100) * ReferallBonusPercent;
        User storage refUser = users[user.referral];
        refUser.earned = refUser.earned + amountBonus;
        refUser.referals.push(_user);
        IERC20Upgradeable(Token).safeTransfer(reseiver, amountBonus);
        emit ReferallGetBonus(reseiver, _user, block.timestamp, lvlCurrentUser);
    }

    function changeReferallPercent(uint256 percent)
        public
        whenPaused
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (uint256)
    {
        ReferallBonusPercent = percent;
        return percent;
    }

    function witdhraw(address token, uint256 amount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IERC20Upgradeable(token).safeTransfer(address(_msgSender()), amount);
    }

    function witdhrawETH(address payable _to, uint256 amount) public {
        AddressUpgradeable.sendValue(_to, amount);
    }

    function changeMaxCountBuyLevel(uint256 _level, uint256 _count)
        public
        whenPaused
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (uint256)
    {
        Level storage lvl = levels[_level];
        lvl.MaxCountToBuyLevelSingleAddress = _count;
        return lvl.MaxCountToBuyLevelSingleAddress;
    }

    function _remove(address[] storage arr, uint256 _index)
        internal
        returns (address[] storage)
    {
        require(_index < arr.length, "index out of bound");
        for (uint256 i = _index; i < arr.length - 1; i++) {
            arr[i] = arr[i + 1];
        }
        arr.pop();
        return arr;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}
}