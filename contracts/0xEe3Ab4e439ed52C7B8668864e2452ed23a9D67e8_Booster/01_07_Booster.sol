// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


import "./interfaces/IStaker.sol";
import "./interfaces/IPoolRegistry.sol";
import "./interfaces/IProxyVault.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';


/*
Main interface for the whitelisted proxy contract.
*/
contract Booster{
    using SafeERC20 for IERC20;

    address public constant fxs = address(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);

    address public immutable proxy;
    address public immutable poolRegistry;
    address public immutable feeRegistry;
    address public owner;
    address public pendingOwner;
    address public poolManager;
    address public rewardManager;
    address public feeclaimer;
    bool public isShutdown;
    address public feeQueue;

    mapping(address=>mapping(address=>bool)) public feeClaimMap;

    

    constructor(address _proxy, address _poolReg, address _feeReg) {
        proxy = _proxy;
        poolRegistry = _poolReg;
        feeRegistry = _feeReg;
        isShutdown = false;
        owner = msg.sender;
        rewardManager = msg.sender;
        poolManager = msg.sender;
        feeclaimer = msg.sender;

        feeClaimMap[address(0xc6764e58b36e26b08Fd1d2AeD4538c02171fA872)][fxs] = true;
        emit FeeClaimPairSet(address(0xc6764e58b36e26b08Fd1d2AeD4538c02171fA872), fxs, true);
    }

    /////// Owner Section /////////

    modifier onlyOwner() {
        require(owner == msg.sender, "!auth");
        _;
    }

    modifier onlyPoolManager() {
        require(poolManager == msg.sender, "!auth");
        _;
    }

    //set pending owner
    function setPendingOwner(address _po) external onlyOwner{
        pendingOwner = _po;
        emit SetPendingOwner(_po);
    }

    function _proxyCall(address _to, bytes memory _data) internal{
        (bool success,) = IStaker(proxy).execute(_to,uint256(0),_data);
        require(success, "Proxy Call Fail");
    }

    //claim ownership
    function acceptPendingOwner() external {
        require(pendingOwner != address(0) && msg.sender == pendingOwner, "!p_owner");

        owner = pendingOwner;
        pendingOwner = address(0);
        emit OwnerChanged(owner);
    }

    //set fee queue, a contract fees are moved to when claiming
    function setFeeQueue(address _queue) external onlyOwner{
        feeQueue = _queue;
        emit FeeQueueChanged(_queue);
    }

    //set who can call claim fees, 0x0 address will allow anyone to call
    function setFeeClaimer(address _claimer) external onlyOwner{
        feeclaimer = _claimer;
        emit FeeClaimerChanged(_claimer);
    }

    function setFeeClaimPair(address _claimAddress, address _token, bool _active) external onlyOwner{
        feeClaimMap[_claimAddress][_token] = _active;
        emit FeeClaimPairSet(_claimAddress, _token, _active);
    }

    //set a reward manager address that controls extra reward contracts for each pool
    function setRewardManager(address _rmanager) external onlyOwner{
        rewardManager = _rmanager;
        emit RewardManagerChanged(_rmanager);
    }

    //set pool manager
    function setPoolManager(address _pmanager) external onlyOwner{
        poolManager = _pmanager;
        emit PoolManagerChanged(_pmanager);
    }
    
    //shutdown this contract.
    function shutdownSystem() external onlyOwner{
        //This version of booster does not require any special steps before shutting down
        //and can just immediately be set.
        isShutdown = true;
        emit Shutdown();
    }

    //claim operator roles for certain systems for direct access
    function claimOperatorRoles() external onlyOwner{
        require(!isShutdown,"shutdown");

        //claim operator role of pool registry
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("setOperator(address)")), address(this));
        _proxyCall(poolRegistry,data);
    }

    //set fees on user vaults
    function setPoolFees(uint256 _cvxfxs, uint256 _cvx, uint256 _platform) external onlyOwner{
        require(!isShutdown,"shutdown");

        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("setFees(uint256,uint256,uint256)")), _cvxfxs, _cvx, _platform);
        _proxyCall(feeRegistry,data);
    }

    //set fee deposit address for all user vaults
    function setPoolFeeDeposit(address _deposit) external onlyOwner{
        require(!isShutdown,"shutdown");

        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("setDepositAddress(address)")), _deposit);
        _proxyCall(feeRegistry,data);
    }

    //add pool on registry
    function addPool(address _implementation, address _stakingAddress, address _stakingToken) external onlyPoolManager{
        IPoolRegistry(poolRegistry).addPool(_implementation, _stakingAddress, _stakingToken);
    }

    //set a new reward pool implementation for future pools
    function setPoolRewardImplementation(address _impl) external onlyPoolManager{
        IPoolRegistry(poolRegistry).setRewardImplementation(_impl);
    }

    //deactivate a pool
    function deactivatePool(uint256 _pid) external onlyPoolManager{
        IPoolRegistry(poolRegistry).deactivatePool(_pid);
    }

    //set extra reward contracts to be active when pools are created
    function setRewardActiveOnCreation(bool _active) external onlyPoolManager{
        IPoolRegistry(poolRegistry).setRewardActiveOnCreation(_active);
    }

    //vote for gauge weights
    function voteGaugeWeight(address _controller, address[] calldata _gauge, uint256[] calldata _weight) external onlyOwner{
        for(uint256 i = 0; i < _gauge.length; ){
            bytes memory data = abi.encodeWithSelector(bytes4(keccak256("vote_for_gauge_weights(address,uint256)")), _gauge[i], _weight[i]);
            _proxyCall(_controller,data);
            unchecked{ ++i; }
        }
    }

    //set voting delegate
    function setDelegate(address _delegateContract, address _delegate, bytes32 _space) external onlyOwner{
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("setDelegate(bytes32,address)")), _space, _delegate);
        _proxyCall(_delegateContract,data);
        emit DelegateSet(_delegate);
    }

    //recover tokens on this contract
    function recoverERC20(address _tokenAddress, uint256 _tokenAmount, address _withdrawTo) external onlyOwner{
        IERC20(_tokenAddress).safeTransfer(_withdrawTo, _tokenAmount);
        emit Recovered(_tokenAddress, _tokenAmount);
    }

    //manually set vefxs proxy for a given vault
    function setVeFXSProxy(address[] calldata _vaults) external onlyOwner{
        for(uint256 i = 0; i < _vaults.length; ){

            //set proxy
            bytes memory data = abi.encodeWithSelector(bytes4(keccak256("setVeFXSProxy(address)")), proxy);
            _proxyCall(_vaults[i],data);

            //call get rewards to checkpoint
            data = abi.encodeWithSelector(bytes4(keccak256("checkpointRewards()")));
            _proxyCall(_vaults[i],data);

            unchecked{ ++i; }
        }

    }

    //recover tokens on the proxy
    function recoverERC20FromProxy(address _tokenAddress, uint256 _tokenAmount, address _withdrawTo) external onlyOwner{

        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("transfer(address,uint256)")), _withdrawTo, _tokenAmount);
        _proxyCall(_tokenAddress,data);

        emit Recovered(_tokenAddress, _tokenAmount);
    }

    //////// End Owner Section ///////////


    function createVault(uint256 _pid) external{
    	//create minimal proxy vault for specified pool
        (address vault, address stakeAddress, address stakeToken, address rewards) = IPoolRegistry(poolRegistry).addUserVault(_pid, msg.sender);

    	//make voterProxy call proxyToggleStaker(vault) on the pool's stakingAddress to set it as a proxied child
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("proxyToggleStaker(address)")), vault);
        _proxyCall(stakeAddress,data);

    	//call proxy initialize
        IProxyVault(vault).initialize(msg.sender, stakeAddress, stakeToken, rewards);

        //set vault vefxs proxy
        data = abi.encodeWithSelector(bytes4(keccak256("setVeFXSProxy(address)")), proxy);
        _proxyCall(vault,data);
    }


    //claim fees - if set, move to a fee queue that rewards can pull from
    function claimFees(address _distroContract, address _token) external {
        require(feeclaimer == address(0) || feeclaimer == msg.sender, "!auth");
        require(feeClaimMap[_distroContract][_token],"!claimPair");

        uint256 bal;
        if(feeQueue != address(0)){
            bal = IStaker(proxy).claimFees(_distroContract, _token, feeQueue);
        }else{
            bal = IStaker(proxy).claimFees(_distroContract, _token, address(this));
        }
        emit FeesClaimed(bal);
    }

    //call vefxs checkpoint
    function checkpointFeeRewards(address _distroContract) external {
        require(feeclaimer == address(0) || feeclaimer == msg.sender, "!auth");

        IStaker(proxy).checkpointFeeRewards(_distroContract);
    }

    
    /* ========== EVENTS ========== */
    event SetPendingOwner(address indexed _address);
    event OwnerChanged(address indexed _address);
    event FeeQueueChanged(address indexed _address);
    event FeeClaimerChanged(address indexed _address);
    event FeeClaimPairSet(address indexed _address, address indexed _token, bool _value);
    event RewardManagerChanged(address indexed _address);
    event PoolManagerChanged(address indexed _address);
    event Shutdown();
    event DelegateSet(address indexed _address);
    event FeesClaimed(uint256 _amount);
    event Recovered(address indexed _token, uint256 _amount);
}