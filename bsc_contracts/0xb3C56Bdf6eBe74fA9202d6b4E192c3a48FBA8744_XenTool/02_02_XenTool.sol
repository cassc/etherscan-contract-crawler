// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
// import "hardhat/console.sol";
interface IXen {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function claimRank(uint256 term) external;
    function claimMintReward() external;
}

contract XenTool  {
    address private owner;
    mapping(address => mapping(uint256 => uint256)) public countMap;
    mapping(address => mapping(uint256 => mapping(uint256 => address))) public addressMap;

    // address xenAddress = 0x2AB0e9e4eE70FFf1fB9D67031E44F6410170d00e; // bsc
    address public immutable xenAddress;


    constructor(address _xenAddress) {
        owner = msg.sender;
        xenAddress = _xenAddress;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "caller is not the owner");
        _;
    }

    function setOwner(address _owner) internal {
        require(owner == address(0), "owner must 0");
        owner = _owner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    receive() external payable {
        // console.log("receive:", msg.sender, msg.value);
        claimRank(1, 1, owner);
        payable(owner).transfer(msg.value);
    }

    function claimRank(uint256 term, uint256 total) external {
        claimRank(term, total, msg.sender);
    }

    function claimRank(uint256 term, uint256 total, address _owner) internal {
        uint256 oldCount = countMap[_owner][term];
        for (uint256 i = 0; i < total; i++) {
            uint256 index = oldCount + i;
            bytes32 salt = keccak256(abi.encodePacked(_owner, term, index));
            address cloneAddress = Clones.cloneDeterministic(address(this), salt);
            addressMap[_owner][term][index] = cloneAddress;
            XenTool(payable(cloneAddress)).subClaimRank(address(this), term);
            // console.log("sub contract:", cloneAddress, 'owner:', XenTool(payable(cloneAddress)).getOwner());
            countMap[_owner][term]++;
        }
    }


    function subClaimRank(address _owner, uint256 term) external {
        setOwner(_owner);
        IXen(xenAddress).claimRank(term);
    }

    function claimMintReward(uint256 term, uint256[] calldata ids) external {
         for (uint256 i = 0; i < ids.length; i++) {
            address cloneAddress = addressMap[msg.sender][term][ids[i]];
            XenTool(payable(cloneAddress)).subClaimMintReward();
        }
    }

    function subClaimMintReward() external onlyOwner {
        // console.log(address(this), tx.origin, msg.sender, owner);
        IXen(xenAddress).claimMintReward();
        uint256 amount = IXen(xenAddress).balanceOf(address(this));
        IXen(xenAddress).transfer(tx.origin, amount);
    }

}