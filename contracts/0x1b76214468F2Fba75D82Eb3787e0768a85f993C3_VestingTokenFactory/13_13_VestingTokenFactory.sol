// SPDX-License-Identifier: None
// Unvest Contracts (last updated v2.0.0) (VestingTokenFactory.sol)
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "./interfaces/IFeeManager.sol";
import "./interfaces/IVestingToken.sol";

error AddressCanNotBeZero();
error AddressIsNotAContract();
error FailedToDeploy();
error FeeOutOfRange();
error NotFeeCollector();

/**
 * @title VestingTokenFactory
 * @dev The VestingTokenFactory contract can be used to create vesting contracts for any ERC20 token.
 */
contract VestingTokenFactory is Ownable2Step, IFeeManager, IBeacon {
    /**
     * @dev `feePercentage` is the old fee percentage that will be valid until `feeValidUntil`.
     * @dev `feeValidUntil` is the timestamp that marks the point in time where the changes of feePercentage will take
     * effect.
     */
    struct DelayedFeeData {
        uint64 feePercentage;
        uint64 feeValidUntil;
    }

    /**
     * @param underlyingToken Address of the ERC20 that will be vest into `vestingToken`.
     * @param vestingToken    Address of the newly deployed `VestingToken`.
     */
    event VestingTokenCreated(address indexed underlyingToken, address vestingToken);

    /**
     * @param feeCollector Address of the new fee collector.
     */
    event FeeCollectorChange(address indexed feeCollector);

    /**
     * @param feePercentage Value for the new fee.
     */
    event FeePercentageChange(uint64 feePercentage);

    /**
     * @dev Percentages and fees are calculated using 18 decimals where 0 ether is 0%.
     */
    uint64 private constant MIN_FEE = 0;

    /**
     * @dev Percentages and fees are calculated using 18 decimals where 0.05 ether is 5%.
     */
    uint64 private constant MAX_FEE = 0.05 ether;

    /**
     * @notice The address that will be used as a delegate call target for `VestingToken`s.
     */
    address public immutable override implementation;

    /**
     * @dev It will be used as the salt for create2
     */
    bytes32 internal _salt;

    /**
     * @dev Stores the address that will collect the fees of every transaction of `VestingToken`s and the percentage
     * that will be charged.
     */
    FeeData internal _feeData;

    /**
     * @dev Stores the info necessary for a delayed change of feePercentage.
     */
    DelayedFeeData internal _delayedFeeData;

    /**
     * @dev Maps `underlyingToken`s to an array of `VestingToken`s.
     */
    mapping(address => address[]) internal _vestingTokensByUnderlyingToken;

    /**
     * @dev Creates a vesting token factory contract.
     *
     * Requirements:
     *
     * - `implementationAddress` has to be a contract.
     * - `feeCollectorAddress` can't be address 0x0.
     * - `feePercentageValue` must be within minFee and maxFee.
     *
     * @param implementationAddress Address of `VestingToken` contract implementation.
     * @param feeCollectorAddress   Address of `feeCollector`.
     * @param feePercentageValue    Value for `feePercentage` that will be charged on `VestingToken`'s transfers.
     */
    constructor(address implementationAddress, address feeCollectorAddress, uint64 feePercentageValue) {
        if (!Address.isContract(implementationAddress)) revert AddressIsNotAContract();

        bytes32 seed;
        assembly ("memory-safe") {
            seed := chainid()
        }
        _salt = seed;

        implementation = implementationAddress;
        // feePercentage can only be set before feeCollector
        setFeePercentage(feePercentageValue);
        _delayedFeeData.feePercentage = feePercentageValue;
        setFeeCollector(feeCollectorAddress);
    }

    /**
     * @notice Increments the salt one step.
     *
     * @dev In the rare case that create2 fails, this function can be used to skip that particular salt.
     */
    function nextSalt() public {
        _salt = keccak256(abi.encode(_salt));
    }

    /**
     * @notice Creates new VestingToken contracts.
     *
     * Requirements:
     *
     * - `underlyingTokenAddress` cannot be the zero address.
     * - `timestamps` must be given in ascending order.
     * - `percentages` must be given in ascending order and the last one must always be 1 eth, where 1 eth equals to
     * 100%.
     *
     * @param name                   The token collection name.
     * @param symbol                 The token collection symbol.
     * @param underlyingTokenAddress The ERC20 token that will be held by this contract.
     * @param milestonesArray        Array of all Milestones for this Contract's lifetime.
     */
    function createVestingToken(
        string calldata name,
        string calldata symbol,
        address underlyingTokenAddress,
        IVestingToken.Milestone[] calldata milestonesArray
    ) public {
        address vestingToken;
        bytes memory bytecode = abi.encodePacked(type(BeaconProxy).creationCode, abi.encode(address(this), ""));
        bytes32 salt = _salt;

        assembly ("memory-safe") {
            vestingToken := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }

        if (vestingToken == address(0)) revert FailedToDeploy();
        nextSalt();

        IVestingToken(vestingToken).initialize(name, symbol, underlyingTokenAddress, milestonesArray);

        _vestingTokensByUnderlyingToken[underlyingTokenAddress].push(vestingToken);
        emit VestingTokenCreated(underlyingTokenAddress, vestingToken);
    }

    /**
     * @dev Set address of fee collector.
     *
     * Requirements:
     *
     * - `msg.sender` has to be the owner of the contract.
     * - `newFeeCollector` can't be address 0x0.
     *
     * @param newFeeCollector Address of `feeCollector`.
     */
    function setFeeCollector(address newFeeCollector) public onlyOwner {
        if (newFeeCollector == address(0)) revert AddressCanNotBeZero();

        _feeData.feeCollector = newFeeCollector;
        emit FeeCollectorChange(newFeeCollector);
    }

    /**
     * @notice Sets a new fee within the range 0% - 5%.
     *
     * @dev Percentages and fees are calculated using 18 decimals where 1 ether is 100%.
     *
     * Requirements:
     *
     * - `msg.sender` has to be `feeCollector`.
     * - `newFeePercentage` must be within minFee and maxFee.
     *
     * @param newFeePercentage Value for `feePercentage` that will be charged on `VestingToken`'s transfers.
     */
    function setFeePercentage(uint64 newFeePercentage) public {
        if (_msgSender() != _feeData.feeCollector && _feeData.feeCollector != address(0)) revert NotFeeCollector();
        if (newFeePercentage < MIN_FEE || newFeePercentage > MAX_FEE) revert FeeOutOfRange();

        if (_delayedFeeData.feeValidUntil <= block.timestamp) {
            _delayedFeeData.feePercentage = _feeData.feePercentage;
        }

        _delayedFeeData.feeValidUntil = uint64(block.timestamp + 1 hours);
        _feeData.feePercentage = newFeePercentage;
        emit FeePercentageChange(newFeePercentage);
    }

    /**
     * @dev Exposes MIN_FEE in a lowerCamelCase.
     */
    function minFee() external pure returns (uint64) {
        return MIN_FEE;
    }

    /**
     * @dev Exposes MAX_FEE in a lowerCamelCase.
     */
    function maxFee() external pure returns (uint64) {
        return MAX_FEE;
    }

    /**
     * @notice Exposes the whole array that `_vestingTokensByUnderlyingToken` maps.
     */
    function vestingTokens(address underlyingToken) external view returns (address[] memory) {
        return _vestingTokensByUnderlyingToken[underlyingToken];
    }

    /**
     * @notice Exposes the `FeeData.feeCollector` to users.
     */
    function feeCollector() external view returns (address) {
        return _feeData.feeCollector;
    }

    /**
     * @notice Exposes the `FeeData.feePercentage` to users.
     */
    function feePercentage() external view returns (uint64) {
        return feeData().feePercentage;
    }

    /**
     * @notice Exposes the `FeeData` for `VestingToken`s to consume.
     */
    function feeData() public view override returns (FeeData memory) {
        if (_delayedFeeData.feeValidUntil > block.timestamp)
            return FeeData(_feeData.feeCollector, _delayedFeeData.feePercentage);
        return _feeData;
    }
}