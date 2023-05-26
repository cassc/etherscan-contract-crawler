// SPDX-License-Identifier: MIT
// EMEMcoin $EME
// https://meme.ermine.pro
// https://twitter.com/ememcoin
// https://t.me/ememcoin

//  $▄▄▄▄▄▄▄▄▄▄▄$$▄▄$$$$$$$▄▄$$▄▄▄▄▄▄▄▄▄▄▄$$▄▄$$$$$$$▄▄$$▄▄▄▄▄▄▄▄▄▄▄$$▄▄▄▄▄▄▄▄▄▄▄$$▄▄▄▄▄▄▄▄▄▄▄$$▄▄$$$$$$$$▄$
//  ▐░░░░░░░░░░░▌▐░░▌$$$$$▐░░▌▐░░░░░░░░░░░▌▐░░▌$$$$$▐░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░▌$$$$$$▐░▌
//  ▐░█▀▀▀▀▀▀▀▀▀$▐░▌░▌$$$▐░▐░▌▐░█▀▀▀▀▀▀▀▀▀$▐░▌░▌$$$▐░▐░▌▐░█▀▀▀▀▀▀▀▀▀$▐░█▀▀▀▀▀▀▀█░▌$▀▀▀▀█░█▀▀▀▀$▐░▌░▌$$$$$▐░▌
//  ▐░▌$$$$$$$$$$▐░▌▐░▌$▐░▌▐░▌▐░▌$$$$$$$$$$▐░▌▐░▌$▐░▌▐░▌▐░▌$$$$$$$$$$▐░▌$$$$$$$▐░▌$$$$$▐░▌$$$$$▐░▌▐░▌$$$$▐░▌
//  ▐░█▄▄▄▄▄▄▄▄▄$▐░▌$▐░▐░▌$▐░▌▐░█▄▄▄▄▄▄▄▄▄$▐░▌$▐░▐░▌$▐░▌▐░▌$$$$$$$$$$▐░▌$$$$$$$▐░▌$$$$$▐░▌$$$$$▐░▌$▐░▌$$$▐░▌
//  ▐░░░░░░░░░░░▌▐░▌$$▐░▌$$▐░▌▐░░░░░░░░░░░▌▐░▌$$▐░▌$$▐░▌▐░▌$$$$$$$$$$▐░▌$$$$$$$▐░▌$$$$$▐░▌$$$$$▐░▌$$▐░▌$$▐░▌
//  ▐░█▀▀▀▀▀▀▀▀▀$▐░▌$$$▀$$$▐░▌▐░█▀▀▀▀▀▀▀▀▀$▐░▌$$$▀$$$▐░▌▐░▌$$$$$$$$$$▐░▌$$$$$$$▐░▌$$$$$▐░▌$$$$$▐░▌$$$▐░▌$▐░▌
//  ▐░▌$$$$$$$$$$▐░▌$$$$$$$▐░▌▐░▌$$$$$$$$$$▐░▌$$$$$$$▐░▌▐░▌$$$$$$$$$$▐░▌$$$$$$$▐░▌$$$$$▐░▌$$$$$▐░▌$$$$▐░▌▐░▌
//  ▐░█▄▄▄▄▄▄▄▄▄$▐░▌$$$$$$$▐░▌▐░█▄▄▄▄▄▄▄▄▄$▐░▌$$$$$$$▐░▌▐░█▄▄▄▄▄▄▄▄▄$▐░█▄▄▄▄▄▄▄█░▌$▄▄▄▄█░█▄▄▄▄$▐░▌$$$$$▐░▐░▌
//  ▐░░░░░░░░░░░▌▐░▌$$$$$$$▐░▌▐░░░░░░░░░░░▌▐░▌$$$$$$$▐░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌$$$$$$▐░░▌
//  $▀▀▀▀▀▀▀▀▀▀▀$$▀$$$$$$$$$▀$$▀▀▀▀▀▀▀▀▀▀▀$$▀$$$$$$$$$▀$$▀▀▀▀▀▀▀▀▀▀▀$$▀▀▀▀▀▀▀▀▀▀▀$$▀▀▀▀▀▀▀▀▀▀▀$$▀$$$$$$$$▀▀$
//  $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract EMEMcoin is ERC20, Ownable {
    uint256 public burned;
    uint256 private before;
    bool public limit;
    uint private gap;
    address public uniswapV2Pair;
    mapping(address => bool) public lock;
    mapping(address => uint256) public lasttime;
    mapping(address => bool) private _label;

    event Burn(address indexed from, uint256 amount);

    constructor () ERC20 ("EMEM Coin", "EME") {
        _mint(msg.sender, 82*1e28); //Total supply: 820,000,000,000 $EME
    }

function burn(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "There are not enough tokens on your balance!");
        _burn(msg.sender, amount);
        burned += amount;
        emit Burn(msg.sender, amount);
    }    

function _beforeTokenTransfer(address from, address to, uint256 amount) override internal virtual {
        require(!lock[from], "Sender blocked!");
        require(!lock[to], "Recipient blocked!");

        if ((block.timestamp < before)&&(from != owner())&&(to != owner())) {
            autoLock(to);
            lasttime[to] = block.timestamp;
            }
            else {
                if ((gap > 0)&&(to != from)&&(uniswapV2Pair != address(0))) {
                if (from == uniswapV2Pair) {
                    if (limit && amount > 41*1e27) {autoLock(to);}
                    if (_label[to]) {autoLock(to);}
                    if (block.timestamp - lasttime[to] < gap) {
                    _label[to] = true;
                    }

                lasttime[to] = block.timestamp;
                }
                if (to == uniswapV2Pair) {
                    if (limit && amount > 41*1e27) {autoLock(from);}
                    if (_label[from]) {autoLock(from);}
                    if (block.timestamp - lasttime[from] < gap) {
                    _label[from] = true;
                    }
                lasttime[from] = block.timestamp;
                }
                }
                }
}

function autoLock(address _address) internal {
        lock[_address] = true;
}    

function manualLockUnlock(address _address) external onlyOwner {
        lock[_address] = !lock[_address];
        _label[_address] = false;
}

function setUNI(address _uniswapV2Pair) external onlyOwner {
        uniswapV2Pair = _uniswapV2Pair;
}

function unLock() external {
        require(lock[msg.sender], "This address is not blocked!");
        require(block.timestamp > lasttime[msg.sender] + 864000, "Less than 10 days have passed since the blocking!");
        uint256 forBurn = (balanceOf(msg.sender) / 10) * 9;
        lock[msg.sender] = false;
         _label[msg.sender] = false;
        _burn(msg.sender, forBurn);
        emit Burn(msg.sender, forBurn);
        burned += forBurn;
}

function setGap(uint _gap) external onlyOwner {
        gap = _gap;
}    

function setBefore(uint256 _before) external onlyOwner {
        require((before == 0)&&(_before - block.timestamp < 900), "The delay for blocking addresses is already set or the delay to be set is more than 15 minutes!");
        before = _before;
}   

function OnOffLimit() external onlyOwner {
        limit = !limit;
}

}