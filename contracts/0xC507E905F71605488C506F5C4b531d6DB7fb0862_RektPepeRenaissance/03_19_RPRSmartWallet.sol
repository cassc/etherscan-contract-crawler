// SPDX-License-Identifier: GNU-GPL v3.0 or later

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";


pragma solidity ^0.8.0;

/// @author RobAnon
contract RPRSmartWallet {

    using SafeERC20 for IERC20;

    address private immutable MASTER;

    constructor() {
        MASTER = msg.sender;
    }

    modifier onlyMaster() {
        require(msg.sender == MASTER, 'E016');
        _;
    }
    //https://ethereum.stackexchange.com/questions/19341/address-send-vs-address-transfer-best-practice-usage
    function withdrawEther(address owner) public onlyMaster {
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
        _cleanMemory();
    }

    function withdrawERC20(address token, uint256 amount, address recipient) external onlyMaster {
        IERC20(token).safeTransfer(recipient, amount);
        withdrawEther(recipient);
        _cleanMemory();
    }

    function withdrawERC721(address token, uint256 tokenId, address recipient) external onlyMaster {
        IERC721(token).safeTransferFrom(address(this), recipient, tokenId);
        withdrawEther(recipient);
        _cleanMemory();
    }
    

    /// Credit to doublesharp for the brilliant gas-saving concept
    /// Self-destructing clone pattern
    function cleanMemory() external onlyMaster {
        _cleanMemory();
    }

    function _cleanMemory() internal {
        selfdestruct(payable(MASTER));
    }

    function _checkApproval(uint amountUnderlying, address vaultToken, address vaultAdapter) private {
        if(IERC20(vaultToken).allowance(address(this), vaultAdapter) < amountUnderlying) {
            IERC20(vaultToken).approve(vaultAdapter, type(uint).max);
        }
    }

}