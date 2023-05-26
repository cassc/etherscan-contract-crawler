// SPDX-License-Identifier: AGPL-1.0
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Deposit is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 v1CATAddress = IERC20(0x3734Dc0D241B5AD886Fa6Bff45fFA67252AC0E89);
    IERC20 v2CATAddress = IERC20(0xf838BFC59469b3Ce459C833d488298e0B66E397e);//<--- SET THIS
    address public treasuryAddress = 0xfcc257B471A66577f1D24A28574C25d2F79A016B;
    bool public depositActive = false;

    constructor() {}

    function depositTokens() external nonReentrant {
        require(depositActive, "DEPOSIT_INACTIVE");
        require(v1CATAddress.balanceOf(_msgSender()) > 0, 'BALANCE_IS_0');
        uint256 v1CATAmount = v1CATAddress.balanceOf(_msgSender());
        IERC20(v1CATAddress).transferFrom(_msgSender(), treasuryAddress, v1CATAmount);
        // v1CAT is 10**9; v2CAT is 10**18; ratio is 1000:1 v1CAT:v2CAT
        // Convert to 18 decimals then divide by 1000
        uint256 v2CATAmount = v1CATAmount * 10**9 / 1000;
        require(v2CATAmount <= IERC20(v2CATAddress).balanceOf(address(this)));
        IERC20(v2CATAddress).transfer(_msgSender(), v2CATAmount);
        emit DepositTokens(_msgSender(), v1CATAmount, v2CATAmount);
    }

    function depositCAT(uint256 amount) external onlyOwner {
        IERC20(v2CATAddress).transferFrom(_msgSender(), address(this), amount);
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasuryAddress = _treasury;
    }

    function toggleDepositActive() external onlyOwner {
        depositActive = !depositActive;
    }

    function setV1CATAddress(address _v1CATAddress) external onlyOwner {
        v1CATAddress = IERC20(_v1CATAddress);
    }

    function setV2CATAddress(address _v2CATAddress) external onlyOwner {
        v2CATAddress = IERC20(_v2CATAddress);
    }

    /*******************/
    /*  GENERAL ADMIN  */
    /*******************/

    function withdrawTokens(address _token) external onlyOwner nonReentrant {
        IERC20(_token).safeTransfer(treasuryAddress, IERC20(_token).balanceOf(address(this)));
        emit Withdraw(_msgSender(), _token);
    }
    
    function withdraw() external onlyOwner nonReentrant {
        payable(treasuryAddress).transfer(address(this).balance);
    }

    event DepositTokens(address indexed msgSender, uint256 indexed v1CATAmount, uint256 indexed v2CATAmount);
    event Withdraw(address indexed msgSender, address indexed token);
}