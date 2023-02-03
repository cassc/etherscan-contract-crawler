// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

 /*$$$$$$$ /$$$$$$  /$$   /$$ /$$   /$$ /$$$$$$$
| $$_____//$$__  $$| $$  | $$| $$$ | $$| $$__  $$
| $$     | $$  \ $$| $$  | $$| $$$$| $$| $$  \ $$
| $$$$$  | $$  | $$| $$  | $$| $$ $$ $$| $$  | $$
| $$__/  | $$  | $$| $$  | $$| $$  $$$$| $$  | $$
| $$     | $$  | $$| $$  | $$| $$\  $$$| $$  | $$
| $$     |  $$$$$$/|  $$$$$$/| $$ \  $$| $$$$$$$/
|__/      \______/  \______/ |__/  \__/|______*/

contract Found is Ownable, ERC20 {
    address private _origin;
    uint private _claim;

    event Mint(
        address indexed to,
        uint amount,
        uint timestamp
    );

    event MintAndApprove(
        address indexed to,
        uint amount,
        address indexed spender,
        uint allowance,
        uint timestamp
    );

    event Claim(
        address indexed to,
        uint amount,
        uint timestamp
    );

    event Swap(
        address indexed from,
        address indexed to,
        uint foundAmount,
        uint etherAmount,
        uint timestamp
    );

    function reserves() external view returns (uint) {
        return address(this).balance;
    }

    function convert(uint found) public view returns (uint) {
        uint total = totalSupply();
        if (total == 0) return 0;

        require(total >= found, "Swap exceeds total supply");
        return total - found <= _claim
            ? found * address(this).balance / total
            : found / 10000;
    }

    function swap(address from, address to, uint found) external {
        require(found > 0, "Please swap more than 0");
        uint value = convert(found);

        _burn(from, found);
        (bool success, ) = to.call{value:value}("");
        require(success, "Swap failed");

        emit Swap(
            from,
            to,
            found,
            value,
            block.timestamp
        );
    }

    function mint(address to) external payable {
        uint amount = msg.value * 10000;

        _mint(to, amount);

        emit Mint(
            to,
            amount,
            block.timestamp
        );
    }

    function mintAndApprove(address to, address spender, uint allowance) external payable {
        uint amount = msg.value * 10000;

        _mint(to, amount);
        _approve(msg.sender, spender, allowance);

        emit MintAndApprove(
            to,
            amount,
            spender,
            allowance,
            block.timestamp
        );
    }

    modifier onlyOrigin {
        require(
            msg.sender == owner() || msg.sender == _origin,
            "Caller is not the owner or origin"
        );
        _;
    }

    function claim(address to, uint amount) external onlyOrigin {
        uint limit = (totalSupply() - _claim) / 10;

        require(
            limit >= amount + _claim,
            "Claim exceeds allowance"
        );

        _claim += amount;
        _mint(to, amount);

        emit Claim(
            to,
            amount,
            block.timestamp
        );
    }

    function totalClaim() external view returns (uint) {
        return _claim;
    }

    function origin() external view returns (address) {
        return _origin;
    }

    function setOrigin(address origin_) external onlyOrigin {
        _origin = origin_;
    }

    constructor(address origin_) ERC20("FOUND", "FOUND") {
        _origin = origin_;
    }
}