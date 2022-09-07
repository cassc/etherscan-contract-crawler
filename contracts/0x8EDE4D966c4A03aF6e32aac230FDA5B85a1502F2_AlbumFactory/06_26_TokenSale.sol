//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenSale {
    event SaleInitialized(
        address creator,
        uint256 price,
        uint256 saleStart,
        uint256 saleEnd,
        uint256 numTokens
    );
    event Sale(address buyer, uint256 amount, uint256 paid);
    event SaleSwept(uint256 saleProceeds, uint256 amountUnsold);

    address public creator;
    IERC20 public token;
    // Number of tokens to sell per wei (1e-18 ETH)
    uint256 public tokensPerWei;
    uint256 public saleStart;
    uint256 public saleEnd;

    uint256 public saleProceeds;
    uint256 public amountUnsold;
    bool public swept;

    modifier saleOver(bool want) {
        bool isOver = block.timestamp >= saleEnd;
        require(want == isOver, "Sale state is invalid for this method");
        _;
    }

    struct Params {
        uint256 price;
        uint256 saleStart;
        uint256 saleEnd;
        uint256 numTokens;
    }

    constructor(
        address _creator,
        address _token,
        Params memory params
    ) {
        initialize(_creator, _token, params);
    }

    // Used in AlbumFactory.
    function initialize(
        address _creator,
        address _token,
        Params memory params
    ) public {
        require(saleEnd == 0);
        require(params.saleStart < params.saleEnd);
        creator = _creator;
        token = IERC20(_token);
        tokensPerWei = params.price;
        saleStart = params.saleStart;
        saleEnd = params.saleEnd;
        amountUnsold = params.numTokens;
        emit SaleInitialized(
            creator,
            params.price,
            params.saleStart,
            params.saleEnd,
            params.numTokens
        );
    }

    function buyTokens() public payable saleOver(false) {
        require(block.timestamp >= saleStart, "Sale has not started yet");
        uint256 amount = msg.value * tokensPerWei;
        require(
            amountUnsold >= amount,
            "Attempted to purchase too many tokens!"
        );
        amountUnsold -= amount;
        token.transfer(msg.sender, amount);
        saleProceeds += msg.value;
        emit Sale(msg.sender, amount, msg.value);
    }

    // Anyone can trigger a sweep, but the proceeds always get sent to the creator.
    function sweepProceeds() public saleOver(true) {
        require(!swept, "Already swept");
        swept = true;
        payable(creator).transfer(saleProceeds);
        token.transfer(creator, amountUnsold);
        emit SaleSwept(saleProceeds, amountUnsold);
    }

    function getTokenSaleData()
        public
        view
        returns (
            address _creator,
            IERC20 _token,
            uint256 _tokensPerWei,
            uint256 _saleStart,
            uint256 _saleEnd,
            uint256 _saleProceeds,
            uint256 _amountUnsold,
            bool _swept
        )
    {
        return (
            creator,
            token,
            tokensPerWei,
            saleStart,
            saleEnd,
            saleProceeds,
            amountUnsold,
            swept
        );
    }
}