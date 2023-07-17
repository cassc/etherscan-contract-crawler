//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUniswapV2Router02.sol";

contract FrogeToken is ERC20, Ownable {
    mapping(address => uint) public cooldowns;
    mapping(address => bool) public isCooldownWhitelist;
    uint cooldownDuration;
    address public immutable uniswapRouter;
    address public immutable pair;

    constructor(address _router) ERC20("Froge", "FROGE") {
        uint initSupply = 8008580085 ether; // BOOBIES LOL!!
        _mint(owner(), initSupply);

        cooldownDuration = block.timestamp + 2 weeks;
        uniswapRouter = _router;
        IUniswapV2Router02 router = IUniswapV2Router02(_router);
        pair = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            router.WETH()
        );
        isCooldownWhitelist[pair] = true;
        isCooldownWhitelist[address(router)] = true;
        isCooldownWhitelist[owner()] = true;
    }

    ///@notice Burn the caller's tokens
    ///@param amount the amount of tokens to burn
    ///@dev only sender tokens are burned
    function burn(uint amount) external {
        _burn(msg.sender, amount);
    }

    ///@notice Same internal transfer function as ERC20 but checks for blacklist
    ///@param sender wallet that sends the tokens
    ///@param recipient wallet that receives the tokens
    ///@param amount the amount of tokens to send
    ///@dev checks that neither sender or recipient are blacklisted;
    function _transfer(
        address sender,
        address recipient,
        uint amount
    ) internal override {
        uint currentTime = block.timestamp;
        uint currentBlock = block.number;
        if (currentTime < cooldownDuration) {
            uint currentCooldown = cooldowns[sender];
            if (!isCooldownWhitelist[sender]) {
                require(currentCooldown < currentBlock, "Cooldown");
            }
            currentCooldown = block.number + 10;
            cooldowns[sender] = currentCooldown;
            cooldowns[recipient] = currentCooldown;
        }
        super._transfer(sender, recipient, amount);
    }

    function setCooldownWhitelist(
        address _wallet,
        bool set
    ) external onlyOwner {
        isCooldownWhitelist[_wallet] = set;
    }
}