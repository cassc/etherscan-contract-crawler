/**
 *Submitted for verification at Etherscan.io on 2023-07-15
*/

pragma solidity 0.8.19;

abstract contract StabilityFeeTreasuryLike {
    function systemCoin() external view virtual returns (address);

    function pullFunds(address, address, uint) external virtual;
}

abstract contract OracleLike {
    function read() external view virtual returns (uint256);
}

abstract contract BaseFeeIncentive {
    StabilityFeeTreasuryLike public immutable treasury; // The stability fee treasury
    address public immutable coin; // The system coin
    OracleLike public ethOracle; // eth oracle
    OracleLike public coinOracle; // coin oracle
    uint256 public fixedReward; // The fixed reward sent by the treasury to a fee receiver (wad)
    uint256 public callDelay; // delay between incentivized calls (seconds)
    uint256 public lastCallMade; // last time a call to target was made (UNIX timestamp)

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(bytes32 parameter, address addr);
    event ModifyParameters(bytes32 parameter, uint256 val);
    event RewardCaller(address indexed finalFeeReceiver, uint256 fixedReward);
    event FailRewardCaller(
        bytes revertReason,
        address feeReceiver,
        uint256 amount
    );

    // --- Auth ---
    mapping(address => uint256) public authorizedAccounts;

    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }

    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }

    /**
     * @notice Checks whether msg.sender can call an authed function
     **/
    modifier isAuthorized() {
        require(
            authorizedAccounts[msg.sender] == 1,
            "StabilityFeeTreasury/account-not-authorized"
        );
        _;
    }

    // --- Constructor ---
    constructor(
        address treasury_,
        uint256 reward_,
        uint256 delay_,
        address coinOracle_,
        address ethOracle_
    ) {
        require(treasury_ != address(0), "invalid-treasury");
        require(reward_ != 0, "invalid-reward");
        require(coinOracle_ != address(0), "invalid-coin-oracle");
        require(ethOracle_ != address(0), "invalid-eth-oracle");

        authorizedAccounts[msg.sender] = 1;

        treasury = StabilityFeeTreasuryLike(treasury_);
        fixedReward = reward_;
        callDelay = delay_;
        coin = StabilityFeeTreasuryLike(treasury_).systemCoin();
        coinOracle = OracleLike(coinOracle_);
        ethOracle = OracleLike(ethOracle_);

        emit AddAuthorization(msg.sender);
        emit ModifyParameters("fixedReward", reward_);
        emit ModifyParameters("callDelay", delay_);
        emit ModifyParameters("coinOracle", coinOracle_);
        emit ModifyParameters("ethOracle", ethOracle_);
    }

    // -- Admin --
    function modifyParameters(
        bytes32 parameter,
        uint256 val
    ) public isAuthorized virtual {
        if (parameter == "fixedReward") fixedReward = val;
        else if (parameter == "callDelay") callDelay = val;
        else revert("invalid-param");
        emit ModifyParameters(parameter, val);
    }

    function modifyParameters(
        bytes32 parameter,
        address val
    ) external isAuthorized {
        require(val != address(0), "invalid-data");
        if (parameter == "coinOracle") coinOracle = OracleLike(val);
        else if (parameter == "ethOracle") ethOracle = OracleLike(val);
        else revert("invalid-param");
        emit ModifyParameters(parameter, val);
    }

    modifier payRewards() {
        uint256 gas = gasleft();
        _;

        if (block.timestamp >= lastCallMade + callDelay) {
            gas = gas - gasleft();
            uint256 coinCost = (gas * block.basefee * ethOracle.read()) /
                coinOracle.read();

            try treasury.pullFunds(msg.sender, coin, coinCost + fixedReward) {
                emit RewardCaller(msg.sender, coinCost + fixedReward);
            } catch (bytes memory revertReason) {
                emit FailRewardCaller(
                    revertReason,
                    msg.sender,
                    coinCost + fixedReward
                );
            }
        }

        lastCallMade = block.timestamp;
    }
}

abstract contract OSMLike {
    function updateResult() external virtual; // OSM Call

    function read() external view virtual returns (uint256);

    function priceSource() external view virtual returns (OracleLike);

    function getNextResultWithValidity() external view virtual returns (uint256, bool);
}

abstract contract OracleRelayerLike {
    function updateCollateralPrice(bytes32) external virtual; // Oracle relayer call

    function orcl(bytes32) external view virtual returns (address);
}

// @notice: Unobtrusive incentives for any call on a TAI like system.
// @dev: Assumes an allowance from the stability fee treasury, all oracles return quotes with 18 decimal places.
// @dev: Assumes all collateral types use the same OSM
contract BasefeeOSMDeviationCallBundler is BaseFeeIncentive {
    OSMLike public immutable osm;
    OracleRelayerLike public immutable oracleRelayer;
    bytes32 public immutable collateralA;
    bytes32 public immutable collateralB;
    bytes32 public immutable collateralC;

    uint256 public acceptedDeviation = 50; // 1000 = 100%, default 5%

    // --- Constructor ---
    constructor(
        address treasury_,
        address osm_,
        address oracleRelayer_,
        bytes32[3] memory collateral_,
        uint256 reward_,
        uint256 delay_,
        address coinOracle_,
        address ethOracle_
    ) BaseFeeIncentive(treasury_, reward_, delay_, coinOracle_, ethOracle_) {
        require(osm_ != address(0), "invalid-osm");
        require(oracleRelayer_ != address(0), "invalid-oracle-relayer");

        osm = OSMLike(osm_);
        oracleRelayer = OracleRelayerLike(oracleRelayer_);

        for (uint i; i < 3; i++) {
            if (collateral_[i] != bytes32(0)) require(oracleRelayer.orcl(collateral_[i]) == osm_, "invalid-collateral");
        }
        collateralA = collateral_[0];
        collateralB = collateral_[1];
        collateralC = collateral_[2];
    }

    function modifyParameters(bytes32 parameter, uint256 data) public override isAuthorized {
        if (parameter == "acceptedDeviation") {
            require(data <= 500, "invalid-deviation");
            acceptedDeviation = data;
            emit ModifyParameters(parameter, data);
        } else super.modifyParameters(parameter, data);
    }

    // @dev Calls are made through the fallback function
    fallback() external payRewards {
        uint256 currentPrice = osm.read();
        (uint256 nextPrice, ) = osm.getNextResultWithValidity();
        uint256 marketPrice = osm.priceSource().read();

        uint256 deviation = (currentPrice * acceptedDeviation) / 1000;

        // will pay if either current vs nextPrice or current vs marketPrice deviates by more than deviation
        require(
            nextPrice >= currentPrice + deviation ||
            nextPrice <= currentPrice - deviation ||
            marketPrice >= currentPrice + deviation ||
            marketPrice <= currentPrice - deviation,
            "not-enough-deviation"
        );

        osm.updateResult();

        if (collateralA != bytes32(0)) oracleRelayer.updateCollateralPrice(collateralA);
        if (collateralB != bytes32(0)) oracleRelayer.updateCollateralPrice(collateralB);
        if (collateralC != bytes32(0)) oracleRelayer.updateCollateralPrice(collateralC);
    }
}