// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IChamTHE.sol";
import "../interfaces/ICpTHENA.sol";
import "../interfaces/IVeToken.sol";

contract CpTHENAMinterFromChamTHE is OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    ICpTHENA public cpTHENA;
    IChamTHE public chamTHE; 
    IVeToken public ve;

    bool public isPause;

    event Mint(uint256 amount);
    event OldAddress(address _cpTHENA, address _chamTHE);
    
    modifier onlyOpen() {
        require(isPause == false, "Minter: in pause state");
        _;
    }

    function initialize(address _cpTHENA, address _chamTHE) public initializer {
        __Ownable_init();
        cpTHENA = ICpTHENA(_cpTHENA);
        chamTHE = IChamTHE(_chamTHE);
        ve = IVeToken(cpTHENA.ve());
        isPause = true;
    }

    function mintFromCpTHE(uint256 _amount) external nonReentrant onlyOpen {
        require(_amount > 0, "Minter: ZERO_AMOUNT");
        IERC20Upgradeable(address(chamTHE)).safeTransferFrom(msg.sender, address(this), _amount);
        chamTHE.withdraw(_amount);

        uint256 totalNft = ve.balanceOf(address(this));
        uint256 tokenId = ve.tokenOfOwnerByIndex(address(this), totalNft - 1);
        require(tokenId > 0, "Minter: NOT_WITHDRAW");

        ve.approve(address(cpTHENA), tokenId);
        cpTHENA.depositVe(tokenId);

        uint256 amountOut = IERC20Upgradeable(address(cpTHENA)).balanceOf(address(this));
        require(amountOut > 0, "Minter: NOT_DEPOSIT");
        IERC20Upgradeable(address(cpTHENA)).safeTransfer(msg.sender, amountOut);

        emit Mint(amountOut);
    }

    function setAddress(address _cpTHENA, address _chamTHE) external onlyOwner {
        emit OldAddress(address(cpTHENA), address(chamTHE));
        cpTHENA = ICpTHENA(_cpTHENA);
        chamTHE = IChamTHE(_chamTHE);
        ve = IVeToken(cpTHENA.ve());
    }

    // set pause state
    function setPause(bool _isPause) external onlyOwner {
        isPause = _isPause;
    }
}