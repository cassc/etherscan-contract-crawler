// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
 

abstract contract MultipleWalletWithdrawable is Ownable {

    using SafeMath for uint256;
    
    address[] internal _wallets = [
        0xaAabE0E0681A77A6DDBf71FEf260519db40e473a,
        0x222aBd1cF0217736E49A99755C41EfcbB0c41568,
        0xcAABCa8e9740Fb96c547F7ab8BeC4F61DB67A130
    ];

    uint256[] internal _ratio = [90, 5, 5];

    function updateWalletAddress(uint256 idx, address _address)
        external
        onlyOwner
    {
        _wallets[idx] = _address;
    }

    // withdraw the balance if needed
    function withdraw() external onlyOwner {
        uint256 originalBalance = address(this).balance;
        for (uint256 i = 0; i < _wallets.length; i++) {
            payable(_wallets[i]).transfer(
                originalBalance.mul(_ratio[i]).div(100)
            );
        }
    }


    // return the wallet address by index
    function walletAddress(uint256 idx) external view returns (address) {
        return _wallets[idx];
    }

    // return the ratio by index
    function ratio(uint256 idx) external view returns (uint256) {
        return _ratio[idx];
    }




}