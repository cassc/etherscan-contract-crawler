// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "./interfaces/EventfulMarket.sol";
import "./libraries/DSMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IERC20Custom.sol";
import "@uniswap/v2-periphery/interfaces/IUniswapV2Router02.sol";
import "./interfaces/IWETH9.sol";
import "./interfaces/IveSCH.sol";

contract SimpleMarket is EventfulMarket, DSMath {

    uint public last_offer_id;

    mapping (uint => OfferInfo) public offers;

    IUniswapV2Router02 public router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address public treasury = 0x496CA1523D6Afb85c9368e8F1146404fB14932Fa;

    IveSCH public vesch;

    bool locked;

    struct OfferInfo {
        uint     pay_amt;
        IERC20    pay_gem;
        uint     buy_amt;
        IERC20    buy_gem;
        address  owner;
        uint64   timestamp;
    }

    modifier can_buy(uint id) {
        require(isActive(id));
        _;
    }

    modifier can_cancel(uint id) virtual {
        require(isActive(id));
        require(getOwner(id) == msg.sender);
        _;
    }

    modifier can_offer {
        _;
    }

    modifier synchronized {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

    function isActive(uint id) public view returns (bool active) {
        return offers[id].timestamp > 0;
    }

    function getOwner(uint id) public view returns (address owner) {
        return offers[id].owner;
    }

    function getOffer(uint id) public view returns (uint, IERC20, uint, IERC20) {
      OfferInfo memory _offer = offers[id];
      return (_offer.pay_amt, _offer.pay_gem,
              _offer.buy_amt, _offer.buy_gem);
    }

    // ---- Public entrypoints ---- //

    function bump(bytes32 id_)
        public
        can_buy(uint256(id_))
    {
        uint256 id = uint256(id_);
        emit LogBump(
            id_,
            keccak256(abi.encodePacked(offers[id].pay_gem, offers[id].buy_gem)),
            offers[id].owner,
            offers[id].pay_gem,
            offers[id].buy_gem,
            uint128(offers[id].pay_amt),
            uint128(offers[id].buy_amt),
            offers[id].timestamp
        );
    }

    // Accept given `quantity` of an offer. Transfers funds from caller to
    // offer maker, and from market to caller.
    function buy(uint id, uint quantity)
        public
        can_buy(id)
        synchronized
        virtual
        returns (bool)
    {
        OfferInfo memory _offer = offers[id];
        uint spend = mul(quantity, _offer.buy_amt) / _offer.pay_amt;

        require(uint128(spend) == spend);
        require(uint128(quantity) == quantity);

        // For backwards semantic compatibility.
        if (quantity == 0 || spend == 0 ||
            quantity > _offer.pay_amt || spend > _offer.buy_amt)
        {
            return false;
        }

        offers[id].pay_amt = sub(_offer.pay_amt, quantity);
        offers[id].buy_amt = sub(_offer.buy_amt, spend);
        uint fee = spend * 10 / 10000;
        safeTransferFrom(_offer.buy_gem, msg.sender, _offer.owner, spend - fee);
        if (fee > 0) {
            safeTransferFrom(_offer.buy_gem, msg.sender, address(this), fee);
        }
        safeTransfer(_offer.pay_gem, msg.sender, quantity);
        address __offer_buy_gem = address(_offer.buy_gem);
        if (__offer_buy_gem == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) { // WETH
            IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).withdraw(fee);
            vesch.depositFees{value: fee * 5000 / 10000}(fee * 5000 / 10000, 4);
            vesch.depositFees{value: fee * 3500 / 10000}(fee * 3500 / 10000, 3);
            vesch.depositFees{value: fee * 1000 / 10000}(fee * 1000 / 10000, 2);
            vesch.depositFees{value: fee * 500 / 10000}(fee * 500 / 10000, 1);
        } else if (
            __offer_buy_gem == 0xdAC17F958D2ee523a2206206994597C13D831ec7 || // USDT
            __offer_buy_gem == 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 || // USDC
            __offer_buy_gem == 0x6B175474E89094C44Da98b954EedeAC495271d0F || // DAI
            __offer_buy_gem == 0x4Fabb145d64652a948d72533023f6E7A623C7C53    // BUSD
        ) {
            address[] memory path = new address[](2);
            path[0] = __offer_buy_gem;
            path[1] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
            IERC20Custom(__offer_buy_gem).approve(address(router), type(uint).max);
            uint256 snapshot = address(this).balance;
            try router.swapExactTokensForETHSupportingFeeOnTransferTokens(fee, 0, path, address(this), block.timestamp + 600) {
                uint256 yield = address(this).balance - snapshot;
                if (yield > 0) {
                    vesch.depositFees{value: yield * 5000 / 10000}(yield * 5000 / 10000, 4);
                    vesch.depositFees{value: yield * 3500 / 10000}(yield * 3500 / 10000, 3);
                    vesch.depositFees{value: yield * 1000 / 10000}(yield * 1000 / 10000, 2);
                    vesch.depositFees{value: yield * 500 / 10000}(yield * 500 / 10000, 1);
                }
            } catch {
                safeTransfer(_offer.buy_gem, treasury, fee);
            }
        } else {
            safeTransfer(_offer.buy_gem, treasury, fee);
        }

        emit LogItemUpdate(id);
        emit LogTake(
            bytes32(id),
            keccak256(abi.encodePacked(_offer.pay_gem, _offer.buy_gem)),
            _offer.owner,
            _offer.pay_gem,
            _offer.buy_gem,
            msg.sender,
            uint128(quantity),
            uint128(spend),
            uint64(block.timestamp)
        );
        emit LogTrade(quantity, address(_offer.pay_gem), spend, address(_offer.buy_gem));

        if (offers[id].pay_amt == 0) {
          delete offers[id];
        }

        return true;
    }

    // Cancel an offer. Refunds offer maker.
    function cancel(uint id)
        public
        can_cancel(id)
        synchronized
        virtual
        returns (bool success)
    {
        // read-only offer. Modify an offer by directly accessing offers[id]
        OfferInfo memory _offer = offers[id];
        delete offers[id];

        safeTransfer(_offer.pay_gem, _offer.owner, _offer.pay_amt);

        emit LogItemUpdate(id);
        emit LogKill(
            bytes32(id),
            keccak256(abi.encodePacked(_offer.pay_gem, _offer.buy_gem)),
            _offer.owner,
            _offer.pay_gem,
            _offer.buy_gem,
            uint128(_offer.pay_amt),
            uint128(_offer.buy_amt),
            uint64(block.timestamp)
        );

        success = true;
    }

    function kill(bytes32 id)
        public
        virtual
    {
        require(cancel(uint256(id)));
    }

    function make(
        IERC20    pay_gem,
        IERC20    buy_gem,
        uint128  pay_amt,
        uint128  buy_amt
    )
        public
        virtual
        returns (bytes32 id)
    {
        return bytes32(offer(pay_amt, pay_gem, buy_amt, buy_gem));
    }

    // Make a new offer. Takes funds from the caller into market escrow.
    function offer(uint pay_amt, IERC20 pay_gem, uint buy_amt, IERC20 buy_gem)
        public
        can_offer
        synchronized
        virtual
        returns (uint id)
    {
        require(uint128(pay_amt) == pay_amt);
        require(uint128(buy_amt) == buy_amt);
        require(pay_amt > 0);
        require(pay_gem != IERC20(address(0)));
        require(buy_amt > 0);
        require(buy_gem != IERC20(address(0)));
        require(pay_gem != buy_gem);

        OfferInfo memory info;
        info.pay_amt = pay_amt;
        info.pay_gem = pay_gem;
        info.buy_amt = buy_amt;
        info.buy_gem = buy_gem;
        info.owner = msg.sender;
        info.timestamp = uint64(block.timestamp);
        id = _next_id();
        offers[id] = info;

        safeTransferFrom(pay_gem, msg.sender, address(this), pay_amt);

        emit LogItemUpdate(id);
        emit LogMake(
            bytes32(id),
            keccak256(abi.encodePacked(pay_gem, buy_gem)),
            msg.sender,
            pay_gem,
            buy_gem,
            uint128(pay_amt),
            uint128(buy_amt),
            uint64(block.timestamp)
        );
    }

    function take(bytes32 id, uint128 maxTakeAmount)
        public
        virtual
    {
        require(buy(uint256(id), maxTakeAmount));
    }

    function _next_id()
        internal
        returns (uint)
    {
        last_offer_id++; return last_offer_id;
    }

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        uint256 size;
        assembly { size := extcodesize(token) }
        require(size > 0, "Not a contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "Token call failed");
        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }

    receive() external payable {}
}