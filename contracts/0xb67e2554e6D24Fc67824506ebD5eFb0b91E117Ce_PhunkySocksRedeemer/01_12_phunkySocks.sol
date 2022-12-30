// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PhunkySocksRedeemer is ERC1155, Ownable, ReentrancyGuard {

    mapping(address => uint256) public depositBalance;
    mapping(address => uint256) public redeemedBalance;
    address public socksTokenAddress;
    uint256 public socksRedeemPrice;

    constructor() ERC1155("PhunkySocks") {
        socksRedeemPrice = 22 * (10**18);
    }

    function setURI(string memory _newuri) public onlyOwner {
        _setURI(_newuri);
    }

    function setSocksTokenAddress(address _addressInput) public onlyOwner {
        socksTokenAddress = _addressInput;
    }

    function setSocksRedeemPrice(uint256 _price) public onlyOwner {
        socksRedeemPrice = _price;
    }

    function depositSocksToken() public nonReentrant {
        // ensure sufficient allowance
        require(
            IERC20(socksTokenAddress).allowance(msg.sender, address(this)) >=
                socksRedeemPrice,
            "Insufficient Allowance, Approve More"
        );

        // transfer
        bool success = IERC20(socksTokenAddress).transferFrom(
            msg.sender,
            address(this),
            socksRedeemPrice
        );

        // ensure success
        require(success, "Transfer failed");

        // increment user balance for redeem
        depositBalance[msg.sender] += 1;
    }

    function mint() public {
        // Ensure more is deposited than redeemed, default response on mappings is 0 so will fail until deposit is incremented
        require(depositBalance[msg.sender] > redeemedBalance[msg.sender], "Insufficient Deposits, Rejected");
        // Standard 1155 Mint to Sender
        _mint(msg.sender, 0, 1, "");
        // Bump redeemed balances
        redeemedBalance[msg.sender] += 1;
    }

}