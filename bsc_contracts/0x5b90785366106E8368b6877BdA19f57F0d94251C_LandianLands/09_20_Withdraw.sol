// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Withdraw is Ownable {
    string public baseTokenURI = "https://nftslands.landian.io/api/"; // The base link that leads to the image / video of the token
    bool public saleActive = true; // Starting and stopping sale, presale and whitelist
    address public addressLnda = 0x5F841172399c5f94b1f8390bb361890fe0ca1857; // Address of the Lnda contract
    uint public price = 90000000000000000000; // Price of the token in wei

    /// @dev windraw the funds native
    function WithdrawOwnerNative(uint256 amount) external payable onlyOwner {
        require(
            payable(address(_msgSender())).send(amount),
            "Withdraw Owner Native: Failed to transfer token to fee contract"
        );
    }

    /// @dev windraw the funds native
    function WithdrawTokenOnwer(address _token, uint256 _amount)
        external
        onlyOwner
    {
        require(
            IERC20(_token).transfer(_msgSender(), _amount),
            "WithdrawTokenOnwer: Failed to transfer token to Onwer"
        );
    }

    /// @dev  set the address of the Lnda contract
    function setAddressLnda(address addr) public onlyOwner {
        addressLnda = addr;
    }

    /// @dev Start and stop sale
    function setSaleActive(bool val) public onlyOwner {
        saleActive = val;
    }

    /// @dev  Set a different price in case ETH changes drastically
    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    /// @dev Set new baseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }
}