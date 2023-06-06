// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Admins.sol";

// @author: miinded.com

contract Royalties is Admins {
    using SafeMath for uint256;

    /**
    @notice Struct containing the association between the wallet and its share
    @dev The share can be /100 or /1000 or something else like /50
    */
    struct Part {
        address wallet;
        uint256 royaltiesPart;
    }

    /**
    @notice Stock the parts of each wallets
    */
    Part[] public parts;

    /**
    @dev Calculation of the divider for royalties for the calculation of each part
    */
    uint256 public royaltiesDivider;

    /**
    @dev list of ERC20 Token available for the withdraw
    */
    address[] public ERC20Address;

    constructor(Part[] memory _parts){
        ERC20Address.push(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // USDC
        ERC20Address.push(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // WETH
        ERC20Address.push(0x6B175474E89094C44Da98b954EedeAC495271d0F); // DAI

        _addParts(_parts);
    }

    /**
    @notice Add a new wallet in the withdraw process
    @dev this method is only internal, it's not possible to add someone after the contract minting
    */
    function _addPart(Part memory _part) internal {
        parts.push(_part);
        royaltiesDivider += _part.royaltiesPart;
    }
    function _addParts(Part[] memory _parts) internal {
        for(uint256 i = 0; i < _parts.length; i++){
            _addPart(_parts[i]);
        }
    }

    /**
    @notice Run the transfer of all ETH to the wallets with each % part of royalties
    */
    function withdraw() public onlyOwnerOrAdmins {

        uint256 balance = address(this).balance;
        require(balance > 0, "Contract Balance = 0");

        for(uint8 i = 0; i < parts.length; i++){
            if(parts[i].royaltiesPart > 0){
                _withdraw(parts[i].wallet, balance.mul(parts[i].royaltiesPart).div(royaltiesDivider));
            }
        }
    }

    /**
    @notice Run the transfer of all Token ERC20 to the wallets with each % part royalties
    */
    function withdrawERC20() public onlyOwnerOrAdmins {

        for(uint256 j = 0; j < ERC20Address.length; j++){
            if(ERC20Address[j] == address(0)){
                continue;
            }
            uint256 balance = IERC20(ERC20Address[j]).balanceOf(address(this));
            for(uint256 i = 0; i < parts.length; i++){
                if(parts[i].royaltiesPart > 0 && balance > 0){
                    IERC20(ERC20Address[j]).transfer(parts[i].wallet, balance.mul(parts[i].royaltiesPart).div(royaltiesDivider));
                }
            }
        }
    }

    /**
    @notice Do a transfer ETH to _address
    */
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    /**
    @notice Add a new ERC20 Token in the contract withdraw
    */
    function addERC20Address(address _contract) public onlyOwnerOrAdmins{
        ERC20Address.push(_contract);
    }

    /**
    @notice Remove a ERC20 Token in the contract withdraw
    */
    function removeERC20Address(address _contract) public onlyOwnerOrAdmins{
        for(uint256 i = 0; i < ERC20Address.length;i++){
            if(ERC20Address[i] == _contract){
                ERC20Address[i] = address(0);
            }
        }
    }

    receive() external payable {}
}