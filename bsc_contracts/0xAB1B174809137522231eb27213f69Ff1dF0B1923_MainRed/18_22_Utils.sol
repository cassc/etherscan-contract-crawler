// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../secutiry/Administered.sol";

contract Utils is Administered {
    address public apocalypse = address(0);
    address public owner = address(0);

    address public fundsWallet = address(0);

    constructor(address _apocalypse, address _fundsWallet) {
        apocalypse = _apocalypse;
        fundsWallet = _fundsWallet;
    }

    /**
     * @dev selfdestruct
     * apocalypse: address to send the remaining balance
     */
    function destroy() public {
        require(
            apocalypse == _msgSender(),
            "only the apocalypse can call this"
        );
        selfdestruct(payable(apocalypse));
    }

    /// @dev withdraw tokens
    function withdrawOwner(uint256 _amount) external payable onlyAdmin {
        require(
            payable(address(_msgSender())).send(_amount),
            "Withdraw Owner: Failed to transfer token to Onwer"
        );
    }

    /// @dev withdraw tokens
    function withdrawToken(address _token, uint256 _amount) external onlyAdmin {
        require(
            IERC20(_token).transfer(_msgSender(), _amount),
            "Withdraw Token Onwer: Failed to transfer token to Onwer"
        );
    }

    /// @dev set funds wallet
    function setFundsWallet(address _fundsWallet) external onlyAdmin {
        fundsWallet = _fundsWallet;
    }
}