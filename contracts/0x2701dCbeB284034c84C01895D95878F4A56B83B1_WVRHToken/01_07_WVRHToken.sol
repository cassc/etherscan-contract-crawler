// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Ownable.sol";
import "EnumerableSet.sol";
import "ERC20.sol";

contract WVRHToken is ERC20, Ownable {

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private minters;

    constructor(
        string memory _name,
        string memory _symbol,
        address _fundAddress,
        uint256 _mintAmount
    ) ERC20(_name, _symbol) {
        _mint(_fundAddress, _mintAmount * (10**decimals()));
    }

    function addMinter(address _minter) external onlyOwner {
        minters.add(_minter);
    }

    function deleteMinter(address _minter) external onlyOwner {
        minters.remove(_minter);
    }

    function isMinter(address _minter) public view returns (bool){
        return minters.contains(_minter);
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "not minter");
        _;
    }


    function mint(address account, uint256 amount) external onlyMinter {
        _mint(account, amount);
    }
}