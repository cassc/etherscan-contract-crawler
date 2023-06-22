/**
 *Submitted for verification at Etherscan.io on 2021-01-15
*/

// File: contracts\GFarmTokenInterface.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface GFarmTokenInterface{
	function balanceOf(address account) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function burn(address from, uint256 amount) external;
    function mint(address to, uint256 amount) external;
}

// File: @openzeppelin\contracts\math\SafeMath.sol

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @uniswap\v2-core\contracts\interfaces\IUniswapV2Pair.sol

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: contracts\GFarm.sol

pragma solidity 0.7.5;




contract GFarm {

    using SafeMath for uint;

    // VARIABLES & CONSTANTS

    // 1. Tokens
    GFarmTokenInterface public token;
    IUniswapV2Pair public lp;
    address public nft;

    // 2. Pool 1
    uint public POOL1_MULTIPLIER; // 1e18
    uint public POOL1_MULTIPLIER_UPDATED;
    uint public constant POOL1_MULTIPLIER_UPDATE_EVERY = 45000; // 1 week (blocks)
    uint public POOL1_lastRewardBlock;
    uint public POOL1_accTokensPerLP; // 1e18
    uint public constant POOL1_REFERRAL_P = 6; // % 2 == 0
    uint public constant POOL1_CREDITS_MIN_P = 1;

    // 3. Pool 2
    uint public immutable POOL2_MULTIPLIER; // 1e18
    uint public constant POOL2_DURATION = 32000; // 5 days
    uint public immutable POOL2_END;
    uint public POOL2_lastRewardBlock;
    uint public POOL2_accTokensPerETH; // 1e18

    // 4. Pool 1 & Pool 2
    uint public immutable POOLS_START;
    uint public constant POOLS_START_DELAY = 1775;
    uint public constant PRECISION = 1e5;

    // 5. Useful Uniswap addresses (for TVL & APY)
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IUniswapV2Pair constant ETH_USDC_PAIR = IUniswapV2Pair(0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc);

    // 6. Governance & dev fund
    address public GOVERNANCE;
    address public immutable DEV_FUND;
    uint constant GOVERNANCE_P = 500000; // PRECISION
    uint constant DEV_FUND_P = 500000; // PRECISION

    // 7. Info about each user
    struct User {
        uint POOL1_provided;
        uint POOL1_rewardDebt;
        address POOL1_referral;
        uint POOL1_referralReward;

        uint POOL2_provided;
        uint POOL2_rewardDebt;

        uint NFT_CREDITS_amount;
        uint NFT_CREDITS_lastUpdated;
        bool NFT_CREDITS_receiving;
    }
    mapping(address => User) public users;

    constructor(address _GOV, address _DEV){
        // Distribution = 7500 * (3/4)^(n-1) (n = week)
        POOL1_MULTIPLIER = uint(7500 * 1e18) / 45000;
        POOL1_MULTIPLIER_UPDATED = block.number.add(POOLS_START_DELAY);

        POOL2_MULTIPLIER = POOL1_MULTIPLIER.div(10);
        POOL2_END = block.number.add(POOLS_START_DELAY)
                    .add(POOL2_DURATION);

        POOLS_START = block.number.add(POOLS_START_DELAY);

        GOVERNANCE = _GOV;
        DEV_FUND = _DEV;
    }

    // GOVERNANCE

    // 0. Modifier
    modifier onlyGov(){
        require(msg.sender == GOVERNANCE);
        _;
    }

    // 1. Update governance address
    function set_GOVERNANCE(address _gov) external onlyGov{
        GOVERNANCE = _gov;
    }

    // 2. Set token address
    function set_TOKEN(address _token) external onlyGov{
        require(token == GFarmTokenInterface(0), "Token address already set");
        token = GFarmTokenInterface(_token);
    }

    // 3. Set lp address
    function set_LP(address _lp) external onlyGov{
        require(lp == IUniswapV2Pair(0), "LP address already set");
        lp = IUniswapV2Pair(_lp);
    }

    // 4. Set token address
    function set_NFT(address _nft) external onlyGov{
        require(nft == address(0), "NFT address already set");
        nft = _nft;
    }

    // POOL REWARDS BETWEEN 2 BLOCKS

    // 1. Pool 1 (1e18)
    function POOL1_getReward(uint _from, uint _to) private view returns (uint){
        uint blocks;

        if(_from >= POOLS_START && _to >= POOLS_START){
            blocks = _to.sub(_from);
        }

        return blocks.mul(POOL1_MULTIPLIER);
    }

    // 2. Pool 2 (1e18)
    function POOL2_getReward(uint _from, uint _to) private view returns (uint){
        uint blocks;

        if(_from >= POOLS_START && _to >= POOLS_START){
            // Before pool 2 has ended
            if(_from <= POOL2_END && _to <= POOL2_END){
                blocks = _to.sub(_from);
            // Between before and after pool 2 has ended
            }else if(_from <= POOL2_END && _to > POOL2_END){
                blocks = POOL2_END.sub(_from);
            // After pool 2 has ended
            }else if(_from > POOL2_END && _to > POOL2_END){
                blocks = 0;
            }
        }

        return blocks.mul(POOL2_MULTIPLIER);
    }

    // UPDATE POOL VARIABLES

    // 1. Pool 1
    function POOL1_update() private {
        uint lpSupply = lp.balanceOf(address(this));

        if (POOL1_lastRewardBlock == 0 || lpSupply == 0) {
            POOL1_lastRewardBlock = block.number;
            return;
        }

        uint reward = POOL1_getReward(POOL1_lastRewardBlock, block.number);
        
        token.mint(address(this), reward);
        token.mint(GOVERNANCE, reward.mul(GOVERNANCE_P).div(100*PRECISION));
        token.mint(DEV_FUND, reward.mul(DEV_FUND_P).div(100*PRECISION));

        POOL1_accTokensPerLP = POOL1_accTokensPerLP.add(
            reward.mul(1e18).div(lpSupply)
        );
        POOL1_lastRewardBlock = block.number;

        if(block.number >= POOL1_MULTIPLIER_UPDATED.add(POOL1_MULTIPLIER_UPDATE_EVERY)){
            POOL1_MULTIPLIER = POOL1_MULTIPLIER.mul(3).div(4);
            POOL1_MULTIPLIER_UPDATED = block.number;
        }
    }   

    // 2. Pool 2
    function POOL2_update(uint ethJustStaked) private {
        // ETH balance is updated before the rest of the code
        uint ethSupply = address(this).balance.sub(ethJustStaked);

        if (POOL2_lastRewardBlock == 0 || ethSupply == 0) {
            POOL2_lastRewardBlock = block.number;
            return;
        }

        uint reward = POOL2_getReward(POOL2_lastRewardBlock, block.number);
        
        token.mint(address(this), reward);
        token.mint(GOVERNANCE, reward.mul(GOVERNANCE_P).div(100*PRECISION));
        token.mint(DEV_FUND, reward.mul(DEV_FUND_P).div(100*PRECISION));

        POOL2_accTokensPerETH = POOL2_accTokensPerETH.add(reward.mul(1e18).div(ethSupply));
        POOL2_lastRewardBlock = block.number;
    }

    // PENDING REWARD

    // 1. Pool 1 external (1e18)
    function POOL1_pendingReward() external view returns(uint){
        return _POOL1_pendingReward(users[msg.sender]);
    }

    // 2. Pool 1 private (1e18)
    function _POOL1_pendingReward(User memory u) private view returns(uint){
        uint _POOL1_accTokensPerLP = POOL1_accTokensPerLP;
        uint lpSupply = lp.balanceOf(address(this));

        if (block.number > POOL1_lastRewardBlock && lpSupply != 0) {
            uint pendingReward = POOL1_getReward(POOL1_lastRewardBlock, block.number);
            _POOL1_accTokensPerLP = _POOL1_accTokensPerLP.add(
                pendingReward.mul(1e18).div(lpSupply)
            );
        }

        return u.POOL1_provided.mul(_POOL1_accTokensPerLP).div(1e18)
                .sub(u.POOL1_rewardDebt);
    }

    // 3. Pool 2 external (1e18)
    function POOL2_pendingReward() external view returns(uint){
        return _POOL2_pendingReward(users[msg.sender], 0);
    }
    
    // 4. Pool 2 private (1e18)
    function _POOL2_pendingReward(User memory u, uint ethJustStaked) private view returns(uint){
        uint _POOL2_accTokensPerETH = POOL2_accTokensPerETH;
        // ETH balance is updated before the rest of the code
        uint ethSupply = address(this).balance.sub(ethJustStaked);

        if (block.number > POOL2_lastRewardBlock && ethSupply != 0) {
            uint pendingReward = POOL2_getReward(POOL2_lastRewardBlock, block.number);
            _POOL2_accTokensPerETH = _POOL2_accTokensPerETH.add(
                pendingReward.mul(1e18).div(ethSupply)
            );
        }

        return u.POOL2_provided.mul(_POOL2_accTokensPerETH).div(1e18)
            .sub(u.POOL2_rewardDebt);
    }

    // HARVEST REWARDS

    // 1. Pool 1 external
    function POOL1_harvest() external{
        require(block.number >= POOLS_START, "Pool hasn't started yet.");
        _POOL1_harvest(msg.sender);
    }

    // 2. Pool 1 private
    function _POOL1_harvest(address a) private{
        User storage u = users[a];
        uint pending = _POOL1_pendingReward(u);
        POOL1_update();

        if(pending > 0){
            if(u.POOL1_referral == address(0)){
                POOLS_safeTokenTransfer(a, pending);
                token.burn(a, pending.mul(POOL1_REFERRAL_P).div(100));
            }else{
                uint referralReward = pending.mul(POOL1_REFERRAL_P.div(2)).div(100);
                uint userReward = pending.sub(referralReward);

                POOLS_safeTokenTransfer(a, userReward);
                POOLS_safeTokenTransfer(u.POOL1_referral, referralReward);

                User storage referralUser = users[u.POOL1_referral];
                referralUser.POOL1_referralReward = referralUser.POOL1_referralReward
                                                    .add(referralReward);
            }
        }

        u.POOL1_rewardDebt = u.POOL1_provided.mul(POOL1_accTokensPerLP).div(1e18);
    }

    // 3. Pool 2 external
    function POOL2_harvest() external{
        require(block.number >= POOLS_START, "Pool hasn't started yet.");
        _POOL2_harvest(msg.sender, 0);
    }
    
    // 4. Pool 2 private
    function _POOL2_harvest(address a, uint ethJustStaked) private{
        User storage u = users[a];
        uint pending = _POOL2_pendingReward(u, ethJustStaked);
        POOL2_update(ethJustStaked);

        if(pending > 0){
            POOLS_safeTokenTransfer(a, pending);
        }

        u.POOL2_rewardDebt = u.POOL2_provided.mul(POOL2_accTokensPerETH).div(1e18);
    }

    // STAKE

    // 1. Pool 1
    function POOL1_stake(uint amount, address referral) external{
        require(tx.origin == msg.sender, "Contracts not allowed.");
        require(block.number >= POOLS_START, "Pool hasn't started yet.");
        require(amount > 0, "Staking 0 lp.");

        uint lpSupplyBefore = lp.balanceOf(address(this));

        _POOL1_harvest(msg.sender);
        lp.transferFrom(msg.sender, address(this), amount);

        User storage u = users[msg.sender];
        u.POOL1_provided = u.POOL1_provided.add(amount);
        u.POOL1_rewardDebt = u.POOL1_provided.mul(POOL1_accTokensPerLP).div(1e18);

        if(!u.NFT_CREDITS_receiving
            && u.POOL1_provided >= lpSupplyBefore.mul(POOL1_CREDITS_MIN_P).div(100)){
            u.NFT_CREDITS_receiving = true;
            u.NFT_CREDITS_lastUpdated = block.number;
        }

        if(u.POOL1_referral == address(0) && referral != address(0)
            && referral != msg.sender){
            u.POOL1_referral = referral;
        }
    }

    // 2. Pool 2
    function POOL2_stake() payable external{
        require(tx.origin == msg.sender, "Contracts not allowed.");
        require(block.number >= POOLS_START, "Pool hasn't started yet.");
        require(block.number <= POOL2_END, "Pool is finished, no more staking.");
        require(msg.value > 0, "Staking 0 ETH.");

        _POOL2_harvest(msg.sender, msg.value);

        User storage u = users[msg.sender];
        u.POOL2_provided = u.POOL2_provided.add(msg.value);
        u.POOL2_rewardDebt = u.POOL2_provided.mul(POOL2_accTokensPerETH).div(1e18);
    }

    // UNSTAKE

    // 1. Pool 1
    function POOL1_unstake(uint amount) external{
        User storage u = users[msg.sender];
        require(amount > 0, "Unstaking 0 lp.");
        require(u.POOL1_provided >= amount, "Unstaking more than currently staked.");

        _POOL1_harvest(msg.sender);
        lp.transfer(msg.sender, amount);

        u.POOL1_provided = u.POOL1_provided.sub(amount);
        u.POOL1_rewardDebt = u.POOL1_provided.mul(POOL1_accTokensPerLP).div(1e18);

        uint lpSupply = lp.balanceOf(address(this));

        if(u.NFT_CREDITS_receiving
            && u.POOL1_provided < lpSupply.mul(POOL1_CREDITS_MIN_P).div(100)
            || u.NFT_CREDITS_receiving && lpSupply == 0){
            u.NFT_CREDITS_amount = NFT_CREDITS_amount(msg.sender);
            u.NFT_CREDITS_receiving = false;
            u.NFT_CREDITS_lastUpdated = block.number;
        }
    }

    // 2. Pool 2
    function POOL2_unstake(uint amount) external{
        User storage u = users[msg.sender];
        require(amount > 0, "Unstaking 0 ETH.");
        require(u.POOL2_provided >= amount, "Unstaking more than currently staked.");

        _POOL2_harvest(msg.sender, 0);
        msg.sender.transfer(amount);

        u.POOL2_provided = u.POOL2_provided.sub(amount);
        u.POOL2_rewardDebt = u.POOL2_provided.mul(POOL2_accTokensPerETH).div(1e18);
    }

    // NFTs

    // 1. NFT credits of msg.sender
    function NFT_CREDITS_amount(address a) public view returns(uint){
        User memory u = users[a];
        if(u.NFT_CREDITS_receiving){
            return u.NFT_CREDITS_amount.add(block.number.sub(u.NFT_CREDITS_lastUpdated));
        }else{
            return u.NFT_CREDITS_amount;
        }
    }

    // 2. Spend NFT credits when claiming an NFT
    function spendCredits(address a, uint requiredCredits) external{
        require(msg.sender == nft, "Can only called by GFarmNFT.");
        User storage u = users[a];
        u.NFT_CREDITS_amount = NFT_CREDITS_amount(a).sub(requiredCredits);
        u.NFT_CREDITS_lastUpdated = block.number;
    }

    // PREVENT ROUNDING ERRORS

    function POOLS_safeTokenTransfer(address _to, uint _amount) private {
        uint bal = token.balanceOf(address(this));
        if (_amount > bal) {
            token.transfer(_to, bal);
        } else {
            token.transfer(_to, _amount);
        }
    }

    // USEFUL PRICING FUNCTIONS (FOR TVL & APY)

    // 1. ETH/USD price (PRECISION)
    function getEthPrice() private view returns(uint){
        (uint112 reserves0, uint112 reserves1, ) = ETH_USDC_PAIR.getReserves();
        uint reserveUSDC;
        uint reserveETH;

        if(WETH == ETH_USDC_PAIR.token0()){
            reserveETH = reserves0;
            reserveUSDC = reserves1;
        }else{
            reserveUSDC = reserves0;
            reserveETH = reserves1;
        }
        // Divide number of USDC by number of ETH
        // we multiply by 1e12 because USDC only has 6 decimals
        return reserveUSDC.mul(1e12).mul(PRECISION).div(reserveETH);
    }
    // 2. GFARM/ETH price (PRECISION)
    function getGFarmPriceEth() private view returns(uint){
        (uint112 reserves0, uint112 reserves1, ) = lp.getReserves();

        uint reserveETH;
        uint reserveGFARM;

        if(WETH == lp.token0()){
            reserveETH = reserves0;
            reserveGFARM = reserves1;
        }else{
            reserveGFARM = reserves0;
            reserveETH = reserves1;
        }

        return reserveETH.mul(PRECISION).div(reserveGFARM);
    }

    // UI VIEW FUNCTIONS (READ-ONLY)
    
    function POOLS_blocksLeftUntilStart() external view returns(uint){
        if(block.number > POOLS_START){ return 0; }
        return POOLS_START.sub(block.number);
    }

    function POOL1_getMultiplier() public view returns (uint) {
        if(block.number < POOLS_START){
            return 0;
        }
        return POOL1_MULTIPLIER;
    }

    function POOL2_getMultiplier() public view returns (uint) {
        if(block.number < POOLS_START || block.number > POOL2_END){
            return 0;
        }
        return POOL2_MULTIPLIER;
    }

    function POOL1_provided() external view returns(uint){
        return users[msg.sender].POOL1_provided;
    }

    function POOL2_provided() external view returns(uint){
        return users[msg.sender].POOL2_provided;
    }

    function POOL1_referralReward() external view returns(uint){
        return users[msg.sender].POOL1_referralReward;
    }

    function POOL2_blocksLeft() external view returns(uint){
        if(block.number > POOL2_END){
            return 0;
        }
        return POOL2_END.sub(block.number);
    }

    function POOL1_referral() external view returns(address){
        return users[msg.sender].POOL1_referral;
    }

    function POOL1_minLpsNftCredits() external view returns(uint){
        return lp.balanceOf(address(this)).mul(POOL1_CREDITS_MIN_P).div(100);
    }

    // (PRECISION)
    function POOL1_tvl() public view returns(uint){
        if(lp.totalSupply() == 0){ return 0; }

        (uint112 reserves0, uint112 reserves1, ) = lp.getReserves();
        uint reserveEth;

        if(WETH == lp.token0()){
            reserveEth = reserves0;
        }else{
            reserveEth = reserves1;
        }

        uint lpPriceEth = reserveEth.mul(1e5).mul(2).div(lp.totalSupply());
        uint lpPriceUsd = lpPriceEth.mul(getEthPrice()).div(1e5);

        return lp.balanceOf(address(this)).mul(lpPriceUsd).div(1e18);
    }

    // (PRECISION)
    function POOL2_tvl() public view returns(uint){
        return address(this).balance.mul(getEthPrice()).div(1e18);
    }

    // (PRECISION)
    function POOLS_tvl() external view returns(uint){
        return POOL1_tvl().add(POOL2_tvl());
    }

    // (PRECISION)
    function POOL1_apy() external view returns(uint){
        if(POOL1_tvl() == 0){ return 0; }
        return POOL1_MULTIPLIER.mul(2336000)
                .mul(getGFarmPriceEth()).mul(getEthPrice())
                .mul(100).div(POOL1_tvl());
    }

    // (PRECISION)
    function POOL2_apy() external view returns(uint){
        if(POOL2_tvl() == 0){ return 0; }
        return POOL2_MULTIPLIER.mul(2336000)
                .mul(getGFarmPriceEth()).mul(getEthPrice())
                .mul(100).div(POOL2_tvl());
    }

    function myNftCredits() external view returns(uint){
        return NFT_CREDITS_amount(msg.sender);
    }

}