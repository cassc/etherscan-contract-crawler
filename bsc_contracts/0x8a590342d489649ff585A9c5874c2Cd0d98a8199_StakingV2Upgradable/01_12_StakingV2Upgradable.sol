//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface IERC20_EXTENDED {
    function name() external returns (string memory);

    function symbol() external returns (string memory);

    function decimals() external returns (uint);

    function owner() external returns (address);

    function GetTokenOwnerAddress() external returns (address);
}

contract StakingV2Upgradable is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    PausableUpgradeable
{
    using AddressUpgradeable for address;

    string private TokenName;
    string private TokenSymbol;
    uint256 private TokenDecimals;
    uint256 private TokenTotalSupply;
    IERC20Upgradeable private TokenContractAddress;
    address private TokenOwnerAddress;
    address private PresaleContractAddress;

    uint256 private TotalStaked;
    uint256 private TotalStakers;
    uint256 private RewardRate;
    uint256 private MaxRewardDuration;

    struct StakedRewardInfo {
        bool isStaked;
        uint256 StartTime;
        uint256 EndTime;
        uint256 Amount;
        uint256 LastTimeRewardClaimed;
        uint256 RewardClaimed;
    }

    event Staked(address indexed from, uint256 amount);
    event UnStaked(address indexed from, uint256 amount);
    event RewardClaimed(address indexed from, uint256 amount);

    mapping(address => StakedRewardInfo) private StakedInfoMap;

    receive() external payable {
        // BuyWithBNB(payable(address(0)));
    }

    function initialize() public initializer {

        // TokenContractAddress = IERC20Upgradeable(
        //     0x534743c5Ed9E11a95bE72C8190ae627067cc33b7
        // );
        // PresaleContractAddress;
        // TokenOwnerAddress = 0x49827482BdeB954EF760D6e25e7Bee0b9a422994;

        TokenContractAddress = IERC20Upgradeable(
            0x0F0EC170DEAF700CAf78aA12806A22E3c8f7621a
        );
        PresaleContractAddress = 0xBA34d8E1C9D8af8d6843F1d9455f6432fDCB0280;
        TokenOwnerAddress = 0x7a0DeC713157f4289E112f5B8785C4Ae8B298F7F;

        TokenName = IERC20_EXTENDED(address(TokenContractAddress)).name();
        TokenSymbol = IERC20_EXTENDED(address(TokenContractAddress)).symbol();
        TokenDecimals = IERC20_EXTENDED(address(TokenContractAddress))
            .decimals();
        TokenTotalSupply = TokenContractAddress.totalSupply();

        RewardRate = 10;
        MaxRewardDuration = 90 days;

        __Ownable_init();
        __UUPSUpgradeable_init();
        __Pausable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function Stake(uint256 _value) external whenNotPaused {
        require(
            TokenContractAddress.balanceOf(msg.sender) > 0,
            "You dont have tokens to stake"
        );
        require(_value > 0, "Stake amount should be greater than 0");

        TokenContractAddress.transferFrom(msg.sender, address(this), _value);

        StakedRewardInfo storage userStakedInfoMap = StakedInfoMap[msg.sender];

        uint256 userStakingReward = GetReward(msg.sender);

        if(userStakedInfoMap.isStaked == false) {
            userStakedInfoMap.isStaked = true;
            userStakedInfoMap.StartTime = block.timestamp;
            userStakedInfoMap.EndTime = block.timestamp + MaxRewardDuration;
            userStakedInfoMap.Amount = _value;
            TotalStaked += _value;
            TotalStakers++;
            emit Staked(msg.sender, _value);
        } else {
            userStakedInfoMap.StartTime = block.timestamp;
            userStakedInfoMap.StartTime = block.timestamp;
            userStakedInfoMap.EndTime = block.timestamp + MaxRewardDuration;
            userStakedInfoMap.Amount += _value + userStakingReward;
            userStakedInfoMap.LastTimeRewardClaimed = block.timestamp;
            userStakedInfoMap.RewardClaimed += userStakingReward;
            TotalStaked += _value + userStakingReward;
            emit RewardClaimed(msg.sender, userStakingReward);
            emit Staked(msg.sender, _value + userStakingReward);
        }
    }

    function StakeToAddress(address _address, uint256 _value)
        external
        whenNotPaused
    {
        require(
            msg.sender == PresaleContractAddress ||
                msg.sender == address(TokenOwnerAddress),
            "Only presale contract or token owner can use this function."
        );

        require(
            TokenContractAddress.balanceOf(TokenOwnerAddress) > 0,
            "Contract Owner has no enough tokens to stake"
        );

        require(_value > 0, "Stake amount should be greater than 0");

        StakedRewardInfo storage userStakedInfoMap = StakedInfoMap[_address];
        uint256 userStakingReward = GetReward(_address);

        if(userStakedInfoMap.isStaked == false) {
            userStakedInfoMap.isStaked = true;
            userStakedInfoMap.StartTime = block.timestamp;
            userStakedInfoMap.EndTime = block.timestamp + MaxRewardDuration;
            userStakedInfoMap.Amount = _value;
            TotalStaked += _value;
            TotalStakers++;
            emit Staked(_address, _value);
        } else {
            userStakedInfoMap.StartTime = block.timestamp;
            userStakedInfoMap.StartTime = block.timestamp;
            userStakedInfoMap.EndTime = block.timestamp + MaxRewardDuration;
            userStakedInfoMap.Amount += _value + userStakingReward;
            userStakedInfoMap.LastTimeRewardClaimed = block.timestamp;
            userStakedInfoMap.RewardClaimed += userStakingReward;
            TotalStaked += _value + userStakingReward;
            emit RewardClaimed(_address, userStakingReward);
            emit Staked(_address, _value + userStakingReward);
        }
    }

    function GetReward(address _address) public view returns (uint256) {
        if (
            StakedInfoMap[_address].isStaked == true &&
            StakedInfoMap[_address].LastTimeRewardClaimed == 0
        ) {
            return
                ((((StakedInfoMap[_address].Amount / TokenDecimals) *
                    RewardRate) / 100) / 30 days) *
                TokenDecimals *
                _min(
                    (block.timestamp - StakedInfoMap[_address].StartTime),
                    (StakedInfoMap[_address].EndTime -
                        StakedInfoMap[_address].StartTime)
                );
        } else if (
            StakedInfoMap[_address].isStaked == true &&
            StakedInfoMap[_address].LastTimeRewardClaimed > 0
        ) {
            return
                ((((StakedInfoMap[_address].Amount / TokenDecimals) *
                    RewardRate) / 100) / 30 days) *
                TokenDecimals *
                _min(
                    (block.timestamp -
                        StakedInfoMap[_address].LastTimeRewardClaimed),
                    (StakedInfoMap[_address].EndTime -
                        StakedInfoMap[_address].LastTimeRewardClaimed)
                );
        }

        return 0;
    }

    function UnStake() external whenNotPaused {
        require(
            StakedInfoMap[msg.sender].isStaked = true,
            "You have not staked tokens"
        );

        StakedRewardInfo storage userStakedInfoMap = StakedInfoMap[msg.sender];

        uint _reward = GetReward(msg.sender);
        uint256 _value = userStakedInfoMap.Amount + _reward;
        if (TokenContractAddress.balanceOf(address(this)) > _value) {
            TokenContractAddress.transfer(msg.sender, _value);
        } else if (TokenContractAddress.balanceOf(address(this)) < _value) {
            TokenContractAddress.transferFrom(
                TokenOwnerAddress,
                msg.sender,
                _value
            );
        }

        TotalStaked -= userStakedInfoMap.Amount;

        userStakedInfoMap.isStaked = false;
        userStakedInfoMap.StartTime = 0;
        userStakedInfoMap.EndTime = 0;
        userStakedInfoMap.Amount = 0;
        userStakedInfoMap.LastTimeRewardClaimed = 0;
        userStakedInfoMap.RewardClaimed += _reward;

        TotalStakers--;
        emit UnStaked(msg.sender, userStakedInfoMap.Amount);
        emit RewardClaimed(msg.sender, _reward);
    }

    function SetPresaleContractAddressAdmin(address _address)
        external
        onlyOwner
    {
        PresaleContractAddress = _address;
    }

    function GetPresaleContractAddress() external view returns (address) {
        return PresaleContractAddress;
    }

    function GetTokenOwnerAddress() external view returns (address) {
        return TokenOwnerAddress;
    }

    function ClaimReward() external whenNotPaused {
        require(
            StakedInfoMap[msg.sender].isStaked = true,
            "You have not staked tokens"
        );
        require(
            GetReward(msg.sender) > 0,
            "You dont have enough reward to withdraw"
        );

        uint256 _reward = GetReward(msg.sender);
        TokenContractAddress.transfer(msg.sender, _reward);

        StakedInfoMap[msg.sender].LastTimeRewardClaimed = block.timestamp;

        StakedInfoMap[msg.sender].RewardClaimed += _reward;

        emit RewardClaimed(msg.sender, _reward);
    }

    function GetStakedInfoMap(address _address)
        external
        view
        returns (StakedRewardInfo memory)
    {
        return StakedInfoMap[_address];
    }

    function SetStakedInfoMap(
            address _address,
            bool _bool,
            uint256 _startTime,
            uint256 _endTime,
            uint256 _amount,
            uint256 _lastTimeRewardClaimed,
            uint256 _rewardClaimed
        )
        external
        onlyOwner
        returns (bool)
    {
        StakedInfoMap[_address] =  StakedRewardInfo ({
            isStaked: _bool,
            StartTime: _startTime,
            EndTime: _endTime,
            Amount: _amount,
            LastTimeRewardClaimed: _lastTimeRewardClaimed,
            RewardClaimed: _rewardClaimed
        });

        return true;
    }

    function GetRewardRate() external view returns (uint256) {
        return RewardRate;
    }

    function SetRewardRateAdmin(uint256 _value) external onlyOwner {
        RewardRate = _value;
    }

    function SetMaxRewardDurationAdmin(uint256 _time) external onlyOwner {
        MaxRewardDuration = _time;
    }

    function GetTotalStaked() external view returns (uint256) {
        return TotalStaked;
    }

    function GetTotalStakers() external view returns (uint256) {
        return TotalStakers;
    }

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }

    function GetTokenName() external view returns (string memory) {
        return TokenName;
    }

    function GetTokenSymbol() external view returns (string memory) {
        return TokenSymbol;
    }

    function GetTokenDecimals() external view returns (uint256) {
        return TokenDecimals;
    }

    function GetTokenSupply() external view returns (uint256) {
        return TokenTotalSupply;
    }

    function GetTokenContractAddress() external view returns (address) {
        return address(TokenContractAddress);
    }

    function ChangeTokenContractAdmin(IERC20Upgradeable _address)
        external
        onlyOwner
    {
        TokenContractAddress = _address;
        TokenName = IERC20_EXTENDED(address(_address)).name();
        TokenDecimals = IERC20_EXTENDED(address(_address)).decimals();
        TokenTotalSupply = IERC20Upgradeable(_address).totalSupply();
    }

    function SetTokenOwnerAdmin(address _address) external onlyOwner {
        TokenOwnerAddress = _address;
    }

    function SendNativeFundsAdmin(address _address, uint256 _value)
        external
        onlyOwner
    {
        payable(_address).transfer(_value);
    }

    function WithdrawAdmin() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function WithdrawTokenAdmin(address _tokenAddress, uint256 _value)
        external
        onlyOwner
    {
        IERC20Upgradeable(_tokenAddress).transfer(msg.sender, _value);
    }

    function Time() public view returns (uint256) {
        return block.timestamp;
    }
}