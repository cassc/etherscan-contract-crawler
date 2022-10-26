// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}
contract ShimaCryptoFantasy is Ownable, AccessControl {
    bytes32 public constant POOL_ADMIN_ROLE = keccak256("POOL_ADMIN_ROLE");
    IUniswapV2Router02 public uniswapV2Router;

    struct pool {
        uint256 entryFee;
        address tokenAddress;
        uint256 startTime;
        uint256 endTime;
        address[] userAddress;
        uint256 pot;
    }
    struct userDetails {
        address[10] aggregatorAddresses;
    }

    struct winners {
        address[] user;
        uint256[] amount;
    }

    address private constant wbnbAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public buybackToken;
    address public marketingWallet;
    address public buybackWallet;
    uint256 public marketingFee;
    uint256 public buybackFee;
    uint256 public poolCounter = 0;
    mapping(uint256 => pool) public pools;
    mapping(uint256 => mapping(address => userDetails)) internal userSelection;
    mapping(uint256 => winners) internal winnerDetails;

    event poolCreated(
        uint256 poolID,
        uint256 entryFees,
        uint256 startTime,
        uint256 endTime,
        address tokenAddress
    );
    event enteredPool(
        address user,
        uint256 poolID,
        address[10] aggregatorAddress
    );
    event setWinners(
        uint256 poolID,
        address[] winners,
        uint256[] amounts
    );
    event RewardClaimed(uint256 poolID, address winner, uint256 amount);
    event FeeDeducted(uint256 poolID, address token, uint256 amount);
    event FeeWithdrawn(address token, uint256 amount);
    event FeeUpdated(uint256 prevFee, uint256 newFee);
    event EmergencyWithdraw(address token, uint256 withdrawAmount);
    event WalletChange(string walletName, address previousWallet, address newWallet);
    event BuybackTokenChange(address previousToken, address newToken);
    event MarketingFundsSent(uint256 fundSent);

    constructor() {
        marketingFee = 2000;
        buybackFee = 2000;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(POOL_ADMIN_ROLE, msg.sender);
        uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        marketingWallet = msg.sender;
        buybackWallet = msg.sender;
        buybackToken = 0x2979BD552940471cee400dfC5C90086f361A8839;
    }

    receive() external payable {}

    function setPoolAdminRole(address user) public onlyRole(POOL_ADMIN_ROLE) {
        _grantRole(POOL_ADMIN_ROLE, user);
    }

    function createPool(
        uint256 entryFees,
        address _tokenAddress,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyRole(POOL_ADMIN_ROLE) {
        require(
            _startTime < _endTime,
            "Start time cannot be greater than end time."
        );
        require(
            _startTime > block.timestamp,
            "Start time must be greater than current time"
        );
        require(
            _tokenAddress != address(0),
            "Token Address must not be zero address"
        );
        pools[poolCounter].entryFee = entryFees;
        pools[poolCounter].startTime = _startTime;
        pools[poolCounter].endTime = _endTime;
        pools[poolCounter].tokenAddress = _tokenAddress;
        emit poolCreated(
            poolCounter,
            entryFees,
            _startTime,
            _endTime,
            _tokenAddress
        );
        poolCounter++;
    }

    function enterPool(uint256 _poolID, address[10] memory _aggregatorAddress)
    external payable
    {
        require(_poolID < poolCounter, "Pool ID must exist");
        require(
            block.timestamp < pools[_poolID].startTime,
            "Pool has already started."
        );

        require(
            userSelection[_poolID][msg.sender].aggregatorAddresses[0] == address(0),
            "User already entered pool"
        );

        for(uint8 i = 0; i < 10; i++) {
            require(
                _aggregatorAddress[i] != address(0),
                "Aggregator cannot be zero address"
            );
        }

        userSelection[_poolID][msg.sender].aggregatorAddresses = _aggregatorAddress;
        pools[_poolID].userAddress.push(msg.sender);

        require(msg.value >= pools[_poolID].entryFee, "Insufficient funds sent");

        IWETH(wbnbAddress).deposit{value: pools[_poolID].entryFee}();
        payable(msg.sender).transfer(SafeMath.sub(msg.value, pools[_poolID].entryFee));

        pools[_poolID].pot = SafeMath.add(pools[_poolID].pot, pools[_poolID].entryFee);

        emit enteredPool(msg.sender, _poolID, _aggregatorAddress);
    }

    function emergencyWithdraw(address _tokenAddress) external onlyOwner {
        uint256 amount = IERC20(_tokenAddress).balanceOf(address(this));

        require(amount > 0, "No funds to withdraw");

        IERC20(_tokenAddress).transfer(msg.sender, amount);

        emit EmergencyWithdraw(_tokenAddress, amount);
    }

    function setWinner(
        uint256 _poolID,
        address[] memory _winners,
        uint256[] memory amount
    ) external onlyRole(POOL_ADMIN_ROLE) {
        require(_poolID < poolCounter, "Pool does not exist");

        require(
            block.timestamp > pools[_poolID].endTime,
            "The pool has not ended."
        );
        require(
            winnerDetails[_poolID].user.length == 0,
            "Winners are already set for this pool."
        );
        require(
            _winners.length <= pools[_poolID].userAddress.length,
            "Winners must be less than total users."
        );
        require(
            _winners.length == amount.length,
            "Winners and amounts must be of same length"
        );
        uint i;
        uint256 sum = 0;

        for(i = 0; i < amount.length; i++)
            sum = SafeMath.add(sum, amount[i]);

        require(sum <= pools[_poolID].pot, "Rewards are greater than pool pot");

        winnerDetails[_poolID].user = _winners;
        winnerDetails[_poolID].amount = amount;

        emit setWinners(_poolID, _winners, amount);
    }

    function claimReward(uint256 _poolID, uint256 position) external {
        require(_poolID < poolCounter, "Pool ID must exist");
        require(
            winnerDetails[_poolID].user.length > position,
            "Invalid winner position"
        );
        require(
            msg.sender == winnerDetails[_poolID].user[position],
            "You are not the winner for this position."
        );

        uint256 _marketingFee = SafeMath.div(SafeMath.mul(winnerDetails[_poolID].amount[position], marketingFee), 10000);
        uint256 _buybackFee = SafeMath.div(SafeMath.mul(winnerDetails[_poolID].amount[position], buybackFee), 10000);

        pools[_poolID].pot = SafeMath.sub(pools[_poolID].pot, winnerDetails[_poolID].amount[position]);

        uint256 payout = SafeMath.sub(winnerDetails[_poolID].amount[position], SafeMath.add(_marketingFee , _buybackFee));

        // Swap for pool reward and send
        swapBNBForTokenAndSend(winnerDetails[_poolID].user[position], pools[_poolID].tokenAddress, payout);

        // Send marketingFee to marketing wallet
        IWETH(wbnbAddress).withdraw(_marketingFee);
        (bool success,) = payable(marketingWallet).call{value : _marketingFee, gas : 30000}("");

        require(success);

        emit MarketingFundsSent(_marketingFee);

        // Swap buybackFee for Shima send to ?
        swapBNBForTokenAndSend(buybackWallet, buybackToken, _buybackFee);

        emit RewardClaimed(_poolID, msg.sender, payout);
        emit FeeDeducted(_poolID, pools[_poolID].tokenAddress, SafeMath.add(_marketingFee , _buybackFee));

        delete winnerDetails[_poolID].user[position];
        delete winnerDetails[_poolID].amount[position];
    }

    function swapBNBForTokenAndSend(address winner, address token, uint256 bnbAmount) private returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(token);

        IWETH(wbnbAddress).withdraw(bnbAmount);
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value : bnbAmount}(
            0, // accept any amount of tokens
            path,
            address(winner),
            block.timestamp
        );
        return bnbAmount;
    }

    function setMarketingFee(uint256 _fee) external onlyOwner {
        uint256 prevFee = marketingFee;
        marketingFee = _fee;

        emit FeeUpdated(prevFee, _fee);
    }

    function setBuybackFee(uint256 _fee) external onlyOwner {
        uint256 prevFee = buybackFee;
        buybackFee = _fee;

        emit FeeUpdated(prevFee, _fee);
    }

    function setMarketingWallet(address wallet) external onlyOwner {
        address prevWallet = marketingWallet;
        marketingWallet = wallet;

        emit WalletChange("Marketing", prevWallet, wallet);
    }

    function setBuybackWallet(address wallet) external onlyOwner {
        address prevWallet = buybackWallet;
        buybackWallet = wallet;

        emit WalletChange("Buyback", prevWallet, wallet);
    }

    function setBuybackToken(address token) external onlyOwner {
        address prevToken = buybackToken;
        buybackToken = token;

        emit BuybackTokenChange(prevToken, token);
    }

    function viewActivePools()
    external
    view
    returns (uint256[] memory, uint256)
    {
        uint256[] memory activePools = new uint256[](poolCounter);
        uint256 count = 0;
        for (uint256 i = 0; i < poolCounter; i++) {
            if (pools[i].endTime > block.timestamp) {
                activePools[count] = i;
                count++;
            }
        }
        return (activePools, count);
    }

    function getPoolInfo(uint256 _poolID) external view returns (pool memory) {
        return pools[_poolID];
    }

    function getUserSelectionInfo(uint256 _poolID, address _address)
    external
    view
    returns (userDetails memory)
    {
        return userSelection[_poolID][_address];
    }
}