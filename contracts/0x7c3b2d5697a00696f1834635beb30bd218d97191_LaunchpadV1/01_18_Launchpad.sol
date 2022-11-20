// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

struct LockerType {
    string name;
    uint256 timeLock;
    bool isLock;
    bool isExist;
}

interface ILocker {
    function lock(
        address _owner,
        uint256 _amount,
        string memory _locker
    ) external;

    function getLockerType(string memory _locker)
        external
        view
        returns (LockerType memory);
}

contract LaunchpadV1 is
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCastUpgradeable for int256;
    using SafeMathUpgradeable for uint256;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BROKER_ROLE = keccak256("BROKER_ROLE");

    string public currentSellType;
    address public recipientWallet;

    ILocker locker;

    IERC20Upgradeable sandoToken;
    IERC20Upgradeable usdcToken;

    struct SellType {
        string name;
        uint256 tokenRate;
        bool isExist;
    }

    string[] sellTypeName;
    mapping(string => SellType) public sellTypeList;

    event TransferToken(
        string transferType,
        address operator,
        uint256 amountPair,
        uint256 amountToken
    );

    AggregatorV3Interface internal priceFeed;

    function initialize(
        address _sandoAddress,
        address _usdcAddress,
        address _locker,
        address _aggergatorAddress
    ) public initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(BROKER_ROLE, msg.sender);

        sandoToken = IERC20Upgradeable(_sandoAddress);
        usdcToken = IERC20Upgradeable(_usdcAddress);
        locker = ILocker(_locker);
        recipientWallet = msg.sender;

        priceFeed = AggregatorV3Interface(_aggergatorAddress);
    }

    function setCurrentSellType(string memory _sellType)
        public
        whenNotPaused
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(bytes(_sellType).length > 0, "Sell Type: not empty");
        currentSellType = _sellType;
    }

    function setSellType(string memory _sellType, uint256 _tokenRate)
        public
        whenNotPaused
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(bytes(_sellType).length > 0, "Sell Type: not empty");
        require(
            sellTypeList[_sellType].isExist == false,
            "Sell Type: already exist"
        );
        sellTypeList[_sellType] = SellType(_sellType, _tokenRate, true);
        sellTypeName.push(_sellType);
    }

    function unsetSellType(string memory _sellType, bool _exist)
        public
        whenNotPaused
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        sellTypeList[_sellType].isExist = _exist;
    }

    function getSellType(string memory _sellType)
        public
        view
        returns (SellType memory)
    {
        return sellTypeList[_sellType];
    }

    function getSellTypeList() public view returns (SellType[] memory) {
        SellType[] memory _lists = new SellType[](sellTypeName.length);

        for (uint256 index = 0; index < sellTypeName.length; index++) {
            _lists[index] = sellTypeList[sellTypeName[index]];
        }

        return _lists;
    }

    function getLatestRoundData() internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price.toUint256();
    }

    function buyWithCoin() public payable nonReentrant whenNotPaused {
        require(msg.value > 0, "Amount: non zero");

        (bool sent, ) = payable(recipientWallet).call{value: msg.value}("");
        require(sent, "Transfer: Failed to send Ether");

        uint256 price = getLatestRoundData().div(1e8);

        uint256 _buyAmountUSD = msg.value.mul(price);

        uint256 rate = getSellType(currentSellType).tokenRate;
        uint256 _sandoAmount = _buyAmountUSD.div(rate).mul(1 ether);

        require(
            sandoToken.balanceOf(address(this)) >= _sandoAmount,
            "Launchpad: not enough token"
        );

        if (locker.getLockerType(currentSellType).isLock == true) {
            locker.lock(msg.sender, _sandoAmount, currentSellType);
            sandoToken.safeTransfer(address(locker), _sandoAmount);
        } else {
            sandoToken.safeTransfer(msg.sender, _sandoAmount);
        }

        emit TransferToken("buy-eth", msg.sender, _sandoAmount, msg.value);
    }

    function buyWithAdmin(
        uint256 _buyAmount,
        address _buyer,
        string memory _sellType
    ) public nonReentrant whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_buyAmount > 0, "Amount: non zero");

        uint256 rate = getSellType(_sellType).tokenRate;
        uint256 _sandoAmount = _buyAmount.div(rate).mul(1 ether);

        require(
            sandoToken.balanceOf(address(this)) >= _sandoAmount,
            "Launchpad: not enough token"
        );

        if (locker.getLockerType(_sellType).isLock == true) {
            locker.lock(_buyer, _sandoAmount, _sellType);
            sandoToken.safeTransfer(address(locker), _sandoAmount);
        } else {
            sandoToken.safeTransfer(_buyer, _sandoAmount);
        }

        emit TransferToken("buy-with-admin", _buyer, _sandoAmount, _buyAmount);
    }

    function buyFiat(address _buyer, uint256 _fiatAmount)
        public
        nonReentrant
        whenNotPaused
        onlyRole(BROKER_ROLE)
    {
        require(_fiatAmount > 0, "Amount: non zero");
        require(_buyer != address(0), "Buyer: non zero address");

        uint256 rate = getSellType(currentSellType).tokenRate;
        uint256 _sandoAmount = _fiatAmount.div(rate).mul(1 ether);

        require(
            sandoToken.balanceOf(address(this)) >= _sandoAmount,
            "Launchpad: not enough token"
        );

        if (locker.getLockerType(currentSellType).isLock == true) {
            locker.lock(_buyer, _sandoAmount, currentSellType);
            sandoToken.safeTransfer(address(locker), _sandoAmount);
        } else {
            sandoToken.safeTransfer(_buyer, _sandoAmount);
        }

        emit TransferToken("buy-fiat", _buyer, _sandoAmount, _fiatAmount);
    }

    function adminWithdraw(uint256 _amount)
        public
        nonReentrant
        whenNotPaused
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            sandoToken.balanceOf(address(this)) >= _amount,
            "Launchpad: not enough token"
        );

        sandoToken.safeTransfer(msg.sender, _amount);
    }
}