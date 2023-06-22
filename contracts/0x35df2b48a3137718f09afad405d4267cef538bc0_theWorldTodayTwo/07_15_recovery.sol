pragma solidity ^0.8.7;
// SPDX-Licence-Identifier: RIGHT-CLICK-SAVE-ONLY


import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract recovery is Ownable {

    address recover;
    constructor(address _recovery) {
        recover = _recovery;
    }
    
    // blackhole prevention methods
    function retrieveETH() external  {
            uint256 _balance = address(this).balance;
            (bool sent, ) = recover.call{value: _balance}(""); // don't use send or xfer (gas)
            require(sent, "Failed to send Ether");
    }
    
    function retrieveERC20(address _tracker) external  {
        uint256 balance = IERC20(_tracker).balanceOf(address(this));
        IERC20(_tracker).transfer(recover, balance);
    }

    function retrieve721(address _tracker, uint256 id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }



}