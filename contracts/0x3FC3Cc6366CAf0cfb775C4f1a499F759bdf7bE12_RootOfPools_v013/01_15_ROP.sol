//SPDX-License-Identifier: GNU GPLv3
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../contracts/Ranking.sol";
import "../contracts/BOP.sol";

/// @title The root of the poole tree. Allows you to close control of a large
/// number of pools to 1 address. Simplifies user interaction with a large number of pools.
/// @author Nethny
/// @dev Must be the owner of child contracts, to short-circuit the administrative
/// rights to one address.
contract RootOfPools_v013 is Initializable, OwnableUpgradeable {
    using AddressUpgradeable for address;
    using Strings for uint256;

    struct Pool {
        address pool;
        string name;
    }

    Pool[] public Pools;

    mapping(string => address) private _poolsTable;

    address public _usdAddress;
    address public _rankingAddress;

    event PoolCreated(string name, address pool);

    modifier shouldExist(string calldata name) {
        require(
            _poolsTable[name] != address(0),
            "ROOT: Selected pool does not exist!"
        );
        _;
    }

    /// @notice Replacement of the constructor to implement the proxy
    function initialize(address usdAddress, address rankingAddress)
        external
        initializer
    {
        require(
            usdAddress != address(0),
            "INIT: The usdAddress must not be zero."
        );
        require(
            rankingAddress != address(0),
            "INIT: The rankingAddress must not be zero."
        );

        __Ownable_init();
        _usdAddress = usdAddress;
        _rankingAddress = rankingAddress;
    }

    /// @notice Returns the address of the usd token in which funds are collected
    function getUSDAddress() external view returns (address) {
        return _usdAddress;
    }

    /// @notice Returns the linked branch contracts
    function getPools() external view returns (Pool[] memory) {
        return Pools;
    }

    /// @notice Allows you to attach a new pool (branch contract)
    function createPool(string calldata name, address pool) external onlyOwner {
        require(isContract(pool), "ROOT: Pool must be a contract!");
        require(
            _poolsTable[name] == address(0),
            "ROOT: Pool with this name already exists!"
        );

        _poolsTable[name] = pool;

        Pool memory poolT = Pool(pool, name);
        Pools.push(poolT);

        emit PoolCreated(name, pool);
    }

    /// @notice The following functions provide access to the functionality of linked branch contracts

    function dataImport(
        string calldata name,
        uint256 fundsRaised,
        uint256 collectedCommission,
        address[] calldata usersData,
        uint256[] calldata usersAmount
    ) external onlyOwner shouldExist(name) {
        require(
            BranchOfPools(_poolsTable[name]).importTable(
                usersData,
                usersAmount
            ),
            "IMPORT: Failed to import a table of participants' shares"
        );
        require(
            BranchOfPools(_poolsTable[name]).importFR(fundsRaised),
            "IMPORT: Failed to write the fundsRaised variable"
        );
        require(
            BranchOfPools(_poolsTable[name]).importCC(collectedCommission),
            "IMPORT: Failed to write the collectedCommission variable"
        );
        require(
            BranchOfPools(_poolsTable[name]).closeImport(),
            "IMPORT: Failed to close import and change pool state"
        );
    }

    function importTable(
        string calldata name,
        address[] calldata usersData,
        uint256[] calldata usersAmount
    ) external onlyOwner shouldExist(name) {
        require(
            BranchOfPools(_poolsTable[name]).importTable(
                usersData,
                usersAmount
            ),
            "IMPORT: Failed to import a table of participants' shares"
        );
    }

    function importFR(string calldata name, uint256 fundsRaised)
        external
        onlyOwner
        shouldExist(name)
    {
        require(
            BranchOfPools(_poolsTable[name]).importFR(fundsRaised),
            "IMPORT: Failed to write the fundsRaised variable"
        );
    }

    function importCC(string calldata name, uint256 collectedCommission)
        external
        onlyOwner
        shouldExist(name)
    {
        require(
            BranchOfPools(_poolsTable[name]).importCC(collectedCommission),
            "IMPORT: Failed to write the collectedCommission variable"
        );
    }

    function closeImport(string calldata name)
        external
        onlyOwner
        shouldExist(name)
    {
        require(
            BranchOfPools(_poolsTable[name]).closeImport(),
            "IMPORT: Failed to close import and change pool state"
        );
    }

    function changeTargetValue(string calldata name, uint256 value)
        external
        onlyOwner
        shouldExist(name)
    {
        BranchOfPools(_poolsTable[name]).changeTargetValue(value);
    }

    function changeStepValue(string calldata name, uint256 step)
        external
        onlyOwner
        shouldExist(name)
    {
        BranchOfPools(_poolsTable[name]).changeStepValue(step);
    }

    function changeDevAddress(string calldata name, address developers)
        external
        onlyOwner
        shouldExist(name)
    {
        BranchOfPools(_poolsTable[name]).changeDevAddress(developers);
    }

    function startFundraising(string calldata name)
        external
        onlyOwner
        shouldExist(name)
    {
        BranchOfPools(_poolsTable[name]).startFundraising();
    }

    function collectFunds(string calldata name)
        external
        onlyOwner
        shouldExist(name)
    {
        BranchOfPools(_poolsTable[name]).collectFunds();
    }

    function stopFundraising(string calldata name)
        external
        onlyOwner
        shouldExist(name)
    {
        BranchOfPools(_poolsTable[name]).stopFundraising();
    }

    function stopEmergency(string calldata name)
        external
        onlyOwner
        shouldExist(name)
    {
        BranchOfPools(_poolsTable[name]).stopEmergency();
    }

    function paybackEmergency(string calldata name) external shouldExist(name) {
        BranchOfPools(_poolsTable[name]).paybackEmergency();
    }

    function deposit(string calldata name, uint256 amount)
        external
        shouldExist(name)
    {
        BranchOfPools(_poolsTable[name]).deposit(amount);
    }

    function entrustToken(
        string calldata name,
        address token,
        uint256 amount
    ) external shouldExist(name) {
        BranchOfPools(_poolsTable[name]).entrustToken(token, amount);
    }

    function claimName(string calldata name) external shouldExist(name) {
        BranchOfPools(_poolsTable[name]).claim();
    }

    function claimAddress(address pool) internal {
        require(pool != address(0), "ROOT: Selected pool does not exist!");

        BranchOfPools(pool).claim();
    }

    function prepClaimAll(address user)
        external
        view
        returns (address[] memory pools)
    {
        address[] memory out;
        for (uint256 i; i < Pools.length; i++) {
            if (BranchOfPools(Pools[i].pool).isClaimable(user)) {
                out[i] = Pools[i].pool;
            }
        }

        return pools;
    }

    ///@dev To find out the list of pools from which a user can mine something,
    ///     use the prepClaimAll function
    function claimAll(address[] calldata pools) external {
        for (uint256 i; i < pools.length; i++) {
            claimAddress(pools[i]);
        }
    }

    function checkAllClaims(address user) external view returns (uint256) {
        uint256 temp;
        for (uint256 i; i < Pools.length; i++) {
            temp += (BranchOfPools(Pools[i].pool).myCurrentAllocation(user));
        }

        return temp;
    }

    function getAllocations(address user, uint256 step)
        external
        view
        returns (uint256[10] memory)
    {
        uint256[10] memory amounts;
        for (
            uint256 i;
            (i + 10 * step < (step + 1) * 10) && (i + 10 * step < Pools.length);
            i++
        ) {
            amounts[i] = (BranchOfPools(Pools[i].pool).myAllocation(user));
        }
        return amounts;
    }

    function getState(string calldata name)
        external
        view
        shouldExist(name)
        returns (BranchOfPools.State)
    {
        return BranchOfPools(_poolsTable[name]).getState();
    }

    function getRanks() external view returns (address) {
        return _rankingAddress;
    }

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }
}