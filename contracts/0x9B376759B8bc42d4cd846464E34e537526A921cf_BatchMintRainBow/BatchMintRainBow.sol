/**
 *Submitted for verification at Etherscan.io on 2023-05-04
*/

// 实际mint的NFT合约
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface Clip {
    function mintClips() external;
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

// 创建一个子合约，通过子合约调用NFT合约的purchase方法
contract BatchMintRainBow {
    address public owner;
    bool public mintStart = true;
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this function");
        _;
    }
    constructor() {
        owner = msg.sender;
    }
    function changeOwner(address _address) public onlyOwner {
        owner = _address;
    }
    function changeMintStart(bool _mintStart) public onlyOwner {
        mintStart = _mintStart;
    }
    function batchMint(uint count) public {
        require(mintStart == true, "mint has stopped");
        for (uint i = 0; i < count; i++) {
            new claimer(msg.sender);
        }
    }
}

// 子合约地址
contract claimer {
    address clipAddress = 0xeCbEE2fAE67709F718426DDC3bF770B26B95eD20;
    constructor (address receiver) {
        Clip clip = Clip(clipAddress);
        clip.mintClips();
        clip.transferFrom(address(this), receiver, clip.balanceOf(address(this)));
    }
}