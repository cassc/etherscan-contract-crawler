pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BlockbotTokenSale is Ownable {
    IERC20 public botToken;
    IERC20 public usdtToken;
    uint256 public constant STAGE_DURATION = 8 days;
    uint256 public stageStartTime;
    uint256 public currentStage;
    uint256[8] public stagePrices = [
        8880,
        9990,
        11110,
        13330,
        15550,
        18880,
        22220,
        33330
    ];
    uint256[8] public stageSupply = [
        11111111111 * (10 ** 18),
        11111111111 * (10 ** 18),
        11111111111 * (10 ** 18),
        11111111111 * (10 ** 18),
        11111111111 * (10 ** 18),
        11111111111 * (10 ** 18),
        11111111111 * (10 ** 18),
        11111111111 * (10 ** 18)
    ];

    constructor(address _botToken, address _usdtToken) {
        botToken = IERC20(_botToken);
        usdtToken = IERC20(_usdtToken);
        stageStartTime = block.timestamp;
        currentStage = 0;
    }

    function buyTokens(uint256 _usdtAmount) external {
        require(currentStage < 8, "Token sale has ended");
        require(
            stageSupply[currentStage] > 0,
            "Not enough tokens in the current stage"
        );

        uint256 tokensToBuy = (_usdtAmount * 10 ** 12) /
            stagePrices[currentStage]; // 10**12 used to compensate for USDT 6 decimals
        uint256 remainingTokens = stageSupply[currentStage];

        if (remainingTokens < tokensToBuy) {
            tokensToBuy = remainingTokens;
            _usdtAmount = (tokensToBuy * stagePrices[currentStage]) / 10 ** 12;
        }

        usdtToken.transferFrom(msg.sender, address(this), _usdtAmount);
        botToken.transfer(msg.sender, tokensToBuy);
        stageSupply[currentStage] -= tokensToBuy;

        if (
            stageSupply[currentStage] == 0 &&
            block.timestamp >= stageStartTime + STAGE_DURATION
        ) {
            currentStage++;
            stageStartTime = block.timestamp;
        }
    }

    function updateStageSupply(
        uint256 _stage,
        uint256 _newSupply
    ) external onlyOwner {
        require(_stage < 8, "Invalid stage");
        stageSupply[_stage] = _newSupply;
    }

    function updateStagePrice(
        uint256 _stage,
        uint256 _newPrice
    ) external onlyOwner {
        require(_stage < 8, "Invalid stage");
        stagePrices[_stage] = _newPrice;
    }

    function withdrawBotTokens(uint256 _amount) external onlyOwner {
        botToken.transfer(msg.sender, _amount);
    }

    function withdrawUsdtTokens(uint256 _amount) external onlyOwner {
        usdtToken.transfer(msg.sender, _amount);
    }

    function purchasedBOTS(
        address[] memory recipients,
        uint256[] memory amounts
    ) external onlyOwner {
        require(
            recipients.length == amounts.length,
            "Recipients and amounts arrays must have the same length"
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            botToken.transfer(recipients[i], amounts[i]);
        }
    }

    function getCurrentStage() external view returns (uint256) {
        return currentStage;
    }

    function getCurrentPrice() external view returns (uint256) {
        require(currentStage < 8, "Token sale has ended");
        return stagePrices[currentStage];
    }

    function getRemainingTokensForSale() external view returns (uint256) {
        require(currentStage < 8, "Token sale has ended");
        return stageSupply[currentStage];
    }
}