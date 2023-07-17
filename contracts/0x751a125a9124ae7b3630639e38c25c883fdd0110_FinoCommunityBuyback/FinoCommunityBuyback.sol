/**
 *Submitted for verification at Etherscan.io on 2023-06-28
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IDEXRouter {

    function WETH() external pure returns (address);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract FinoCommunityBuyback is Ownable {
    address public router;
    IDEXRouter public dexRouter;

    address public token;
    address public path0;

    uint256 public tokensBurned = 0;

    
    //voting variables
    uint256 public currentRound = 0;
    uint256 public currentVotes = 0;
    uint256 public votesNeeded = 20;
    uint256 public minBalanceToVote = 1 * 1e18;

    uint256 public minEthToBuyback =  1 * 1e17;
    uint256 public maxEthPerBuyback = 1 * 1e18;

    mapping(uint256 => mapping(address => bool)) public votedRound;

    event EthReceived(uint256 indexed round, uint256 indexed ethReceived);
    event Vote(address indexed voter, uint256 indexed round, uint256 indexed votes);
    event Buyback(uint256 indexed round, uint256 indexed ethSpent, uint256 indexed tokensBurned);

    address public DEAD = address(0xdead);

    constructor(address _router, address _token) {
        router = _router;
        dexRouter = IDEXRouter(_router);
        token = _token;
        path0 = dexRouter.WETH();
    }

    receive () external payable {
        emit EthReceived(currentRound, msg.value);
    }   

    /// @notice Vote for the buyback. You must hold at least minBalanceToVote tokens.
    function vote() public {
        require(IERC20(token).balanceOf(msg.sender) >= minBalanceToVote, "You must hold at least minBalanceToVote tokens to vote.");
        require(!votedRound[currentRound][msg.sender], "You have already voted in this round.");
        require(address(this).balance >= minEthToBuyback, "The contract doesnt have enough ETH for a buyback");

        votedRound[currentRound][msg.sender] = true;

        currentVotes += 1;

        emit Vote(msg.sender, currentRound, currentVotes);

        if (currentVotes >= votesNeeded) {
            buybackAndBurn();
        }
    }

    function buybackAndBurn() internal {
        uint burnAmount = address(this).balance;

        if (burnAmount > maxEthPerBuyback) {
            burnAmount = maxEthPerBuyback;
        }

        address[] memory path = new address[](2);
        path[0] = path0;
        path[1] = token;

        dexRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: burnAmount}(
            0,
            path,
            address(this),
            block.timestamp
        );

        currentVotes = 0;
        currentRound += 1;

        tokensBurned += IERC20(token).balanceOf(address(this));
        emit Buyback(currentRound, burnAmount, IERC20(token).balanceOf(address(this)));
        IERC20(token).transfer(DEAD, IERC20(token).balanceOf(address(this)));
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawToken(address _token) public onlyOwner {
        IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }

    function setRouter(address _router) public onlyOwner {
        router = _router;
        dexRouter = IDEXRouter(_router);
        path0 = dexRouter.WETH();
    }

    function setToken(address _token) public onlyOwner {
        token = _token;
    }

    function setPath0(address _path0) public onlyOwner {
        path0 = _path0;
    }

    function setDead(address _dead) public onlyOwner {
        DEAD = _dead;
    }

    function setVotesNeeded(uint256 _votesNeeded) public onlyOwner {
        votesNeeded = _votesNeeded;
    }

    function setMinBalanceToVote(uint256 _minBalanceToVote) public onlyOwner {
        minBalanceToVote = _minBalanceToVote;
    }

    function setMinEthToBuyback(uint256 _minEthToBuyback) public onlyOwner {
        minEthToBuyback = _minEthToBuyback;
    }

    function setMaxEthPerBuyback(uint256 _maxEthPerBuyback) public onlyOwner {
        maxEthPerBuyback = _maxEthPerBuyback;
    }

}