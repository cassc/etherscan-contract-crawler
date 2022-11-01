// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

//import "./TokenVendor.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vendor is Ownable {
    error Vendor_TokenTransferFromFailed();
    error Vendor_TokenTransferFailed();
    /* State vars */
    uint256 public constant ITEM_PRICE = 10 * 1e6;
    uint256 public constant TOKEN_VALUE = 100 * 1e18;
    IERC20 public immutable vendorToken;
    IERC20 public immutable stableToken;

    /* events */
    //event ItemBought(address indexed sender, address indexed token, uint256 amount);
    event ItemBought(address indexed sender);

    /* Functions */
    constructor(address tokenAddress, address stableAddress) {
        vendorToken = IERC20(tokenAddress); // 18 decimals
        stableToken = IERC20(stableAddress); // 6 decimals
    }

    ///////

    function buyItem() external payable {
        //IERC20 token = IERC20(_token);
        bool transferedFrom = stableToken.transferFrom(msg.sender, owner(), ITEM_PRICE);
        if (!transferedFrom) {
            revert Vendor_TokenTransferFromFailed();
        }
        // (bool success, ) = token.call(token){""};
        bool transfered = vendorToken.transfer(msg.sender, TOKEN_VALUE);
        if (!transfered) {
            revert Vendor_TokenTransferFailed();
        }
        emit ItemBought(msg.sender);
    }

    function withdrawToken(
        address tokenAddress,
        address _to,
        uint256 amount
    ) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        //uint256 amount = token.balanceOf(address(this));
        bool transfered = token.transferFrom(_to, owner(), amount);
        if (!transfered) {
            revert Vendor_TokenTransferFailed();
        }
    }
}