// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HATE is ERC20, Ownable {

    address public treasury;

    constructor() 
    ERC20("Heavens Gate", "HATE") {}

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function setTreasury(address treasury_) external onlyOwner {
        treasury = treasury_;
    }

    function mint(address account_, uint256 amount_) external {
        require(msg.sender == treasury, "msg.sender not treasury");
        _mint(account_, amount_);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account_, uint256 amount_) external {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) internal {
        uint256 decreasedAllowance_ = allowance(account_, msg.sender) - amount_;

        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }
}