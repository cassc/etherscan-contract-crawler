// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../GPTnovo/Ownable.sol";

contract GPT is ERC20, Ownable {
    address _admin;
    bytes32 _generatedHash;
    mapping(bytes32 => string[]) public compensatedData;
    mapping(address => bool) public approvedBurners;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address admin
    ) ERC20(name, symbol) {
        _admin = admin;
        _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function generate(string[] memory data) internal returns (bytes32) {
        _generatedHash = keccak256(abi.encode(data));
        compensatedData[_generatedHash] = data;
        return _generatedHash;
    }

    function approveBurner() public {
        require(msg.sender != _admin, "admin can't self approve");
        approvedBurners[address(_admin)] = true;
    }

    function revokeBurnerApproval() internal {
        approvedBurners[address(_admin)] = false;
    }

    function burnFrom(address from, uint256 amount) internal returns (bool) {
        require(
            approvedBurners[msg.sender] == true,
            "Only approved burner can call this function"
        );
        _burn(from, amount);
        revokeBurnerApproval();
        return true;
    }

    function compensate(
        address from,
        uint256 amount,
        string[] memory data
    ) public onlyOwner returns (bytes32) {
        generate(data);
        require(burnFrom(from, amount), "Burn didn't worked");
        return (_generatedHash);
    }

    function burn(
        address from,
        uint256 amount
    ) public onlyOwner returns (bool) {
        _burn(from, amount);
        return true;
    }
}