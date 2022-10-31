// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../dependencies/open-zeppelin/token/ERC20/ERC20.sol";
import "../dependencies/open-zeppelin/access/Ownable.sol";

contract xBybetToken is ERC20, Ownable {
    mapping(address => bool) public _whitelist;

    modifier onlyWhitelistMember() {
      if (!_whitelist[msg.sender]) {
        revert();
      }    
      _;
    }

    constructor() ERC20("X Bybet", "xBT") {
        _whitelist[msg.sender] = true;
    }

    function addToWhitelist(address account) public onlyOwner {
        _whitelist[account] = true;
    }

    function removeFromWhitelist(address account) public onlyOwner {
        _whitelist[account] = false;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);
    }

    function mint(address account, uint256 amount) public onlyWhitelistMember {
        _mint(account, amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        revert("Token cannot transfer.");
        return super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        revert("Token cannot transfer.");
        return super.transferFrom(sender, recipient, amount);
    }

    function burn(address account, uint256 amount) public onlyWhitelistMember {
        _burn(account, amount);
    }

    /* ========== EMERGENCY ========== */
    function emergencySupport(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }
}