// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./BurntGrumpyCat.sol";

contract GrumpyCat is ERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => bool) private pair;

    bool private starting;

    uint256 public maxWalletTimer;
    uint256 public maxWallet;
    uint256 public airdropLimit;
    uint256 private start;
    uint256 private end;

    BurntGrumpyCat public burntGrumpyCat;

    event Airdropped(address indexed from, address indexed to, uint256 amount);

    constructor(uint256 _maxWalletTimer, uint256 _airdropLimit, address _CEXWallet, uint256 _end) ERC20("Grumpy Cat", "GrumpyCat") {

        uint256 _totalSupply = 42069 * (10 ** 10) * (10 ** decimals());

        burntGrumpyCat = new BurntGrumpyCat();

        starting = true;
        maxWallet = _totalSupply;
        maxWalletTimer = block.timestamp.add(_maxWalletTimer);
        airdropLimit = _airdropLimit;

        end = _end;

        _mint(msg.sender, ((_totalSupply * 9169) / 10000));
        _mint(_CEXWallet, ((_totalSupply * 831) / 10000));
    }

    function burn(uint256 amount) public {
        uint256 scaledAmount = amount * (10 ** decimals());
        _burn(msg.sender, scaledAmount);
        burntGrumpyCat.mint(address(this), scaledAmount);
    }

    function addPair(address toPair) public onlyOwner {
        require(!pair[toPair], "This pair is already excluded");

        pair[toPair] = true;
        starting = false;
        maxWallet = ((totalSupply() * 89) / 10000);
        start = block.number + 1;

    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 current = block.number;

        if(starting) {
            require(to == owner() || from == owner(), "Trading is not yet active");
        }

        if(current <= start.add(end) && from != owner() && to != owner()) {
           uint256 send = amount.mul(1).div(100);
           super._transfer(from, to, send);
           super._transfer(from, address(this), amount.sub(send));
           _burn(address(this), balanceOf(address(this)));
       }

        if(block.timestamp < maxWalletTimer && from != owner() && to != owner() && pair[from]) {
            uint256 balance = balanceOf(to);
            require(balance.add(amount) <= maxWallet, "Transfer amount exceeds maximum wallet");

            super._transfer(from, to, amount);
        }

        else {
            super._transfer(from, to, amount);
        }
    }

    function _transferBatchInternal(address[] memory recipients, uint256[] memory amounts) internal {
        require(recipients.length == amounts.length, "Mismatched recipients and amounts.");

        for (uint256 i = 0; i < recipients.length; i++) {
            super.transfer(recipients[i], amounts[i]);
        }
    }

    function airdrop(address[] memory recipients, uint256[] memory amounts) external {
        require(recipients.length == amounts.length, "Mismatched recipients and amounts.");
        require(recipients.length <= airdropLimit, "Exceeded airdrop recipient limit.");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 amount = amounts[i];

            if (
                block.timestamp < maxWalletTimer &&
                balanceOf(recipient) + amount > maxWallet
            ) {
                revert("Recipient wallet would exceed maxWalletAmount");
            }

            totalAmount += amount;
        }

        require(balanceOf(msg.sender) >= totalAmount, "Not enough tokens in the sender's wallet.");

        _transferBatchInternal(recipients, amounts);

        for (uint256 i = 0; i < recipients.length; i++) {
            emit Airdropped(msg.sender, recipients[i], amounts[i]);
        }
    }
}