// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "../interfaces/IClaimPool.sol";
import "../interfaces/IClaimPoolFactory.sol";
import "../Adminable.sol";

contract ClaimPoolFactory is IClaimPoolFactory, Adminable, ERC165Upgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    CountersUpgradeable.Counter private _claimPoolCounter;

    /**
     *  @notice This struct defining data
     *
     *  @param salt                         Additional data to make the ClaimPool unique
     *  @param claimPoolAddress             Address of the ClaimPool
     *  @param owner                        Owner's Address of the ClaimPool
     */
    struct ClaimPoolInfo {
        bytes32 salt;
        address claimPoolAddress;
        address owner;
    }

    /**
     *  @notice templateClaimPool is address of template
     */
    IClaimPool public templateClaimPool;

    /**
     *  @notice mapping claimPool ID => claimPool Info
     */
    mapping(uint256 => ClaimPoolInfo) public claimPoolIdToClaimPoolInfos;

    /**
     *  @notice mapping user address => list of claim pool address
     */
    mapping(address => EnumerableSetUpgradeable.AddressSet) private _ownerToClaimPoolAddress;

    event ClaimPoolDeployed(address claimPool, address deployer);
    event SetTemplateAddress(address oldValue, address newValue);

    /**
     *  @notice Initialize new logic contract.
     */
    function initialize(
        IClaimPool _templateClaimPool,
        address owner_
    ) public initializer notZeroAddress(address(_templateClaimPool)) notZeroAddress(owner_) {
        __ERC165_init();
        __Adminable_init();
        transferOwnership(owner_);

        templateClaimPool = _templateClaimPool;
    }

    /**
     *  @notice Create new claim pool
     *  @param  _project is address of project
     *  @param  _paymentToken is address of payment token
     */
    function create(
        address _project,
        address _paymentToken
    ) external onlyAdmin notZeroAddress(_project) returns (address) {
        _claimPoolCounter.increment();
        uint256 _currentId = _claimPoolCounter.current();
        bytes32 salt = bytes32(_currentId);
        IClaimPool _claimPool = IClaimPool(ClonesUpgradeable.cloneDeterministic(address(templateClaimPool), salt));
        require(address(_claimPool) != address(0), "Clone failed");
        // store
        ClaimPoolInfo memory newInfo = ClaimPoolInfo(salt, address(_claimPool), owner());
        claimPoolIdToClaimPoolInfos[_currentId] = newInfo;

        // initialize
        _claimPool.initialize(owner(), _project, _paymentToken);
        //slither-disable-next-line unused-return
        _ownerToClaimPoolAddress[_msgSender()].add(address(_claimPool));

        emit ClaimPoolDeployed(address(_claimPool), _msgSender());

        return address(_claimPool);
    }

    /**
     *  @notice Set template dddress
     *  @param  _templateClaimPool that set claimPool address
     */
    function setTemplateAddress(address _templateClaimPool) external notZeroAddress(_templateClaimPool) onlyAdmin {
        address _oldValue = address(templateClaimPool);
        templateClaimPool = IClaimPool(_templateClaimPool);

        emit SetTemplateAddress(_oldValue, _templateClaimPool);
    }

    function getClaimPoolByUser(address _user) external view returns (address[] memory) {
        return _ownerToClaimPoolAddress[_user].values();
    }

    function getClaimPoolLength() external view returns (uint256) {
        return _claimPoolCounter.current();
    }
}