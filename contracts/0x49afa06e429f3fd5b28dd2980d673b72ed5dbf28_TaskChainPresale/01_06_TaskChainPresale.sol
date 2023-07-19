// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface Aggregator {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract TaskChainPresale is Ownable, ReentrancyGuard, Pausable {
    // Addresses for the various roles in the contract
    address private fundsAddress;
    address private tokenHolderAddress;
    address public saleTokenAddress =
        0x4C2e29dbc437C4b781963E5B2B393b1D4ea64b19;

    // Tokens and prices per stage
    uint256[11] public tokensInStages;
    uint256[11] public pricePerStage;

    // The token balance for each buyer
    mapping(address => uint256) public tokensBought;

    // Track which buyers have claimed their tokens
    mapping(address => bool) public tokensClaimed;
    mapping(uint256 => uint256) public tokensSoldPerStage;

    // Interfaces for the USDT token and the oracle price feed
    IERC20 public USDTInterface;
    Aggregator public priceFeed;

    // Track whether claims are active and the current sale stage
    bool public claimActive;
    Stages public stage;

    // Stages of the sale
    enum Stages {
        BETA_STAGE,
        STAGE_1,
        STAGE_2,
        STAGE_3,
        STAGE_4,
        STAGE_5,
        STAGE_6,
        STAGE_7,
        STAGE_8,
        STAGE_9,
        STAGE_10
    }

    // Events to be emitted by the contract
    event claimStart(bool claimActive);
    event TokenBought(address indexed buyer, uint256 amount, uint256 timestamp);
    event TokensClaimed(
        address indexed claimer,
        uint256 amount,
        uint256 timestamp
    );

    /**
     * @dev Constructor for the presale contract
     * @param _usdt address to send USDT token
     * @param _oracle Oracle contract to fetch ETH/USDT price
     */

    constructor(
        address _usdt,
        address _oracle
    ) ReentrancyGuard() nonZeroAddress(_usdt) nonZeroAddress(_oracle) {
        USDTInterface = IERC20(_usdt);
        priceFeed = Aggregator(_oracle);

        tokenHolderAddress = 0xc493fD92b08579682935520e9779Ee71CbD29A09;
        fundsAddress = 0xC35A5df1Bc74C7e96AfA6e047890f46459369743; 
        claimActive = false;
        stage = Stages.BETA_STAGE;
        tokensInStages = [
            280_000_000,
            300_000_000,
            300_000_000,
            200_000_000,
            200_000_000,
            200_000_000,
            200_000_000,
            200_000_000,
            200_000_000,
            360_000_000,
            360_000_000
        ];
        pricePerStage = [
            4000_000_000_000_000,
            5000_000_000_000_000,
            5200_000_000_000_000,
            5500_000_000_000_000,
            5700_000_000_000_000,
            6000_000_000_000_000,
            6500_000_000_000_000,
            8000_000_000_000_000,
            8500_000_000_000_000,
            9000_000_000_000_000,
            9500_000_000_000_000
        ];
    }

    modifier claimable() {
        require(claimActive == true, "Claiming is not active yet.");
        _;
    }

    modifier nonZeroAddress(address _addr) {
        require(_addr != address(0), "Address can't be zero");
        _;
    }

    /**
     * @dev buyTokenWithETH allows users to buy tokens with ETH
     * @param _tokenAmount total number of tokens user wants to buy
     */

    function buyTokenWithETH(
        uint256 _tokenAmount
    ) external payable nonReentrant whenNotPaused {
        require(_tokenAmount > 0, "Cannot buy zero tokens.");
        require(
            _tokenAmount <= getAvailableTokensInStage(),
            "Insufficient tokens available."
        );
        uint256 ethCost = calculateEthCost(_tokenAmount);
        require(msg.value >= ethCost, "Not enough ETH sent.");
        // Calculate excess ETH by user
        uint256 excessAmount = msg.value - ethCost;

        // Refund the excess ETH to the buyer
        if (excessAmount > 0) {
            (bool successTransferExcess, ) = payable(msg.sender).call{
                value: excessAmount
            }("");
            require(
                successTransferExcess,
                "Failed to send ETH to funds address."
            );
        }

        tokensSoldPerStage[uint256(stage)] += _tokenAmount;
        tokensBought[msg.sender] += _tokenAmount;

        (bool success, ) = payable(fundsAddress).call{value: ethCost}("");
        require(success, "Failed to send ETH to funds address.");

        emit TokenBought(msg.sender, _tokenAmount, block.timestamp);
    }

    /**
     * @dev buyTokenWithUSDT allows users to buy tokens with USDT
     * @param _tokenAmount total number of tokens user wants to buy
     */

    function buyTokenWithUSDT(
        uint256 _tokenAmount
    ) public nonReentrant whenNotPaused {
        require(_tokenAmount > 0, "Cannot buy zero tokens.");
        require(
            _tokenAmount <= getAvailableTokensInStage(),
            "Insufficient tokens available."
        );
        uint256 usdtCost = calculateUsdtCost(_tokenAmount);
        tokensSoldPerStage[uint256(stage)] += _tokenAmount;
        tokensBought[msg.sender] += _tokenAmount;
        require(
            USDTInterface.allowance(msg.sender, address(this)) >= usdtCost,
            "Not enough allowance"
        );

        require(
            USDTInterface.balanceOf(msg.sender) >= usdtCost,
            "Not enough balance"
        );
        USDTInterface.transferFrom(msg.sender, fundsAddress, usdtCost);
        emit TokenBought(msg.sender, _tokenAmount, block.timestamp);
    }

    /**
     * @dev claimTokens allows users to claim tokens after the sale is over
     */

    function claimTokens() external claimable nonReentrant {
        require(
            tokensBought[msg.sender] > 0,
            "You have not bought any tokens."
        );
        require(
            !tokensClaimed[msg.sender],
            "You have already claimed your tokens."
        );

        uint256 amountToClaim = tokensBought[msg.sender];
        require(amountToClaim > 0, "No tokens to claim.");
        tokensClaimed[msg.sender] = true;
        IERC20(saleTokenAddress).transferFrom(
            tokenHolderAddress,
            msg.sender,
            amountToClaim * 10 ** 18
        );
        emit TokensClaimed(msg.sender, amountToClaim, block.timestamp);
    }

    /**
     * @dev calculateEthCost helper function to calculate ETH cost for a given token amount
     */

    function calculateEthCost(
        uint256 _tokenAmount
    ) public view returns (uint256) {
        uint256 price = pricePerStage[uint256(stage)];
        (, int256 priceETH, , , ) = priceFeed.latestRoundData();
        uint256 ethCost = (_tokenAmount * price * 10 ** 18) /
            (uint256(priceETH) * 10 ** 10);
        return ethCost;
    }

    /**
     * @dev EthToTokenHelper function to calculate ETH cost for a given token amount
     */
    function EthToTokenHelper(uint _ethAmount) public view returns (uint256) {
        uint256 price = pricePerStage[uint256(stage)];
        (, int256 priceETH, , , ) = priceFeed.latestRoundData();
        uint256 tokenAmount = (_ethAmount * uint256(priceETH) * 10 ** 10) /
            (price * 10 ** 18);
        return tokenAmount;
    }

    /**
     * @dev USDTToTokenHelper function to calculate ETH cost for a given token amount
     */
    function USDTToTokenHelper(uint _usdtAmount) public view returns (uint256) {
        uint256 price = pricePerStage[uint256(stage)];
        uint256 tokenAmount = (_usdtAmount * 10 ** 12) / price;
        return tokenAmount;
    }

    /**
     * @dev calculateUsdtCost helper function to calculate UST cost for a given token amount
     */

    function calculateUsdtCost(
        uint256 _tokenAmount
    ) public view returns (uint256) {
        uint256 price = pricePerStage[uint256(stage)];
        uint256 usdtCost = (_tokenAmount * price) / (10 ** 12);
        return usdtCost;
    }

    function getAvailableTokensInStage() public view returns (uint256) {
        return
            tokensInStages[uint256(stage)] - tokensSoldPerStage[uint256(stage)];
    }

    /**
     * @dev setFundsAddress allows owner to set the funds address
     * @param _fundsAddress address of the funds address
     */
    function setFundsAddress(
        address _fundsAddress
    ) external onlyOwner nonZeroAddress(fundsAddress) {
        fundsAddress = _fundsAddress;
    }

    /**
     * @dev setTokenHolder allows owner to set the token holder address
     * @param _tokenHolder address of the token holder
     */

    function setTokenHolder(
        address _tokenHolder
    ) external onlyOwner nonZeroAddress(_tokenHolder) {
        tokenHolderAddress = _tokenHolder;
    }


    /**
     * @dev switchStage allows owner to switch to the next stage
     */

    function switchStage() external onlyOwner {
        require(
            uint256(stage) >= 0 && uint256(stage) <= 10,
            "Invalid stage transition."
        );

        // If it's not the first stage, move the remaining tokens to the next stage
        if (uint256(stage) >= 0 && uint256(stage) <= 9) {
            uint256 remainingTokens = tokensInStages[uint256(stage)] -
                tokensSoldPerStage[uint256(stage)];

            tokensInStages[uint256(stage) + 1] += remainingTokens;
        }

        // Move to the next stage
        stage = Stages(uint256(stage) + 1);
    }

    /**
     * @dev startClaim allows owner to start the claiming process
     */

    function startClaim() external onlyOwner {
        claimActive = true;
        emit claimStart(claimActive);
    }

    /**
     * @dev pauseContract allows owner to pause the contract
     */

    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @dev unpauseContract allows owner to unpause the contract
     */

    function unpauseContract() external onlyOwner {
        _unpause();
    }
}