// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./interfaces/IPoolFactory.sol";
import "./libraries/Clones.sol";
import "./LinerPool.sol";
import "./AllocationPool.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract PoolFactory is IPoolFactory, AccessControl {
    bytes32 public constant MOD = keccak256("MOD");
    bytes32 public constant ADMIN = keccak256("ADMIN");
    
    LinearPool public linerImpl; 
    AllocationPool public allocationImpl;

    LinerParams public linerParameters;
    AllocationParams public allocationParameters;

    address public override signerAddress;

    function getLinerParameters() 
            external 
            view 
            override 
            returns (
                address[] memory stakeToken,
                address[] memory saleToken,
                uint256[] memory stakedTokenRate,
                uint256 APR,
                uint256 cap,
                uint256 startTimeJoin,
                uint256 endTimeJoin,
                uint256 lockDuration,
                address rewardDistributor
            ) {
                LinerParams memory linearParam = linerParameters;
                return (
                    linearParam.stakeToken,
                    linearParam.saleToken,
                    linearParam.stakedTokenRate,
                    linearParam.APR,
                    linearParam.cap,
                    linearParam.startTimeJoin,
                    linearParam.endTimeJoin,
                    linearParam.lockDuration,
                    linearParam.rewardDistributor
                );
            }

    function getAllocationParameters() 
            external 
            view 
            override 
            returns (
                address[] memory lpToken,
                address[] memory rewardToken,
                uint256[] memory stakedTokenRate,
                uint256 bonusMultiplier,
                uint256  startBlock,
                uint256  bonusEndBlock,
                uint256 lockDuration,
                address rewardDistributor,
                uint256 tokenPerBlock
            ) {
                AllocationParams memory alloParam = allocationParameters;
                return (
                    alloParam.lpToken,
                    alloParam.rewardToken,
                    alloParam.stakedTokenRate,
                    alloParam.bonusMultiplier,
                    alloParam.startBlock,
                    alloParam.bonusEndBlock,
                    alloParam.lockDuration,
                    alloParam.rewardDistributor,
                    alloParam.tokenPerBlock
                );
            }

    constructor(LinearPool _linerImpl, AllocationPool _allocImpl) {
        _setRoleAdmin(MOD, ADMIN);
        _setRoleAdmin(ADMIN, ADMIN);
        _setupRole(ADMIN, msg.sender);
        _setupRole(MOD, msg.sender);

        linerImpl = _linerImpl;
        allocationImpl = _allocImpl;
        signerAddress = msg.sender;
    }

    function changeLinerImpl(LinearPool _linerImpl) external {
        require(hasRole(ADMIN, msg.sender), "PoolFactory: require ADMIN role");
        linerImpl = _linerImpl;

        emit ChangeLinerImpl(address(_linerImpl));
    }

    function changeAllocationImpl(AllocationPool _allocImpl) external {
        require(hasRole(ADMIN, msg.sender), "PoolFactory: require ADMIN role");
        allocationImpl = _allocImpl;

        emit ChangeAllocationImpl(address(_allocImpl));
    }


    function createLinerPool(
        address[] calldata _stakeToken,
        address[] calldata _saleToken,
        uint256[] calldata _stakedTokenRate,
        uint256 _APR,
        uint256 _cap,
        uint256 _startTimeJoin,
        uint256 _lockDuration,
        address _rewardDistributor
    ) external returns (address poolAddress) {
        require(hasRole(ADMIN, msg.sender), "PoolFactory: require ADMIN role");

        uint256 clear_apr_decimal = _APR / 1e18;
        require(0 <= clear_apr_decimal && clear_apr_decimal < 1e10, "PoolFactory: APR must be less than 1e10");

        poolAddress = _deployLiner(
            _stakeToken,
            _saleToken,
            _stakedTokenRate,
            _APR,
            _cap,
            _startTimeJoin,
            _lockDuration,
            _rewardDistributor
        );

        emit LinerPoolCreated(poolAddress);
    }

    function createAllocationPool(
        address[] calldata _lpToken,
        address[] calldata _rewardToken,
        uint256[] calldata _stakedTokenRate,
        uint256 _bonusMultiplier,
        uint256  _startBlock,
        uint256  _bonusEndBlock,
        uint256 _lockDuration,
        address _rewardDistributor,
        uint256 _tokenPerBlock
    ) external returns (address poolAddress) {
        require(hasRole(ADMIN, msg.sender), "PoolFactory: require ADMIN role");

        poolAddress = _deployAllocation(
            _lpToken,
            _rewardToken,
            _stakedTokenRate,
            _bonusMultiplier,
            _startBlock,
            _bonusEndBlock,
            _lockDuration,
            _rewardDistributor,
            _tokenPerBlock
        );

        emit AllocationPoolCreated(poolAddress);
    }

    function _deployLiner(
        address[] calldata _stakeToken,
        address[] calldata _saleToken,
        uint256[] calldata _stakedTokenRate,
        uint256 _APR,
        uint256 _cap,
        uint256 _startTimeJoin,
        uint256 _lockDuration,
        address _rewardDistributor
    ) private returns (address poolAddress) {

        linerParameters = LinerParams({
            stakeToken: _stakeToken,
            saleToken: _saleToken,
            stakedTokenRate: _stakedTokenRate,
            APR: _APR,
            cap: _cap,
            startTimeJoin: _startTimeJoin,
            endTimeJoin: 0,
            lockDuration: _lockDuration,
            rewardDistributor: _rewardDistributor
        });

        poolAddress = Clones.clone(address(linerImpl));

        LinearPool(poolAddress).initialize();

        delete linerParameters;
    }

    function _deployAllocation(
        address[] calldata _lpToken,
        address[] calldata _rewardToken,
        uint256[] calldata _stakedTokenRate,    
        uint256 _bonusMultiplier,
        uint256  _startBlock,
        uint256  _bonusEndBlock,
        uint256 _lockDuration,
        address _rewardDistributor,
        uint256 _tokenPerBlock
    ) private returns(address poolAddress) {
        allocationParameters = AllocationParams({
            lpToken: _lpToken,
            rewardToken: _rewardToken,
            stakedTokenRate: _stakedTokenRate,
            bonusMultiplier: _bonusMultiplier, 
            startBlock: _startBlock, 
            bonusEndBlock: _bonusEndBlock ,
            lockDuration: _lockDuration,
            rewardDistributor: _rewardDistributor,
            tokenPerBlock: _tokenPerBlock
        });

        poolAddress = Clones.clone(address(allocationImpl));

        AllocationPool(poolAddress).initialize();

        delete allocationParameters;
    }

    function changeSigner(address _newSigner) external {
        require(hasRole(ADMIN, msg.sender), "PoolFactory: require ADMIN role");
        signerAddress = _newSigner;
        emit ChangeSigner(_newSigner);
    }
}