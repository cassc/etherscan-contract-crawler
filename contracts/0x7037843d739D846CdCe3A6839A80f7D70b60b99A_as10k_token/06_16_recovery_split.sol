pragma solidity ^0.8.7;
// SPDX-Licence-Identifier: RIGHT-CLICK-SAVE-ONLY


import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract recovery_split is Ownable {

    address[]                           public      wallets;
    uint256[]                           public      shares;

    constructor(address[] memory _wallets, uint256[] memory _shares) {
        wallets = _wallets;
        shares  = _shares;
    }


    // blackhole prevention methods
    function retrieveETH() external  {
        _split(address(this).balance);
    }
    
    function retrieveERC20(address _tracker) external  {
        uint256 bal = IERC20(_tracker).balanceOf(address(this));
        _split20(bal,_tracker);
    }

    function retrieve721(address _tracker, uint256 id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }

    function _split(uint256 amount) internal {
        bool sent;
        uint256 _total;
        for (uint256 j = 0; j < wallets.length; j++) {
            uint256 _amount = amount * shares[j] / 1000;
            if (j == wallets.length-1) {
                _amount = amount - _total;
            } else {
                _total += _amount;
            }
            ( sent, ) = wallets[j].call{value: _amount}(""); // don't use send or xfer (gas)
            require(sent, "Failed to send Ether");
        }
    }

    function _split20(uint256 amount, address token) internal {
        uint256 _total;
        for (uint256 j = 0; j < wallets.length; j++) {
            uint256 _amount = amount * shares[j] / 1000;
            if (j == wallets.length-1) {
                _amount = amount - _total;
            } else {
                _total += _amount;
            }
            IERC20(token).transfer(wallets[j],_amount); 
        }
    }


}