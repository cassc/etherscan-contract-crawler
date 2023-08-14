// SPDX-License-Identifier: MIT

// $KATZ by Katz.Community
// author: sadat.eth

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract KATZ is ERC20, Ownable {

    uint256 private maxSupply = 10000000 * 10 ** decimals();
    bool    private distributed;
    bool    private limited;
    uint256 private txLimit;
    uint256 private maxBuy;
    address private pool;
    address private KM = 0xb5C2c4bdd64379DDA029F04340598EE9EBA7A7aF;
    address private KW = 0x8D28EB8079aE341cA45Bb91E4900974b6999b959;
    mapping (address => uint256) public unclaimed;

    constructor() ERC20("KATZ", "KATZ") {
       _mint(msg.sender, 500000 * 10 ** decimals()); // 5% deployer wallet for setting up liquidity pool
    }

    function distribute() external onlyOwner {
        if(!distributed) {
            distributed = true;
            _mint(0x01c466c5DbEdDec87BFEb43B9D64bC21800233B9, 1450000 * 10 ** decimals()); // 14.5% treasury
            _mint(0x1779769E01a5B954d813E85446318441D322F2f6, 1000000 * 10 ** decimals()); // 10% casino
            _mint(0x2d4d806b60737422b66Dae8D83b60912e11821B3, 500000 * 10 ** decimals()); // 5% marketing
            _mint(0x44eb189EAf8Fef9Fc518E99344E70d327cf8E83F, 100000 * 10 ** decimals()); // 1% founder
            _mint(0xFaeE491442d408191c6e6702cF1910b7211E5042, 100000 * 10 ** decimals()); // 1% designer
            _mint(0x562ADBaBE7F3912A67a9FC52b4D9ca600650dbE3, 100000 * 10 ** decimals()); // 1% dev
        } else return;
    }

    function getReward(address _address) external {
        if (msg.sender == KM) { unclaimed[_address] += 2000 * 10 ** decimals(); }
        else if (msg.sender == KW) { unclaimed[_address] += 500 * 10 ** decimals(); }
    }

    function claimReward() external {
        uint256 amount = unclaimed[msg.sender];
        require(amount > 0, "E0: no burns");
        unclaimed[msg.sender] = 0;
        _mint(msg.sender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) override internal virtual {

        // @dev: if its a transfer not a mint, runs below checks
        if (from != address(0)) {

            // E1: if pool is not initialized, only owner() can move tokens
            if (pool == address(0)) { require(from == owner() || to == owner(), "E1"); }

            // E2: if tx limit is set, amount must not exceed tx limit
            if (txLimit != 0) { require(amount <= txLimit, "E2"); }

            // E3: if max buy is set, balance must not exceed max buy
            if (maxBuy != 0) { require(balanceOf(to) + amount <= maxBuy, "E3"); }

            // E4: if token is limited, must hold a KM or KW nft to buy
            if (limited && from == pool) { require(IERC721(KM).balanceOf(to) > 0 || IERC721(KW).balanceOf(to) > 0, "E4"); }

        }
    }

    function setPool(address _pool) external onlyOwner {
        pool = _pool;
    }

    function setLimits(bool _limited, uint256 _txLimit, uint256 _maxBuy) external onlyOwner {
        limited = _limited;
        txLimit = _txLimit;
        maxBuy = _maxBuy;
    }

    function burn(uint256 value) public {
        _burn(msg.sender, value);
        maxSupply -= value;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return maxSupply;
    }

}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
}