/**
 *Submitted for verification at Etherscan.io on 2021-01-07
*/

//
//  _           _   _                    ___    ___
// | |         | | | |                  |__ \  / _ \
// | |     ___ | |_| |_ ___ _ __ _   _     ) || | | |
// | |    / _ \| __| __/ _ \ '__| | | |   / / | | | |
// | |___| (_) | |_| ||  __/ |  | |_| |  / /_ | |_| |
// |______\___/ \__|\__\___|_|   \__, | |____(_)___/
//                                __/ |
//                               |___/
//
pragma solidity ^0.7.5;


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
//Keeps track of owner
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public  onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public  onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

//Interface for ERC20 tokens
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

//Interface for Uni V2 tokens
interface IUniswapV2ERC20 {
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
}

//Interface for the Pepemon factory
//Contains only the mint method
interface IPepemonFactory{
    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) external;
}
pragma solidity >=0.6.0 <0.8.0;

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

contract LotteryTwo is Ownable{

    //Uni V2 Address for ppdex
    address public UniV2Address;

    //PPDEX address
    address public PPDEX;

    //pepemonFactory address
    address public pepemonFactory;

    //how long users have to wait before they can withdraw LP
    //5760 blocks = 1 day
    //40320 blocks = 1 week
    //184320 block = 32 days
    uint public blockTime;

    //Block when users will be allowed to mint NFTs if they provided liq before this block
    uint public stakingDeadline;

    //how many PPDEX needed to stake for a normal NFT
    uint public minPPDEX = 1000*10**17;

    //how many PPDEX needed to stake for a golden NFT
    uint public minPPDEXGolden = 1000*10**17;

    //nft ids for minting
    uint public normalID;
    uint public goldenID;

    using SafeMath for uint;

    //events
    event Redeemed(address indexed user, uint id);
    event Staked(address indexed user, uint amount);
    event Unstaked(address indexed user, uint amount);

    /**
     *  _UniV2Address => Uni V2 token address (should be 0x6B1455E27902CA89eE3ABB0673A8Aa9Ce1609952)
     *  _PPDEX => PPDEX token address (should be 0xf1f508c7c9f0d1b15a76fba564eef2d956220cf7)
     *  _pepemonFactory => pepemonFactory address (should be 0xcb6768a968440187157cfe13b67cac82ef6cc5a4)
     *  _blockTime => Time a user must wait to mint a NFT (should be 208000 for 32 days)
     */
    constructor(address _UniV2Address, address _PPDEX, address _pepemonFactory, uint _blockTime)  {
        UniV2Address = _UniV2Address;
        PPDEX = _PPDEX;
        pepemonFactory = _pepemonFactory;
        blockTime = _blockTime;
    }
    //mapping that keeps track of last nft claim
    mapping (address => uint) depositBlock;

    //mapping that keeps track of how many LP tokens user deposited
    mapping (address => uint ) LPBalance;

    //mapping that keeps track of if a user is staking
    mapping (address => bool) isStaking;

    //mapping that keeps track of if a user is staking normal nft
    mapping (address => bool) isStakingNormalNFT;

    //Keeps track of if a user has minted a NFT;
    mapping(address => mapping(uint => bool)) hasMinted;

    //setter functions

    //Sets Uni V2 Pair address
    function setUniV2Address (address addr) public onlyOwner{
        UniV2Address = addr;
    }
    //Sets PPDEX token address
    function setPPDEX (address _PPDEX) public onlyOwner{
        PPDEX = _PPDEX;
    }
    //Sets Pepemon Factory address
    function setPepemonFactory (address _pepemonFactory) public onlyOwner{
        pepemonFactory = _pepemonFactory;
    }
    //Sets the min number of PPDEX needed in liquidity to mint golden nfts
    function setminPPDEXGolden (uint _minPPDEXGolden) public onlyOwner{
        minPPDEXGolden = _minPPDEXGolden;
    }
    //Sets the min number of PPDEX needed in liquidity to mint normal nfts
    function setminPPDEX (uint _minPPDEX) public onlyOwner{
        minPPDEX = _minPPDEX;
    }
    //Updates NFT info - IDs + block
    function updateNFT (uint _normalID, uint _goldenID) public onlyOwner{
        normalID = _normalID;
        goldenID = _goldenID;
        stakingDeadline = block.number;
    }
    //Sets

    //view LP functions

    //Returns mininum amount of LP tokens needed to qualify for minting a normal NFT
    //Notice a small fudge factor is added as it looks like uniswap sends a tiny amount of LP tokens to the zero address
    function MinLPTokens() public view returns (uint){
        //Get PPDEX in UniV2 address
        uint totalPPDEX = IERC20(PPDEX).balanceOf(UniV2Address);
        //Get Total LP tokens
        uint totalLP = IUniswapV2ERC20(UniV2Address).totalSupply();
        //subtract a small fudge factor
        return (minPPDEX.mul(totalLP) / totalPPDEX).sub(10000);
    }

    //Returns min amount of LP tokens needed to qualify for golden NFT
    //Notice a small fudge factor is added as it looks like uniswap sends a tiny amount of LP tokens to the zero address
    function MinLPTokensGolden() public view returns (uint){
        //Get PPDEX in UniV2 address
        uint totalPPDEX = IERC20(PPDEX).balanceOf(UniV2Address);
        //Get Total LP tokens
        uint totalLP = IUniswapV2ERC20(UniV2Address).totalSupply();
        //subtract a small fudge factor
        return (minPPDEXGolden.mul(totalLP) / totalPPDEX).sub(10000);
    }

    //Converts LP token balances to PPDEX
    function LPToPPDEX(uint lp) public view returns (uint){
        //Get PPDEX in UniV2 address
        uint totalPPDEX = IERC20(PPDEX).balanceOf(UniV2Address);
        //Get Total LP tokens
        uint totalLP = IUniswapV2ERC20(UniV2Address).totalSupply();
        return (lp.mul(totalPPDEX)/totalLP);
    }

    //mapping functions

    //Get the block num of the time the user staked
    function getStakingStart(address addr) public view returns(uint){
        return depositBlock[addr];
    }

    //Get the amount of LP tokens the address deposited
    function getLPBalance(address addr) public view returns(uint){
        return LPBalance[addr];
    }

    //Check if an address is staking.
    function isUserStaking(address addr) public view returns (bool){
        return isStaking[addr];
    }

    //Check if user has minted a NFT
    function hasUserMinted(address addr, uint id) public view returns(bool){
        return hasMinted[addr][id];
    }

    //Check if an address is staking for a normal or golden NFT
    //True = user is staking for a normal NFT
    //False = user is staking for a golden NFT (or the user is not staking at all)
    function isUserStakingNormalNFT(address addr) public view returns (bool){
        return isStakingNormalNFT[addr];
    }

    //staking functions
    //Transfers liqudity worth 46.6 PPDEX from the user to stake
    function stakeForNormalNFT() public {
        //Make sure user is not already staking
        require (!isStaking[msg.sender], "Already staking");

        //Transfer liquidity worth 46.6 PPDEX to contract
        IUniswapV2ERC20 lpToken = IUniswapV2ERC20(UniV2Address);
        uint lpAmount = MinLPTokens();
        require (lpToken.transferFrom(msg.sender, address(this), lpAmount), "Token Transfer failed");

        //Update mappings
        LPBalance[msg.sender] = lpAmount;
        depositBlock[msg.sender] = block.number;
        isStaking[msg.sender] = true;
        isStakingNormalNFT[msg.sender]= true;
        emit Staked(msg.sender, lpAmount);
    }
    //Transfers liquidity worth 150 PPDEX for user to get golden NFT
    function stakeForGoldenNFT() public {
        //Make sure user is not already staking
        require (!isStaking[msg.sender], "Already staking");

        //Transfer liquidity worth 150 ppdex to contract
        IUniswapV2ERC20 lpToken = IUniswapV2ERC20(UniV2Address);
        uint lpAmount = MinLPTokensGolden();
        require (lpToken.transferFrom(msg.sender, address(this), lpAmount), "Token Transfer failed");

        //Update mappings
        LPBalance[msg.sender] = lpAmount;
        depositBlock[msg.sender] = block.number;
        isStaking[msg.sender] = true;
        isStakingNormalNFT[msg.sender]= false;
        emit Staked(msg.sender, lpAmount);
    }
    //Allow the user to withdraw
    function withdrawLP() public{

        IUniswapV2ERC20 lpToken = IUniswapV2ERC20(UniV2Address);

        //LP tokens are locked for 32 days
        require (depositBlock[msg.sender]+blockTime < block.number, "Must wait 32 days to withdraw");

        //Update mappings
        uint lpAmount = LPBalance[msg.sender];
        LPBalance[msg.sender] = 0;
        depositBlock[msg.sender] = 0;
        isStaking[msg.sender] = false;
        isStakingNormalNFT[msg.sender]= false;
        //Send user his LP token balance
        require (lpToken.transfer(msg.sender, lpAmount));
        emit Unstaked(msg.sender, lpAmount);
    }

    //Allow the user to mint a NFT
    function mintNFT() public {

        //Make sure user is staking
        require (isStaking[msg.sender], "User isn't staking");

        //Make sure enough time has passed
        require (block.number > stakingDeadline, "Please wait longer");

        //Make sure user deposited before deadline
        require (depositBlock[msg.sender] < stakingDeadline, "You did not stake before the deadline");

        //Make sure user did not already mint a nft
        require ((hasMinted[msg.sender][normalID]  == false)&& (hasMinted[msg.sender][goldenID])== false, "You have already minted a NFT");

        IPepemonFactory factory = IPepemonFactory(pepemonFactory);

        //Send user 1 normal nft or 1 golden nft, depending on how much he staked
        if (isStakingNormalNFT[msg.sender]){
            factory.mint(msg.sender, normalID, 1, "");
            hasMinted[msg.sender][normalID] = true;
            emit Redeemed(msg.sender, normalID);
        }
        else{
            factory.mint(msg.sender, goldenID, 1, "");
            hasMinted[msg.sender][goldenID] = true;
            emit Redeemed(msg.sender, goldenID);
        }
    }

}