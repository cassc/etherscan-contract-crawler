// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "./openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "./openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./USBStaking.sol";
import "./USBStakingYield.sol";

contract USBStakingFactory is Initializable, AccessControlUpgradeable {

    using SafeERC20Upgradeable for ERC20Upgradeable;

    /**
     * @dev 32 byte code of FACTORY_MANAGER_ROLE
     */
    bytes32 public constant FACTORY_MANAGER_ROLE = keccak256("FACTORY_MANAGER_ROLE");

    /**
     * @dev address of upgradeableBeacon of USBStaking contract
     */
    UpgradeableBeacon public upgradeableBeaconUsbStaking;

    /**
     * @dev address of upgradeableBeacon of USBStakingYield contract
     */
    UpgradeableBeacon public upgradeableBeaconUsbStakingYield;

    /**
     * @dev list of USBStaking contracts
     */
    USBStaking[] public stakings;
    
    /**
     * @dev USBStaking address => id in list `stakings`
     */
    mapping(address => uint256) public stakingId;

    event DeployStaking(address indexed usbStaking, uint256 indexed stakingId, address stakeToken, address rewardToken, uint256 initialReward, uint256 rewardPerBlock, uint256 startBlock, uint256 endBlock);
    event AddYieldToStaking(address indexed usbStaking, address yieldRewardToken, uint256 initialYieldReward, uint256 yieldRewardPerBlock, uint256 startBlock, uint256 endBlock);
    event RemoveYieldStaking(address indexed usbStaking, uint8 yiedlId);

    modifier onlyAdmin {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "USBStakingFactory: Caller is not the Admin");
        _;
    }

    modifier onlyFactoryManager(){
        require(hasRole(FACTORY_MANAGER_ROLE, msg.sender), "USBStakingFactory: Caller is not the factory manager");
        _;
    }

    /**
     * @dev initializer of USBStaking factory
     * @param _usbStaking address of logic contract of USBStaking
     * @param _usbStakingYield address of logic contract of USBStakingYield
     */
    function initialize(
        address _usbStaking,
        address _usbStakingYield
    ) external initializer {
        require(_usbStaking != address(0), "USBStakingFactory: _usbStaking=0");
        require(_usbStakingYield != address(0), "USBStakingFactory: _usbStakingYield=0");
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(FACTORY_MANAGER_ROLE, msg.sender);
        
        upgradeableBeaconUsbStaking = new UpgradeableBeacon(_usbStaking);
        upgradeableBeaconUsbStakingYield = new UpgradeableBeacon(_usbStakingYield);
    }

    /******************** ADMIN FUNCTIONS ******************** */

    /**
     * @dev transfer admin of USBStakingFactory to `_admin`
     * @param _admin address of new admin
     */
    function transferAdminship(address _admin) external onlyAdmin {
        require(_admin != address(0), "USBStakingFactory: _admin is zero");
        require(!hasRole(DEFAULT_ADMIN_ROLE, _admin), "USBStakingFactory: _admin already have admin role");
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev grants `_factoryManager` factory manager
     * @param _factoryManager address of new factory manager
     */
    function grantFactoryManager(address _factoryManager) external onlyAdmin{
        _grantRole(FACTORY_MANAGER_ROLE, _factoryManager);
    }

    /**
     * @dev revokes factory manager
     * @param _factoryManager address of factory manager
     */
    function revokeFactoryManager(address _factoryManager) external onlyAdmin{
        _revokeRole(FACTORY_MANAGER_ROLE, _factoryManager);
    }
     
    /**
     * @dev upgrade the logic implementation of usb staking  
     * @param _usbStaking address of contract with logic usbStaking
     */
    function setUsbStaking(address _usbStaking) external onlyAdmin() {
        require(_usbStaking != address(0), "USBStakingFactory: invalid _usbStaking");
        upgradeableBeaconUsbStaking.upgradeTo(_usbStaking);
    }

    /**
     * @dev upgrade the logic implementation of usb staking yield 
     * @param _usbStakingYield address of contract with logic usbStakingYield
     */
    function setUsbStakingYield(address _usbStakingYield) external onlyAdmin() {
        require(_usbStakingYield != address(0), "USBStakingFactory: invalid _usbStakingYield");
        upgradeableBeaconUsbStakingYield.upgradeTo(_usbStakingYield);
    }

    /******************** END ADMIN FUNCTIONS ******************** */

    /******************** FACTORY MANAGER FUNCTIONS ******************** */

    /**
     * @dev deploys new staking
     * @param _stakeToken address of stake token
     * @param _rewardToken address of reward token
     * @param _initialReward amount of initial reward
     * @param _rewardPerBlock the amount of reward token to be initial reward
     * @param _startBlock block number of start staking
     * @param _endBlock block number of end staking
     */
    function deployStaking(
        address _stakeToken,
        address _rewardToken,
        uint256 _initialReward,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _endBlock
    ) external onlyFactoryManager {
        address beaconProxy = address(new BeaconProxy(address(upgradeableBeaconUsbStaking), ""));
        USBStaking usbStaking = USBStaking(beaconProxy);
        if (_initialReward > 0) {
            ERC20Upgradeable(_rewardToken).safeTransferFrom(msg.sender, address(this), _initialReward);
            ERC20Upgradeable(_rewardToken).approve(beaconProxy, _initialReward);
        }
        usbStaking.initialize(
            address(this), 
            _stakeToken, 
            _rewardToken, 
            _initialReward, 
            _rewardPerBlock, 
            _startBlock, 
            _endBlock
        );
        usbStaking.grantManager(msg.sender);
        usbStaking.revokeManager(address(this));
        usbStaking.transferAdminship(msg.sender);
        stakingId[address(usbStaking)] = stakingsLength();
        stakings.push(usbStaking);
        emit DeployStaking(address(usbStaking), stakingsLength() - 1, _stakeToken, _rewardToken, _initialReward, _rewardPerBlock, _startBlock, _endBlock);
    }
    
    /**
     * @dev add yield on staking
     * @param _usbStaking address of USBStaking
     * @param _yieldRewardToken address of yield reward token
     * @param _initialYieldReward amount of initial yield reward
     * @param _yieldRewardPerBlock the amount of yield reward token to be initial reward
     * @param _startBlock block number of start yield rewarding
     * @param _endBlock block number of end yield rewarding
     */
    function addYieldToStaking(
        address _usbStaking,
        address _yieldRewardToken,
        uint256 _initialYieldReward,
        uint256 _yieldRewardPerBlock,
        uint256 _startBlock,
        uint256 _endBlock
    ) external {
        USBStaking usbStaking = USBStaking(_usbStaking);
        bytes32 adminRole = usbStaking.DEFAULT_ADMIN_ROLE();
        require(usbStaking.hasRole(adminRole, msg.sender), "USBStakingFactory: msg.sender is not admin of _usbStaking");

        address beaconProxy = address(new BeaconProxy(address(upgradeableBeaconUsbStakingYield), ""));
        USBStakingYield usbStakingYield = USBStakingYield(beaconProxy);
        if (_initialYieldReward > 0) {
            ERC20Upgradeable(_yieldRewardToken).safeTransferFrom(msg.sender, address(this), _initialYieldReward);
            ERC20Upgradeable(_yieldRewardToken).approve(beaconProxy, _initialYieldReward);
        }
        usbStakingYield.initialize(
            _usbStaking, 
            _yieldRewardToken, 
            _initialYieldReward, 
            _yieldRewardPerBlock, 
            _startBlock, 
            _endBlock
        );
        usbStaking.addYield(usbStakingYield);
        emit AddYieldToStaking(_usbStaking, _yieldRewardToken, _initialYieldReward, _yieldRewardPerBlock, _startBlock, _endBlock);
    }

    /**
     * @dev remove the yield on staking
     * @param _usbStaking address of staking
     * @param yiedlId id of yield
     */
    function removeYieldStaking(
        address _usbStaking,
        uint8 yiedlId
    ) external {
        USBStaking usbStaking = USBStaking(_usbStaking);
        bytes32 adminRole = usbStaking.DEFAULT_ADMIN_ROLE();
        require(usbStaking.hasRole(adminRole, msg.sender), "USBStakingFactory: msg.sender is not admin of _usbStaking");

        usbStaking.removeYield(yiedlId);
        emit RemoveYieldStaking(_usbStaking, yiedlId);
    }

    /******************** END FACTORY MANAGER FUNCTIONS ******************** */
    
    /******************** VIEW FUNCTIONS ******************** */
    
    /**
     * @dev returns the staking address in array `stakings`
     * @param _stakingId id of staking address in array `stakings`
     */
    function getStaking(uint8 _stakingId) external view returns(address) {
        require(_stakingId < stakingsLength(), "USBStakingFactory: invalid _stakingId");
        return address(stakings[_stakingId]);
    }

    /**
     * @dev return the length of array `stakings`
     */
    function stakingsLength() public view returns (uint256) {
        return stakings.length;
    }


    /******************** END VIEW FUNCTIONS ******************** */

}