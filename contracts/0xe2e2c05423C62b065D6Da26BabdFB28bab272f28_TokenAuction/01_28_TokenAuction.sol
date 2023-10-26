pragma solidity ^0.8.0;

import "./interfaces/TokenBankInterface.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./erc20/IERC20.sol";
import "./erc20/SafeERC20.sol";
import "./utils/SafeMath.sol";

import "forge-std/Test.sol";

contract TokenAuction is Initializable, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public bank;
    address public target_token;
    address public recv_token;
    address public yield_pool;
    uint256 public start_price;
    uint256 public last_duration_in_blocknum;
    uint256 public minimal_bumpup;
    uint256 public minimal_amount;
    uint256 public ratio_base;
    address public proof_token;

    bool public paused;

    struct round_info {
        uint256 last_auction_block;
        uint256 highest_price;
        uint256 highest_amount;
        address payable highest_sender;
        bool settled;
    }

    round_info[] public all_rounds;

    function initialize(
        address _bank,
        address _target_token,
        address _recv_token,
        address _yield_pool,
        uint256 _start_price,
        uint256 _last_duration_in_blocknum,
        uint256 _minimal_bumpup,
        uint256 _minimal_amount,
        address _proof_token
    )
        external
        initializer
    {
        __Ownable_init();
        bank = _bank;
        target_token = _target_token;
        recv_token = _recv_token;
        start_price = _start_price;
        last_duration_in_blocknum = _last_duration_in_blocknum;
        minimal_bumpup = _minimal_bumpup;
        minimal_amount = _minimal_amount;
        proof_token = _proof_token;
        yield_pool = _yield_pool;
        ratio_base = 10_000;
        paused = false;
    }

    event PlaceAuction(
        address newAuctioner,
        uint256 newAmount,
        uint256 newPrice,
        address oldAuctioner,
        uint256 oldAmount,
        uint256 oldPrice
    );
    event BidExceeded(address bidder, uint256 oldBidAmount, uint256 newBidAmount);

    function auction(uint256 amount, uint256 price) public returns (bool) {
        require(!paused, "auction already paused");
        require(amount >= minimal_amount, "less than minimal amount");
        require(price >= start_price, "less than start price");
        require(IERC20(proof_token).balanceOf(msg.sender) > 0, "only employee can auction");

        if (all_rounds.length == 0) {
            round_info memory mri;
            mri.last_auction_block == block.number;
            all_rounds.push(mri);
        }

        round_info storage ri = all_rounds[all_rounds.length - 1];
        if (block.number > ri.last_auction_block.safeAdd(last_duration_in_blocknum)) {
            if (!ri.settled) {
                _end_current_auction();
            }
            round_info memory ti;
            ti.last_auction_block == block.number;
            all_rounds.push(ti);
            ri = all_rounds[all_rounds.length - 1];
        }
        //require(price >= ri.highest_price.safeMul(ratio_base + minimal_bumpup).safeDiv(ratio_base), "price bump up too
        // small");

        uint256 t = amount.safeMul(price).safeDiv(uint256(10) ** ERC20Property(target_token).decimals());
        uint256 h =
            ri.highest_amount.safeMul(ri.highest_price).safeDiv(uint256(10) ** ERC20Property(target_token).decimals());

        //require(price >= ri.highest_price, "price too low");
        require(t >= h.safeMul(ratio_base + minimal_bumpup).safeDiv(ratio_base), "total payment bump up too small");
        require(amount <= IERC20(target_token).balanceOf(bank), "bank doesn't have enough token");

        if (ri.highest_sender != address(0x0)) {
            IERC20(recv_token).safeTransfer(ri.highest_sender, h);
            emit BidExceeded(ri.highest_sender, h, t);
        }
        emit PlaceAuction(msg.sender, amount, price, ri.highest_sender, ri.highest_amount, ri.highest_price);

        IERC20(recv_token).safeTransferFrom(msg.sender, address(this), t);
        ri.last_auction_block = block.number;
        ri.highest_price = price;
        ri.highest_amount = amount;
        ri.highest_sender = payable(msg.sender);
        ri.settled = false;
        return true;
    }

    event AuctionDone(address bidder, uint256 price, uint256 amount);

    function _end_current_auction() internal {
        round_info storage ri = all_rounds[all_rounds.length - 1];
        if (ri.settled) return;
        //require(ri.settled == false, "already settled");
        ri.settled = true;
        TokenBankInterface(bank).issue(target_token, ri.highest_sender, ri.highest_amount);
        IERC20(recv_token).safeTransfer(
            yield_pool,
            ri.highest_price.safeMul(ri.highest_amount).safeDiv(uint256(10) ** ERC20Property(target_token).decimals())
        );
        emit AuctionDone(ri.highest_sender, ri.highest_price, ri.highest_amount);
    }

    function end_current_auction() public {
        if (all_rounds.length == 0) {
            return;
        }
        round_info storage ri = all_rounds[all_rounds.length - 1];
        if (ri.settled) {
            return;
        }
        require(block.number > ri.last_auction_block.safeAdd(last_duration_in_blocknum), "not ready to end");
        _end_current_auction();
    }

    function pause_auction() public onlyOwner {
        _end_current_auction();
        paused = true;
    }

    function resume_auction() public onlyOwner {
        paused = false;
    }

    event SetStartPrice(uint256 start_price);

    function set_start_price(uint256 _start_price) public onlyOwner {
        start_price = _start_price;
        emit SetStartPrice(start_price);
    }

    event SetMinimalAmount(uint256 minimal_amount);

    function set_minimal_amount(uint256 _minimal_amount) public onlyOwner {
        minimal_amount = _minimal_amount;
        emit SetMinimalAmount(minimal_amount);
    }

    event SetMinimalBumpup(uint256 minimal_bumpup);

    function set_minimal_bumpup(uint256 _minimal_bumpup) public onlyOwner {
        minimal_bumpup = _minimal_bumpup;
        emit SetMinimalBumpup(minimal_bumpup);
    }

    event SetDuration(uint256 last_duration_in_blocknum);

    function set_duration(uint256 _last_duration_in_blocknum) public onlyOwner {
        last_duration_in_blocknum = _last_duration_in_blocknum;
        emit SetDuration(last_duration_in_blocknum);
    }

    event ChangeYieldPool(address yield_pool);

    function change_yield_pool(address _yield_pool) public onlyOwner {
        yield_pool = _yield_pool;
        emit ChangeYieldPool(yield_pool);
    }

    event ChangeBank(address bank);

    function change_bank(address _bank) public onlyOwner {
        bank = _bank;
        emit ChangeBank(bank);
    }

    function get_current_auction_round() public view returns (uint256) {
        return all_rounds.length;
    }

    function get_current_auction_info()
        public
        view
        returns (
            uint256 last_auction_block,
            uint256 highest_price,
            uint256 highest_amount,
            address payable highest_sender
        )
    {
        return get_auction_info(get_current_auction_round() - 1);
    }

    function get_auction_info(uint256 index)
        public
        view
        returns (
            uint256 last_auction_block,
            uint256 highest_price,
            uint256 highest_amount,
            address payable highest_sender
        )
    {
        round_info storage ri = all_rounds[index];
        last_auction_block = ri.last_auction_block;
        highest_price = ri.highest_price;
        highest_amount = ri.highest_amount;
        highest_sender = ri.highest_sender;
    }
}