// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

import "Initializable.sol";

import "IStrategy.sol";
import "IBooster.sol";
import "IDetails.sol";
import "IPoolManager.sol";
import "IRegistry.sol";
import "IVault.sol";
import {ICurveGauge} from "ICurve.sol";



contract Factory is Initializable {
    event NewVault(
        uint256 indexed category,
        address indexed lpToken,
        address gauge,
        address indexed vault,
        address strategy
    );

    ///////////////////////////////////
    //
    //  Storage variables and setters
    //
    ////////////////////////////////////

    address[] public deployedVaults;

    function allDeployedVaults() external view returns (address[] memory) {
        return deployedVaults;
    }

    function numVaults() external view returns (uint256) {
        return deployedVaults.length;
    }

    address public constant cvx = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    uint256 public constant category = 0; // 0 for curve


    IBooster public booster;

    // always owned by ychad
    address public owner;
    address internal pendingOwner;

    function setOwner(address newOwner) external {
        require(msg.sender == owner);
        pendingOwner = newOwner;
    }

    function acceptOwner() external {
        require(msg.sender == pendingOwner);
        owner = pendingOwner;
    }

    address public convexPoolManager;

    function setConvexPoolManager(address _convexPoolManager) external {
        require(msg.sender == owner);
        convexPoolManager = _convexPoolManager;
    }

    IRegistry public registry;

    function setRegistry(address _registry) external {
        require(msg.sender == owner);
        registry = IRegistry(_registry);
    }


    address public governance;

    function setGovernance(address _governance) external {
        require(msg.sender == owner);
        governance = _governance;
    }

    address public management;

    function setManagement(address _management) external {
        require(msg.sender == owner);
        management = _management;
    }

    address public guardian;

    function setGuardian(address _guardian) external {
        require(msg.sender == owner);
        guardian = _guardian;
    }

    address public treasury;

    function setTreasury(address _treasury) external {
        require(msg.sender == owner);
        treasury = _treasury;
    }

    address public keeper;

    function setKeeper(address _keeper) external {
        require(msg.sender == owner || msg.sender == management);
        keeper = _keeper;
    }

    uint256 public depositLimit;

    function setDepositLimit(uint256 _depositLimit) external {
        require(msg.sender == owner || msg.sender == management);
        depositLimit = _depositLimit;
    }

    address public convexStratImplementation;

    function setConvexStratImplementation(address _convexStratImplementation)
        external
    {
        require(msg.sender == owner);
        convexStratImplementation = _convexStratImplementation;
    }


    uint256 public performanceFee = 1_00;

    function setPerformanceFee(uint256 _performanceFee) external {
        require(msg.sender == owner);
        require(_performanceFee <= 5_000);
        performanceFee = _performanceFee;
    }

    uint256 public managementFee = 0;

    function setManagementFee(uint256 _managementFee) external {
        require(msg.sender == owner);
        require(_managementFee <= 1_000);
        managementFee = _managementFee;
    }

    ///////////////////////////////////
    //
    // Functions
    //
    ////////////////////////////////////

    function initialize (
        address _registry,
        address _convexStratImplementation,
        address _keeper,
        address _owner
    ) public initializer {
        registry = IRegistry(_registry);
        convexStratImplementation = _convexStratImplementation;
        owner = _owner;

        depositLimit = 10_000_000_000_000 * 1e18; // some large number

        keeper = _keeper;

        treasury = _owner;

        guardian = _owner;

        management = _owner;

        governance = _owner;

        convexPoolManager =
        0xD1f9b3de42420A295C33c07aa5C9e04eDC6a4447;

        booster =
        IBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);

    }

    /// @notice Public function to check whether, for a given gauge address, its possible to permissionlessly create a vault for corressponding LP token
    /// @param _gauge The gauge address to find the latest vault for
    /// @return bool if true, vault can be created permissionlessly
    function canCreateVaultPermissionlessly(address _gauge) public view returns (bool) {
        return latestDefaultOrAutomatedVaultFromGauge(_gauge) == address(0);
    }

    /// @dev Returns only the latest vault address for any DEFAULT/AUTOMATED type vaults
    /// @dev If no vault of either DEFAULT or AUTOMATED types exists for this gauge, 0x0 is returned from registry.
    function latestDefaultOrAutomatedVaultFromGauge(address _gauge)
        internal
        view
        returns (address)
    {
        address lptoken = ICurveGauge(_gauge).lp_token();
        if (!registry.isRegistered(lptoken)) {
            return address(0);
        }

        address latest = latestVault(lptoken);

        return latest;
    }


    function latestVault(address _token) public view returns(address) {
         bytes memory data = abi.encodeWithSignature(
            "latestVault(address)",
            _token
        );
        (bool success, bytes memory returnBytes) = address(registry)
            .staticcall(data);
        if (success) {
            return abi.decode(returnBytes, (address));
        }
        return address(0);
    }

    function getPid(address _gauge) public view returns (uint256 pid) {
        pid = type(uint256).max;

        if (!booster.gaugeMap(_gauge)) {
            return pid;
        }

        for (uint256 i = booster.poolLength(); i > 0; i--) {
            //we start at the end and work back for most recent
            (, , address gauge, , , ) = booster.poolInfo(i - 1);

            if (_gauge == gauge) {
                return i - 1;
            }
        }
    }

    // only permissioned users can deploy if there is already one endorsed
    function createNewVaultsAndStrategies(
        address _gauge,
        bool _allowDuplicate
    ) external returns (address vault, address convexStrategy) {
        require(msg.sender == owner || msg.sender == management);

        return _createNewVaultsAndStrategies(_gauge, _allowDuplicate);
    }

    function _createNewVaultsAndStrategies(
        address _gauge,
        bool _allowDuplicate
    ) internal returns (address vault, address strategy) {
        if (!_allowDuplicate) {
            require(
                canCreateVaultPermissionlessly(_gauge),
                "Vault already exists"
            );
        }
        address lptoken = ICurveGauge(_gauge).lp_token();

        //get convex pid. if no pid create one
        uint256 pid = getPid(_gauge);
        if (pid == type(uint256).max) {
            //when we add the new pool it will be added to the end of the pools in convexDeposit.
            pid = booster.poolLength();
            //add pool
            require(
                IPoolManager(convexPoolManager).addPool(_gauge),
                "Unable to add pool to Convex"
            );
        }

        //now we create the vault, endorses it from governance after
        vault = registry.newExperimentalVault(
            lptoken,
            address(this),
            guardian,
            treasury,

            string.concat(
                    "Curve ",
                    IDetails(address(lptoken)).symbol(),
                    " yieldVault"
            ),
            string.concat("yieldCurve", IDetails(address(lptoken)).symbol()),
            0
        );

        deployedVaults.push(vault);


        IVault v = IVault(vault);
        v.setManagement(management);
        //set governance to ychad who needs to accept before it is finalised. until then governance is this factory
        v.setGovernance(governance);
        v.setDepositLimit(depositLimit);

        if (v.managementFee() != managementFee) {
            v.setManagementFee(managementFee);
        }
        if (v.performanceFee() != performanceFee) {
            v.setPerformanceFee(performanceFee);
        }


        //now we create the convex strat
        strategy = IStrategy(convexStratImplementation).cloneConvex3CrvRewards(
            vault,
            management,
            treasury,
            keeper,
            pid,
            lptoken,
            string(
            abi.encodePacked("yvConvex", IDetails(address(lptoken)).symbol())
            )
       );

        v.addStrategy(
            strategy,
            10_000,
            0,
            type(uint256).max,
            0
        );

        emit NewVault(category, lptoken, _gauge, vault, strategy);
    }
}