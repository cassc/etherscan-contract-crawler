// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IDOPool.sol";
import "./AthenaLaunchPadInfo.sol";

/// @title AthenaLaunchPadPoolFactory
/// @notice Factory contract to create PreSale
contract AthenaLaunchPadPoolFactory is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @dev Struct to store the IDO Pool Information
     * @param contractAddr The contract address
     * @param currency The curreny used for the IDO
     * @param token The ERC20 token contract address
     */
    struct IDOPoolInfo {
        address contractAddr;
        address currency;
        address token;
        uint256 tokenDecimal;
    }

    /**
     * @dev Struct to store IDO Information
     * @param _token The ERC20 token contract address
     * @param _tokenDecimal The ERC20 token decimal
     * @param _currency The curreny used for the IDO
     * @param _startTime Timestamp of when pre-Sale starts
     * @param _releaseTime Timestamp of when the token will be released
     * @param _price Price of the token for the IDO
     * @param _totalAmount The total amount for the IDO
     * @param _presaleProjectID The PreSale project ID
     * @param _participationFees An array of participation fee as per tiers
     * @param _maxAmountThatCanBeInvestedInTiers An array of max investments amount in tiers
     * @param _tiersAllocation An array of amounts as per tiers
     */
    struct IDOInfo {
        address _token;
        uint256 _tokenDecimal;
        address _currency;
        uint256 _startTime;
        uint256 _fundingPeriod;
        uint256 _releaseTime;
        uint256 _price;
        uint256 _totalAmount;
        uint256 _presaleProjectID;
        uint256[] _participationFees;
        uint256[] _maxAmountThatCanBeInvestedInTiers;
    }

    uint256 public nextPoolId;
    IDOPoolInfo[] public poolList;

    //solhint-disable-next-line var-name-mixedcase
    AthenaLaunchPadInfo public immutable athenaPadInfo;
    // Ath Staking contract
    address public athStaking;
    // DEV TEAM Address
    address public devAddress;

    event PoolCreated(
        uint256 indexed athenaPadId,
        uint256 presaleDbID,
        address indexed _token,
        uint256 _tokenDecimal,
        address indexed _currency,
        address pool,
        address creator
    );

    event DevAddressUpdated(
        address indexed _user,
        address _oldDev,
        address _newDev
    );

    /**
     * @dev Sets the values for {_athenaPadInfoAddress, _athStaking, _devAddress}
     */
    constructor(address _athenaPadInfoAddress, address _athStaking, address _devAddress) public {
        athenaPadInfo = AthenaLaunchPadInfo(_athenaPadInfoAddress);
        athStaking = _athStaking;
        devAddress = _devAddress;
    }

    /**
     * @dev To create a pool
     *
     * Requirements:
     * - poolinfo token & currency cannot be the same
     * - poolinfo token cannot be address zero
     * - poolinfo currency cannot be address zero
     */
    //solhint-disable-next-line function-max-lines
    function createPoolPublic(IDOInfo calldata poolInfo) external onlyOwner {
        require(poolInfo._token != poolInfo._currency, "Currency and Token can not be the same");
        require(poolInfo._currency != address(0), "PoolInfo currency cannot be address zero");

        IDOPool _idoPool = new IDOPool(
            poolInfo._token,
            poolInfo._tokenDecimal,
            poolInfo._currency,
            poolInfo._startTime,
            poolInfo._fundingPeriod,
            poolInfo._releaseTime,
            poolInfo._price,
            poolInfo._totalAmount
        );

        poolList.push(IDOPoolInfo(address(_idoPool), poolInfo._currency, poolInfo._token, poolInfo._tokenDecimal));

        uint256 athPadId = athenaPadInfo.addPresaleAddress(address(_idoPool), poolInfo._presaleProjectID);

        _idoPool.setAthStaking(athStaking);
        _idoPool.setDevAddress(devAddress);
        _idoPool.setTierInfo(poolInfo._participationFees, poolInfo._maxAmountThatCanBeInvestedInTiers);
        _idoPool.transferOwnership(owner());
        nextPoolId++;

        emit PoolCreated(
            athPadId,
            poolInfo._presaleProjectID,
            poolInfo._token,
            poolInfo._tokenDecimal,
            poolInfo._currency,
            address(_idoPool),
            msg.sender
        );
    }

    /**
     * @dev To set the Ath Staking address
     * @param _athStaking ath staking contract address
     */
    function setAthStaking(address _athStaking) external onlyOwner {
        require(_athStaking != address(0x0), "_athStaking should be valid address");

        athStaking = _athStaking;
    }

    /**
     * @dev To set the DEV address
     * @param _devAddr dev wallet address.
     */
    function setDevAddress(address _devAddr) external onlyOwner {
        require(_devAddr != address(0x0), "_devAddr should be valid Address");

        emit DevAddressUpdated(msg.sender, devAddress, _devAddr);
        devAddress = _devAddr;
    }
}