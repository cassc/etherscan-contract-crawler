/**

 ______     __  __     __     ______     ______     ______     __     __  __     __    __    
/\  ___\   /\ \_\ \   /\ \   /\  == \   /\  __ \   /\  == \   /\ \   /\ \/\ \   /\ "-./  \   
\ \___  \  \ \  __ \  \ \ \  \ \  __<   \ \  __ \  \ \  __<   \ \ \  \ \ \_\ \  \ \ \-./\ \  
 \/\_____\  \ \_\ \_\  \ \_\  \ \_____\  \ \_\ \_\  \ \_\ \_\  \ \_\  \ \_____\  \ \_\ \ \_\ 
  \/_____/   \/_/\/_/   \/_/   \/_____/   \/_/\/_/   \/_/ /_/   \/_/   \/_____/   \/_/  \/_/ 
 _____     ______     ______                                                                 
/\  __-.  /\  __ \   /\  __ \                                                                
\ \ \/\ \ \ \  __ \  \ \ \/\ \                                                               
 \ \____-  \ \_\ \_\  \ \_____\                                                              
  \/____/   \/_/\/_/   \/_____/                                                              


    Website: https://shibariumdao.io
    Telegram: https://t.me/ShibariumDAO

**/
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakingRewardsClaim is EIP712, Ownable {
    IERC20 public immutable SHIB;
    IERC20 public immutable BONE;

    mapping(address => bool) public claimed;

    bytes32 public constant CLAIM_TYPEHASH =
        keccak256(
            "Claim(uint256 shibAmount,uint256 boneAmount,address staker)"
        );

    constructor(
        address shib,
        address bone
    ) EIP712("StakingRewardsClaim", "1") Ownable() {
        SHIB = IERC20(shib);
        BONE = IERC20(bone);
    }

    function claimMyRewards(
        uint256 shibAmount,
        uint256 boneAmount,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external {
        require(claimed[msg.sender] == false, "Already claimed");

        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(CLAIM_TYPEHASH, shibAmount, boneAmount, msg.sender)
            )
        );

        address signer = ECDSA.recover(digest, v, r, s);
        require(signer == owner(), "Invalid signature");

        claimed[msg.sender] = true;

        bool successShib = SHIB.transfer(msg.sender, shibAmount);
        require(successShib, "Transfer failed");

        bool successBone = BONE.transfer(msg.sender, boneAmount);
        require(successBone, "Transfer failed");
    }

    function clearBalance(address _token) external onlyOwner {
        if (_token == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20 token = IERC20(_token);
            token.transfer(msg.sender, token.balanceOf(address(this)));
        }
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }
}