// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract LollipopCoin is Ownable, ERC20Burnable {
    // Total supply is 420.69 trillion
    uint256 public constant INITIAL_TOTAL_SUPPLY = 420_690_000_000_000 ether;

    // LOLLIs are not transferable until launch time
    uint256 public launchTime;

    // Whitelist and blacklist
    mapping(address => bool) public whitelist;
    mapping(address => bool) public blacklist;

    modifier canTransfer(address _from, address _to) {
        if (!whitelist[_from]) {
            require(launched(), "LollipopCoin: Not launched yet");
            require(!blacklist[_from] && !blacklist[_to], "LollipopCoin: Blacklisted");
        }
        _;
    }

    constructor() ERC20("LollipopCoin", "LOLLI") {
        _mint(msg.sender, INITIAL_TOTAL_SUPPLY);
        whitelist[msg.sender] = true;
    }

    // Override _transfer to add the canTransfer modifier
    function _transfer(address _from, address _to, uint256 _amount) internal override canTransfer(_from, _to) {
        super._transfer(_from, _to, _amount);
    }

    // Returns true if the launch time has passed
    function launched() public view returns (bool) {
        return launchTime != 0 && block.timestamp >= launchTime;
    }

    // Set the launch time
    function setLaunchTime(uint256 _launchTime) external onlyOwner {
        require(launchTime == 0, "LollipopCoin: Launch time already set");
        launchTime = _launchTime;
    }

    // Update the whitelist
    function updateWhitelist(address _address, bool _whitelisted) external onlyOwner {
        whitelist[_address] = _whitelisted;
    }

    // Update the blacklist
    function updateBlacklist(address _address, bool _blacklisted) external onlyOwner {
        blacklist[_address] = _blacklisted;
    }
}