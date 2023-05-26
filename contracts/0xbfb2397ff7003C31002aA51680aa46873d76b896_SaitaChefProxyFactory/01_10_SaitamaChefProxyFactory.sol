// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SaitaChefProxy.sol";
import "./interfaces/ISaitaChef.sol";
import "./interfaces/IToken.sol";


contract SaitaChefProxyFactory is OwnableUpgradeable{

    address internal imp;
    address[] public totalChefInstances;

    mapping(address => address) public tokenAddrToChefAddr;
    mapping(address => bool) public tokenExistence;


    event Deposit(address indexed chefProxy, uint256 amount, uint256 pid, address indexed user);
    event Withdraw(address indexed chefProxy, uint256 amount, uint256 pid, address indexed user);
    event Harvest(address indexed chefProxy,  uint256 rewardAmount, uint256 pid, address indexed user);

    event Add(address indexed chefProxy, address indexed _lpToken, uint256 pid, uint256 depositFees, uint256 withdrawalFees, address indexed token, address  pairToken, string lpName);
    event Set(address indexed chefProxy, uint256 pid, uint256 depositFees, uint256 withdrawalFees);

    event EmergencyWithdrawn(address indexed chefProxy,  uint256 amount, uint256 pid, address indexed user);
    event UpdateEmergencyFees(address indexed chefProxy, uint256 newFees);
    event UpdatePlatformFee(address indexed chefProxy, uint256 newFees);
    event UpdateOwnerWallet(address indexed chefProxy, address indexed newOwnerWallet);
    event UpdateTreasuryWallet(address indexed chefProxy, address indexed newTreasuryWallet);
    event UpdateRewardWallet(address indexed chefProxy, address indexed newRewardWallet);
    event UpdateRewardPerBlock(address indexed chefProxy, uint256 newRate);
    event UpdateMultiplier(address indexed chefProxy, uint256 newMultiplier);


    event Deployed(address indexed instance);
    event StakingInitialized(address indexed _proxyInstance, address indexed _saita, uint256 _saitaPerBlock, uint256 _startBlock );

    modifier isDuplicated(address _token) {
        require(tokenExistence[_token] == false, "TOKEN_ALREADY_ADDED");
        _;
    }

    function initialize(address _imp) external initializer {
        __Ownable_init();
        imp = _imp;
    }

    function deposit(address token, uint256 _pid, uint256 _amount) external payable {
        uint256 amount = ISaitaChef(tokenAddrToChefAddr[token]).deposit{value:msg.value}(msg.sender, _pid, _amount);
        emit Deposit(tokenAddrToChefAddr[token], amount, _pid, msg.sender);
    }
    

    function withdraw(address token, uint256 _pid, uint256 _amount) external payable {
        ISaitaChef(tokenAddrToChefAddr[token]).withdraw{value:msg.value}(msg.sender, _pid, _amount);
        emit Withdraw(tokenAddrToChefAddr[token], _amount, _pid, msg.sender);
    }

    function harvest(address token, uint256 _pid) external payable {
        uint256 rewardAmount = ISaitaChef(tokenAddrToChefAddr[token]).harvest{value:msg.value}(msg.sender, _pid);
        emit Harvest(tokenAddrToChefAddr[token], rewardAmount, _pid, msg.sender);
    }

    function emergencyWithdraw(address token, uint256 _pid) external payable {
        (uint256 amount) = ISaitaChef(tokenAddrToChefAddr[token]).emergencyWithdraw{value:msg.value}(msg.sender, _pid);
        emit EmergencyWithdrawn(tokenAddrToChefAddr[token], amount, _pid, msg.sender);
    }

    function add(address token, address _lpToken, uint256 _allocPoint, uint256 _depositFees, uint256 _withdrawalFees, bool _withUpdate, address pairToken) external onlyOwner{
        uint256 _pid = ISaitaChef(tokenAddrToChefAddr[token]).add(_allocPoint, _lpToken, _depositFees, _withdrawalFees, _withUpdate);
        string memory pairName = string.concat(IToken(token).symbol(), "-", pairToken!=address(0) ? IToken(pairToken).symbol() : "ETH");
        emit Add(tokenAddrToChefAddr[token], _lpToken,  _pid, _depositFees, _withdrawalFees, token, pairToken, pairName);
    }

    function set(address token,uint256 _pid, uint256 _allocPoint, uint256 _depositFees, uint256 _withdrawalFees, bool _withUpdate) external onlyOwner{
        ISaitaChef(tokenAddrToChefAddr[token]).set(_pid, _allocPoint, _depositFees, _withdrawalFees, _withUpdate);
        emit Set(tokenAddrToChefAddr[token], _pid, _depositFees, _withdrawalFees);
    }


    function updateEmergencyFees(address token, uint256 newFees) external onlyOwner {
        ISaitaChef(tokenAddrToChefAddr[token]).updateEmergencyFees(newFees);
        emit UpdateEmergencyFees(tokenAddrToChefAddr[token], newFees);
    }

    function updatePlatformFee(address token, uint256 newFee) external onlyOwner {
        ISaitaChef(tokenAddrToChefAddr[token]).updatePlatformFee(newFee);

        emit UpdatePlatformFee(tokenAddrToChefAddr[token], newFee);
    }

    function updateFeeCollector(address token, address newWallet) external onlyOwner {
       ISaitaChef(tokenAddrToChefAddr[token]).updateFeeCollector(newWallet);

        emit UpdateOwnerWallet(tokenAddrToChefAddr[token], newWallet);
    }

    function updateTreasuryWallet(address token, address newTreasuryWallet) external onlyOwner {
        ISaitaChef(tokenAddrToChefAddr[token]).updateTreasuryWallet(newTreasuryWallet);

        emit UpdateTreasuryWallet(tokenAddrToChefAddr[token], newTreasuryWallet);
    }

    function updateRewardWallet(address token, address newWallet) external onlyOwner {
        ISaitaChef(tokenAddrToChefAddr[token]).updateRewardWallet(newWallet);

        emit UpdateRewardWallet(tokenAddrToChefAddr[token], newWallet);
    }

    function updateRewardPerBlock(address token, uint256 newRate) external onlyOwner {
        ISaitaChef(tokenAddrToChefAddr[token]).updateRewardPerBlock(newRate);

        emit UpdateRewardPerBlock(tokenAddrToChefAddr[token], newRate);
    }

    function updateMultiplier(address token, uint256 newMultiplier) external onlyOwner {
        ISaitaChef(tokenAddrToChefAddr[token]).updateMultiplier(newMultiplier);

        emit UpdateMultiplier(tokenAddrToChefAddr[token], newMultiplier);
    }


    function getPoolLength(address token) external view returns(uint256) {
        return ISaitaChef(tokenAddrToChefAddr[token]).poolLength();
    }

    function deployInstance() external onlyOwner returns(address addr) {
        addr = address(new SaitaChefProxy(address(this)));
        require(addr!=address(0), "NULL_CONTRACT_ADDRESS_CREATED");
        totalChefInstances.push(addr);
        
        emit Deployed(addr);
        return addr;
    }

    function initializeProxyInstance(address _proxyInstance, uint256 _saitaPerBlock, uint256 _startBlock, address token, address _treasury, 
                                    address _feeCollector, uint256 _platformFees, uint256 _emergencyFees,
                                    address _rewardWallet) external onlyOwner isDuplicated(token) {
        
            tokenAddrToChefAddr[token] = _proxyInstance;
            tokenExistence[token] = true;
            {

            // initialize pool
            SaitaChefProxy proxyInstance = SaitaChefProxy(payable(_proxyInstance));
            {
                bytes memory init = returnHash(_saitaPerBlock,_startBlock,token,_treasury, _feeCollector, _platformFees, _emergencyFees, _rewardWallet);
                if (init.length > 0)
                    
                    assembly 
                    {
                        if eq(call(gas(), proxyInstance, 0, add(init, 0x20), mload(init), 0, 0), 0) {
                            revert(0, 0)
                        }
                    }
            }
            emit StakingInitialized(_proxyInstance, token, _saitaPerBlock,_startBlock);
            }
        
    }

    function setFactoryProxyInstance(address _proxyInstance) external onlyOwner {
                // set factory in deployed proxy instance
                SaitaChefProxy proxyInstance = SaitaChefProxy(payable(_proxyInstance));
                proxyInstance.setFactory(address(this));
    }

    function returnHash(uint256 _saitaPerBlock, uint256 _startBlock, address _saita, address _treasury, 
                                    address _feeCollector, uint256 _platformFees, uint256 _emergencyFees,
                                    address _rewardWallet) internal pure returns(bytes memory data) {
        data = abi.encodeWithSignature("initialize(uint256,uint256,address,address,address,uint256,uint256,address)", 
                                        _saitaPerBlock,_startBlock,_saita,_treasury, _feeCollector, _platformFees, _emergencyFees, _rewardWallet);
    }

    function updateImp(address _newImp) external onlyOwner {
        imp = _newImp;
    }

    function impl() external view returns(address) {
        return imp;
    }

    function totalChefNo() external view returns(uint256) {
        return totalChefInstances.length;
    }

    function pendingSaita(address token, uint256 pid, address user) external view returns(uint256) {
    return ISaitaChef(tokenAddrToChefAddr[token]).pendingSaita(pid, user);
    }

    function userInfo(address token, uint256 pid, address user) external view returns(uint256) {
        (uint256 amount,) = ISaitaChef(tokenAddrToChefAddr[token]).userInfo(pid, user);
        return amount;
    }

    function updatePool(address token, uint256 pid) external {
        ISaitaChef(tokenAddrToChefAddr[token]).updatePool(pid);
    }

    function massUpdatePools(address token) external {
        ISaitaChef(tokenAddrToChefAddr[token]).massUpdatePools();
    }

    
}