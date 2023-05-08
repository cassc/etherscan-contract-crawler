// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract YeahToken is ERC20, Ownable {
    event AddMinter(address minter);
    event RemoveMinter(address minter);

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private minters;

    modifier onlyMinter() {
        require(isMinter(msg.sender), "YeahToken: Caller is not the minter");
        _;
    }

    constructor() ERC20("YeahToken", "Yeah!") {}

    function addMinter(address minter) external onlyOwner returns (bool) {
        require(minter != address(0), "YeahToken.addMinter: Zero address");
        emit AddMinter(minter);
        return EnumerableSet.add(minters, minter);
    }

    function removeMinter(address minter) external onlyOwner returns (bool) {
        require(minter != address(0), "YeahToken.removeMinter: Zero address");
        emit RemoveMinter(minter);
        return EnumerableSet.remove(minters, minter);
    }

    function isMinter(address account) public view returns (bool) {
        return EnumerableSet.contains(minters, account);
    }

    function mint(address to, uint256 amount) public onlyMinter {
        require(amount > 0, "YeahToken.mint: Zero amount");
        _mint(to, amount);
    }

    function burn(address account, uint256 amount) public onlyMinter {
        require(amount > 0, "YeahToken.burn: Zero amount");
        _burn(account, amount);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account);
    }

    function totalSupply() public view override returns (uint256) {
        return super.totalSupply();
    }

    function _transfer(address, address, uint256) internal pure override {
        revert("YeahToken: transfer are disabled");
    }

    function allowance(
        address,
        address
    ) public pure override returns (uint256) {
        revert("YeahToken: allowance are disabled");
    }

    function approve(address, uint256) public pure override returns (bool) {
        revert("YeahToken: approve are disabled");
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public pure override returns (bool) {
        revert("YeahToken: transferFrom are disabled");
    }

    function getMinterSize() external view returns (uint256) {
        return EnumerableSet.length(minters);
    }

    function getMinter(
        uint256 index
    ) external view onlyOwner returns (address) {
        require(
            index <= EnumerableSet.length(minters) - 1,
            "YeahToken.getMinter: Out of Bounds"
        );
        return EnumerableSet.at(minters, index);
    }
}