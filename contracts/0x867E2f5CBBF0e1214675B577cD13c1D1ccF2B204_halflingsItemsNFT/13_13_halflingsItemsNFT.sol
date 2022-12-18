// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract halflingsItemsNFT is ERC1155,Ownable {
    constructor(string memory url) ERC1155("") {
    }
    event Withdraw(
        uint256 amount
    );
    event WithdrawERC20Token(
        address tokenContractAddress,
        uint256 amount
    );
    mapping(address => bool) public isMinter;
    event SetMinter(address callerAddress,address minter, bool status);
    function setMinter(address minter, bool status) external onlyOwner {
        isMinter[minter] = status;
        emit SetMinter(_msgSender(), minter, status);
    }
    

    function mint(address to, uint256 id, uint256 amount) external  {
      require(isMinter[_msgSender()] == true, "Caller is not a minter");
      _mint(to, id, amount, "");
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) external  {
      require(isMinter[_msgSender()] == true, "Caller is not a minter");
      _mintBatch(to, ids, amounts, "");
    }

    function burn(address user,uint256 id, uint256 amount) external  {
        _burn(user, id, amount); 
    }

    function burnBatch(address user,uint256[] memory ids, uint256[] memory amounts) external  {
        _burnBatch(user, ids, amounts);
    }

     function updateUri(string memory newuri) external onlyOwner
    {
        _setURI(newuri);
    }
     // BNB sent by mistake can be returned
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        payable( msg.sender ).transfer( balance );
        
        emit Withdraw(balance);
    }

    // ERC20 sent by mistake can be returned
    function withdrawERC20Token(address tokenContractAddress) external onlyOwner {
        uint256 amount = IERC20(tokenContractAddress).balanceOf(address(this));
        require(amount > 0);
        IERC20(tokenContractAddress).transfer( msg.sender , amount);

        emit WithdrawERC20Token(tokenContractAddress, amount);
    }
     
}