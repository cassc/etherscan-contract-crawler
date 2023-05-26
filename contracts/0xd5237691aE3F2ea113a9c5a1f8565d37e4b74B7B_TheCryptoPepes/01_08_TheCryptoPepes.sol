// SPDX-License-Identifier: MIT
/*
  /$$$$$$  /$$$$$$$  /$$     /$$ /$$$$$$$  /$$$$$$$$ /$$$$$$  /$$$$$$$  /$$$$$$$$ /$$$$$$$  /$$$$$$$$  /$$$$$$ 
 /$$__  $$| $$__  $$|  $$   /$$/| $$__  $$|__  $$__//$$__  $$| $$__  $$| $$_____/| $$__  $$| $$_____/ /$$__  $$
| $$  \__/| $$  \ $$ \  $$ /$$/ | $$  \ $$   | $$  | $$  \ $$| $$  \ $$| $$      | $$  \ $$| $$      | $$  \__/
| $$      | $$$$$$$/  \  $$$$/  | $$$$$$$/   | $$  | $$  | $$| $$$$$$$/| $$$$$   | $$$$$$$/| $$$$$   |  $$$$$$ 
| $$      | $$__  $$   \  $$/   | $$____/    | $$  | $$  | $$| $$____/ | $$__/   | $$____/ | $$__/    \____  $$
| $$    $$| $$  \ $$    | $$    | $$         | $$  | $$  | $$| $$      | $$      | $$      | $$       /$$  \ $$
|  $$$$$$/| $$  | $$    | $$    | $$         | $$  |  $$$$$$/| $$      | $$$$$$$$| $$      | $$$$$$$$|  $$$$$$/
 \______/ |__/  |__/    |__/    |__/         |__/   \______/ |__/      |________/|__/      |________/ \______/ 
*/
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./erc721a/contracts/ERC721A.sol";

contract TheCryptoPepes is ERC721A, Ownable {
    uint public pepePrice = 100000000;
    uint public maxSupply = 9879;
    uint public maxTx = 10;

    address public pepeAddress = 0xd2a5bC10698FD955D1Fe6cb468a17809A08fd005;

    bool private mintOpen = false;

    string internal baseTokenURI = '';
    
    constructor() ERC721A("TheCryptoPepes", "CPEPES") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function toggleMint() external onlyOwner {
        mintOpen = !mintOpen;
    }
    
    function setPepePrice(uint newPrice) external onlyOwner {
        pepePrice = newPrice;
    }

    function setPepeAddress(address newAddress) external onlyOwner {
        pepeAddress = newAddress;
    }
    
    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }

    function setMaxSupply(uint newSupply) external onlyOwner {
        maxSupply = newSupply;
    }
    
    function setMaxTx(uint newMax) external onlyOwner {
        maxTx = newMax;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }

    function devMint(address to, uint qty) external onlyOwner {
        _mint(to, qty);
    }

    function GetAllowance() public view returns(uint256) {
       return IERC20(pepeAddress).allowance(msg.sender, address(this));
    }
    
    function mintWithPepeCoin(uint256 qty) external callerIsUser returns(bool) {
        require(mintOpen, "store closed");
        require(qty <= maxTx && qty > 0, "TRANSACTION: qty of mints not allowed");
        require(qty + totalSupply() <= maxSupply, "SUPPLY: Value exceeds totalSupply");
        IERC20(pepeAddress).transferFrom(msg.sender, address(this), qty * pepePrice);
        _mint(msg.sender, qty);
        return true;
    }

    function withdrawPepe(uint256 _amount) external onlyOwner {
        IERC20 pepeContract = IERC20(pepeAddress);
        pepeContract.approve(address(this), _amount);
        pepeContract.transferFrom(address(this), owner(), _amount);
    }
}