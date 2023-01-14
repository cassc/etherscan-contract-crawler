// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract ZippToken is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    address public constant deadWallet =
        0x000000000000000000000000000000000000dEaD;
    mapping(address => bool) public _isBlacklisted;
    address public mintMaster;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    function initialize() external virtual initializer {
        __Ownable_init();
        __ERC20_init("xZipp Token", "xZIPP");
          mintMaster = owner(); // initial owner = mintmaster (set to piston race contract later)
    }

    function mint(address _to, uint256 _amount) external {
        require(msg.sender == mintMaster); // only allowed for mint master
        _mint(_to, _amount);
    }

    receive() external payable {}

    function transferBnb() external onlyOwner {
        // withdraw accidentally sent bnb
        payable(owner()).transfer(address(this).balance);
    }

    function blacklistAddress(address account, bool value) external onlyOwner {
        _isBlacklisted[account] = value;
    }

    function setMintMasterAddress(address _value) external {
        require(
            msg.sender == mintMaster,
            "only the current mint master is allowed to do this"
        );
        mintMaster = _value;
    }
}