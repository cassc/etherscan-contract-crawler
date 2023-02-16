// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ChamTHESolidStaker.sol";
import "../interfaces/IRewardPool.sol";
import "../interfaces/IWrappedBribeFactory.sol";
import "../interfaces/ISolidlyRouter.sol";
import "../interfaces/IFeeConfig.sol";
import "../interfaces/ISolidlyGauge.sol";

contract ThenaStaker is ERC20, ChamTHESolidStaker {
    using SafeERC20 for IERC20;

    // Needed addresses
    IRewardPool public chamTHERewardPool;
    address[] public activeVoteLps;
    ISolidlyRouter public router;
    address public coFeeRecipient;
    IFeeConfig public coFeeConfig;
    address public native;

    // Voted Gauges
    struct Gauges {
        address bribeGauge;
        address feeGauge;
        address[] bribeTokens;
        address[] feeTokens;
    }

    // Mapping our `reward token` to `want token` in routes for Router
    ISolidlyRouter.Routes[] public thenaToNativeRoute;
    mapping(address => ISolidlyRouter.Routes[]) public routes;
    mapping(address => bool) public lpInitialized;
    mapping(address => Gauges) public gauges;

    // Events
    event SetChamTHERewardPool(address oldPool, address newPool);
    event SetRouter(address oldRouter, address newRouter);
    event SetBribeFactory(address oldFactory, address newFactory);
    event SetFeeRecipient(address oldRecipient, address newRecipient);
    event SetFeeId(uint256 id);
    event AddedGauge(
        address gauge,
        address feeGauge,
        address[] bribeTokens,
        address[] feeTokens
    );
    event AddedRewardToken(address token);
    event RewardsHarvested(uint256 amount);
    event Voted(address[] votes, uint256[] weights);
    event ChargedFees(uint256 callFees, uint256 coFees, uint256 strategistFees);
    event MergeVe(address indexed user, uint256 veTokenId, uint256 amount);
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _reserveRate,
        address _solidVoter,
        address[] memory _manager,
        address _chamTHERewardPool,
        address _coFeeRecipient,
        address _coFeeConfig,
        address _router,
        ISolidlyRouter.Routes[] memory _thenaToNativeRoute
    )
        ChamTHESolidStaker(
            _name,
            _symbol,
            _reserveRate,
            _solidVoter,
            _manager[0],
            _manager[1],
            _manager[2]
        )
    {
        chamTHERewardPool = IRewardPool(_chamTHERewardPool);
        router = ISolidlyRouter(_router);
        coFeeRecipient = _coFeeRecipient;
        coFeeConfig = IFeeConfig(_coFeeConfig);

        native = _thenaToNativeRoute[_thenaToNativeRoute.length - 1].to;
        for (uint i; i < _thenaToNativeRoute.length; i++) {
            thenaToNativeRoute.push(_thenaToNativeRoute[i]);
        }
    }

    // Vote information
    function voteInfo()
        external
        view
        returns (
            address[] memory lpsVoted,
            uint256[] memory votes,
            uint256 lastVoted
        )
    {
        uint256 len = activeVoteLps.length;
        lpsVoted = new address[](len);
        votes = new uint256[](len);
        for (uint i; i < len; i++) {
            lpsVoted[i] = solidVoter.poolVote(tokenId, i);
            votes[i] = solidVoter.votes(tokenId, lpsVoted[i]);
        }
        lastVoted = solidVoter.lastVoted(tokenId);
    }

    // Claim veToken emissions and increases locked amount in veToken
    function claimVeEmissions() public override {
        uint256 _amount = veDist.claim(tokenId);
        uint256 gap = totalWant() - totalSupply();
        if (gap > 0) {
            _mint(address(chamTHERewardPool), gap);
            chamTHERewardPool.notifyRewardAmount();
        }
        emit ClaimVeEmissions(msg.sender, tokenId, _amount);
    }

    // vote for emission weights
    function vote(
        address[] calldata _tokenVote,
        uint256[] calldata _weights,
        bool _withHarvest
    ) external onlyVoter {
        // Check to make sure we set up our rewards
        for (uint i; i < _tokenVote.length; i++) {
            require(lpInitialized[_tokenVote[i]], "Staker: TOKEN_VOTE_INVALID");
        }

        if (_withHarvest) harvest();

        activeVoteLps = _tokenVote;
        // We claim first to maximize our voting power.
        claimVeEmissions();
        solidVoter.vote(tokenId, _tokenVote, _weights);
        emit Voted(_tokenVote, _weights);
    }

    // Add gauge
    function addGauge(
        address _lp,
        address[] calldata _bribeTokens,
        address[] calldata _feeTokens
    ) external onlyManager {
        address gauge = solidVoter.gauges(_lp);
        gauges[_lp] = Gauges(
            solidVoter.external_bribes(gauge),
            solidVoter.internal_bribes(gauge),
            _bribeTokens,
            _feeTokens
        );
        lpInitialized[_lp] = true;
        emit AddedGauge(
            solidVoter.external_bribes(_lp),
            solidVoter.internal_bribes(_lp),
            _bribeTokens,
            _feeTokens
        );
    }

    // Delete a reward token
    function deleteRewardToken(address _token) external onlyManager {
        delete routes[_token];
    }

    // Add multiple reward tokens
    function addMultipleRewardTokens(
        ISolidlyRouter.Routes[][] calldata _routes
    ) external onlyManager {
        for (uint i; i < _routes.length; i++) {
            addRewardToken(_routes[i]);
        }
    }

    // Add a reward token
    function addRewardToken(
        ISolidlyRouter.Routes[] calldata _route
    ) public onlyManager {
        require(
            _route[0].from != address(want),
            "Staker: ROUTE_FROM_IS_TOKEN_WANT"
        );
        require(
            _route[_route.length - 1].to == address(want),
            "Staker: ROUTE_TO_NOT_TOKEN_WANT"
        );
        for (uint i; i < _route.length; i++) {
            routes[_route[0].from].push(_route[i]);
        }
        IERC20(_route[0].from).safeApprove(address(router), 0);
        IERC20(_route[0].from).safeApprove(address(router), type(uint256).max);
        emit AddedRewardToken(_route[0].from);
    }

    function getRewards(
        address _bribe,
        address[] calldata _tokens,
        ISolidlyRouter.Routes[][] calldata _routes
    ) external nonReentrant onlyManager {
        uint256 before = balanceOfWant();
        ISolidlyGauge(_bribe).getReward(tokenId, _tokens);
        for (uint i; i < _routes.length; i++) {
            address tokenFrom = _routes[i][0].from;
            require(
                _routes[i][_routes[i].length - 1].to == address(want),
                "Staker: ROUTE_TO_NOT_TOKEN_WANT"
            );
            require(
                tokenFrom != address(want),
                "Staker: ROUTE_FROM_IS_TOKEN_WANT"
            );
            uint256 tokenBal = IERC20(tokenFrom).balanceOf(address(this));
            if (tokenBal > 0) {
                IERC20(tokenFrom).safeApprove(address(router), 0);
                IERC20(tokenFrom).safeApprove(
                    address(router),
                    type(uint256).max
                );
                router.swapExactTokensForTokens(
                    tokenBal,
                    0,
                    _routes[i],
                    address(this),
                    block.timestamp
                );
            }
        }
        uint256 rewardBal = balanceOfWant() - before;
        _chargeFeesAndMint(rewardBal);
    }

    // claim owner rewards such as trading fees and bribes from gauges swap to thena, notify reward pool
    function harvest() public {
        uint256 before = balanceOfWant();
        for (uint i; i < activeVoteLps.length; i++) {
            Gauges memory _gauges = gauges[activeVoteLps[i]];
            ISolidlyGauge(_gauges.bribeGauge).getReward(
                tokenId,
                _gauges.bribeTokens
            );
            ISolidlyGauge(_gauges.feeGauge).getReward(
                tokenId,
                _gauges.feeTokens
            );

            for (uint j; j < _gauges.bribeTokens.length; ++j) {
                address bribeToken = _gauges.bribeTokens[j];
                uint256 tokenBal = IERC20(bribeToken).balanceOf(address(this));
                if (tokenBal > 0 && bribeToken != address(want))
                    router.swapExactTokensForTokens(
                        tokenBal,
                        0,
                        routes[bribeToken],
                        address(this),
                        block.timestamp
                    );
            }

            for (uint k; k < _gauges.feeTokens.length; ++k) {
                address feeToken = _gauges.feeTokens[k];
                uint256 tokenBal = IERC20(feeToken).balanceOf(address(this));
                if (tokenBal > 0 && feeToken != address(want))
                    router.swapExactTokensForTokens(
                        tokenBal,
                        0,
                        routes[feeToken],
                        address(this),
                        block.timestamp
                    );
            }
        }
        uint256 rewardBal = balanceOfWant() - before;
        _chargeFeesAndMint(rewardBal);
    }

    function _chargeFeesAndMint(uint256 _rewardBal) internal {
        // Charge our fees here since we send CeThena to reward pool
        IFeeConfig.FeeCategory memory fees = coFeeConfig.getFees(address(this));
        uint256 feeBal = (_rewardBal * fees.total) / 1e18;
        if (feeBal > 0) {
            IERC20(want).safeApprove(address(router), feeBal);
            uint256[] memory amounts = router.swapExactTokensForTokens(
                feeBal,
                0,
                thenaToNativeRoute,
                address(coFeeRecipient),
                block.timestamp
            );
            IERC20(want).safeApprove(address(router), 0);
            emit ChargedFees(0, amounts[amounts.length - 1], 0);
        }

        uint256 gap = totalWant() - totalSupply();
        if (gap > 0) {
            _mint(address(chamTHERewardPool), gap);
            chamTHERewardPool.notifyRewardAmount();
            emit RewardsHarvested(gap);
        }
    }

    // Set our reward Pool to send our earned chamTHE
    function setChamTHERewardPool(address _rewardPool) external onlyOwner {
        emit SetChamTHERewardPool(address(chamTHERewardPool), _rewardPool);
        chamTHERewardPool = IRewardPool(_rewardPool);
    }

    // Set fee id on fee config
    function setFeeId(uint256 id) external onlyManager {
        emit SetFeeId(id);
        coFeeConfig.setStratFeeId(id);
    }

    // Set fee recipient
    function setCoFeeRecipient(address _feeRecipient) external onlyOwner {
        emit SetFeeRecipient(address(coFeeRecipient), _feeRecipient);
        coFeeRecipient = _feeRecipient;
    }

    // Set our router to exchange our rewards, also update new thenaToNative route.
    function setRouterAndRoute(
        address _router,
        ISolidlyRouter.Routes[] calldata _route
    ) external onlyOwner {
        emit SetRouter(address(router), _router);
        for (uint i; i < _route.length; i++) thenaToNativeRoute.pop();
        for (uint i; i < _route.length; i++) thenaToNativeRoute.push(_route[i]);
        router = ISolidlyRouter(_router);
    }

    function mergeVe(uint256 _tokenId) external {
        ve.merge(_tokenId, tokenId);
        uint256 gap = totalWant() - totalSupply();
        if (gap > 0) {
            _mint(address(chamTHERewardPool), gap);
            chamTHERewardPool.notifyRewardAmount();
        }
        emit MergeVe(msg.sender, _tokenId, gap);
    }
}