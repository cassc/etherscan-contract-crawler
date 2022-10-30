pragma solidity ^0.8.7;
import "hardhat/console.sol";


interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

function name() 
external view returns(string memory);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

interface ERC20TokenFrink {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

function name() 
external view returns(string memory);
    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function getDailyList() external view returns (address[] memory);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

contract Managed {
    address public manager;
    address public newManager;

    constructor() {
        manager = msg.sender;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Sender not authorized.");
        _;
    }

    function transferOwnership(address _newManager) public onlyManager {
        newManager = _newManager;
    }

    function acceptOwnership() public {
        require(msg.sender == newManager, "Sender not authorized.");
        manager = newManager;
        newManager = address(0);
    }
}

contract DailyFrinkLottery is Managed {
    address public lastWinner;
    address public tokenAddress;
    uint256 public minPlayers = 2;
    address[] public winners;
    ERC20TokenFrink public tokenContract;
    IERC20 public USDTToken;
    mapping(address => uint256) public winnerDetails;

    event onLotteryEnd(address);

    constructor(address FrinkAddress, address _USDTAddress) public {
        USDTToken = IERC20(_USDTAddress);
    tokenContract = ERC20TokenFrink(FrinkAddress);
    }

    function pickDailyLotteryWinner() public onlyManager {
        
        address winner = pickWinner();

        lastWinner = winner;
      
        winners.push(winner);
        uint256 lotteryBalance = USDTToken.balanceOf(address(this));
        winnerDetails[winner] = lotteryBalance;
        require(
            USDTToken.transfer(winner, lotteryBalance),
            "An error occurred when closing the lottery."
        );
        
        emit onLotteryEnd(winner);
    }

    function getPlayers() public view returns (address[] memory) {
        return tokenContract.getDailyList();
    }

    function getLastWinner() public view returns (address) {
        return lastWinner;
    }

    function pickWinner() private returns (address) {
         require(
            getPlayers().length >= minPlayers,
            "There are not enough participants"
        );
        uint256 index = random() % getPlayers().length -1;

        address winner = getPlayers()[index];

        return winner;
    }
    

    function random() private view returns (uint256) {
        return uint256(keccak256(encodeData()));
    }

    function encodeData() private view returns (bytes memory) {
        return
            abi.encodePacked(block.difficulty, block.timestamp, getPlayers());
    }

    fallback() external payable {
        revert("Don't accept ETH");
    }
}