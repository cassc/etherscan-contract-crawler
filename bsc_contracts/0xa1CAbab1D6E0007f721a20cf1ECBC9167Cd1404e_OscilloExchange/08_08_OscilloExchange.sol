// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IERC20Meta.sol";
import "./interface/IWrapped.sol";
import "./library/LibTrade.sol";
import "./library/LibTransfer.sol";


contract OscilloExchange is Ownable {
    using LibTrade for LibTrade.MatchExecution;
    using LibTransfer for IERC20Meta;

    bytes32 private constant _DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    bytes32 private constant _DOMAIN_VERSION = 0x0984d5efd47d99151ae1be065a709e56c602102f24c1abc4008eb3f815a8d217;
    bytes32 private constant _DOMAIN_NAME = 0xd8847acffb1e80c967781c9cefc950c79c285c67014ab8ca7bfb053adcb94e20;

    uint private constant GAS_EXPECTATION_BUFFERED = 280000;
    uint private constant RESERVE_MAX = 2500;
    uint private constant RESERVE_DENOM = 1000000;
    uint private constant PRICE_DENOM = 1000000;

    bytes32 private immutable _domainSeparator;
    mapping(uint => uint) private _fills;
    mapping(address => bool) private _executors;

    IWrapped public immutable nativeToken;

    event Executed(uint indexed matchId, uint[3] askTransfers, uint[3] bidTransfers);
    event Cancelled(uint indexed matchId, uint code);

    modifier onlyExecutor {
        require(msg.sender != address(0) && _executors[msg.sender], "!executor");
        _;
    }

    receive() external payable {}

    constructor(address _nativeToken) {
        _domainSeparator = keccak256(abi.encode(_DOMAIN_TYPEHASH, _DOMAIN_NAME, _DOMAIN_VERSION, block.chainid, address(this)));
        nativeToken = IWrapped(_nativeToken);
    }

    /** Views **/

    function toAmountQuote(address base, address quote, uint amount, uint price) public view returns (uint) {
        return amount * price * (10 ** IERC20Meta(quote).decimals()) / PRICE_DENOM / (10 ** IERC20Meta(base).decimals());
    }

    function toAmountsInOut(LibTrade.MatchExecution memory exec) public view returns (uint[2] memory askTransfers, uint[2] memory bidTransfers) {
        uint baseUnit = 10 ** IERC20Meta(exec.base).decimals();
        uint quoteUnit = 10 ** IERC20Meta(exec.quote).decimals();

        uint bidReserve = exec.amount * exec.reserve / RESERVE_DENOM;
        uint askReserve = bidReserve * exec.price * quoteUnit / PRICE_DENOM / baseUnit;
        uint amountQ = exec.amount * exec.price * quoteUnit / PRICE_DENOM / baseUnit;
        askTransfers = [exec.amount, amountQ - askReserve];
        bidTransfers = [amountQ, exec.amount - bidReserve];
    }

    function reserves(address base, address quote, uint amount, uint price, uint reserve) public view returns (uint askReserve, uint bidReserve) {
        bidReserve = amount * (reserve > RESERVE_MAX ? RESERVE_MAX : reserve) / RESERVE_DENOM;
        askReserve = toAmountQuote(base, quote, bidReserve, price);
    }

    function txCosts(LibTrade.MatchExecution memory exec, uint gasprice, uint gasUsed) private view returns (uint askTx, uint bidTx) {
        uint baseDecimals = IERC20Meta(exec.base).decimals();
        uint txCost = gasprice * gasUsed * exec.priceN / exec.price / (10 ** (18 - baseDecimals));
        askTx = _fills[exec.ask.id] == 0 ? txCost * exec.price * (10 ** IERC20Meta(exec.quote).decimals()) / PRICE_DENOM / (10 ** baseDecimals) : 0;
        bidTx = _fills[exec.bid.id] == 0 ? txCost : 0;
    }

    function acceptance(LibTrade.MatchExecution[] memory chunk, uint gasprice) public view returns (LibTrade.Acceptance[] memory) {
        LibTrade.Acceptance[] memory accepts = new LibTrade.Acceptance[](chunk.length);
        for (uint i = 0; i < chunk.length; i++) {
            LibTrade.MatchExecution memory e = chunk[i];
            accepts[i].mid = e.mid;

            if (!e.recover(_domainSeparator) || e.reserve > RESERVE_MAX) accepts[i].code = accepts[i].code | (1 << LibTrade.CodeIdxSignature);
            if (e.price < e.ask.lprice || e.price > e.bid.lprice) accepts[i].code = accepts[i].code | (1 << LibTrade.CodeIdxPrice);
            if (e.ask.amount < _fills[e.ask.id] + e.amount) accepts[i].code = accepts[i].code | (1 << LibTrade.CodeIdxAskFilled);
            if (e.bid.amount < _fills[e.bid.id] + e.amount) accepts[i].code = accepts[i].code | (1 << LibTrade.CodeIdxBidFilled);

            uint amountQ = toAmountQuote(e.base, e.quote, e.amount, e.price);
            (uint askReserve, uint bidReserve) = reserves(e.base, e.quote, e.amount, e.price, e.reserve);
            (uint askTx, uint bidTx) = txCosts(e, gasprice, GAS_EXPECTATION_BUFFERED);
            if (askReserve + askTx > amountQ) accepts[i].code = accepts[i].code | (1 << LibTrade.CodeIdxAskCost);
            if (bidReserve + bidTx > e.amount) accepts[i].code = accepts[i].code | (1 << LibTrade.CodeIdxBidCost);

            (uint[2] memory askTransfers, uint[2] memory bidTransfers) = toAmountsInOut(e);
            if (IERC20Meta(e.base).available(e.ask.account, address(this)) < askTransfers[0]) accepts[i].code = accepts[i].code | (1 << LibTrade.CodeIdxAskBalance);
            if (IERC20Meta(e.quote).available(e.bid.account, address(this)) < bidTransfers[0]) accepts[i].code = accepts[i].code | (1 << LibTrade.CodeIdxBidBalance);

            if (e.ask.deadline < block.timestamp) accepts[i].code = accepts[i].code | (1 << LibTrade.CodeIdxAskDeadline);
            if (e.bid.deadline < block.timestamp) accepts[i].code = accepts[i].code | (1 << LibTrade.CodeIdxBidDeadline);

            accepts[i].askTransfers = [askTransfers[0], askTransfers[1], askTx];
            accepts[i].bidTransfers = [bidTransfers[0], bidTransfers[1], bidTx];
        }
        return accepts;
    }

    /** Interactions **/

    function execute(LibTrade.MatchExecution[] calldata chunk, uint gasUsed) external onlyExecutor {
        gasUsed = gasUsed == 0 ? GAS_EXPECTATION_BUFFERED : gasUsed;
        for (uint i = 0; i < chunk.length; i++) {
            uint code;
            LibTrade.MatchExecution memory e = chunk[i];

            if (e.ask.deadline < block.timestamp) code = code | (1 << LibTrade.CodeIdxAskDeadline);
            if (e.bid.deadline < block.timestamp) code = code | (1 << LibTrade.CodeIdxBidDeadline);
            if (code != 0) {
                emit Cancelled(e.mid, code);
                continue;
            }

            uint amountQ = e.amount * e.price * (10 ** IERC20Meta(e.quote).decimals()) / PRICE_DENOM / (10 ** IERC20Meta(e.base).decimals());
            if (IERC20Meta(e.base).available(e.ask.account, address(this)) < e.amount) code = code | (1 << LibTrade.CodeIdxAskBalance);
            if (IERC20Meta(e.quote).available(e.bid.account, address(this)) < amountQ) code = code | (1 << LibTrade.CodeIdxBidBalance);
            if (code != 0) {
                emit Cancelled(e.mid, code);
                continue;
            }

            if (!e.recover(_domainSeparator) || e.reserve > RESERVE_MAX) code = code | (1 << LibTrade.CodeIdxSignature);
            if (e.price < e.ask.lprice || e.price > e.bid.lprice) code = code | (1 << LibTrade.CodeIdxPrice);
            if (code != 0) {
                emit Cancelled(e.mid, code);
                continue;
            }

            (uint askFilled, uint bidFilled) = (_fills[e.ask.id], _fills[e.bid.id]);
            if (e.ask.amount < askFilled + e.amount) code = code | (1 << LibTrade.CodeIdxAskFilled);
            if (e.bid.amount < bidFilled + e.amount) code = code | (1 << LibTrade.CodeIdxBidFilled);
            if (code != 0) {
                emit Cancelled(e.mid, code);
                continue;
            }

            uint bidReserve = e.amount * e.reserve / RESERVE_DENOM;
            uint askReserve = bidReserve * e.price * (10 ** IERC20Meta(e.quote).decimals()) / PRICE_DENOM / (10 ** IERC20Meta(e.base).decimals());
            (uint askTx, uint bidTx) = _txCosts(e, askFilled, bidFilled, tx.gasprice, gasUsed);
            if (askReserve + askTx > amountQ) code = code | (1 << LibTrade.CodeIdxAskCost);
            if (bidReserve + bidTx > e.amount) code = code | (1 << LibTrade.CodeIdxBidCost);

            if (code != 0) {
                emit Cancelled(e.mid, code);
                continue;
            }

            _fills[e.ask.id] = askFilled + e.amount;
            _fills[e.bid.id] = bidFilled + e.amount;

            IERC20Meta(e.base).safeTransferFrom(e.ask.account, address(this), e.amount);
            IERC20Meta(e.quote).safeTransferFrom(e.bid.account, address(this), amountQ);

            IERC20Meta(e.quote).safeTransfer(e.ask.account, amountQ - askReserve - askTx);
            if (e.unwrap && e.base == address(nativeToken)) {
                uint balance = address(this).balance;
                nativeToken.withdraw(e.amount - bidReserve - bidTx);
                LibTransfer.safeTransferETH(e.bid.account, address(this).balance - balance);
            } else {
                IERC20Meta(e.base).safeTransfer(e.bid.account, e.amount - bidReserve - bidTx);
            }

            if (askTx > 0) IERC20Meta(e.quote).safeTransfer(msg.sender, askTx);
            if (bidTx > 0) IERC20Meta(e.base).safeTransfer(msg.sender, bidTx);
            emit Executed(e.mid, [e.amount, amountQ - askReserve, askTx], [amountQ, e.amount - bidReserve, bidTx]);
        }
    }

    /** Restricted **/

    function setExecutor(address target, bool on) external onlyOwner {
        require(target != address(0), "!target");
        _executors[target] = on;
    }

    function sweep(address[] calldata tokens, address target) external onlyOwner {
        require(target != address(0), "!target");
        for (uint i = 0; i < tokens.length; i++) {
            IERC20Meta token = IERC20Meta(tokens[i]);
            uint leftover = token.balanceOf(address(this));
            if (leftover > 0) token.safeTransfer(target, leftover);
        }
    }

    /** Privates **/

    function _txCosts(LibTrade.MatchExecution memory exec, uint askFilled, uint bidFilled, uint gasprice, uint gasUsed) private view returns (uint askTx, uint bidTx) {
        uint baseDecimals = IERC20Meta(exec.base).decimals();
        uint txCost = gasprice * gasUsed * exec.priceN / exec.price / (10 ** (18 - baseDecimals));
        askTx = askFilled == 0 ? txCost * exec.price * (10 ** IERC20Meta(exec.quote).decimals()) / PRICE_DENOM / (10 ** baseDecimals) : 0;
        bidTx = bidFilled == 0 ? txCost : 0;
    }
}