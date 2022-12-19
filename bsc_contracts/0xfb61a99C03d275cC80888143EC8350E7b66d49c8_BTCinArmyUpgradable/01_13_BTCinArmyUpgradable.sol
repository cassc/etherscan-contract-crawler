//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface IERC20_EXTENDED {
    function name() external returns (string memory);

    function decimals() external returns (uint);
}

contract BTCinArmyUpgradable is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using SafeMathUpgradeable for uint256;

    string public tokenName;
    uint256 public tokenDecimals;
    uint256 public tokenSupply;

    address private tokenContract;

    uint256 private rewardRate;

    receive() external payable {}

    address payable[] private globalAddress;
    uint256 private totalRewardDistributed;
    uint256 private totalRegistrations;

    address payable private defaultReferrer;
    bool private isPayReward;

    struct Account {
        address payable referrer;
        bool payReward;
        address[] referee;
        uint256[] globalId;
        uint256 globalIdCount;
        uint256 totalBusiness;
        uint256[] rewardPaid;
        address[] rewardPaidBy;
        uint256[] rewardPaidTimestamp;
    }

    mapping(address => Account) private accounts;

    uint256 private contribution;

    event Registration(
        address indexed account,
        uint256 indexed value,
        uint256 index
    );

    event RegistrationFailed(
        address indexed referrer,
        address indexed account,
        string indexed reason
    );

    event RewardPaid(
        address indexed referrer,
        address indexed account,
        uint256 indexed amount
    );

    event GlobalRewardPaid(
        address indexed beneficiary,
        address indexed account,
        uint256 indexed amount
    );

    event ReferrerAdded(address indexed referrer, address indexed referee);

    event GlobalAddressAdded(address indexed referrer, uint256 index);

    function initialize() external initializer {
        tokenContract = 0x925eBDb158043bb126aBD16Ebc3efA911127ae4C;

        tokenName = IERC20_EXTENDED(tokenContract).name();
        tokenDecimals = IERC20_EXTENDED(tokenContract).decimals();
        tokenSupply = IERC20Upgradeable(tokenContract).totalSupply();

        defaultReferrer = payable(0xefc3C922b8DA6517927B8cEc17604020ACA1e67e);
        globalAddress.push(defaultReferrer);

        contribution = 150 * 10 ** tokenDecimals;

        rewardRate = 100;

        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function getContribution() external view returns (uint256) {
        return contribution;
    }

    function setContribution(uint256 _value) external onlyOwner returns (bool) {
        contribution = _value;
        return true;
    }

    function getGlobalAddress()
        external
        view
        returns (address payable[] memory)
    {
        return globalAddress;
    }

    function addGlobalAddress(address[] calldata _address) external onlyOwner {
        uint8 addressLength = uint8(_address.length);
        for (uint8 i; i < addressLength; i++) {
            globalAddress.push(payable(_address[i]));
        }
    }

    function getTotalRewardDistributed() external view returns (uint256) {
        return totalRewardDistributed;
    }

    function getTotalRegistrations() external view returns (uint256) {
        return totalRegistrations;
    }

    function AccountMap(address addr) external view returns (Account memory) {
        return accounts[addr];
    }

    function getDefaultReferrer() public view returns (address) {
        return defaultReferrer;
    }

    function setDefaultReferrer(address payable _address) public onlyOwner {
        defaultReferrer = _address;
    }

    function getTokenContract() external view returns (address) {
        return tokenContract;
    }

    function setTokenContractAdmin(
        address _address
    ) external onlyOwner returns (bool) {
        tokenContract = _address;
        tokenName = IERC20_EXTENDED(_address).name();
        tokenDecimals = IERC20_EXTENDED(_address).decimals();
        tokenSupply = IERC20Upgradeable(_address).totalSupply();

        return true;
    }

    function getRewardRate() external view returns (uint256) {
        return rewardRate;
    }

    function setRewardRate(uint256 _value) external onlyOwner returns (bool) {
        rewardRate = _value;
        return true;
    }

    function getUserRefereeAddress(
        address _address
    ) external view returns (address[] memory userRefereeAddress) {
        Account storage userAccount = accounts[_address];
        userRefereeAddress = userAccount.referee;
    }

    function getUserRefereeCount(
        address _address
    ) external view returns (uint256 userRefereeCount) {
        Account storage userAccount = accounts[_address];
        userRefereeCount = userAccount.referee.length;
    }

    function getUserTotalBusiness(
        address _address
    ) external view returns (uint256 userTotalBusiness) {
        Account storage userAccount = accounts[_address];
        userTotalBusiness = userAccount.totalBusiness;
    }

    function getUserTotalRewardPaid(
        address _address
    ) external view returns (uint256 userTotalRewardPaid) {
        Account storage userAccount = accounts[_address];
        uint256 length = userAccount.rewardPaid.length;
        for (uint256 i; i < length; i++) {
            userTotalRewardPaid += userAccount.rewardPaid[i];
        }
    }

    function getUserGlobalIdCount(
        address _address
    ) external view returns (uint256 globalIdCount) {
        Account storage userAccount = accounts[_address];
        uint256 length = userAccount.globalId.length;
        for (uint256 i; i < length; i++) {
            globalIdCount += userAccount.rewardPaid[i];
        }
    }

    function hasReferrer(address addr) private view returns (bool) {
        return accounts[addr].referrer != address(0);
    }

    function getUserReferrerAddress(
        address _address
    ) external view returns (address referrer) {
        Account storage userAccount = accounts[_address];
        referrer = userAccount.referrer;
    }

    function getReferredCount(
        address _address
    ) external view returns (uint256 referredCount) {
        referredCount = accounts[_address].referee.length;
    }

    function _addReferrer(
        address _referrer,
        address _address
    ) private returns (bool) {
        if (accounts[_address].referrer != address(0)) {
            emit RegistrationFailed(
                _referrer,
                _address,
                "Address already have referrer."
            );

            return false;
        }

        Account storage userAccount = accounts[_address];
        Account storage referrerAccount = accounts[_referrer];
        userAccount.referrer = payable(_referrer);
        referrerAccount.referee.push(_address);
        emit ReferrerAdded(_referrer, _address);

        if (!hasReferrer(_referrer)) {
            referrerAccount.referrer = defaultReferrer;
            emit ReferrerAdded(defaultReferrer, _referrer);
        }

        return true;
    }

    function _getRandomNo() private view returns (address randomGlobalAddress) {
        uint256 randomIndex = uint256(
            keccak256(
                abi.encodePacked(block.difficulty, block.timestamp, msg.sender)
            )
        ) % globalAddress.length;
        randomGlobalAddress = globalAddress[randomIndex];
    }

    function _payReward(uint256 _value, address _user) private {
        Account storage userAccount = accounts[_user];
        Account storage userReferrerAccount = accounts[userAccount.referrer];
        uint256 rewardValue = _value.mul(rewardRate).div(100);
        bool payGlobalReward = userReferrerAccount.payReward;

        if (payGlobalReward) {
            address randomGlobalAddress = _getRandomNo();
            Account storage globalAddressAccount = accounts[
                randomGlobalAddress
            ];

            globalAddressAccount.rewardPaid.push(rewardValue);
            globalAddressAccount.rewardPaidBy.push(_user);
            globalAddressAccount.rewardPaidTimestamp.push(block.timestamp);
            userReferrerAccount.globalId.push(globalAddress.length - 1);
            globalAddress.push(userAccount.referrer);

            IERC20Upgradeable(tokenContract).transferFrom(
                _user,
                randomGlobalAddress,
                rewardValue
            );

            emit GlobalAddressAdded(
                userAccount.referrer,
                globalAddress.length - 1
            );
            emit GlobalRewardPaid(randomGlobalAddress, _user, rewardValue);
        } else {
            userReferrerAccount.rewardPaid.push(rewardValue);
            userReferrerAccount.rewardPaidBy.push(_user);
            userReferrerAccount.rewardPaidTimestamp.push(block.timestamp);

            IERC20Upgradeable(tokenContract).transferFrom(
                _user,
                userAccount.referrer,
                rewardValue
            );

            emit RewardPaid(userAccount.referrer, _user, rewardValue);
        }

        userReferrerAccount.payReward = !userReferrerAccount.payReward;
        userReferrerAccount.totalBusiness += _value;
        totalRewardDistributed += rewardValue;
    }

    function addReferrerAdmin(
        address _referrer,
        address _address
    ) external onlyOwner returns (bool) {
        _addReferrer(_referrer, _address);
        return true;
    }

    function register(address _referrer) external whenNotPaused {
        uint256 _value = contribution;

        if (!hasReferrer(msg.sender) && _referrer != address(0)) {
            _addReferrer(_referrer, msg.sender);
        }

        if (hasReferrer(msg.sender)) {
            _payReward(_value, msg.sender);
            totalRegistrations += 1;
            emit Registration(msg.sender, _value, totalRegistrations);
        }
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function pauseAdmin() external onlyOwner {
        _pause();
    }

    function unpauseAdmin() external onlyOwner {
        _unpause();
    }

    function sendNativeFundsAdmin(
        address _address,
        uint256 _value
    ) external onlyOwner {
        payable(_address).transfer(_value);
    }

    function withdrawAdmin() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawTokenAdmin(
        address _tokenAddress,
        uint256 _value
    ) external onlyOwner {
        IERC20Upgradeable(_tokenAddress).transfer(msg.sender, _value);
    }
}