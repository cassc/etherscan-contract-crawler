// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract XOXSTokenETH is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    address public treasury;

    /* ========== CONSTRUCTOR ========== */
    function initialize() public initializer {
        __Ownable_init_unchained();
        __ERC20_init_unchained("XOX Stable Coin", "XOXS");
    }

    modifier onlyTreasury() {
        require(
            msg.sender == treasury,
            "XOX Treasury: Only Treasury SC can call this function"
        );
        _;
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address _to, uint256 _amount) public onlyTreasury {
        _mint(_to, _amount);
    }

    function setTreasury(address treasury_) external onlyOwner {
        treasury = treasury_;
    }
}