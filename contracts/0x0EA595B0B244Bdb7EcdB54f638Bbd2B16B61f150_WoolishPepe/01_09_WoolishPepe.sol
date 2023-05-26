// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RandomTrueFalse {
    uint256 private seed = 0;
    function getRandom() public returns (bool) {
        seed = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, seed)));
        return (seed % 2 == 0);
    }
}

contract WoolishPepe is ERC20, Ownable {
    IUniswapV2Router02 public uniswapRouter;
    IERC20 public woolToken;
    IERC20 public pepeToken;
    RandomTrueFalse private randomTrueFalse;
    address public rewardPoolAddress;
    using Address for address payable;
    bool public rewardEnabled;

    event TransferWithReward(
        address indexed recipient,
        uint256 amount,
        uint256 rewardAmount,
        uint256 rewardPoolAmount
    );

    event Mint(address indexed to, uint256 amount);
    event RewardPoolAddressUpdated(address indexed previousRewardPoolAddress, address indexed newRewardPoolAddress);

    constructor(address _uniswapRouter, address _woolToken, address _pepeToken, address _rewardPoolAddress)
        ERC20("WoolishPepe", "WOPE")
    {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        woolToken = IERC20(_woolToken);
        pepeToken = IERC20(_pepeToken);
        rewardPoolAddress = _rewardPoolAddress;
        randomTrueFalse = new RandomTrueFalse();
        rewardEnabled = false;
    }

    function setUniswapRouter(IUniswapV2Router02 _router) public onlyOwner {
        uniswapRouter = _router;
    }


    function setRewardEnabled(bool _enabled) public onlyOwner {
        rewardEnabled = _enabled;
    }


    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
        emit Mint(to, amount);
    }

    function changeOwner(address newOwner) public onlyOwner {
        transferOwnership(newOwner);
    }

    function updateRewardPoolAddress(address newRewardPoolAddress) public onlyOwner {
        require(newRewardPoolAddress != address(0), "New reward pool address cannot be a zero address");
        require(newRewardPoolAddress != rewardPoolAddress, "New reward pool address must be different from the current address");

        address previousRewardPoolAddress = rewardPoolAddress;
        rewardPoolAddress = newRewardPoolAddress;
        emit RewardPoolAddressUpdated(previousRewardPoolAddress, newRewardPoolAddress);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        
        // Calculate the amounts for the transfer and the reward
        uint256 percentage = rewardEnabled ? 95 : 97;
        uint256 transferAmount = (amount * percentage) / 100;
        uint256 rewardAmount = (amount * 2) / 100;
        uint256 rewardPoolAmount = (amount * 3) / 100;

        // Transfer 95% or 97% of PepeWool tokens from the sender to the recipient
        super.transfer(recipient, transferAmount);

        // Transfer 3% of PepeWool tokens from the sender to the reward pool address
        super.transfer(rewardPoolAddress, rewardPoolAmount);

        if (rewardEnabled) {
            // Transfer 2% of PepeWool tokens from the sender to the contract for the reward
            super.transfer(address(this), rewardAmount);    

            // Swap the reward amount for WOOL or PEPE tokens
            _swapAndReward(rewardAmount, recipient);

            // Emit the TransferWithReward event
            emit TransferWithReward(recipient, transferAmount, rewardAmount, rewardPoolAmount);
    
        }

        return true;
    }

    function _swapAndReward(uint256 rewardAmount, address recipient) private {
        bool shouldRewardInWool = randomTrueFalse.getRandom();

        // Define the path for the token swap (PepeWool -> output token)
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = shouldRewardInWool ? address(woolToken) : address(pepeToken);

        // Approve the Uniswap router to spend PepeWool tokens on behalf of the contract
        IERC20 outputToken = IERC20(path[1]);
         // Approve the Uniswap router to spend PepeWool tokens on behalf of the contract
        _approve(address(this), address(uniswapRouter), rewardAmount);

        // Execute the token swap on Uniswap
        uniswapRouter.swapExactTokensForTokens(
            rewardAmount,
            0,
            path,
            address(this),
            block.timestamp + 300
        );

        // Transfer the swapped tokens to the recipient
        uint256 tokenBalance = outputToken.balanceOf(address(this));
        if (tokenBalance > 0) {
            outputToken.transfer(recipient, tokenBalance);
        }
    }

    function drainEther() external onlyOwner {
        address payable rewardPoolAddressPayable = payable(rewardPoolAddress);
        uint256 etherBalance = address(this).balance;
        require(etherBalance > 0, "No Ether available to drain");

        rewardPoolAddressPayable.sendValue(etherBalance);
    }

    function drainTokens(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));

        require(tokenBalance > 0, "No tokens available to drain");

        token.transfer(rewardPoolAddress, tokenBalance);
    }


    function renounceContractOwnership() external onlyOwner {
        renounceOwnership();
    }
}