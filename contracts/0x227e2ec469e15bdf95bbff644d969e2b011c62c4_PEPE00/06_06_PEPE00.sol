// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC20.sol";
import "./Ownable.sol";

contract PEPE00 is ERC20, Ownable {
    address marketingWallet;
    uint256 public constant INITIAL_SUPPLY = 100000000000;
    uint256 public constant MINT_AMOUNT = 1000000000;
    uint256 public constant DECIMALS = 18;
    uint256 public constant MINT_INTERVAL = 60;
    uint256 public lastMint;
    uint256 public mintTimes;
    mapping (address => bool) public minted;

    constructor(address _marketingWallet) ERC20("PEPE0.0", "PEPE0.0") {
        marketingWallet = _marketingWallet;
        _mint(msg.sender, INITIAL_SUPPLY * (10 ** uint256(DECIMALS)));
        mintTimes = 0;
        lastMint = block.timestamp;
    }

    function mint() public {
        require(!minted[msg.sender], "You have already minted.");
        require(block.timestamp >= lastMint + MINT_INTERVAL, "Wait for next mint time.");
        uint256 mintAmount = MINT_AMOUNT * (10 ** uint256(DECIMALS)) * (10000 - mintTimes) / 10000;
        _mint(msg.sender, mintAmount);
        minted[msg.sender] = true;
        mintTimes++;
        lastMint = block.timestamp;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        uint256 tax = amount * 2 / 100;
        uint256 amountAfterTax = amount - tax;
        super._transfer(sender, recipient, amountAfterTax);
        super._transfer(sender, marketingWallet, tax / 2);
        _burn(sender, tax / 2);
    }
}
