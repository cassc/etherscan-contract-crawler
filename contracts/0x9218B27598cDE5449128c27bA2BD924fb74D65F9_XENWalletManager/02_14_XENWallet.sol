// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IXENCrypto.sol";

contract XENWallet is Initializable {
    IXENCrypto public XENCrypto;
    address public manager;

    function initialize(address xenAddress, address managerAddress)
        public
        initializer
    {
        XENCrypto = IXENCrypto(xenAddress);
        manager = managerAddress;
    }

    function getUserMint() external view returns (IXENCrypto.MintInfo memory) {
        return XENCrypto.getUserMint();
    }

    // Claim ranks
    function claimRank(uint256 _term) public {
        require(msg.sender == manager, "No access");

        XENCrypto.claimRank(_term);
    }

    // Claim mint reward
    function claimAndTransferMintReward(address target)
        external
        returns (uint256 reward)
    {
        require(msg.sender == manager, "No access");

        uint256 balanceBefore = XENCrypto.balanceOf(target);
        XENCrypto.claimMintRewardAndShare(target, 100);
        reward = XENCrypto.balanceOf(target) - balanceBefore;
    }
}