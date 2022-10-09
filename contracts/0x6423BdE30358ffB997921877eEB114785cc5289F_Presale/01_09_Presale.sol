pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IMintableERC20.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IUniswapRouterV2.sol";
import "./Initializable.sol";

contract Presale is Ownable, ReentrancyGuard, Initializable {

    event Mint (
        address indexed to,
        uint256 amount
    );

    struct PresaleRound {
        uint256 saleAmount;
        uint256 startTime;
        uint256 duration;
        uint256 price;
        uint256 minBuyPrice;
    }

    IMintableERC20 public token;
    IStaking public staking;
    IUniswapRouterV2 public uniswapRouter;

    uint256 public currentRoundId;
    uint256 public constant RELEASE_TOKEN_PRICE_X7 = 695860;
    bool public presaleStarted = false;
    address receiver;

    mapping(uint256 => PresaleRound) public rounds;
    mapping(uint256 => uint256) public tokensSold;
    uint256 public roundsLength;
    

    constructor() {
    }

    function init(address _token, address _staking, address _router, address _receiver) external onlyOwner notInitialized {
        token = IMintableERC20(_token);
        staking = IStaking(_staking);
        uniswapRouter = IUniswapRouterV2(_router);
        receiver = _receiver;

        initialized = true;
    }

    fallback() external {

    }

    function startPresale(PresaleRound[] memory _rounds) external onlyOwner {
        require(!presaleStarted, "Already started");

        uint256 _roundsLength = _rounds.length;

        for(uint256 i = 0; i < _roundsLength; i++) {
            rounds[i] = _rounds[i];
        }

        roundsLength = _roundsLength;
        presaleStarted = true;
    }

    function buy(uint256 _tokensToBuy) external payable nonReentrant {
        require(_tokensToBuy > 0, "ZeroTokensToBuy");

        uint256 _roundId = currentRoundId;
        PresaleRound memory round = rounds[_roundId];
        uint256 tokensInUse = tokensSold[_roundId];

        if(block.timestamp > round.startTime + round.duration && _roundId < roundsLength) {
            _roundId++;
            currentRoundId = _roundId;
            // rounds[_roundId + 1].startTime = block.timestamp;
            round = rounds[_roundId];
        }

        require(msg.value >= round.minBuyPrice, "Lower min buy price");
        require((msg.value * 1e18) >= (_tokensToBuy * round.price), "Not enought eth to pay");
        require((round.saleAmount - tokensInUse) >= _tokensToBuy, "Too much to buy");

        token.mint(address(this), _tokensToBuy);
        rounds[_roundId].saleAmount -= _tokensToBuy;
    
        staking.stakePresale(msg.sender, _tokensToBuy, msg.value);

        (bool success,) = payable(receiver).call{value: msg.value/2}("");
        require(success, "Payment not send");

        emit Mint(
            msg.sender,
            _tokensToBuy
        );
    }

    function releaseTokensToUniswap() external onlyOwner {
        uint256 ethBalance = address(this).balance;
        
        uint256 amountToMint = ethBalance * RELEASE_TOKEN_PRICE_X7 / 10000000;

        token.mint(address(this), amountToMint);
        token.approve(
            address(uniswapRouter),
            amountToMint
        );

        (uint256 amountInTokenAdded,,) = uniswapRouter.addLiquidityETH{value: ethBalance}(
            address(token),
            amountToMint,
            0,
            ethBalance,
            address(this),
            block.timestamp + 10 days
        );

        token.burn(amountToMint - amountInTokenAdded);
    }

    function getCurrentRoundInfo() external view returns(PresaleRound memory, uint256) {
        uint256 _roundId = currentRoundId;
        PresaleRound memory round = rounds[_roundId];

        if(block.timestamp > round.startTime + round.duration && _roundId < roundsLength) {
            _roundId++;
        }

        return (rounds[_roundId], tokensSold[_roundId]);
    }

    function changeReceiver(address _receiver) external onlyOwner {
        receiver = _receiver;
    }
}