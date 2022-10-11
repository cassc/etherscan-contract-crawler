// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/* ========== External Inheritance ========== */
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDynasetTvlOracle.sol";
import "./interfaces/IDynasetContract.sol";

/**
 * @title DynasetFactory
 * @author singdaodev
 */
abstract contract AbstractDynasetFactory is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /* ==========  Constants  ========== */
    
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint256 public constant WITHDRAW_FEE_FACTOR = 10000;
    // Performance fee should be less than 25%
    uint16 public constant MAX_PERFORMANCE_FEE_FACTOR = 2500;
    // Management fee should be less than 5%
    uint16 public constant MAX_MANAGEMENT_FEE_FACTOR = 500;

    /* ==========  Storage  ========== */

    struct DynasetEntity {
        string name;
        bool bound;
        bool initialised;
        address forge;
        address dynaddress;
        uint16 performanceFee;
        uint16 managementFee;
        uint256 timelock;
        uint256 tvlSnapshot;
    }
    // multisig contract where performance fee is collected
    address public gnosisSafe;
    address[] public dynasets;
    mapping(address => DynasetEntity) internal dynasetList;
    mapping(address => address) internal oracleList;

    /* ==========  Events  ========== */

    /** @dev Emitted when dynaset is deployed. */
    event NewDynaset(
        address indexed dynaset,
        address indexed dam,
        address indexed controller
    );
    event FeeCollected(address indexed dynaset, uint256 indexed amount);
    event OracleAssigned(
        address indexed dynaset,
        address indexed oracleAddress
    );
    event InitialiseDynaset(
        address indexed dynasetAddress,
        address[] tokens,
        address indexed tokenProvider,
        uint16 performanceFee,
        uint16 managementFee
    );
    event DynasetTvlSet(address indexed dynaset, uint256 indexed tvl);

    /* ========== Dynaset Deployment  ========== */

    /**
     * @dev Deploys a dynaset
     *
     * Note: To support future interfaces, this does not initialize or
     * configure the pool, this must be executed by the controller.
     *
     * Note: Must be called by an approved admin.
     *
     */
    constructor(address gnosis) {
        require(gnosis != address(0), "ERR_ZERO_ADDRESS");
        gnosisSafe = gnosis;
    }

    /* ==========  External Functions  ========== */

    /**   @notice Creates new dynaset contract
     * @dev dam and controller can can not be zero as the checks are
            added to constructor of Dynaset contract
     * @param dam us the asset manager of the new deployed dynaset.
     * @param controller will is the BLACK_SMITH role user for dynaset contract.
     * @param name, @param symbol will be used for dynaset ERC20 token
     */
    function deployDynaset(
        address dam,
        address controller,
        string calldata name,
        string calldata symbol
    ) external virtual;

    /**
     * @notice initializes the dynaset contract with tokens.
     * @param dynasetAddress is the dynaset contract address.
     * @param  tokens is the tokens list that will be initialized.
     * @param balances are the initial balance for initialized tokens.
     * @param balances and @param tokens length should be same.
     * the balances for initialization will be transfered from
     * @param tokenProvider address
     * @dev all @param tokens for @param balance must be approved first.
     */
    function initialiseDynaset(
        address dynasetAddress,
        address[] calldata tokens,
        uint256[] calldata balances,
        address tokenProvider,
        uint16 performanceFeeFactor,
        uint16 managementFeeFactor
    ) external onlyOwner {
        // require(_dynasetlist[_dynaset].dynaddress, "ERR_NOT_AUTH");
        require(dynasetList[dynasetAddress].bound, "ADDRESS_NOT_DYNASET");
        require(
            performanceFeeFactor <= MAX_PERFORMANCE_FEE_FACTOR,
            "ERR_HIGH_PERFORMANCE_FEE"
        );
        require(
            managementFeeFactor <= MAX_MANAGEMENT_FEE_FACTOR,
            "ERR_HIGH_MANAGEMENT_FEE"
        );
        require(
            !dynasetList[dynasetAddress].initialised,
            "ERR_ALREADY_INITIALISED"
        );

        IDynasetContract dynaset = IDynasetContract(dynasetAddress);
        dynasetList[dynasetAddress].initialised = true;
        dynasetList[dynasetAddress].performanceFee = performanceFeeFactor;
        dynasetList[dynasetAddress].managementFee = managementFeeFactor;
        dynaset.initialize(tokens, balances, tokenProvider);

        emit InitialiseDynaset(
            dynasetAddress,
            tokens,
            tokenProvider,
            performanceFeeFactor,
            managementFeeFactor
        );
    }

    /**
     * @dev assign which oracle to use for calculating tvl.
     * @notice this function can be called to update the oracle of dynaset as well
     * @param dynaset is the dynasetContract address
     * @param oracle is the DynasetTvlOracle contract which has to be initialized
     * using the @param dynaset address
     */
    function assignTvlOracle(address dynaset, address oracle)
        external
        onlyOwner
        nonReentrant
    {
        require(dynasetList[dynaset].bound, "ADDRESS_NOT_DYNASET");
        oracleList[dynaset] = oracle;
        IDynasetContract(dynaset).setDynasetOracle(oracle);
        emit OracleAssigned(dynaset, oracle);
    }

    function assignTvlSnapshot(address dynasetAddress)
        external
        onlyOwner
        nonReentrant
    {
        require(dynasetList[dynasetAddress].bound, "ADDRESS_NOT_DYNASET");
        require(
            dynasetList[dynasetAddress].tvlSnapshot == 0,
            "ERR_SNAPSHOT_SET"
        );
        uint256 totalvalue = IDynasetTvlOracle(getDynasetOracle(dynasetAddress))
            .dynasetTvlUsdc();

        dynasetList[dynasetAddress].tvlSnapshot = totalvalue;
        emit DynasetTvlSet(dynasetAddress, totalvalue);
    }

    /**  @notice collects fee from dynaset contract.
    * Fee can only be collected after atleast 30 days.
    * total fee collected will be performanceFee + managementFee
     @dev collected fee is in USDC token.
     @param dynasetAddress is address of dynaset contract.
    */
    function collectFee(address dynasetAddress)
        external
        onlyOwner
        nonReentrant
    {
        require(dynasetList[dynasetAddress].bound, "ADDRESS_NOT_DYNASET");
        uint256 feeLock = dynasetList[dynasetAddress].timelock;
        require(block.timestamp >= feeLock, "ERR_FEE_PRRIOD_LOCKED");

        uint256 snapshot = dynasetList[dynasetAddress].tvlSnapshot;
        require(snapshot > 0, "ERR_TVL_NOT_SET");
        uint256 totalValue = IDynasetTvlOracle(getDynasetOracle(dynasetAddress))
            .dynasetTvlUsdc();
        uint256 withdrawFee_;

        if (totalValue > snapshot) {
            // withdrawFee_ = (performance * (performanceFeeFactor) ) / 10,000
            withdrawFee_ =
                ((totalValue - snapshot) *
                    dynasetList[dynasetAddress].performanceFee) /
                (WITHDRAW_FEE_FACTOR);
        }

        uint256 managementFee = (totalValue *
            dynasetList[dynasetAddress].managementFee) / (WITHDRAW_FEE_FACTOR);
        uint256 timeSinceLastFeeCollection = block.timestamp -
            (dynasetList[dynasetAddress].timelock - 30 days);

        // managementFee = (0-5 % of tvl) * (no. sec from last fee collection / no. sec in year);
        uint256 managementFeeAnnualised = (managementFee *
            (timeSinceLastFeeCollection)) / (365 days);
        uint256 finalFee = managementFeeAnnualised + withdrawFee_;

        require(
            IERC20(USDC).balanceOf(dynasetAddress) >= finalFee,
            "ERR_INSUFFICIENT_USDC"
        );
        dynasetList[dynasetAddress].timelock = block.timestamp + 30 days;
        IDynasetContract(dynasetAddress).withdrawFee(USDC, finalFee);
        emit FeeCollected(dynasetAddress, finalFee);
    }

    /**  @notice fee collected from dynasets is transfered to
     * externaly owned account.
     * the account is set in constructor gnosisSafe.
     * NOTE NO user funds are transfered or withdrawn.
     * only the fee collected from dynasets is transfered
     */
    function withdrawFee(address tokenAddress, uint256 amount)
        external
        onlyOwner
    {
        require(amount > 0, "ERR_INVALID_AMOUNT");
        IERC20 token = IERC20(tokenAddress);
        require(
            token.balanceOf(address(this)) >= amount,
            "ERR_INSUFFICUENT_BALANCE"
        );
        token.safeTransfer(gnosisSafe, amount);
    }

    function updateGnosisSafe(address newGnosisSafe) external onlyOwner {
        require(newGnosisSafe != address(0), "ERR_ZERO_ADDRESS");
        gnosisSafe = newGnosisSafe;
    }

    /* ==========  Public Functions  ========== */

    function getDynasetOracle(address dynaset)
        public
        view
        returns (address oracle)
    {
        require(oracleList[dynaset] != address(0), "ERR_ORACLE_UNASSIGNED");
        return oracleList[dynaset];
    }
}