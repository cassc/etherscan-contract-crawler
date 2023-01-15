// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

error Unauthorized();
error ZeroAddress();
error NullValue();
error ClaimEnded();

contract WTF is ERC20Burnable, Ownable {
    mapping(uint256 => string) public contractName;
    mapping(uint256 => address) public authorizedContractAddress;
    mapping(uint256 => uint256) public emissionRate;
    mapping(uint256 => uint256) public claimEndTime;

    constructor() ERC20("WTF", "WTF") {}

    function reserveMint(uint256 totalSupply_) external onlyOwner {
        _mint(msg.sender, totalSupply_);
    }

    function setAuthorizedContractAddressData(
        uint256 index,
        string calldata contractName_,
        address address_,
        uint256 emissionRate_,
        uint256 claimEndTime_
    ) public onlyOwner {
        if (address_ == address(0)) revert ZeroAddress();
        if (emissionRate_ == 0) revert NullValue();

        contractName[index] = contractName_;
        authorizedContractAddress[index] = address_;
        emissionRate[index] = emissionRate_;
        claimEndTime[index] = claimEndTime_;
    }

    function claimRewards(uint256 index_, address to_, uint256 total_) public {
        if (msg.sender != authorizedContractAddress[index_])
            revert Unauthorized();
        if (claimEndTime[index_] > 0) {
            if (block.timestamp > claimEndTime[index_]) revert ClaimEnded();
        }

        _mint(to_, total_);
    }

    function getEmissionRate(uint256 index_) public view returns (uint256) {
        return emissionRate[index_];
    }
}