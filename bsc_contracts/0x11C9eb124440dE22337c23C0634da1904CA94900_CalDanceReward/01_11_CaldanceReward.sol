// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";




interface CalDanceVoucher {
    struct TokenInfo {
        uint256 id;
        uint256 batch;
        uint256 mintTime;
    }

    function getTokensByOwner(address owner) external view returns (TokenInfo[] memory);
}



contract CalDanceReward is Ownable,UUPSUpgradeable,Initializable {
    address  private _cdtTokenAddr;
    address  private _voucherTokenAddr;

    mapping(uint256 => uint256) public batchToReward;

    mapping(uint256 => bool)    public tokenRewardClaimed;




    function initialize(address cdtTokenAddr,address voucherTokenAddr) public initializer {
        _cdtTokenAddr = cdtTokenAddr;
        _voucherTokenAddr = voucherTokenAddr;
        _transferOwnership(msg.sender);
    }


    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}




    // claim reward
    function claimRewards() external  {
        CalDanceVoucher voucher = CalDanceVoucher(_voucherTokenAddr);
        CalDanceVoucher.TokenInfo[] memory ownTokens = voucher.getTokensByOwner(msg.sender);
        uint256 totalReward = 0;
        for (uint i= 0; i < ownTokens.length;i++) {
            CalDanceVoucher.TokenInfo memory tokenTmp = ownTokens[i];
            bool hasClaimed = tokenRewardClaimed[tokenTmp.id];
            if (hasClaimed) {
                continue;
            }
            totalReward += batchToReward[tokenTmp.batch];
            tokenRewardClaimed[tokenTmp.id] = true;
        }
        require(totalReward > 0,"Caldance: no reward to claim");
        IERC20 cdtToken = IERC20(_cdtTokenAddr);
        require(cdtToken.balanceOf(address(this)) >= totalReward,"Caldance: not enough cdt token");
        require(cdtToken.transfer(msg.sender,totalReward),"Caldance: transfer failed");
    }

    // set reward for batch
    function setBatchReward(uint256 batch,uint256 reward) external onlyOwner {
        batchToReward[batch] = reward;
    }

    // withdraw cdt token
    function withdrawCdtToken(uint256 amount) external onlyOwner {
        IERC20 cdtToken = IERC20(_cdtTokenAddr);
        require(cdtToken.balanceOf(address(this)) >= amount,"Caldance: not enough cdt token");
        require(cdtToken.transfer(msg.sender,amount),"Caldance: transfer failed");
    }


}