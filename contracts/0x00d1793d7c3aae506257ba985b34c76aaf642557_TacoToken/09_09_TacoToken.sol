// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./DeflationaryERC20.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./SocialProofable.sol";

interface IUniswapV2Pair {
    function sync() external;
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

/**                                 
 *            ╭╯╭╯  ╭╯╭╯  ╭╯╭╯      
 *        ╱▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔╲▔▔▔╲   
 *       ╱      ╭╮   ╭╮      ╲╮╮ ╲  
 *       ▏     ▂▂▂▂▂▂▂▂▂     ▕╮╮ ▕  
 *       ▏     ╲▂▂▂▂▂▂▂╱     ▕╮╮ ▕  
 *       ╲▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂╲▂▂╱  
 *               TACOS              
 *
 *
 * @title TacoToken
 * @dev Contract for $TACO.
 *      Based of the work by Tendies $TEND
 *
 * @author [email protected] ($TEND)
 * @author @Onchained ($TACO)
 */
contract TacoToken is DeflationaryERC20, Pausable, SocialProofable {
    using SafeMath for uint256;

    //===============================================//
    //          Contract Variables                   //
    //===============================================//

    // SOCIAL PROOF //
    string public constant override getTwitter = "Taconomics101";
    string public constant override getTelegram = "TacoGram";
    string public constant override getWebsite = "taconomics.io";
    string public constant override getGithub = "taconomics";
    uint256 public twitterProof;
    bytes public githubProof;

    // CRUNCH //
    uint256 public lastCrunchTime;
    uint256 public totalCrunched;

    // crunchRate is defined as a percentage (e.g. 1 = 1%, 5 = 5%, 27 = 27%)
    uint256 public crunchRate;

    /**
     * rewardForTaquero is defined as a percentage (e.g. 1 = 1%, 5 = 5%, 27 = 27%)
     * this is however a percentage of the crunchRate.
     */ 
    uint256 public rewardForTaquero;

    /**
     * Taco Tuesday means the reward is multiplied by a factor defined here.
     * This percentage is defined as a multiplier with 1 decimal.
     * (e.g. 15 = 1.5x, 10 = 1x, 2 = 2x)
     * This is a multiplier applied to the rewardForTaquero percentage
     * (e.g. if rewardForTaquery = 2%, and multiplier is 20 (2x), then the reward is 4%)
     */
    uint256 public tacoTuesdayRewardMultiplier;

    struct TaqueroStats {
        uint256 timesCrunched;
        uint256 tacosCrunched;
    }

    mapping(address => TaqueroStats) public taquerosCrunchStats;
    address[] public taqueros;

    // UNISWAP //
    IERC20 public WETH;
    IUniswapV2Factory public uniswapFactory;
    address public uniswapPool;

    //===============================================//
    //                 Constructor                   //
    //===============================================//
    constructor(uint256 initialSupply, address _uniswapFactoryAddress, address _wethToken)
        public
        Pausable()
        DeflationaryERC20("Tacos", "TACO")
    {
        _mint(msg.sender, initialSupply);

        // Initialize UniswapFactory
        uniswapFactory = IUniswapV2Factory(_uniswapFactoryAddress);
        WETH = IERC20(_wethToken);

        // Crunch variables
        crunchRate = 4; // Initial crunch rate set at 4%
        rewardForTaquero = 1; // Initial reward percentage set at 1% (1% of 4%)
        tacoTuesdayRewardMultiplier = 20; // Initial tacoTuesday multiplier set at 2x

    }

    //===============================================//
    //                   Events                      //
    //===============================================//
    event PoolCrunched(
        address taquero,
        uint256 crunchedAmount,
        uint256 newTotalSupply,
        uint256 newUniswapPoolSupply,
        uint256 taqueroReward,
        uint256 timesCrunched,
        uint256 totalTacosCrunched
    );

    //===============================================//
    //                   Methods                     //
    //===============================================//

    // UNISWAP POOL //
    function setUniswapPool() external onlyOwner {
        require(uniswapPool == address(0), "TacoToken: pool already created");
        uniswapPool = uniswapFactory.createPair(address(WETH), address(this));
    }

    // TOKEN TRANSFER HOOK //
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(
            !paused || msg.sender == pauser,
            "TacoToken: Cannot transfer tokens while game is paused and sender is not the Pauser."
        );
    }

    // PAUSABLE OVERRIDE //
    function unpause() external onlyPauser {
        super._unpause();

        // Start crunching
        lastCrunchTime = now;
    }

    // CRUNCH VARIABLES SETTERS //
    function setCrunchRate(uint256 _crunchRate) external onlyOwner {
        require(
            _crunchRate > 0 && _crunchRate <= 10,
            "TacoToken: crunchRate must be at least 1 and at most 10"
        );
        crunchRate = _crunchRate;
    }

    function setRewardForTaquero(uint256 _rewardForTaquero) external onlyOwner {
        require(
            _rewardForTaquero > 0 && _rewardForTaquero <= 10,
            "TacoToken: rewardForTaquero must be at least 1 and at most 10"
        );
        rewardForTaquero = _rewardForTaquero;
    }

    function setTacoTuesdayRewardMultiplier(uint256 _tacoTuesdayRewardMultiplier) external onlyOwner {
        require(
            _tacoTuesdayRewardMultiplier > 9 && _tacoTuesdayRewardMultiplier <= 30,
            "TacoToken: tacoTuesdayRewardMultiplier must be at least 10 and at most 30"
        );
        tacoTuesdayRewardMultiplier = _tacoTuesdayRewardMultiplier;
    }

