// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SaitaProxy.sol";
import "./interface/IStaking3.sol";
import "./interface/IToken.sol";


contract SaitaStakingFactory is OwnableUpgradeable{

    address internal imp;
    address[] public totalStakingInstances;

    mapping(address => address) public tokenAddrToStakingAddr;

    event Deposit(address indexed stakeProxy, uint128 stakeAmount, uint128 stakeType, address indexed user, uint256 blockTimestamp, uint128 period, uint128 totalStakedInPool);
    event Compound(address indexed stakeProxy, uint128 amount, uint128 stakeType, address indexed user, uint256 blockTimestamp, uint128 period, uint128 totalStakedInPool);
    event Withdraw(address indexed stakeProxy, uint128 amount, uint128 stakeType, address indexed user, uint256 blockTimestamp, uint128 period, uint128 totalStakedInPool);
    event Claim(address indexed stakeProxy,  uint128 amount, uint128 stakeType, address indexed user, uint256 blockTimestamp, uint128 period);
    event AddStakeType(address indexed stakeProxy, uint128 stakeType, uint128 stakePeriod, uint128 depositFees, uint128 withdrawalFees, uint128 rewardRate, address indexed caller, uint256 blockTimestamp);
    event UpdateStakeType(address indexed stakeProxy, uint128 stakeType, uint128 stakePeriod, uint128 depositFees, uint128 withdrawalFees, uint128 rewardRate, address indexed caller, uint256 blockTimestamp);
    event DeleteStakeType(address indexed stakeProxy, uint128 stakeType, address indexed caller, uint256 blockTimestamp, bool active);
    event EmergencyWithdrawn(address indexed stakeProxy,  uint128 amount, uint128 stakeType, address indexed user, uint256 blockTimestamp, uint128 period, uint128 totalStakedInPool);
    event UpdateEmergencyFees(address indexed _owner, uint128 newFees, uint256 time);
    event UpdatePlatformFee(address indexed stakeProxy, uint128 newFee);
    event UpdateOwnerWallet(address indexed stakeProxy, address indexed newOwnerWallet);
    event UpdateTreasuryWallet(address indexed stakeProxy, address indexed newTreasuryWallet);
    event UpdateStakeLimit(address indexed stakeProxy, uint128 _newLimit);

    event Deployed(address indexed instance);
    event StakingInitialized(address indexed proxyInstance, address indexed stakedToken, uint128 stakePeriod, uint128 depositFees, uint128 withdrawlsFees, uint128 rewardRate, string name, string _symbol, uint256 blockTimestamp, string uri);

    function initialize(address _imp) external initializer {
        __Ownable_init();
        imp = _imp;
    }

    function deposit(address _stakedToken, uint128 _stakeAmount, uint128 _stakeType) external payable {
        IERC20(_stakedToken).approve(tokenAddrToStakingAddr[_stakedToken], _stakeAmount);
        (uint128 amount, uint128 period, uint128 totalStakedInPool) = IStaking3(tokenAddrToStakingAddr[_stakedToken]).deposit{value:msg.value}(msg.sender, _stakeAmount, _stakeType);
        emit Deposit(tokenAddrToStakingAddr[_stakedToken], amount, _stakeType, msg.sender, block.timestamp, period, totalStakedInPool);
    }
    
    function compound(address _stakedToken, uint128 _stakeType) external payable {
        (uint128 amount, uint128 period, uint128 totalStakedInPool) = IStaking3(tokenAddrToStakingAddr[_stakedToken]).compound{value:msg.value}(msg.sender, _stakeType);
        emit Compound(tokenAddrToStakingAddr[_stakedToken], amount, _stakeType, msg.sender, block.timestamp, period, totalStakedInPool);
    }

    function withdraw(address _stakedToken, uint128 _amount, uint128 _stakeType) external payable {
        IERC20(_stakedToken).approve(tokenAddrToStakingAddr[_stakedToken], _amount);
        (uint128 amount, uint128 period, uint128 totalStakedInPool) = IStaking3(tokenAddrToStakingAddr[_stakedToken]).withdraw{value:msg.value}(msg.sender, _amount, _stakeType);
        emit Withdraw(tokenAddrToStakingAddr[_stakedToken], amount, _stakeType, msg.sender, block.timestamp, period, totalStakedInPool);
    }

    function claim(address _stakedToken, uint128 _stakeType) external payable {
        (uint128 amount, uint128 period) = IStaking3(tokenAddrToStakingAddr[_stakedToken]).claim{value:msg.value}(msg.sender, _stakeType);
        emit Claim(tokenAddrToStakingAddr[_stakedToken], amount, _stakeType, msg.sender, block.timestamp, period);
    }

    function emergencyWithdraw(address _stakedToken, uint128 _stakeType) external payable {
        (uint128 amount, uint128 period, uint128 totalStakedInPool) = IStaking3(tokenAddrToStakingAddr[_stakedToken]).emergencyWithdraw{value:msg.value}(msg.sender, _stakeType);
        emit EmergencyWithdrawn(tokenAddrToStakingAddr[_stakedToken], amount, _stakeType, msg.sender, block.timestamp, period, totalStakedInPool);
    }

    function addStakedType(address _stakedToken, uint128 _stakePeriod, uint128 _depositFees, uint128 _withdrawalFees, uint128 _rewardRate) external onlyOwner{
        uint128 _stakeType = IStaking3(tokenAddrToStakingAddr[_stakedToken]).addStakedType(_stakePeriod,_depositFees,_withdrawalFees,_rewardRate);
        emit AddStakeType(tokenAddrToStakingAddr[_stakedToken], _stakeType, _stakePeriod, _depositFees, _withdrawalFees, _rewardRate, msg.sender, block.timestamp);
    }

    function updateStakeType(address _stakedToken, uint128 _stakeType, uint128 _stakePeriod, uint128 _depositFees, uint128 _withdrawalFees, uint128 _rewardRate) external onlyOwner{
        IStaking3(tokenAddrToStakingAddr[_stakedToken]).updateStakeType(_stakeType,_stakePeriod,_depositFees,_withdrawalFees,_rewardRate);
        emit UpdateStakeType(tokenAddrToStakingAddr[_stakedToken], _stakeType, _stakePeriod, _depositFees, _withdrawalFees, _rewardRate,msg.sender, block.timestamp);
    }

    function deleteStakeType(address _stakedToken, uint128 _stakeType) external onlyOwner {
        bool active = IStaking3(tokenAddrToStakingAddr[_stakedToken]).deleteStakeType(_stakeType);
        emit DeleteStakeType(tokenAddrToStakingAddr[_stakedToken], _stakeType,msg.sender, block.timestamp, active);
    }
    function updateEmergencyFees(address _stakedToken, uint128 newFees) external onlyOwner {
        IStaking3(tokenAddrToStakingAddr[_stakedToken]).updateEmergencyFees(newFees);
        emit UpdateEmergencyFees(msg.sender, newFees, block.timestamp);
    }

    function updatePlatformFee(address _stakedToken, uint128 newFee) external onlyOwner {
        IStaking3(tokenAddrToStakingAddr[_stakedToken]).updatePlatformFee(newFee);

        emit UpdatePlatformFee(tokenAddrToStakingAddr[_stakedToken], newFee);
    }

    function updateOwnerWallet(address _stakedToken, address newOwnerWallet) external onlyOwner {
       IStaking3(tokenAddrToStakingAddr[_stakedToken]).updateOwnerWallet(newOwnerWallet);

        emit UpdateOwnerWallet(tokenAddrToStakingAddr[_stakedToken], newOwnerWallet);
    }

    function updateTreasuryWallet(address _stakedToken, address newTreasuryWallet) external onlyOwner {
        IStaking3(tokenAddrToStakingAddr[_stakedToken]).updateTreasuryWallet(newTreasuryWallet);

        emit UpdateTreasuryWallet(tokenAddrToStakingAddr[_stakedToken], newTreasuryWallet);
    }

    function getPoolLength(address _stakedToken) external view returns(uint128) {
        return IStaking3(tokenAddrToStakingAddr[_stakedToken]).getPoolLength();
    }

    function deployInstance() external onlyOwner returns(address addr) {
        addr = address(new SaitaProxy(address(this)));
        require(addr!=address(0), "NULL_CONTRACT_ADDRESS_CREATED");
        totalStakingInstances.push(addr);
        
        emit Deployed(addr);
        return addr;
    }

    function initializeProxyInstance(address _proxyInstance, 
                                    address _ownerWallet, 
                                    address _stakedToken, 
                                    uint128 _stakePeriod, 
                                    uint128 _depositFees, 
                                    uint128 _withdrawalFees, 
                                    uint128 _rewardRate, 
                                    uint128 _emergencyFees, 
                                    uint128 _platformFee, 
                                    address _treasury, 
                                    uint128 _maxStakeLimit, 
                                    string memory uri) external onlyOwner {
        
            tokenAddrToStakingAddr[_stakedToken] = _proxyInstance;
        {
            string memory _name = IToken(_stakedToken).name();
            string memory _symbol = IToken(_stakedToken).symbol();

            // initialize pool
            SaitaProxy proxyInstance = SaitaProxy(payable(_proxyInstance));
            {
                bytes memory init = returnHash(_ownerWallet, _stakedToken, _stakePeriod, _depositFees, _withdrawalFees, _rewardRate, _emergencyFees, _platformFee, _treasury, _maxStakeLimit);
                if (init.length > 0)
                    
                    assembly 
                    {
                        if eq(call(gas(), proxyInstance, 0, add(init, 0x20), mload(init), 0, 0), 0) {
                            revert(0, 0)
                        }
                    }
            }
            emit StakingInitialized(_proxyInstance, _stakedToken, _stakePeriod, _depositFees, _withdrawalFees, _rewardRate, _name, _symbol, block.timestamp, uri);
        }
    }

    function setFactoryProxyInstance(address _proxyInstance) external onlyOwner {
                // set factory in deployed proxy instance
                SaitaProxy proxyInstance = SaitaProxy(payable(_proxyInstance));
                proxyInstance.setFactory(address(this));
    }

    function returnHash(address _ownerWallet, address _stakedToken, 
                        uint128 _stakePeriod, uint128 _depositFees, 
                        uint128 _withdrawalFees, uint128 _rewardRate, uint128 _emergencyFees, uint128 _platformFee, address _treasury, uint128 _maxStakeLimit) internal pure returns(bytes memory data) {
        data = abi.encodeWithSignature("initialize(address,address,uint128,uint128,uint128,uint128,uint128,uint128,address,uint128)", _ownerWallet,_stakedToken,_stakePeriod,_depositFees,_withdrawalFees,_rewardRate, _emergencyFees,_platformFee,_treasury, _maxStakeLimit);
    }

    function updateImp(address _newImp) external onlyOwner {
        imp = _newImp;
    }

    function impl() external view returns(address) {
        return imp;
    }

    function totalStakingNo() external view returns(uint256) {
        return totalStakingInstances.length;
    }

    function updateStakeLimit(address _stakedToken, uint128 _newLimit) external onlyOwner {
        IStaking3(tokenAddrToStakingAddr[_stakedToken]).updateStakeLimit(_newLimit);
        emit UpdateStakeLimit(tokenAddrToStakingAddr[_stakedToken], _newLimit);
    }
    
}