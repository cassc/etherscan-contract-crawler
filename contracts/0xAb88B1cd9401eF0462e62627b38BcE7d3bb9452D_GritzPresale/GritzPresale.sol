/**
 *Submitted for verification at Etherscan.io on 2023-05-26
*/

//********************************************************************************
//********************************************************************************
//********************************************************************************
//*******             **.            ***     ***             **             ******
//******         *******              *       *                              *****
//******       **     **       ****   *       *              **              *****
//******         **    *              *       ******    ,***********,    *********
//******               *       **   ***       ******    *******              *****
//********************************************************************************
//********************************************************************************
//********************************************************************************
// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract GritzPresale {
    address public owner;
    IERC20 public token;
    uint256 public rate;
    uint256 public softCap;
    uint256 public hardCap;
    uint256 public minContribution;
    uint256 public maxContribution;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public totalRaised;
    bool public isRefunded;
    bool public presaleFinalized = false;
    uint256 public presaleTokens;

    mapping(address => uint256) public contributions;
    mapping(address => bool) public isContributor;
    address[] public contributors;

    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Factory public uniswapV2Factory;
    address public uniswapV2Pair;

    event TokensPurchased(address indexed buyer, uint256 amount);
    event PresaleRefunded(address indexed buyer, uint256 amount);
    event LiquidityAddedAndLocked(uint256 tokenAmount, uint256 ethAmount);
    event NFTAwarded(uint256 indexed nftId, address indexed winner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    bool public initialized = false;

modifier noReentrancy() {
    require(!initialized, "Reentrant call.");
    initialized = true;
    _;
    initialized = false;
}


    constructor() {
        owner = msg.sender;
    }

    function initialize(
        IERC20 _token,
        uint256 _rate,
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _minContribution,
        uint256 _maxContribution,
        uint256 _startTime,
        uint256 _endTime,
        address _uniswapV2Router,
        address _uniswapV2Factory
    ) external onlyOwner {
        require(!initialized, "Contract already initialized");

        token = _token;
        rate = _rate;
        softCap = _softCap;
        hardCap = _hardCap;
        minContribution = _minContribution;
        maxContribution = _maxContribution;
        startTime = _startTime;
        endTime = _endTime;

        uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
        uniswapV2Factory = IUniswapV2Factory(_uniswapV2Factory);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Factory).createPair(address(token), uniswapV2Router.WETH());

        initialized = true;
    }

    receive() external payable {
        buyTokens();

        if (!isContributor[msg.sender]) {
            contributors.push(msg.sender);
            isContributor[msg.sender] = true;
        }
    }

    function lockPresaleTokens() external onlyOwner {
        presaleTokens = token.balanceOf(address(this));
    }

function buyTokens() public payable  {
    require(block.timestamp >= startTime, "Presale has not started yet.");
    require(block.timestamp <= endTime, "Presale has ended.");
    require(totalRaised + msg.value <= hardCap, "Hard cap reached. Cannot accept more contributions.");

    uint256 newContribution = contributions[msg.sender] + msg.value;
    require(newContribution >= minContribution, "Minimum contribution not met.");
    require(newContribution <= maxContribution, "Max contribution exceeded. Cannot accept more contributions from this address.");

    uint256 amount = msg.value * rate;
    uint256 tokenBalance = token.balanceOf(address(this));

    require(tokenBalance >= amount, "Not enough tokens in the contract.");

    if (!isContributor[msg.sender]) {
        contributors.push(msg.sender);
        isContributor[msg.sender] = true;
    }

    contributions[msg.sender] = newContribution;
    totalRaised += msg.value;

    // Transfer tokens to the buyer
    token.transfer(msg.sender, amount);
    // Approve contract to spend the same amount of tokens on behalf of the buyer
    IERC20(token).approve(address(this), amount);

    emit TokensPurchased(msg.sender, amount);
}

    function hasEnded() public view returns (bool) {
        return block.timestamp > endTime;
    }

