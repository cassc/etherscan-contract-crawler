// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/*
 * Pre Sale Contract
 */
contract IncomePresale is Ownable {
    using SafeMath for uint256;

    address public saleToken;
    address public marketingWallet;
    uint256 public tokensPerUnit;

    mapping(address => uint256) public userContribution;

    constructor() Ownable() {
        saleToken = 0x75Ef7e9028798B4deaa10Ac8348dFE70b770325c;
        marketingWallet = 0xF007f7382850A8846902bA1217A3877834158B77;
        tokensPerUnit = 34500; // SET AS RAW NUMBER, NOT AS WEI
    }

    receive() external payable {
        processContribution(msg.sender, msg.value);
        payable(marketingWallet).transfer(address(this).balance);
    }

    /*
     * Admin Functions
     */
    function returnUnusedTokens() external onlyOwner {
        IERC20(saleToken).transfer(
            msg.sender,
            IERC20(saleToken).balanceOf(address(this))
        );
    }

    function collectSaleFunds() external onlyOwner {
        payable(marketingWallet).transfer(address(this).balance);
    }

    function removeWrongTokens(address token_) external onlyOwner {
        IERC20(token_).transfer(
            msg.sender,
            IERC20(token_).balanceOf(address(this))
        );
    }

    /*
     * Basic Contract Functions
     */
    function processContribution(address wallet_, uint256 amount_) internal {
        require(
            amount_.mul(tokensPerUnit) <=
                IERC20(saleToken).balanceOf(address(this)),
            "Not enough tokens remain"
        );

        bool tokensSent = IERC20(saleToken).transfer(
            msg.sender,
            amount_.mul(tokensPerUnit)
        );

        if (tokensSent) {
            userContribution[wallet_] += amount_;
        }
    }

    function updateSaleToken(address _saleToken) external onlyOwner {
        saleToken = _saleToken;
    }

    function updateMarketingWallet(
        address _marketingWallet
    ) external onlyOwner {
        marketingWallet = _marketingWallet;
    }

    function updateTokenPerUnit(uint256 _tokensPerUnit) external onlyOwner {
        tokensPerUnit = _tokensPerUnit;
    }
}