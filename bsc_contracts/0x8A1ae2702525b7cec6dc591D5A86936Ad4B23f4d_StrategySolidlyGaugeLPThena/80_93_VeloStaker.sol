// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./CeSolidStaker.sol";
import "../interfaces/IRewardPool.sol";
import "../interfaces/IWrappedBribeFactory.sol";
import "../interfaces/ISolidlyRouter.sol";
import "../interfaces/IFeeConfig.sol";
import "../interfaces/ISolidlyGauge.sol";

contract VeloStaker is ERC20, CeSolidStaker {
    using SafeERC20 for IERC20;

    // Needed addresses
    IRewardPool public ceVeloRewardPool;
    IWrappedBribeFactory public bribeFactory = IWrappedBribeFactory(0x7955519E14fdF498E28831F4cC06af4B8e3086A8);
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

    // Mapping our reward token to a route 
    ISolidlyRouter.Routes[] public veloToNativeRoute;
    mapping (address => ISolidlyRouter.Routes[]) public routes;
    mapping (address => bool) public lpInitialized;
    mapping (address => Gauges) public gauges;

    // Events
    event SetCeVeloRewardPool(address oldPool, address newPool);
    event SetRouter(address oldRouter, address newRouter);
    event SetBribeFactory(address oldFactory, address newFactory);
    event SetFeeRecipient(address oldRecipient, address newRecipient);
    event SetFeeId(uint256 id);
    event AddedGauge(address bribeGauge, address feeGauge, address[] bribeTokens, address[] feeTokens);
    event AddedRewardToken(address token);
    event RewardsHarvested(uint256 amount);
    event Voted(address[] votes, uint256[] weights);
    event ChargedFees(uint256 callFees, uint256 coFees, uint256 strategistFees);
    
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _reserveRate,
        address _solidVoter,
        address _keeper,
        address _voter,
        address _ceVeloRewardPool,
        address _coFeeRecipient,
        address _coFeeConfig,
        address _router,
        ISolidlyRouter.Routes[] memory _veloToNativeRoute
    ) CeSolidStaker(
        _name,
        _symbol,
        _reserveRate,
        _solidVoter,
        _keeper,
        _voter
    ) {
        ceVeloRewardPool = IRewardPool(_ceVeloRewardPool);
        router = ISolidlyRouter(_router);
        coFeeRecipient = _coFeeRecipient;
        coFeeConfig = IFeeConfig(_coFeeConfig);

        native = _veloToNativeRoute[_veloToNativeRoute.length - 1].to; 
        for (uint i; i < _veloToNativeRoute.length;) {
            veloToNativeRoute.push(_veloToNativeRoute[i]);
            unchecked { ++i; }
        }
    }

    // Vote information 
    function voteInfo() external view returns (address[] memory lpsVoted, uint256[] memory votes, uint256 lastVoted) {
        uint256 len = activeVoteLps.length;
        lpsVoted = new address[](len);
        votes = new uint256[](len);
        for (uint i; i < len;) {
            lpsVoted[i] = solidVoter.poolVote(tokenId, i);
            votes[i] = solidVoter.votes(tokenId, lpsVoted[i]);
            unchecked { ++i; }
        }
        lastVoted = solidVoter.lastVoted(tokenId);
    }

    // Claim veToken emissions and increases locked amount in veToken
    function claimVeEmissions() public override {
        uint256 _amount = veDist.claim(tokenId);
        uint256 gap = totalWant() - totalSupply();
        if (gap > 0) {
            _mint(address(ceVeloRewardPool), gap);
            ceVeloRewardPool.notifyRewardAmount();
        }
        emit ClaimVeEmissions(msg.sender, tokenId, _amount);
    }

    // vote for emission weights
    function vote(address[] calldata _tokenVote, uint256[] calldata _weights, bool _withHarvest) external onlyVoter {
        // Check to make sure we set up our rewards
        for (uint i; i < _tokenVote.length;) {
            require(lpInitialized[_tokenVote[i]], "lp not lpInitialized");
            unchecked { ++i; }
        }

        if (_withHarvest) {
            harvest();
        }

        activeVoteLps = _tokenVote;
        // We claim first to maximize our voting power.
        claimVeEmissions();
        solidVoter.vote(tokenId, _tokenVote, _weights);
        emit Voted(_tokenVote, _weights);
    }

    // Add gauge
    function addGauge(address _lp, address[] calldata _bribeTokens, address[] calldata _feeTokens) external onlyManager {
        address gauge = solidVoter.gauges(_lp);
        gauges[_lp] = Gauges(
            bribeFactory.oldBribeToNew(solidVoter.external_bribes(gauge)),
            solidVoter.internal_bribes(gauge),
            _bribeTokens,
            _feeTokens
        );
        lpInitialized[_lp] = true;
        emit AddedGauge(solidVoter.external_bribes(_lp), solidVoter.internal_bribes(_lp), _bribeTokens, _feeTokens);
    }

    // Delete a reward token 
    function deleteRewardToken(address _token) external onlyManager {
        delete routes[_token];
    }

    // Add multiple reward tokens
    function addMultipleRewardTokens(ISolidlyRouter.Routes[][] calldata _routes) external onlyManager {
        for (uint i; i < _routes.length;) {
            addRewardToken(_routes[i]);
            unchecked { ++i; }
        }
    }

     // Add a reward token
    function addRewardToken(ISolidlyRouter.Routes[] calldata _route) public onlyManager {
        require(_route[0].from != address(want), "from cant be want");
        require(_route[_route.length - 1].to == address(want), "to has to be want");
        for (uint i; i < _route.length;) {
            routes[_route[0].from].push(_route[i]);
            unchecked { ++i; }
        }
        
        IERC20(_route[0].from).safeApprove(address(router), 0);
        IERC20(_route[0].from).safeApprove(address(router), type(uint256).max);
        emit AddedRewardToken(_route[0].from);
    }

    function getRewards(address _gauge, address[] calldata _tokens, ISolidlyRouter.Routes[][] calldata _routes) external nonReentrant onlyManager {
        uint256 before = balanceOfWant();
        ISolidlyGauge(_gauge).getReward(tokenId, _tokens);
        for (uint i; i < _routes.length;) {
            require(_routes[i][_routes[i].length - 1].to == address(want), "to != Want");
            require(_routes[i][0].from != address(want), "Can't sell Want");
            uint256 tokenBal = IERC20(_routes[i][0].from).balanceOf(address(this));
            if (tokenBal > 0) {
                IERC20(_routes[i][0].from).safeApprove(address(router), 0);
                IERC20(_routes[i][0].from).safeApprove(address(router), type(uint256).max);
                router.swapExactTokensForTokens(tokenBal, 0, _routes[i], address(this), block.timestamp);
            }
            unchecked { ++i; }
        }

        uint256 rewardBal = balanceOfWant() - before;

        _chargeFeesAndMint(rewardBal);
    }   

    // claim owner rewards such as trading fees and bribes from gauges swap to velo, notify reward pool
    function harvest() public {
        uint256 before = balanceOfWant();
        for (uint i; i < activeVoteLps.length;) {
            Gauges memory rewardsGauge = gauges[activeVoteLps[i]];
            ISolidlyGauge(rewardsGauge.bribeGauge).getReward(tokenId, rewardsGauge.bribeTokens);
            ISolidlyGauge(rewardsGauge.feeGauge).getReward(tokenId, rewardsGauge.feeTokens);
            
            for (uint j; j < rewardsGauge.bribeTokens.length;) {
                uint256 tokenBal = IERC20(rewardsGauge.bribeTokens[j]).balanceOf(address(this));
                if (tokenBal > 0 && rewardsGauge.bribeTokens[j] != address(want)) {
                    router.swapExactTokensForTokens(tokenBal, 0, routes[rewardsGauge.bribeTokens[j]], address(this), block.timestamp);
                }
                unchecked { ++j; }
            }

            for (uint k; k < rewardsGauge.feeTokens.length;) {
                uint256 tokenBal = IERC20(rewardsGauge.feeTokens[k]).balanceOf(address(this));
                if (tokenBal > 0 && rewardsGauge.feeTokens[k] != address(want)) {
                    router.swapExactTokensForTokens(tokenBal, 0, routes[rewardsGauge.feeTokens[k]], address(this), block.timestamp);
                }
                unchecked { ++k; }
            }
            unchecked { ++i; }
        }

        uint256 rewardBal = balanceOfWant() - before;
    
        _chargeFeesAndMint(rewardBal);
    }

    function _chargeFeesAndMint(uint256 _rewardBal) internal {
        // Charge our fees here since we send CeVelo to reward pool
        IFeeConfig.FeeCategory memory fees = coFeeConfig.getFees(address(this));
        uint256 feeBal = _rewardBal * fees.total / 1e18;
        if (feeBal > 0) {
            IERC20(want).safeApprove(address(router), feeBal);
            uint256[] memory amounts = router.swapExactTokensForTokens(feeBal, 0, veloToNativeRoute, address(coFeeRecipient), block.timestamp);
            IERC20(want).safeApprove(address(router), 0);
            emit ChargedFees(0, amounts[amounts.length - 1], 0);
        }

        uint256 gap = totalWant() - totalSupply();
        if (gap > 0) {
            _mint(address(ceVeloRewardPool), gap);
            ceVeloRewardPool.notifyRewardAmount();
            emit RewardsHarvested(gap);
        }
    }

    // Set our reward Pool to send our earned CeVelo
    function setCeVeloRewardPool(address _rewardPool) external onlyOwner {
        emit SetCeVeloRewardPool(address(ceVeloRewardPool), _rewardPool);
        ceVeloRewardPool = IRewardPool(_rewardPool);
    }

    // Set the wrapped bribe factory
    function setBribeFactory(address _bribeFactory) external onlyOwner {
        emit SetBribeFactory(address(bribeFactory), _bribeFactory);
        bribeFactory = IWrappedBribeFactory(_bribeFactory);
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

    // Set our router to exchange our rewards, also update new veloToNative route. 
    function setRouterAndRoute(address _router, ISolidlyRouter.Routes[] calldata _route) external onlyOwner {
        emit SetRouter(address(router), _router);
        for (uint i; i < _route.length;) {
            veloToNativeRoute.push(_route[i]);
            unchecked { ++i; }
        }
        router = ISolidlyRouter(_router);
    }
}