function claimRefundAndReturnTokens() external  {
    require(hasEnded(), "Presale has not ended yet.");
    require(totalRaised < softCap, "Soft cap has been reached, no refunds.");
    require(contributions[msg.sender] > 0, "No contributions to refund.");

    uint256 refundAmount = contributions[msg.sender];
    uint256 tokenAmountToReturn = refundAmount * rate;

    require(token.allowance(msg.sender, address(this)) >= tokenAmountToReturn, "You need to approve the contract to retrieve the tokens.");

    // Retrieve tokens from the contract and transfer to the buyer
    IERC20(token).transferFrom(address(this), msg.sender, tokenAmountToReturn);

    // Update the contribution state and perform the refund
    contributions[msg.sender] = 0;
    totalRaised -= refundAmount;
    (bool success, ) = payable(msg.sender).call{value: refundAmount}("");
    require(success, "Refund failed.");

    emit PresaleRefunded(msg.sender, refundAmount);
}

    function presaleStatus() public view returns (string memory) {
        if (block.timestamp < startTime) {
            return "Not started yet";
        } else if (block.timestamp >= startTime && block.timestamp <= endTime) {
            return "Live";
        } else {
            return "Ended";
        }
    }

    function withdrawGritz() external onlyOwner {
        require(hasEnded(), "Presale has not ended yet.");
        require(totalRaised < softCap, "Soft cap has been reached, can't withdraw tokens.");

        uint256 remainingTokens = token.balanceOf(address(this));
        token.transfer(owner, remainingTokens);
    }

    function finalizePresale() external onlyOwner {
        require(hasEnded(), "Presale has not ended yet.");

        if (totalRaised < softCap) {
            isRefunded = true;
            return;
        }

        require(totalRaised >= softCap, "Soft cap has not been reached, cannot add liquidity and lock.");

        uint256 unsoldTokens = presaleTokens - totalRaised * rate;

        // Add liquidity and lock it
        addLiquidityAndLock(unsoldTokens);

        // Presale finalized successfully
        presaleFinalized = true;
    }

    function addLiquidityAndLock(uint256 unsoldTokens) internal {
        uint256 raisedEth = address(this).balance;

        // Calculate 90% of raisedEth
        uint256 ninetyPercentEth = raisedEth * 9 / 10;

        // Approve Uniswap router to transfer tokens
        token.approve(address(uniswapV2Router), unsoldTokens);

        // Add liquidity to the Uniswap pool
        (uint256 amountToken, uint256 amountETH,) = uniswapV2Router.addLiquidityETH{value: ninetyPercentEth}(
            address(token),
            unsoldTokens,
            unsoldTokens,
            ninetyPercentEth,
            owner,
            block.timestamp + 1 weeks // Deadline one week from now
        );

        emit LiquidityAddedAndLocked(amountToken, amountETH);
    }

    function withdrawETH() external onlyOwner {
        require(presaleFinalized, "Presale has not been finalized yet.");
        require(hasEnded(), "Presale has not ended yet.");
        require(totalRaised >= softCap, "Soft cap has not been reached, can't withdraw ETH.");

        uint256 remainingEth = address(this).balance;

        (bool success, ) = payable(owner).call{value: remainingEth}("");
        require(success, "Transfer failed.");
    }

    struct NFT {
        uint256 id;
        string uri;
        address owner;
    }

    uint256 public nftCounter = 0;
    mapping (uint256 => NFT) public nfts;

    function createNFT(string memory _uri) internal returns (uint256) {
        nfts[nftCounter] = NFT(nftCounter, _uri, address(this));
        nftCounter++;
        return nftCounter - 1;
    }

    function transferNFT(uint256 _id, address _to) internal {
        require(nfts[_id].owner == address(this), "NFT not owned by contract");
        nfts[_id].owner = _to;
        emit NFTAwarded(_id, _to);
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, contributors)));
    }

    function airdropNFTs(uint256 _numberOfWinners) external onlyOwner {
        require(totalRaised >= softCap, "Soft cap not reached");
        require(_numberOfWinners <= contributors.length, "Not enough contributors for the number of winners");

        for (uint i = 0; i < _numberOfWinners; i++) {
            uint256 winnerIndex;
            bool winnerExists = true;

            while (winnerExists == true) {
                winnerIndex = random() % contributors.length;
                if (nfts[winnerIndex].owner == address(0)) {
                    winnerExists = false;
                }
            }

            uint256 nftId = createNFT("https://ipfs.io/ipfs/QmStMRBS5VMWkBx3xhdYe2AjzJzsFi82zXWLrLDdztcoV4?filename=goldenticketwinner.PNG");
            transferNFT(nftId, contributors[winnerIndex]);
        }
    }

    function resetPresale(
        uint256 _rate,
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _minContribution,
        uint256 _maxContribution,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOwner  {
        require(hasEnded(), "Presale has not ended yet.");
        require(totalRaised < softCap, "Soft cap reached, can't reset presale.");

        rate = _rate;
        softCap = _softCap;
        hardCap = _hardCap;
        minContribution = _minContribution;
        maxContribution = _maxContribution;
        startTime = _startTime;
        endTime = _endTime;
        totalRaised = 0;

        // Reset contributions
        for (uint i = 0; i < contributors.length; i++) {
            contributions[contributors[i]] = 0;
            isContributor[contributors[i]] = false;
        }

        // Reset contributors array
        delete contributors;
    }
}