// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract MetaSportsTokenCrossChainBSC is
    Ownable,
    Pausable,
    ReentrancyGuard,
    AccessControl
{
    using SafeERC20 for IERC20;

    bytes32 public constant TOKEN_OUT_ROLE = keccak256("TOKEN_OUT_ROLE");
    IERC20 public immutable MS_BSC_MST;
    address public adminAddress;

    event TransferIn(address indexed seller, uint256 indexed amount);
    event TransferOut(address indexed receiver, uint256 indexed amount);

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    constructor(address _contractAddress) {
        require(
            _contractAddress != address(0),
            "Token contract address can not be zero"
        );
        MS_BSC_MST = IERC20(_contractAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function transferIn(uint256 _amount) external whenNotPaused nonReentrant {
        require(
            MS_BSC_MST.balanceOf(msg.sender) >= _amount,
            "Insufficient Balance"
        );
        MS_BSC_MST.safeTransferFrom(msg.sender, address(this), _amount);
        emit TransferIn(msg.sender, _amount);
    }

    function transferOut(address _receiver, uint256 _amount)
        external
        onlyRole(TOKEN_OUT_ROLE)
        whenNotPaused
        nonReentrant
    {
        require(_receiver != address(0), "Receive address can not be zero");
        require(
            MS_BSC_MST.balanceOf(address(this)) >= _amount,
            "Insufficient Balance"
        );
        MS_BSC_MST.safeTransfer(_receiver, _amount);
        emit TransferOut(_receiver, _amount);
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            Address.sendValue(payable(owner()), balance);
        }
    }

    function withdrawERC20(address _tokenContract)
        external
        onlyOwner
        nonReentrant
    {
        uint256 balance = IERC20(_tokenContract).balanceOf(address(this));
        if (balance > 0) {
            IERC20(_tokenContract).safeTransfer(owner(), balance);
        }
    }
}