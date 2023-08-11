/**
 *Submitted for verification at Etherscan.io on 2023-08-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BabuPunks {

    error MaxSupplyReached();
    error InvalidValue();
    error RequestingTooMany();
    error TransferFailed();
    error OnlyOwner();
    error MintClosed();

    event Mint(address indexed minter, uint256 indexed amount, uint256 startID, uint256 endID);

    uint256 public TOTAL_SUPPLY = 0;
    uint256 public PRICE = 0.002 * 1 ether;
    uint256 public immutable MAX_SUPPLY = 10_000;
    uint256 public immutable MAX_PER_TXN = 69;
    uint256 public MINT_STATE = 0;

    address OWNER;

    modifier onlyOwner() {
        require(msg.sender == OWNER, "OnlyOwner()");
        _;
    }

    constructor () {
        OWNER = msg.sender;
    }

    function setMintState(uint256 _MINT_STATE) external onlyOwner {
        MINT_STATE = _MINT_STATE;
    }

    function setPrice(uint256 _PRICE) external onlyOwner {
        PRICE = _PRICE;
    }

    function purchaseBabus(uint256 amount) payable external {
        if (MINT_STATE != 1) { revert MintClosed(); }
        if ((TOTAL_SUPPLY + amount) > MAX_SUPPLY ||
            amount > MAX_PER_TXN) { revert RequestingTooMany(); }
        if (TOTAL_SUPPLY == MAX_SUPPLY) { revert MaxSupplyReached(); }
        if ((amount * PRICE) < msg.value) { revert InvalidValue(); }

        uint256 startId = TOTAL_SUPPLY;
        unchecked {
            TOTAL_SUPPLY += amount;
        }

        (bool success,) = address(OWNER).call{value: msg.value}('');
        if (!success) { revert TransferFailed(); }

        emit Mint(msg.sender, amount, startId, TOTAL_SUPPLY);
    }
}