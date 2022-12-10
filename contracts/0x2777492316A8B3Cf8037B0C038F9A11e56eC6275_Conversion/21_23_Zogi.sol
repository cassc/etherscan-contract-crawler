// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../accessControl/AccessProtected.sol";
import "../interfaces/IZogi.sol";

contract ZOGI is ERC20Snapshot, Pausable,AccessProtected,IZOGI {

    mapping(address => bool) _blacklist;
    
    event BlacklistUpdated(address indexed user, bool value);
    
    constructor() ERC20("Zogi","ZOGI") {
    }

    function mint(address account_, uint256 amount_) external whenNotPaused onlyAdmin{
        require(account_!= address(0), "ZOGI: Invalid address");
        _mint(account_, amount_);
        emit Mint(account_, amount_);
    }

    function burn(uint256 amount_) external whenNotPaused{
        require(balanceOf(msg.sender) >= amount_, "Not enough Zogi");
        _burn(msg.sender, amount_);
        emit Burn(msg.sender, amount_);
    }

    function blacklistUpdate(address user, bool value) external onlyOwner {
        require(user != owner(), "Owner can not be blacklisted");
        _blacklist[user] = value;
        emit BlacklistUpdated(user, value);
    }

    function renounceOwnership() public view override onlyOwner {
        revert("can't renounceOwnership here");
    }

    function transfer(address recipient, uint256 amount) public whenNotPaused override(ERC20,IERC20) returns (bool) {
        require (!isBlackListed(msg.sender), "Token transfer refused because Sender is on blacklist");
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address from,address to,uint256 amount) public whenNotPaused virtual override(ERC20,IERC20) returns (bool) {
        require (!isBlackListed(_msgSender()), "Token transfer refused because Sender is on blacklist");

        address spender = _msgSender();

        if(spender == owner() && isBlackListed(from)) {
            _transfer(from, to, amount);
            return true;
        } else {
            require (!isBlackListed(from), "Token transfer refused because Sender is on blacklist");
            _spendAllowance(from, spender, amount);
            _transfer(from, to, amount);
            return true;
        }
    }

    function allowance(address ownerAddress, address spender) public view virtual override(ERC20,IERC20) returns (uint256) {
        if (isBlackListed(spender) || isBlackListed(ownerAddress)) {
            return 0;
         }
        return super.allowance(ownerAddress, spender);
    }
    
    function isBlackListed(address user) public view returns (bool) {
        return _blacklist[user];
    }

    function snapShot()external onlyOwner returns (uint256){
        return _snapshot();
    }

    function getCurrentSnapshotId()external view returns (uint256){
        return _getCurrentSnapshotId();
    }

    function pause()external onlyOwner{
        _pause();
    }

    function unpause()external onlyOwner{
        _unpause();
    }

}