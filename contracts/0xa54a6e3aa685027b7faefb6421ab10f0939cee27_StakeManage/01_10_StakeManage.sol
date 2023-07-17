// SPDX-License-Identifier: MIT

import "../interface/INFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {CouponSet} from "../libs/CouponSet.sol";

pragma solidity >=0.7.0 <0.9.0;

contract StakeManage is AccessControl{
    using CouponSet for CouponSet.Coupon;
    bytes32 public constant ADMIN = keccak256("ADMIN");
    INFT public nft;
    address public adminSigner;
    
    constructor(){
        _setRoleAdmin(ADMIN, ADMIN);
        _grantRole(ADMIN, msg.sender);  // set owner as admin
    }

    // modifier
    modifier onlyAdmin() {
        require(hasRole(ADMIN, msg.sender), "You are not authorized.");
        _;
    }

    function setAppContract(INFT _nft) external onlyAdmin{
        nft = _nft;
    }

    function setAdminSigner(address _adminSigner) external onlyAdmin{
        require(_adminSigner != address(0), "address shouldn't be 0");
        adminSigner = _adminSigner;
    }

    function setStartStakeArray(uint256[] calldata _tokenIds)external {
        require(_tokenIds.length > 0,"list length is error");
        
        // check
        for(uint256 i = 0; i < _tokenIds.length;i++){
            require(msg.sender == nft.ownerOf(_tokenIds[i]),"Not the holder of tokenId");
        } 
        nft.setStartStake(_tokenIds);
    }

    function setEndStakeArray(uint256[] calldata _tokenIds, uint256[] calldata _validInfo,CouponSet.Coupon[] calldata _coupon)external {
        require(_tokenIds.length > 0,"list length is error");
        require(_tokenIds.length == _validInfo.length,"list length is error");
        require(_tokenIds.length == _coupon.length,"list length is error");

        // check
        for(uint256 i = 0; i < _tokenIds.length;i++){
            require(msg.sender == nft.ownerOf(_tokenIds[i]),"Not the holder of tokenId");
            require(_validInfo[i] > block.timestamp,"timestamp incorrect");
            require(_coupon[i]._isVerifiedCoupon(_tokenIds[i],_validInfo[i],adminSigner) == true,"coupon is no valid");
        } 
        nft.setEndStake(_tokenIds);
    }
}