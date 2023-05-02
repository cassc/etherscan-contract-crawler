// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BPebbles is ERC20, Ownable {

    address public NFTAddress;
	address public GameAddress;
	
    constructor() ERC20("Beach Pebbles", "BPebbles") {}
	
    function mint(address to, uint256 amount) public {
        require(address(msg.sender) == address(NFTAddress), "Request source is not valid");
        _mint(to, amount);
    }
	
	function burn(address from, uint256 amount) public {
		require(address(msg.sender) == address(GameAddress), "Request source is not valid");
		
		uint256 currentAllowance = allowance(from, address(msg.sender));
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
           _approve(from, address(msg.sender), currentAllowance - amount);
        }
        _burn(from, amount);
    }
	
	function setGameAddress(address newGameAddress) external onlyOwner {
        require(newGameAddress != address(0), "Zero address");
		GameAddress = address(newGameAddress);
    }
	
	function setNFTAddress(address newNFTAddress) external onlyOwner {
        require(newNFTAddress != address(0), "Zero address");
		require(NFTAddress == address(0), "NFT address already set");
		
		NFTAddress = address(newNFTAddress);
    }
}