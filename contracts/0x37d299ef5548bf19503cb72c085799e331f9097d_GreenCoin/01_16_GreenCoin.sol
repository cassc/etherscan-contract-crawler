//SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./GreenVesting.sol";

contract GreenCoin is Initializable, ERC20Upgradeable, OwnableUpgradeable{
    uint256 public constant TOTAL_AMOUNT = 1 * 10 ** 9 * 10 ** 18;

    GreenVesting public vestingContract;

    function initialize(address ownerAddress) public initializer {
        __ERC20_init("GreenCoin", "GRNC");
        __Ownable_init();
        transferOwnership(ownerAddress);

        vestingContract = new GreenVesting(address(this), TOTAL_AMOUNT, ownerAddress);
        _mint(address(vestingContract), TOTAL_AMOUNT);
    }

    function batchTransfer(address[] calldata addresses, uint256[] calldata amounts) public {
        require(addresses.length == amounts.length, "Counts of addresses must be equal to amounts.");
        require(addresses.length != 0, "Counts of addresses or amounts must be more than zero.");

        for (uint8 i = 0; i < addresses.length; i++) {
            transfer(addresses[i], amounts[i]);
        }
    }

    receive() external payable {}

    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= TOTAL_AMOUNT, "Total amount cannot be more than 1 billion");
        _mint(to, amount);
    }

    function burn(uint256 amount) public onlyOwner {
        _burn(_msgSender(), amount);
    }

    function withdrawETH() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success,) = address(owner()).call{value : amount}("");
        require(success, "Transfer failed.");
    }

    function withdrawERC20(address fundsToken) public onlyOwner {
        uint256 amount = IERC20(fundsToken).balanceOf(address(this));
        IERC20(fundsToken).transfer(address(owner()), amount);
    }
}