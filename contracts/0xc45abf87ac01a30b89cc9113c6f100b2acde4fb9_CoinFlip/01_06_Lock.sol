// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract CoinFlip is Ownable {
    enum coinSelection {
        HEAD,
        TAIL
    }

    event newResultRequested(uint256 requestId);
    event ResultRecived(uint256 requestId);
    event LinkBoughtSuccess(uint256 fromBnb);
    event LinkBoughtFaild(uint256 avilableBnb, uint256 requireBnb);

    struct CoinFlipStatus {
        uint256 randomWord;
        address player;
        bool isWin;
        bool chainLinkFullFilled;
        coinSelection bet;
        uint256 betAmount;
    }

    uint256 reward = 194;

    address public feeAdmin = 0x86B36EdEEe4051F86a74DC0F3efc26571595a0Af;

    address private deadAddress = 0x000000000000000000000000000000000000dEaD;

    IUniswapV2Router02 public router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    // admin fees percentage
    uint256 public tokenFee = 100;
    uint256 public burnFee = 300;
    uint256 public lpFee = 100;

    uint256 public maxPoolPercentage = 5;

    IERC20 public betToken;
    uint256 public minimumBetAmount;
    uint256 public maxBetAmount;

    mapping(uint256 => CoinFlipStatus) public betStatus;

    receive() external payable {}

    constructor() {
        betToken = IERC20(0xa34Ee6108Fe427f91edce0D6520d9fEc0E64F67b);
        minimumBetAmount = 66066050 * 10 ** 9;
        maxBetAmount = 33033025033 * 10 ** 9;

        betToken.approve(address(router), type(uint256).max);
    }

    function flipCoin(
        coinSelection choise,
        uint256 _betAmount
    ) external returns (uint256) {
        require(
            minimumBetAmount <= _betAmount,
            "You should bet more than minimum bet amount"
        );
        require(
            maxBetAmount >= _betAmount,
            "You can not bet more than maximum bet amount"
        );

        uint256 oldBalance = betToken.balanceOf(address(this));

        require(
            _betAmount <= ((oldBalance * maxPoolPercentage) / 100),
            "Use less token amount to bet"
        );

        betToken.transferFrom(msg.sender, address(this), _betAmount);

        // take admin fees
        uint256 tokensFee = (_betAmount * tokenFee) / 10000;
        uint256 burnTokens = (_betAmount * burnFee) / 10000;
        uint256 lpTokenFee = (_betAmount * lpFee) / 10000;

        swapAndLiquify(lpTokenFee);

        betToken.transfer(feeAdmin, tokensFee);
        betToken.transfer(deadAddress, burnTokens);

        uint256 requestId = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.difficulty))
        );

        betStatus[requestId] = CoinFlipStatus({
            randomWord: 0,
            player: msg.sender,
            isWin: false,
            chainLinkFullFilled: false,
            bet: choise,
            betAmount: _betAmount
        });

        emit newResultRequested(requestId);

        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256 _randomWord
    ) external onlyOwner {
        betStatus[_requestId].randomWord = _randomWord;
        betStatus[_requestId].chainLinkFullFilled = true;

        coinSelection result = coinSelection.HEAD;

        if (_randomWord % 2 == 0) {
            result = coinSelection.TAIL;
        }

        if (betStatus[_requestId].bet == result) {
            betStatus[_requestId].isWin = true;

            uint256 winingAmount = (betStatus[_requestId].betAmount * reward) /
                100;

            betToken.transfer(betStatus[_requestId].player, winingAmount);
        }

        emit ResultRecived(_requestId);
    }

    function getStatus(
        uint256 requestId
    ) public view returns (CoinFlipStatus memory) {
        return betStatus[requestId];
    }

    function withdrawBnb(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function withdrawBep20Tokens(
        address _token,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }

    function changeRewardPercentage(uint256 _percentage) external onlyOwner {
        reward = _percentage;
    }

    function changeMinimumBetAmount(uint256 _amount) external onlyOwner {
        minimumBetAmount = _amount;
    }

    function changeMaxBetAmount(uint256 _amount) external onlyOwner {
        minimumBetAmount = _amount;
    }

    function changeAdminFeePercentages(
        uint256 _burnFee,
        uint256 _tokenFee,
        uint256 _lpFee
    ) external {
        require(
            msg.sender == feeAdmin,
            "Only Super Admin can call this function"
        );

        burnFee = _burnFee;
        tokenFee = _tokenFee;
        lpFee = _lpFee;
    }

    function swapAndLiquify(uint256 tokens) private {
        // split the contract balance into halves
        uint256 half = tokens / 2;
        uint256 otherHalf = tokens - half;

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance - initialBalance;

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(betToken);
        path[1] = router.WETH();
        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // add the liquidity
        router.addLiquidityETH{value: bnbAmount}(
            address(betToken),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }
}