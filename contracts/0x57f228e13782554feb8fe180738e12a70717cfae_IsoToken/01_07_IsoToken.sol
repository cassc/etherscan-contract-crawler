// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract IsoToken is ERC20, ERC20Burnable, Ownable {
    uint256 constant CAP = 3000000000 * 10 ** 18;
    uint256 public treasuryClaimed = 0;
    uint8 public reserveRate = 10;
    mapping(address => bool) public controllers;

    address public isoTreasury;
    bool public freezeControllers = false;
    bool public freezeReserveRate = false;

    constructor() ERC20("isotoken", "ISO") {
        isoTreasury = msg.sender;
    }

    function onFreezeController() external onlyOwner {
        freezeControllers = true;
    }

    function onFreezeReserveRate() external onlyOwner {
        freezeReserveRate = true;
    }

    function addController(address controller) external onlyOwner {
        require(!freezeControllers, "Controller freezed");
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

    function setReserveRate(uint8 _reserveRate) external onlyOwner {
        require(!freezeReserveRate, "Reserve rate freezed");
        reserveRate = _reserveRate;
    }

    function setTreasuryAddress(address _address) external onlyOwner {
        isoTreasury = _address;
    }

    function mint(address to, uint256 amount) external {
        require(totalSupply() + amount <= CAP, "Limit exceeded");
        require(controllers[msg.sender], "Only controllers can mint");
        _mint(to, amount);
    }

    function treasuryClaim() external {
        uint256 currentTs = totalSupply();
        require(currentTs > treasuryClaimed, "All claimed");
        uint256 allowToClaim = (currentTs - treasuryClaimed) * reserveRate / 100;
        _mint(isoTreasury, allowToClaim);
        treasuryClaimed = totalSupply();
    }
}