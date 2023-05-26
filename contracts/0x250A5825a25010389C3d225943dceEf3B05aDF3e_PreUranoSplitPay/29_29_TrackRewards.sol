// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./PreUtils.sol";
import "./InterfaceManageRewards.sol";

contract TrackRewards is Ownable, InterfaceManageRewards {
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    EnumerableMap.AddressToUintMap private addrToRewardRate;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private enabledAddressSet;
    

    event RewardManagerAdded(address indexed newRewardManager);
    event RewardManagerRemoved(address indexed oldRewardManager);
    event MainUsdRecipientUpdate(
        address indexed oldusdRecipient,
        address indexed newUsdRecipient
    );
    event ManagerAddressUpdateRewardForAddress(
        address indexed manager,
        address indexed rewardedAddress,
        uint16 decimillReward
    );

    function addOrUpdateRewardAddress(
        address _recipientAddress,
        uint16 _decimillReward
    ) public onlyRewardManager {
        require(_decimillReward >= 0, "reward too low");
        require(
            _decimillReward <= PreUtils.TEN_THOUSANDTH_PERCENT,
            "reward too high"
        );
        if (!enabledAddressSet.contains(_recipientAddress)) {
            enabledAddressSet.add(_recipientAddress);
        }
        addrToRewardRate.set(_recipientAddress, _decimillReward);
        emit ManagerAddressUpdateRewardForAddress(msg.sender, _recipientAddress, _decimillReward);
    }

    function listRegisteredRewardAddresses()
        external
        view
        returns (address[] memory)
    {
        return enabledAddressSet.values();
    }

    function getRewardByAddress(address _targetAddress)
        external
        view
        returns (uint16)
    {
        require(
            EnumerableSet.contains(enabledAddressSet, _targetAddress),
            "Address is not configured"
        );
        return uint16(EnumerableMap.get(addrToRewardRate, _targetAddress));
    }

    function isRegisteredRewardAddress(address _rewardAddress)
        external
        view
        returns (bool)
    {
        return enabledAddressSet.contains(_rewardAddress);
    }

    //main usdt recipient address
    address public mainUsdtRecipient;

    //reward manager
    EnumerableSet.AddressSet private rewardsManagerSet;

    // solhint-disable-next-line
    constructor() {
        authorizeRewardsManager(msg.sender);
        mainUsdtRecipient = msg.sender;
    }

    // MANAGEMENT

    function setMainRecipientAddress(address _mainUsdtRecipient)
        public
        onlyOwner
    {
        address oldUsdRec = mainUsdtRecipient;
        mainUsdtRecipient = _mainUsdtRecipient;
        emit MainUsdRecipientUpdate(oldUsdRec, mainUsdtRecipient);
    }

    function getMainUsdRecipient() external view returns (address) {
        return mainUsdtRecipient;
    }

    //only owner can authorize reward manager
    function authorizeRewardsManager(address _sellManagerAddress)
        public
        onlyOwner
    {
        rewardsManagerSet.add(_sellManagerAddress);
        emit RewardManagerAdded(_sellManagerAddress);
    }

    function _isAuthorizedRewardmanager(address _rewardsManager)
        public
        view
        returns (bool)
    {
        return rewardsManagerSet.contains(_rewardsManager);
    }

    function isAuthorizedRewardmanager(address _rewardsManager)
        public
        view
        returns (bool)
    {
        return _isAuthorizedRewardmanager(_rewardsManager);
    }

    modifier onlyRewardManager() {
        require(
            _isAuthorizedRewardmanager(msg.sender),
            "required authorized reward manager"
        );
        _;
    }

    //only owner can remove reward manager
    function deauthorizeRewardsManager(address _sellManagerAddress)
        public
        onlyOwner
    {
        require(
            _sellManagerAddress != owner(),
            "it is not possible to remove the contract owner from the rewards managers."
        );
        rewardsManagerSet.remove(_sellManagerAddress);
        emit RewardManagerRemoved(_sellManagerAddress);
    }

    function listRewardsManagers() public view returns (address[] memory) {
        return rewardsManagerSet.values();
    }
}