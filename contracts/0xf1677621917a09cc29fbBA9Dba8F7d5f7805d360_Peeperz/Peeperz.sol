/**
 *Submitted for verification at Etherscan.io on 2023-10-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract Peeperz {

    error MaxSupplyReached();
    error InvalidValue();
    error RequestingTooMany();
    error TransferFailed();
    error OnlyOwner();
    error MintIsNotLive();

    event Mint(address indexed minter, uint256 indexed amount, uint256 startID);

    uint256 public TOTAL_SUPPLY = 0;
    uint256 public PRICE = 0.0069 * 1 ether;
    uint256 public immutable MAX_SUPPLY = 6410;

    bool public IS_LIVE = false;

    address OWNER;

    modifier onlyOwner() {
        if (msg.sender != OWNER) {
            revert OnlyOwner();
        }
        _;
    }

    constructor () {
        OWNER = msg.sender;
    }

    function setPrice(uint256 _PRICE) external onlyOwner {
        PRICE = _PRICE;
    }

    function mint(uint256 amount) external payable {
        if (!IS_LIVE) { revert MintIsNotLive(); }
        if (TOTAL_SUPPLY == MAX_SUPPLY) { revert MaxSupplyReached(); }
        if ((TOTAL_SUPPLY + amount) > MAX_SUPPLY) { revert RequestingTooMany(); }
        if ((PRICE * amount) != msg.value) { revert InvalidValue(); }
        

        (bool success,) = address(OWNER).call{value: msg.value}("");
        if (!success) {
            revert TransferFailed();
        }

        emit Mint(msg.sender, amount, TOTAL_SUPPLY);
        
        unchecked {
            TOTAL_SUPPLY += amount;
        }
    }

    function setLive(bool status) external onlyOwner {
        IS_LIVE = status;
    }

    function withdraw() external onlyOwner {
        (bool success,) = address(OWNER).call{value: address(this).balance}("");
        if (!success) {
            revert TransferFailed();
        }
    }
}