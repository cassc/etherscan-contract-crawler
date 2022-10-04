// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Ownable} from "@oz/access/Ownable.sol";
import {Pausable} from "@oz/security/Pausable.sol";
import {IERC20} from "@oz/token/ERC20/IERC20.sol";
import {ITearToken} from "./interfaces/ITearToken.sol";
import {IUniswapV2Pair} from "./interfaces/uniswapv2/IUniswapV2Pair.sol";
import {IUniswapV2Router01} from "./interfaces/uniswapv2/IUniswapV2Router01.sol";
import {PriceAggregatorV2} from "./PriceAggregatorV2.sol";
import "@std/console.sol";

/**
 * MMMMMW0dxxxdkXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMM0cdKNNKloXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMKolk00kloXMWNK0KKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMXkxxddkXWKdoddxxxxkOKXXXNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMWWMMMXllO000KKKOkxxxxkkkkkkkkkO0KNWMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMKccO000000KKXNNNNNNNXXXK0OkkkkkkOKNMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMN0xocck0000000000KKKKXXXNNNNWWWWNX0kkkkOKWMMMMMMMMMMMMMMMMM
 * MMMMMMMMWXkoodkOOO00000000000000000000KKXXNNWWWMWXOxxk0NMMMMMMMMMMMMMM
 * MMMMMMWKxlokO000000000000000000000000000000KXWMMMMMMN0kxkKWMMMMMMMMMMM
 * MMMMMXxlok0000000000000000000000000000000000KNMMMMMMMMMN0xxONMMMMMMMMM
 * MMMW0ook0000000000000000000000000000000000000XWMMMMMMMMMMWKxdONMMMMMMM
 * MMWkldO000000000000000000000000000000000000000KXNWMMWNNWMMMWKxd0WMMMMM
 * MNxcx00000000000000000000000000000000000000000000KXOc,':ONWWMW0dkNMMMM
 * Wkcd0000000000000000Oo;,:dO00000000000000000000000d.    .oXWWMMXxdKMMM
 * KloO000000000000000k;    .:k000000000000000000000O:    ;'.dNNWWMNxoKMM
 * dck000000000000000Oc    '..lO00000000000000000000O:       ;KNNWWMNxoXM
 * lo0000000000000000x'   .:;.;k00000000000000000000Ol.      'ONNNWWMXdxN
 * cd0000000000000000x'       ,k000000000000000000000x'      .xNNNNWWM0o0
 * cd0000000000000000x'       ;O000000000000000000000Oo.     ;kXNNNNWMNdd
 * cd0000000000000000k;      .lO0000000000000000000000Od:'.,ck0KXNNNWWWko
 * olO0000000000000000d'     'x000000000000000O0000000000Okxk000XNNNNWMOl
 * kcx00000000000000000x:...;xOOxkO00000OOxolc::cclooodolccok000KNNNNWMOl
 * XolO00000000000000000OkkkO00kollccclcc:;,,;;;;,,,,,'.,lk00000KNNNNWMko
 * M0loO0000000000000000000000000Oko:,''',,,,,,,,,,,;;:okO000000KNNNNWWxd
 * MWOloO000000000000000000000000000OkkxdddddddoodddxkO000000000XNNNWMKoO
 * MMW0lok00000000000000000000000000000000000000000000000000000KXNNWWNddN
 * MMMMXdlxO000000000000000000000000000000000000000000000000000XNNNWNxdXM
 * MMMMMWOolxO000000000000000000000000000000000000000000000000KNNNWKxdKMM
 * MMMMMMMNOoldO000000000000000000000000000000000000000000000KNNNXkdkNMMM
 * MMMMMMMMMN0dooxO00000000000000000000000000000000000000000KXKkxdkXWMMMM
 * MMMMMMMMMMMWXOxdooxkO0000000000000000000000000000000Okxxdxxxk0NMMMMMMM
 * MMMMMMMMMMMMMMMNKOxdddoooddxxxxkkkkkkkxxxxxddddoooodddxkOKNWMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMWNKOxdollccccccccccccccccllodxk0KNWMMMMMMMMMMMMMMMM
 *
 * @title TearSwapV2
 * @custom:website www.descend.gg
 * @custom:version 2
 * @author Lozz (@lozzereth / www.allthingsweb3.com)
 * @notice Contract that enables allows the exchange of one ERC20 token
 *         for another, provided that there is a valid exchange rate. This
 *         version allows us to forcefully send 40% to partners and pull an
 *         exchange rate from a UniSwap/SushiSwap liquidity pool.
 */
