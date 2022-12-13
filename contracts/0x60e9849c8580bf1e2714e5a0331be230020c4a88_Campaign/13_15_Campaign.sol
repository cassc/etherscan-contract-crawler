// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "./interfaces/ICampaign.sol";
import "./interfaces/ICampaignFactory.sol";


contract Campaign is ICampaign, Ownable, Initializable {
    event TokensReserve(address indexed user, uint256 bnb_val, uint256 tokens_amount);
    event TokensRealized(address indexed user, uint256 tokens_amount);
    event Refund(address indexed user, uint256 bnb_val, uint256 tokens_amount);
    event Reset();
    event FeeTaken(uint256 bnb_amount);
    event LiquidityAdded(uint256 bnb_amount, uint256 token_amount, uint256 lp_tokens, uint32 lock_until);
    event LiquidityReleased();

    address constant BURN = 0x000000000000000000000000000000000000dEaD;
    address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    using SafeERC20 for IERC20;

    uint16 constant MAX_PERCENT = 10000;
    uint16 public fee;
    Config public config;
    ICampaignFactory public factory;
    IUniswapV2Router02 public router;
    bool public reseted;
    bool public finished;
    uint256 public raised;
    mapping (address => uint256) public reserved_tokens;
    mapping (address => uint256) public reserved_bnbs;
    uint256 public tokens_sold;
    uint256 public contributors;
    uint32 public lp_lock_until;

    function initialize(address _owner, uint16 _fee, address _router, Config calldata _config) external initializer {
        _transferOwnership(_owner);
        fee = _fee;
        factory = ICampaignFactory(msg.sender);
        config = _config;
        router = IUniswapV2Router02(_router);
    }

    modifier onlyFactoryOwner() {
        require (msg.sender == factory.owner(), "Campaign::onlyFactoryOwner: not factory owner");
        _;
    }

    modifier presaleLive() {
        require (!reseted && block.timestamp > config.start && block.timestamp < config.end, "Campaign::presaleLive: presale not live");
        _;
    }

    modifier presaleEnded() {
        require (block.timestamp > config.end, "Campaign::presaleEnded: presale not ended");
        _;
    }

    function hardCap() public view returns (uint256) {
        return (config.presaleTokens * 10**18) / config.tokensPerBnb;
    }

    function reset() external onlyFactoryOwner {
        require (block.timestamp < config.start, "Campaign::reset: too late to reset");
        require (reseted == false, "Campaign::reset: reseted already");

        uint256 token_balance = config.token.balanceOf(address(this));
        if (token_balance > 0) {
            config.token.safeTransfer(owner(), token_balance);
        }

        reseted = true;
        emit Reset();
    }

    function calculateTokens(uint256 bnb_value) public view returns (uint256 _tokens_to_buy, uint256 _refund_val, uint256 _buy_val) {
        uint256 max_allowed_val = hardCap() - raised;
        _buy_val = bnb_value;
        if (_buy_val > max_allowed_val) {
            _refund_val = _buy_val - max_allowed_val;
            _buy_val = max_allowed_val;
        }
        _tokens_to_buy = _buy_val * config.tokensPerBnb / 10**18;
    }

    function buyTokens() external payable presaleLive {
        require (raised < hardCap(), "Campaign::buyTokens: hardCap reached");
        require (msg.value > 0, "Campaign::buyTokens: zero msg.value");

        uint256 token_balance = config.token.balanceOf(address(this));
        require (token_balance >= config.presaleTokens + config.liquidityTokens, "Campaign::buyTokens: tokens not provided");

        (uint256 tokens_to_buy, uint256 refund_val, uint256 buy_val) = calculateTokens(msg.value);
        if (refund_val > 0) {
            payable(msg.sender).transfer(refund_val);
        }

        uint256 total_spent = reserved_bnbs[msg.sender] + buy_val;
        require (
            total_spent >= config.minPurchaseBnb && total_spent <= config.maxPurchaseBnb,
            "Campaign::buyTokens: too low/high purchase amount"
        );

        raised += buy_val;
        if (reserved_tokens[msg.sender] == 0) {
            contributors += 1;
        }
        reserved_tokens[msg.sender] += tokens_to_buy;
        reserved_bnbs[msg.sender] += buy_val;
        tokens_sold += tokens_to_buy;

        require (tokens_sold <= config.presaleTokens, "Campaign::buyTokens: cant sell more tokens");

        emit TokensReserve(msg.sender, buy_val, tokens_to_buy);
    }

    function getReservedTokens() external presaleEnded {
        uint256 reserved = reserved_tokens[msg.sender];

        require (raised >= config.softCap, "Campaign::getReservedTokens: softCap not reached");
        require (reserved > 0, "Campaign::getReservedTokens: user has no reserved tokens");

        delete reserved_tokens[msg.sender];
        delete reserved_bnbs[msg.sender];
        config.token.safeTransfer(msg.sender, reserved);

        emit TokensRealized(msg.sender, reserved);
    }

    function refund() external presaleEnded {
        require (raised < config.softCap, "Campaign::refund: softCap reached");
        require (reserved_bnbs[msg.sender] > 0, "Campaign::refund: no reserved BNBs");

        uint256 tokens = reserved_tokens[msg.sender];
        uint256 refund_val = reserved_bnbs[msg.sender];

        delete reserved_tokens[msg.sender];
        delete reserved_bnbs[msg.sender];
        payable(msg.sender).transfer(refund_val);

        emit Refund(msg.sender, refund_val, tokens);
    }

    function getPair() public view returns (address) {
        IUniswapV2Factory uni_factory = IUniswapV2Factory(router.factory());
        return uni_factory.getPair(WBNB, address(config.token));
    }

    function lpLocked() public view returns (uint256) {
        return IUniswapV2Pair(getPair()).balanceOf(address(this));
    }

    function finishPresale() external presaleEnded onlyOwner {
        require (!finished,  "Campaign::finishPresale: already finished");

        finished = true;

        if (raised < config.softCap) {
            uint256 token_balance = config.token.balanceOf(address(this));
            if (token_balance > 0) {
                config.token.safeTransfer(owner(), token_balance);
            }
        } else {
            uint256 platform_fee = fee * raised / MAX_PERCENT;
            address(factory).call{value: platform_fee}("");

            uint256 raised_clear = raised - platform_fee;
            uint256 bnb_liq = raised_clear * config.liquidityPercent / MAX_PERCENT;

            config.token.approve(address(router), config.liquidityTokens);
            // add liquidity without any conditions
            (
                uint token_amount,
                uint bnb_amount,
                uint liquidity
            ) = router.addLiquidityETH{value: bnb_liq}(address(config.token), config.liquidityTokens, 0, 0, address(this), block.timestamp);

            // send remaining bnb to owner
            payable(owner()).transfer(address(this).balance);
            // send dust tokens, if any
            if (token_amount < config.liquidityTokens) {
                config.token.safeTransfer(owner(), config.liquidityTokens - token_amount);
            }

            // set lock interval for liquidity
            lp_lock_until = uint32(block.timestamp) + config.liquidityLockupPeriod;

            uint256 unsoldTokens = config.presaleTokens - tokens_sold;
            if (unsoldTokens > 0) {
                if (config.action == UnsoldTokensAction.burn) {
                    config.token.safeTransfer(BURN, unsoldTokens);
                } else {
                    config.token.safeTransfer(owner(), unsoldTokens);
                }
            }

            emit LiquidityAdded(bnb_amount, token_amount, liquidity, lp_lock_until);
        }
    }

    function unlockLiquidity() external onlyOwner {
        require (block.timestamp >= lp_lock_until, "Campaign::unlockLiquidity: too early to unlock liq");

        IUniswapV2Pair pair = IUniswapV2Pair(getPair());
        pair.transfer(owner(), pair.balanceOf(address(this)));

        emit LiquidityReleased();
    }

    receive() external payable {}

    function sweep(IERC20 token, address receiver) external onlyFactoryOwner {
        require (address(token) != address(config.token), "Campaign::sweep: cant sweep campaign token");
        require (address(token) != getPair(), "Campaign::sweep: cant sweep LP token");

        uint256 token_balance = token.balanceOf(address(this));
        config.token.safeTransfer(receiver, token_balance);
    }
}