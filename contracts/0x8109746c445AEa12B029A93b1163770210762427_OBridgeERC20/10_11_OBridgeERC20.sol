// contracts/OBridgeERC20.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./utils/MinterRole.sol";
import "./interfaces/IWrappedNativeToken.sol";

contract OBridgeERC20 is ERC20, Ownable, MinterRole {
    using SafeERC20 for IERC20;

    uint8 private immutable decimal;
    address public immutable orgToken;
    
    event LogOBTokenSwapOut(uint uID, address indexed account, uint amount, uint form);

    constructor(string memory _name, string memory _symbol, uint8 _decimal, address _orgToken) ERC20(_name, _symbol) {
        orgToken = _orgToken;
        decimal = _decimal;
    }
    
    receive() external payable { }

    function init(address _routerAddress) external onlyOwner {
        addMinter(_routerAddress);
        transferOwnership(_routerAddress);
    }

    function decimals() public view override returns (uint8) {
        return decimal;
    }

    function getOrgToken() external view returns (address) {
        return orgToken;
    }

    function mint(address to, uint256 amount) external onlyMinter returns (bool) {
        _mint(to, amount);
        
        return true;
    }

    function burn(address from, uint256 amount) external onlyMinter returns (bool) {
        _burn(from, amount);
        
        return true;
    }

    function deposit() external returns (uint) {
        return _deposit(IERC20(orgToken).balanceOf(msg.sender), msg.sender);
    }

    function deposit(uint amount) external returns (uint) {
        return _deposit(amount, msg.sender);
    }

    function deposit(uint amount, address to) external returns (uint) {
        return _deposit(amount, to);
    }

    function _deposit(uint amount, address to) internal returns (uint) {
        require(orgToken != address(0) && orgToken != address(this));
        
        IERC20(orgToken).safeTransferFrom(msg.sender, address(this), amount);
        _mint(to, amount);
        
        return amount;
    }

    function withdraw() external returns (uint) {
        return _withdraw(msg.sender, balanceOf(msg.sender), msg.sender);
    }

    function withdraw(uint amount) external returns (uint) {
        return _withdraw(msg.sender, amount, msg.sender);
    }

    function withdraw(uint amount, address to) external returns (uint) {
        return _withdraw(msg.sender, amount, to);
    }

    function _withdraw(address from, uint amount, address to) internal returns (uint) {
        require(orgToken != address(0) && orgToken != address(this));
        
        _burn(from, amount);
        IERC20(orgToken).safeTransfer(to, amount);
        
        return amount;
    }

    function swapOut(uint uID, address to, uint256 amount, uint form) external onlyOwner returns (bool) {
        if(orgToken != address(0)) {
            if (IERC20(orgToken).balanceOf(address(this)) >= amount) {
                if(form == 0) {
                    IWrappedNativeToken(orgToken).withdraw(amount);
                    payable(to).transfer(amount);

                    emit LogOBTokenSwapOut(uID, to, amount, 0);
                } else {
                    IERC20(orgToken).safeTransfer(to, amount);

                    emit LogOBTokenSwapOut(uID, to, amount, 1);
                }

                return true;
            }
        }

        _mint(to, amount);

        emit LogOBTokenSwapOut(uID, to, amount, 2);

        return true;
    }
}