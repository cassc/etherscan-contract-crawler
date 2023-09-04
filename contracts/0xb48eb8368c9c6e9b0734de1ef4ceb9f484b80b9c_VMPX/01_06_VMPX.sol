// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

contract VMPX is ERC20("VMPX", "VMPX"), ERC20Capped(108_624_000 ether) {

    string public constant AUTHORS = "@MrJackLevin @ackebom @lbelyaev @JammaBeans faircrypto.org";

    uint256 public constant BATCH = 200 ether;
    uint256 public immutable cycles; // depends on a network block side, set in constructor
    uint256 public immutable startBlockNumber;

    uint256 public counter;
    mapping(uint256 => bool) private _work;

    /**
        @dev    Start of Operations Guard
    */
    modifier notBeforeStart() {
        require(block.number > startBlockNumber, "mint not active yet");
        _;
    }


    constructor(uint256 cycles_, uint256 startBlockNumber_) {
        require(cycles_ > 0, 'bad limit');
        startBlockNumber = startBlockNumber_;
        cycles = cycles_;
    }

    function _doWork(uint256 power) internal {
        for(uint i = 0; i < cycles * power; i++) {
            _work[++counter] = true;
        }
    }

    function _mint(address account, uint256 amount) internal override (ERC20, ERC20Capped) {
        super._mint(account, amount);
    }

    function mint(uint256 power) external notBeforeStart {
        require(power > 0 && power < 196, 'power out of bounds');
        require(tx.origin == msg.sender, 'only EOAs allowed');
        require(totalSupply() + (BATCH * power) <= cap(), "minting would exceed cap");

        _doWork(power);
        _mint(msg.sender, BATCH * power);
    }
}