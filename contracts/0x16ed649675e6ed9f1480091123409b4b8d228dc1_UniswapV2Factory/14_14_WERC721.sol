// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IWERC721 } from "./interfaces/IWERC721.sol";
import { IERC721 } from "./interfaces/IERC721.sol";
import { IUniswapV2Factory } from "./interfaces/IUniswapV2Factory.sol";

contract WERC721 is IWERC721 {
    string public constant name = "Wrapped NFT";
    string public constant symbol = "WNFT";
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    address public factory;
    address public collection;

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "SweepnFlip: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier onlyRouter() {
        require(IUniswapV2Factory(factory).router(msg.sender), "SweepnFlip: FORBIDDEN");
        _;
    }

    constructor() {
        factory = msg.sender;
    }

    function initialize(address _collection) external {
        require(msg.sender == factory, "SweepnFlip: FORBIDDEN"); // sufficient check
        collection = _collection;
    }

    function _mint(address from, address to, uint[] memory tokenIds) private {
        uint count = tokenIds.length;
        uint value = count * 1e18;
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
        for (uint i = 0; i < count; i++) {
            IERC721(collection).transferFrom(from, address(this), tokenIds[i]);
        }
        emit Mint(from, to, tokenIds);
    }

    function _burn(address from, address to, uint[] memory tokenIds) private {
        uint count = tokenIds.length;
        uint value = count * 1e18;
        balanceOf[from] -= value;
        totalSupply -= value;
        emit Transfer(from, address(0), value);
        for (uint i = 0; i < count; i++) {
            IERC721(collection).transferFrom(address(this), to, tokenIds[i]);
        }
        emit Burn(from, to, tokenIds);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        require(value % 1e18 == 0, "SweepnFlip: PARTIAL_AMOUNT");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function mint(address to, uint[] memory tokenIds) external onlyRouter lock {
        _mint(msg.sender, to, tokenIds);
    }

    function burn(address to, uint[] memory tokenIds) external onlyRouter lock {
        _burn(msg.sender, to, tokenIds);
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] -= value;
        }
        _transfer(from, to, value);
        return true;
    }
}