contract TearSwapV2 is PriceAggregatorV2, Pausable, Ownable {
    /// @notice Contract for $TEAR
    ITearToken public immutable tearContract;

    /// @notice Carry the exchange information
    struct ExchangeRate {
        uint256 rate;
        IUniswapV2Pair pair;
        address receiver;
        uint256 received;
        uint256 markup;
        uint256 rounding;
    }

    /// @notice Exchange rate for the swap
    mapping(IERC20 => ExchangeRate) public exchangeableErc20;

    /// @notice Destination address for the receiving tokens
    address public destinationAddress;

    /// @notice SLIME $ERC20 Token used for Peg
    IERC20 public immutable slimeAddress;

    /// @notice Expected amount of $TEAR is not the actual amount
    error InvalidSwap(uint256 expected, uint256 actual);

    /// @notice Non-receiver or not a contract owner
    error UnauthorizedUpdate();

    /// @notice Pair does not exist
    error PairDoesNotExist();

    /// @notice Base token is immutable and cannot be uopdated
    error UpdateBaseTokenProhibited();

    constructor(
        IERC20 slimeAddress_,
        ITearToken tearContract_,
        IUniswapV2Router01 uniswapV2Router_,
        IUniswapV2Router01 sushiswapRouter_,
        address destinationAddress_
    ) PriceAggregatorV2(uniswapV2Router_, sushiswapRouter_) {
        slimeAddress = slimeAddress_;
        tearContract = tearContract_;
        destinationAddress = destinationAddress_;
    }

    /**
     * @notice Swap ERC20 tokens for $TEAR tokens
     * @param contract_ ERC20 contract to swap tokens
     * @param amount Amount of ERC20 coins
     */
    function swap(IERC20 contract_, uint256 amount) public whenNotPaused {
        uint256 exchangeRate = exchangeableErc20[contract_].rate;
        if (exchangeRate == 0) {
            revert InvalidSwap(amount, 0);
        }
        uint256 tearAmount = amount / exchangeRate;
        uint256 slimeAmount = tearAmount * exchangeRate;
        if (slimeAmount != amount) {
            revert InvalidSwap(slimeAmount, amount);
        }
        _fairlyDistribute(contract_, amount);
        ITearToken(tearContract).eoaMint(msg.sender, tearAmount);
    }

    /**
     * @notice Fairly distribute at least 40% of the tokens back to the partner.
     *         The rest will be manually distributed according to agreements.
     * @param contract_ ERC20 Contract Address
     * @param amount Amount to distribute
     */
    function _fairlyDistribute(IERC20 contract_, uint256 amount) private {
        ExchangeRate storage exchange = exchangeableErc20[contract_];
        if (exchange.receiver == destinationAddress) {
            IERC20(contract_).transferFrom(
                msg.sender,
                destinationAddress,
                amount
            );
        } else {
            IERC20(contract_).transferFrom(
                msg.sender,
                exchange.receiver,
                (amount * 40) / 100
            );
            IERC20(contract_).transferFrom(
                msg.sender,
                destinationAddress,
                (amount * 60) / 100
            );
        }
        exchange.received += amount;
    }

    /**
     * @notice Update the exchange rate between the partner according to LP.
     * @dev Intended to be publically updated for trustlessness.
     * @param contract_ ERC20 Contract Address
     */
    function updateExchangeRate(IERC20 contract_) public {
        if (contract_ == slimeAddress) {
            revert UpdateBaseTokenProhibited();
        }
        ExchangeRate storage exchangable = exchangeableErc20[contract_];
        if (exchangable.pair == IUniswapV2Pair(address(0))) {
            revert PairDoesNotExist();
        }
        if (exchangable.receiver != msg.sender && msg.sender != owner()) {
            revert UnauthorizedUpdate();
        }
        ExchangeRate memory slime = exchangeableErc20[slimeAddress];
        uint256 exchangeRate = findPairEquivalentToPairV2(
            slime.rate,
            exchangable.markup,
            slime.pair,
            exchangable.pair
        );
        if (exchangable.rate == 0) {
            revert NonZeroNumberRequired();
        }
        exchangable.rate =
            (exchangeRate / exchangable.rounding) *
            exchangable.rounding;
    }

    /**
     * @notice Set the exchange rate for ERC20 to $TEAR
     * @param address_ ERC20 contract address
     * @param pair UniSwap/SushiSwap pair
     * @param rate Rate in wei
     */
    function upsertExchangeableERC20(
        IERC20 address_,
        IUniswapV2Pair pair,
        address receiver,
        uint256 rate,
        uint256 markup,
        uint256 rounding
    ) external onlyOwner {
        if (rounding == 0) {
            revert NonZeroNumberRequired();
        }
        exchangeableErc20[address_] = ExchangeRate({
            rate: rate,
            pair: pair,
            receiver: receiver,
            received: exchangeableErc20[address_].received,
            markup: markup,
            rounding: rounding
        });
    }

    /**
     * @notice Set the destination address for the tokens
     * @param destinationAddress_ Destination address for all the tokens
     */
    function setDestinationAddress(address destinationAddress_)
        external
        onlyOwner
    {
        destinationAddress = destinationAddress_;
    }

    /**
     * @notice Toggle paused state of the contract
     */
    function togglePause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }
}