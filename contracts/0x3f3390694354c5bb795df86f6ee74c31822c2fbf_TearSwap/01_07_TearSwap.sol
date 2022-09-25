// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Ownable} from "@oz/access/Ownable.sol";
import {Pausable} from "@oz/security/Pausable.sol";
import {IERC20} from "@oz/token/ERC20/IERC20.sol";
import {ITearToken} from "./interfaces/ITearToken.sol";

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
 * @title TearSwap
 * @custom:website www.descend.gg
 * @author Lozz (@lozzereth / www.allthingsweb3.com)
 * @notice Contract that enables allows the exchange of one ERC20 token
 *         for another, provided that there is a valid exchange rate.
 */
contract TearSwap is Pausable, Ownable {
    /// @notice Contract for $TEAR
    ITearToken public immutable tearContract;

    /// @notice Exchange rate for the swap
    mapping(IERC20 => uint256) public exchangeableErc20;

    /// @notice Destination address for the receiving tokens
    address public destinationAddress;

    /// @notice Expected amount of $TEAR is not the actual amount
    error InvalidSwap(uint256 expected, uint256 actual);

    constructor(ITearToken tearContract_) {
        tearContract = tearContract_;
        destinationAddress = 0x160cf78416e33a73C7f59043F12C8B6dA50d30D4;
    }

    /**
     * @notice Swap ERC20 tokens for $TEAR tokens
     * @param contract_ ERC20 contract to swap tokens
     * @param amount Amount of ERC20 coins
     */
    function swap(IERC20 contract_, uint256 amount) public whenNotPaused {
        uint256 exchangeRate = exchangeableErc20[contract_];
        if (exchangeRate == 0) {
            revert InvalidSwap(amount, 0);
        }
        uint256 tearAmount = amount / exchangeRate;
        uint256 slimeAmount = tearAmount * exchangeRate;
        if (slimeAmount != amount) {
            revert InvalidSwap(slimeAmount, amount);
        }
        IERC20(contract_).transferFrom(msg.sender, destinationAddress, amount);
        ITearToken(tearContract).eoaMint(msg.sender, tearAmount);
    }

    /**
     * @notice Set the exchange rate for ERC20 to $TEAR
     * @param address_ ERC20 contract address
     * @param rate Rate in wei
     */
    function setExchangeableERC20(IERC20 address_, uint256 rate)
        external
        onlyOwner
    {
        exchangeableErc20[address_] = rate;
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