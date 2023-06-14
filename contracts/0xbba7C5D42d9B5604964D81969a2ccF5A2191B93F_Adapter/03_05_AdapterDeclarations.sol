// SPDX-License-Identifier: --DAO--

/**
 * @author René Hochmuth
 * @author Vitally Marinchenko
 */

pragma solidity =0.8.19;

import "./AdapterInterfaces.sol";

error InvalidFeed();
error InvalidToken();
error InvalidDecimals();

contract AdapterDeclarations {

    struct TokenData {
        IERC20 tokenERC20;
        IChainLink feedLink;
        uint8 feedDecimals;
        uint8 tokenDecimals;
    }

    uint256 constant TOKENS = 1;
    TokenData[TOKENS] public tokens;

    IERC20 public immutable WETH;
    IERC20 public immutable USDC;

    address public immutable WETH_ADDRESS;
    address public immutable USDC_ADDRESS;

    address public immutable TOKEN_PROFIT_ADDRESS;
    address public immutable UNIV2_ROUTER_ADDRESS;
    address public immutable LIQUID_NFT_ROUTER_ADDRESS;

    ITokenProfit public immutable tokenProfit;
    ILiquidNFTsPool public immutable liquidNFTsWETHPool;
    ILiquidNFTsPool public immutable liquidNFTsUSDCPool;

    address public admin;
    address public multisig;
    address public proposedMultisig;
    address public proposedAdmin;

    uint256 public buyFee = 1000;

    uint256 constant public FEE_PRECISION = 1E4;
    uint256 constant public FEE_THRESHOLD = 50000;
    uint256 constant public FEE_LOWER_BOUND = 10;
    uint256 constant public PRECISION_FACTOR = 1E18;

    bool public budgetWithdrawn;
    uint256 constant public BUDGET_FOR_2023 = 115E18;

    uint80 constant MAX_ROUND_COUNT = 50;
    address constant ZERO_ADDRESS = address(0x0);
    uint256 constant UINT256_MAX = type(uint256).max;

    mapping(address => uint256) public chainLinkHeartBeat;

    modifier onlyAdmin() {
        require(
            msg.sender == admin,
            "AdapterDeclarations: NOT_ADMIN"
        );
        _;
    }

    modifier onlyTokenProfit() {
        require(
            msg.sender == TOKEN_PROFIT_ADDRESS,
            "AdapterDeclarations: NOT_TOKEN_PROFIT"
        );
        _;
    }

    modifier onlyProposedMultisig() {
        require(
            msg.sender == proposedMultisig,
            "AdapterDeclarations: NOT_PROPOSED_MULTISIG"
        );
        _;
    }

    modifier onlyProposedAdmin() {
        require(
            msg.sender == proposedAdmin,
            "AdapterDeclarations: NOT_PROPOSED_ADMIN"
        );
        _;
    }

    modifier onlyMultiSig() {
        require(
            msg.sender == multisig,
            "AdapterDeclarations: NOT_MULTISIG"
        );
        _;
    }

    event AdminSwap(
        address indexed from,
        address indexed to,
        uint256 amountIn,
        uint256 amountOut
    );

    event BuyFeeChanged(
        uint256 indexed oldFee,
        uint256 indexed newFee
    );

    event MultisigUpdate(
        address oldMultisig,
        address newMultisig
    );

    event MultisigUpdateProposed(
        address oldProposedMultisig,
        address newProposedMultisig
    );

    event AdminUpdate(
        address oldAdmin,
        address newAdmin
    );

    event AdminUpdateProposed(
        address oldProposedAdmin,
        address newProposedAdmin
    );

    constructor(
        address _tokenProfitAddress,
        address _uniV2RouterAddress,
        address _liquidNFTsRouterAddress,
        address _liquidNFTsWETHPool,
        address _liquidNFTsUSDCPool
    ) {
        // --- liquidNFTs group ---

        liquidNFTsWETHPool = ILiquidNFTsPool(
            _liquidNFTsWETHPool
        );

        liquidNFTsUSDCPool = ILiquidNFTsPool(
            _liquidNFTsUSDCPool
        );

        LIQUID_NFT_ROUTER_ADDRESS = _liquidNFTsRouterAddress;

        // --- token group ---

        USDC_ADDRESS = liquidNFTsUSDCPool.poolToken();
        WETH_ADDRESS = liquidNFTsWETHPool.poolToken();

        USDC = IERC20(
            USDC_ADDRESS
        );

        WETH = IWETH(
            WETH_ADDRESS
        );

        IChainLink chainLinkFeed = IChainLink(
            0x986b5E1e1755e3C2440e960477f25201B0a8bbD4
        );

        tokens[0] = TokenData({
            tokenERC20: USDC,
            feedLink: chainLinkFeed,
            feedDecimals: chainLinkFeed.decimals(),
            tokenDecimals: USDC.decimals()
        });

        _validateData();

        // --- tokenProfit group ---

        tokenProfit = ITokenProfit(
            _tokenProfitAddress
        );

        TOKEN_PROFIT_ADDRESS = _tokenProfitAddress;
        UNIV2_ROUTER_ADDRESS = _uniV2RouterAddress;
    }

    function _validateData()
        private
    {
        for (uint256 i = 0; i < TOKENS; i++) {

            TokenData memory token = tokens[i];

            if (token.tokenDecimals == 0) {
                revert InvalidDecimals();
            }

            if (token.feedDecimals == 0) {
                revert InvalidDecimals();
            }

            if (token.tokenERC20 == IERC20(ZERO_ADDRESS)) {
                revert InvalidToken();
            }

            if (token.feedLink == IChainLink(ZERO_ADDRESS)) {
                revert InvalidFeed();
            }

            string memory expectedFeedName = string.concat(
                token.tokenERC20.symbol(),
                " / "
                "ETH"
            );

            string memory chainLinkFeedName = token.feedLink.description();

            require(
                keccak256(abi.encodePacked(expectedFeedName)) ==
                keccak256(abi.encodePacked(chainLinkFeedName)),
                "AdapterDeclarations: INVALID_CHAINLINK_FEED"
            );

            recalibrate(
                address(token.feedLink)
            );
        }
    }

    /**
     * @dev Determines info for the heartbeat update
     *  mechanism for chainlink oracles (roundIds)
     */
    function getLatestAggregatorRoundId(
        IChainLink _feed
    )
        public
        view
        returns (uint80)
    {
        (
            uint80 roundId,
            ,
            ,
            ,
        ) = _feed.latestRoundData();

        return uint64(roundId);
    }

    /**
     * @dev Determines number of iterations necessary during recalibrating
     * heartbeat.
     */
    function _getIterationCount(
        uint80 _latestAggregatorRoundId
    )
        internal
        pure
        returns (uint80)
    {
        return _latestAggregatorRoundId > MAX_ROUND_COUNT
            ? MAX_ROUND_COUNT
            : _latestAggregatorRoundId;
    }

    /**
     * @dev fetches timestamp of a byteshifted aggregatorRound with specific
     * phaseID. For more info see chainlink historical price data documentation
     */
    function _getRoundTimestamp(
        IChainLink _feed,
        uint16 _phaseId,
        uint80 _aggregatorRoundId
    )
        internal
        view
        returns (uint256)
    {
        (
            ,
            ,
            ,
            uint256 timestamp,
        ) = _feed.getRoundData(
            getRoundIdByByteShift(
                _phaseId,
                _aggregatorRoundId
            )
        );

        return timestamp;
    }

    /**
     * @dev Determines info for the heartbeat update mechanism for chainlink
     * oracles (shifted round Ids)
     */
    function getRoundIdByByteShift(
        uint16 _phaseId,
        uint80 _aggregatorRoundId
    )
        public
        pure
        returns (uint80)
    {
        return uint80(uint256(_phaseId) << 64 | _aggregatorRoundId);
    }

    /**
     * @dev Function to recalibrate the heartbeat for a specific feed
     */
    function recalibrate(
        address _feed
    )
        public
    {
        chainLinkHeartBeat[_feed] = recalibratePreview(
            IChainLink(_feed)
        );
    }

    /**
    * @dev View function to determine the heartbeat for a specific feed
    * Looks at the maximal last 50 rounds and takes second highest value to
    * avoid counting offline time of chainlink as valid heartbeat
    */
    function recalibratePreview(
        IChainLink _feed
    )
        public
        view
        returns (uint256)
    {
        uint80 latestAggregatorRoundId = getLatestAggregatorRoundId(
            _feed
        );

        uint80 iterationCount = _getIterationCount(
            latestAggregatorRoundId
        );

        if (iterationCount < 2) {
            revert("LiquidRouter: SMALL_SAMPLE");
        }

        uint16 phaseId = _feed.phaseId();
        uint256 latestTimestamp = _getRoundTimestamp(
            _feed,
            phaseId,
            latestAggregatorRoundId
        );

        uint256 currentDiff;
        uint256 currentBiggest;
        uint256 currentSecondBiggest;

        for (uint80 i = 1; i < iterationCount; i++) {

            uint256 currentTimestamp = _getRoundTimestamp(
                _feed,
                phaseId,
                latestAggregatorRoundId - i
            );

            currentDiff = latestTimestamp - currentTimestamp;

            latestTimestamp = currentTimestamp;

            if (currentDiff >= currentBiggest) {
                currentSecondBiggest = currentBiggest;
                currentBiggest = currentDiff;
            } else if (currentDiff > currentSecondBiggest && currentDiff < currentBiggest) {
                currentSecondBiggest = currentDiff;
            }
        }

        return currentSecondBiggest;
    }

    function setApprovals()
        external
    {
        address[2] memory spenders = [
            UNIV2_ROUTER_ADDRESS,
            LIQUID_NFT_ROUTER_ADDRESS
        ];

        for (uint256 i = 0; i < spenders.length; i++) {
            for (uint256 j = 0; j < tokens.length; j++) {
                tokenProfit.executeAdapterRequest(
                    address(tokens[j].tokenERC20),
                    abi.encodeWithSelector(
                        IERC20.approve.selector,
                        spenders[i],
                        UINT256_MAX
                    )
                );
            }
            tokenProfit.executeAdapterRequest(
                WETH_ADDRESS,
                abi.encodeWithSelector(
                    IERC20.approve.selector,
                    spenders[i],
                    UINT256_MAX
                )
            );
        }
    }
}