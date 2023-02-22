// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.17;

import "./IERC20.sol";
import "./Ownable.sol";

contract NexusPrivateSale is Ownable {
    event SpacelistAdd(address indexed wallet);
    event SpacelistRemove(address indexed wallet);
    event SpacelistLocked();

    // --- Settings ---

    IERC20 public Token;
    IERC20 public USDC;

    uint256 public allocationWindow = 3600;
    uint256 public currentTier = 0;
    uint256[] public tierPrice = [0, 0.0075 ether, 0.0080 ether, 0.0085 ether, 0.0090 ether, 0.0095 ether];
    uint256[] public tierSupply = [0, 2000000 ether, 3000000 ether, 4000000 ether, 5000000 ether, 6000000 ether];
    bool public saleEndedForever;
    bool public salePaused;

    mapping (address => bool) public isSpacelisted;
    uint256 public slCount;
    bool public slLocked;

    mapping (uint256 => mapping (address => uint256)) public tierAndAddressToAmountBought;
    mapping (uint256 => uint256) public tierToAmountLeft;
    mapping (uint256 => uint256) public tierToAllocation;
    mapping (uint256 => uint256) public tierStartTimestamp;

    uint256 public constant vestingPercentageTGE = 50;
    
    constructor (address _tokenAddr, address _usdcAddr) {
        Token = IERC20(_tokenAddr);
        USDC = IERC20(_usdcAddr);
    }

    // --- Owner config ---

    /*
     * @dev Add or remove addresses to/from SL
     */
    function updateSpacelist(address[] calldata walletsToAdd, address[] calldata walletsToRemove) external onlyOwner {
        require(!slLocked, "Locked");

        for (uint256 i=0; i<walletsToAdd.length; i++) {
            require(isSpacelisted[walletsToAdd[i]] == false, "Already spacelisted");
            isSpacelisted[walletsToAdd[i]] = true;
            emit SpacelistAdd(walletsToAdd[i]);
        }
        for (uint256 i=0; i<walletsToRemove.length; i++) {
            require(isSpacelisted[walletsToRemove[i]] == true, "Wallet is not spacelisted");
            isSpacelisted[walletsToRemove[i]] = false;
            emit SpacelistRemove(walletsToRemove[i]);
        }
        slCount = slCount + walletsToAdd.length - walletsToRemove.length;
    }

    /*
     * @dev Lock SL
     */
    function lockSL() external onlyOwner {
        require(!slLocked, "Already locked");
        slLocked = true;
        emit SpacelistLocked();
    }

    /*
     * @dev Trigger next tier
     */
    function triggerNextTier(uint256 nextTier) external onlyOwner {
        require(slLocked, "SL not locked");
        require(currentTier+1 == nextTier, "Next tier invalid");
        require(nextTier <= 5, "Can't go past tier 5");

        if (nextTier == 1) {
            require(Token.balanceOf(address(this)) == 10000000 ether, "Token not deposited");
        }

        currentTier = nextTier;
        tierToAllocation[currentTier] = tierSupply[currentTier] / slCount;
        tierStartTimestamp[currentTier] = block.timestamp;
        tierToAmountLeft[currentTier] = tierSupply[currentTier];
    }

    /*
     * @dev Toggle pause sale
     */
    function togglePauseSale() external onlyOwner {
        salePaused = !salePaused;
    }

    /*
     * @dev End sale forever
     */
    function endSaleForever() external onlyOwner {
        saleEndedForever = true;
    }

    /**
     * @dev Withdraw USDC balance from the contract
     */
    function withdrawUSDC() external onlyOwner {
        uint256 balance = USDC.balanceOf(address(this));
        USDC.transfer(msg.sender, balance);
    }

    /**
     * @dev Withdraw token balance from the contract
     */
    function withdrawToken() external onlyOwner {
        uint256 balance = Token.balanceOf(address(this));
        Token.transfer(msg.sender, balance);
    }

    // --- Sale ---

    /*
     * @dev Buy token in private sale
     */
    function buy(uint256 tokenAmountNoDecimals) external {
        require(salePaused == false, "Sale temporarily paused");
        require(currentTier > 0, "Sale not started");
        require(saleEndedForever == false, "Sale ended");
        require(isSpacelisted[msg.sender], "Not spacelisted");

        uint256 amountLeftForTier = tierToAmountLeft[currentTier];
        require(amountLeftForTier > 0, "Current tier sold out");

        uint256 tokenAmount = tokenAmountNoDecimals * 10**18;

        if (block.timestamp < (tierStartTimestamp[currentTier] + allocationWindow)) {
            require(tierAndAddressToAmountBought[currentTier][msg.sender] + tokenAmount <= tierToAllocation[currentTier], "Allocation exceeded");
            tierAndAddressToAmountBought[currentTier][msg.sender] += tokenAmount;
        }

        if (tokenAmount > amountLeftForTier) {
            tokenAmount = amountLeftForTier;
        }

        uint256 usdcCost = (tokenAmount / 10**18) * tierPrice[currentTier];
        USDC.transferFrom(msg.sender, address(this), usdcCost);

        uint256 tokenAmountToReceive = tokenAmount * vestingPercentageTGE / 100;
        Token.transfer(msg.sender, tokenAmountToReceive);

        tierToAmountLeft[currentTier] -= tokenAmount;
    }
}