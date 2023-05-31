// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RPLC is ERC20Permit, Ownable {
    mapping(address => bool) public minters; 

    bool preSupplyInitialized = false;

    event MinterAdded(address indexed addr);
    event MinterRemoved(address indexed addr);

    modifier onlyMinters() {
        require(
            minters[msg.sender] == true,
            "Only minters"
        );
        _;
    }

    constructor() ERC20("Republic Token", "RPLC") ERC20Permit("RPLC") {}

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function initMinters(address _bondContract, address _rewardContract)
        external
        onlyOwner
    {
        require(
            _bondContract != address(0) && _rewardContract != address(0),
            "zero addr"
        );

        minters[_bondContract] = true;
        minters[_rewardContract] = true;
    }

    function initPreSupply() external onlyOwner {
        require(preSupplyInitialized == false, "Already sent");
        preSupplyInitialized = true;

        _mint(msg.sender, 3100*10**decimals());
    }

    function addMinter(address minterAddr) external onlyOwner {
        require(minterAddr != address(0), "Zero addr");
        
        minters[minterAddr] = true;

        emit MinterAdded(minterAddr);
    }

    function removeMinter(address minterAddr) external onlyOwner {
        require(minterAddr != address(0), "Zero addr");
        
        minters[minterAddr] = false;

        emit MinterRemoved(minterAddr);
    }

    function mint(address account_, uint256 amount_) external onlyMinters {
        _mint(account_, amount_);
    }

    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account_, uint256 amount_) public virtual {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) public virtual {
        uint256 decreasedAllowance_ = allowance(account_, msg.sender) - amount_;

        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }
}