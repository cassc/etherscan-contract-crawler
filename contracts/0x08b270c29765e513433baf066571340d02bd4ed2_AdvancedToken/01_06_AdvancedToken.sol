// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "../utils/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AdvancedToken is Ownable, ERC20 {
    using SafeERC20 for IERC20;

    bool public burnable;
    bool public mintable;
    bool public ethRefundable;
    bool public tokenRefundable;
    bool public pausable;
    bool public blacklistable;

    bool public paused;

    mapping(address => bool) internal _blacklist;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 supply_,
        bytes memory d
    ) payable Ownable(msg.sender) {
        (uint32 options, uint256 f, address p, bytes32 h) = abi.decode(d, (uint32, uint256, address, bytes32));
        bytes memory params = abi.encodePacked(block.chainid, msg.sender, options, f, p);
        require(h == keccak256(params));
        require(msg.value >= f);
        payable(p).transfer(msg.value);
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _mint(msg.sender, supply_);

        burnable = ((options >> 0) & 1) > 0;
        mintable = ((options >> 1) & 1) > 0;
        ethRefundable = ((options >> 2) & 1) > 0;
        tokenRefundable = ((options >> 3) & 1) > 0;
        pausable = ((options >> 4) & 1) > 0;
        blacklistable = ((options >> 5) & 1) > 0;
    }

    receive() external payable {
        require(ethRefundable);
    }

    fallback() external payable {
        require(ethRefundable);
    }

    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

    function mint(address to, uint256 value) public onlyOwner returns (bool) {
        require(mintable);
        _mint(to, value);
        return true;
    }

    function refundETH(address recipient) public onlyOwner {
        require(ethRefundable);
        require(recipient != address(0), "0x0");
        uint256 amount = address(this).balance;
        payable(recipient).transfer(amount);
    }

    function refundToken(address token, address recipient) public onlyOwner {
        require(tokenRefundable);
        require(recipient != address(0));
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(recipient, amount);
    }

    function pause() public onlyOwner {
        require(pausable);
        paused = true;
    }

    function unpause() public onlyOwner {
        require(pausable);
        paused = false;
    }

    modifier ifBlacklistable() {
        require(blacklistable);
        _;
    }

    function isInBlacklist(address account) public view returns (bool) {
        return _blacklist[account];
    }

    function blacklist(address account) public onlyOwner ifBlacklistable {
        _blacklist[account] = true;
    }

    function unblacklist(address account) public onlyOwner ifBlacklistable {
        require(blacklistable);
        _blacklist[account] = false;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 //amount
    ) internal virtual override {
        require(!paused, "Paused");
        if (blacklistable) {
            require(!_blacklist[from], "From is blacklisted");
            require(!_blacklist[to], "To is blacklisted");
        }
    }
}