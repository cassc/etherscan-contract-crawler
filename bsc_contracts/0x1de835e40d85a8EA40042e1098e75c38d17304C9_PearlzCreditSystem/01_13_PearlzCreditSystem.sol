// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./IPearlzCreditSystem.sol";
import "./ITokensRecoverable.sol";

contract PearlzCreditSystem is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable ;
    using AddressUpgradeable for address;

    address public constant deadWallet =
        0x000000000000000000000000000000000000dEaD;
    address public paymentToken;
    mapping(address => uint256) public availableClaim;

    function initialize() external virtual initializer {
        __Ownable_init();
        paymentToken = address(0x5A56EbB676C48B58aC8507Ff2e9396CC84950f22); // prlz token address
    }

    function setPaymentToken(address _paymentToken) public onlyOwner {
        paymentToken = _paymentToken;
    }

    function creditAccounts(
        address[] calldata addrs,
        uint256[] calldata amounts,
        uint256 totalAmount
    ) public onlyOwner {
        require(IERC20Upgradeable(paymentToken).balanceOf(owner()) >= totalAmount);
        for (uint256 i = 0; i < addrs.length; i++) {
            availableClaim[addrs[i]] += amounts[i];
        }
        IERC20Upgradeable(paymentToken).transferFrom(msg.sender, address(this), totalAmount);
    }

    function claimPayout() public nonReentrant {
        uint256 amount = availableClaim[msg.sender];
        require(availableClaim[msg.sender] > 0, "No payout available");
        availableClaim[msg.sender] = 0;

        IERC20Upgradeable(paymentToken).transfer(msg.sender, amount);
    }

    function recoverTokens(IERC20Upgradeable token) public onlyOwner 
    {
        require (canRecoverTokens(token));
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    function canRecoverTokens(IERC20Upgradeable token) internal virtual view returns (bool) 
    { 
        return address(token) != address(this); 
    }
}