    // INFORMATION OF TAQUEROS FOR UI //
    function getInfoFor(address addr)
        public
        view
        returns (
            uint256 balance,
            uint256 poolBalance,
            uint256 totalSupply,
            uint256 totalTacosCrunched,
            uint256 crunchableTacos,
            uint256 lastCrunchAt,
            uint256 timesCrunched,
            uint256 tacosCrunched,
            bool tacoTuesday,
            uint256 tacosCrunchRate,
            uint256 taqueroRewardRate,
            uint256 tacoTuesdayMultiplier
        )
    {
        TaqueroStats memory taqueroStats = taquerosCrunchStats[addr];

        return (
            balanceOf(addr),
            balanceOf(uniswapPool),
            _totalSupply,
            totalCrunched,
            getCrunchAmount(),
            lastCrunchTime,
            taqueroStats.timesCrunched,
            taqueroStats.tacosCrunched,
            isTacoTuesday(),
            crunchRate,
            rewardForTaquero,
            tacoTuesdayRewardMultiplier
        );
    }

    // CRUNCH DAT POOL! //
    function crunchPool() external whenNotPaused {
        uint256 toRemoveFromUniswap = getCrunchAmount();
        require(
            toRemoveFromUniswap >= 1 * 1e18,
            "crunchPool: min crunch amount not reached."
        );

        // Reset last crunch time
        lastCrunchTime = now;

        uint256 toPayTaquero = toRemoveFromUniswap
            .mul(rewardForTaquero)
            .mul(rewardMultiplier())
            .div(1000);

        uint256 toBurnPermanently = toRemoveFromUniswap.sub(toPayTaquero);

        //=== DEFLATE SUPPLY
        // Remove tokens from Uniswap Pool.
        _balances[uniswapPool] = _balances[uniswapPool].sub(toRemoveFromUniswap);
        // Payout reward to taquero.
        _balances[msg.sender] = _balances[msg.sender].add(toPayTaquero);
        // "Burn" remaining tokens.
        _totalSupply = _totalSupply.sub(toBurnPermanently);
        //=== END DEFLATE

        totalCrunched = totalCrunched.add(toBurnPermanently); // Track all tacos crunched

        //=== UPDATE TAQUERO STATS
        // Retrieve Taquero Stats
        TaqueroStats storage taqueroStats = taquerosCrunchStats[msg.sender];
        // If this is a new taquero, add to the list
        if (taqueroStats.timesCrunched == 0) {
            taqueros.push(msg.sender);
        }
        // Update the stats
        taqueroStats.timesCrunched = taqueroStats.timesCrunched.add(1);
        taqueroStats.tacosCrunched = taqueroStats.tacosCrunched.add(toPayTaquero);
        // Save stats in the map
        taquerosCrunchStats[msg.sender] = taqueroStats;
        //=== END UPDATE STATS

        IUniswapV2Pair(uniswapPool).sync();

        emit PoolCrunched(
            msg.sender,
            toRemoveFromUniswap,
            _totalSupply,
            balanceOf(uniswapPool),
            toPayTaquero,
            taqueroStats.timesCrunched,
            taqueroStats.tacosCrunched
        );
    }

    // Calculates the Amount of tokens available for Crunching given the delta in time since
    // last Crunch.
    function getCrunchAmount() public view returns (uint256) {
        if (paused) return 0;

        uint256 timeBetweenLastCrunch = now - lastCrunchTime;
        uint256 tokensInUniswapPool = balanceOf(uniswapPool);
        uint256 dayInSeconds = 1 days;
        uint256 crunchAmount = (tokensInUniswapPool.mul(crunchRate).mul(timeBetweenLastCrunch))
                .div(dayInSeconds)
                .div(100);

        return crunchAmount;
    }

    // Determines the Reward Multiplier
    function rewardMultiplier() public view returns (uint256) {
        // This returns a multiplier with 1 decimal. so 10 means 1.0x
        if (isTacoTuesday()) {
            return tacoTuesdayRewardMultiplier;
        } else {
            return 10;
        }
    }

    // Is it Tuesday Today?
    // Thank you @nanexcool
    // https://twitter.com/nanexcool/status/1259623747339849729
    function isTacoTuesday() public view returns (bool) {
        uint256 day = (now / 1 days + 3) % 7;
        return day == 1;
    }

    // Taquero Stats getter for Leaderboard
    function countTaqueros() public view returns (uint256) {
        return taqueros.length;
    }

    function getTaqueros() public view returns(address[] memory) {
        return taqueros;
    }

    function getTaqueroStats(address _address) public view returns (uint256 timesCrunched, uint256 tacosCrunched) {
        return (taquerosCrunchStats[_address].timesCrunched, taquerosCrunchStats[_address].tacosCrunched);
    }

    //===============================================//
    //                Social Proof                   //
    //===============================================//
    function setTwitterProof(uint256 _twitterProof) external onlyOwner {
        twitterProof = _twitterProof;
    }

    function getTwitterProof() external override view returns(uint256) {
        return twitterProof;
    }

    function setGithubProof(bytes calldata _githubProof) external onlyOwner {
        githubProof = _githubProof;
    }

    function getGithubProof() external override view returns(bytes memory) {
        return githubProof;
    }
}
