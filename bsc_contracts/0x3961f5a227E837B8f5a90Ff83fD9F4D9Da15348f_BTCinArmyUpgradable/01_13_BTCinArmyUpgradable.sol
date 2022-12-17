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

    event Registration(address indexed account, uint256 indexed value);

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

    event GlobalAddressAdded(address indexed referrer);

    function initialize() external initializer {
        tokenContract = 0x925eBDb158043bb126aBD16Ebc3efA911127ae4C;

        tokenName = IERC20_EXTENDED(tokenContract).name();
        tokenDecimals = IERC20_EXTENDED(tokenContract).decimals();
        tokenSupply = IERC20Upgradeable(tokenContract).totalSupply();

        isPayReward = true;
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

    function isPayRewardEnable() external view returns (bool) {
        return isPayReward;
    }

    function setPayReferralAdmin(bool _bool) external onlyOwner returns (bool) {
        isPayReward = _bool;
        return true;
    }

    function hasReferrer(address addr) public view returns (bool) {
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
        referrerAccount.payReward = true;
        referrerAccount.referee.push(_address);
        emit ReferrerAdded(_referrer, _address);
        return true;
    }

    function _getRandomGlobalAddress()
        private
        view
        returns (address beneficiaryAddress)
    {
        uint256 randomIndex = uint256(
            keccak256(
                abi.encodePacked(block.difficulty, block.timestamp, msg.sender)
            )
        ) % globalAddress.length;
        beneficiaryAddress = globalAddress[randomIndex];
    }

    function _payReward(uint256 _value, address _referee) private {
        Account storage userAccount = accounts[_referee];
        Account storage userReferrerAccount = accounts[userAccount.referrer];
        uint256 rewardValue = _value.mul(rewardRate).div(100);

        if (
            userAccount.referrer != address(0) &&
            userReferrerAccount.payReward == true
        ) {
            address randomGlobalAddress = _getRandomGlobalAddress();
            Account storage randomGlobalAddressAccount = accounts[
                randomGlobalAddress
            ];

            userReferrerAccount.globalId.push(globalAddress.length - 1);
            userReferrerAccount.globalIdCount += 1;
            randomGlobalAddressAccount.rewardPaid.push(rewardValue);
            randomGlobalAddressAccount.rewardPaidBy.push(_referee);
            randomGlobalAddressAccount.rewardPaidTimestamp.push(
                block.timestamp
            );
            globalAddress.push(userAccount.referrer);

            IERC20Upgradeable(tokenContract).transferFrom(
                _referee,
                randomGlobalAddress,
                rewardValue
            );

            userReferrerAccount.payReward = false;
            emit GlobalRewardPaid(randomGlobalAddress, _referee, rewardValue);
        } else if (
            userAccount.referrer != address(0) &&
            userReferrerAccount.payReward == false
        ) {
            IERC20Upgradeable(tokenContract).transferFrom(
                _referee,
                userAccount.referrer,
                rewardValue
            );

            userReferrerAccount.rewardPaid.push(rewardValue);
            userReferrerAccount.rewardPaidBy.push(_referee);
            userReferrerAccount.rewardPaidTimestamp.push(block.timestamp);
            userReferrerAccount.payReward = true;
            emit RewardPaid(userAccount.referrer, _referee, rewardValue);
        }

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
        Account storage userAccount = accounts[msg.sender];
        Account storage referrerAccount = accounts[_referrer];
        uint256 _value = contribution;

        if (!hasReferrer(msg.sender) && _referrer != address(0)) {
            _addReferrer(_referrer, msg.sender);
        }

        if (referrerAccount.referrer == address(0)) {
            _addReferrer(defaultReferrer, _referrer);
        }

        if (userAccount.referrer != address(0)) {
            referrerAccount.totalBusiness += _value;
        }

        if (isPayReward) {
            _payReward(_value, msg.sender);
        }

        totalRegistrations += 1;
        emit Registration(msg.sender, _value);
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