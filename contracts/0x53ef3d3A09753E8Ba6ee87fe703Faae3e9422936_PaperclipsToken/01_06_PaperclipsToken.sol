// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PaperclipsToken is Ownable, ERC20 {
    address public uniswapPair;
    mapping(address => bool) public acceptLists;

    constructor() ERC20("Paperclips", "CLIPS") {
        uint256 totalSupply = 1000000000000 * 10**decimals();
        _mint(msg.sender, totalSupply);
    }

    function acceptList(address _address, bool _isAcceptListing)
        external
        onlyOwner
    {
        acceptLists[_address] = _isAcceptListing;
    }

    function setUniswapPair(address _uniswapPair) external onlyOwner {
        uniswapPair = _uniswapPair;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (uniswapPair == address(0)) {
            require(
                from == owner() || to == owner() || acceptLists[from],
                "trading is not started"
            );
        }

        super._beforeTokenTransfer(from, to, amount);
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}