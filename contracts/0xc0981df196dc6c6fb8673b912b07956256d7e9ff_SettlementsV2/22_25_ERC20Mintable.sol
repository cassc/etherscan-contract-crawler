// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SettlementsV2.sol";

contract ERC20Mintable is ERC20Burnable, Ownable {
    mapping(address => bool) public approvedMinters;
    SettlementsV2 settlements;
    uint256 public totalMinters = 0;
    bool public canToggleMints = true;

    modifier onlyMinter() {
        require(approvedMinters[msg.sender] == true, "Not an approved minter");
        _;
    }

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {
        approvedMinters[msg.sender] = true;
    }

    function setSettlementsAddress(SettlementsV2 _settlements)
        public
        onlyOwner
    {
        settlements = _settlements;
    }

    function turnOffMintGovernance() public onlyOwner {
        canToggleMints = false;
    }

    function addMinter(address minter) public onlyOwner {
        require(canToggleMints, "Minting turned off");
        totalMinters += 1;
        approvedMinters[minter] = true;
    }

    function removeMinter(address minter) public onlyOwner {
        require(canToggleMints, "Minting turned off");
        approvedMinters[minter] = false;
        totalMinters -= 1;
    }

    function mint(address to, uint256 amount) public onlyMinter {
        _mint(to, amount);
    }
}