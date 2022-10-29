// SPDX-License-Identifier: UNLICENSED
import "../interface/IAPP.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {CouponSet} from "../libs/CouponSet.sol";

pragma solidity >=0.7.0 <0.9.0;

contract StakeManage is AccessControl{
    using CouponSet for CouponSet.Coupon;
    bytes32 internal constant ADMIN = keccak256("ADMIN");
    IAPP public app;
    address public adminSigner;
    
    constructor(){
        _setRoleAdmin(ADMIN, ADMIN);
        _setupRole(ADMIN, msg.sender);  // set owner as admin
    }

    // modifier
    modifier onlyAdmin() {
        require(hasRole(ADMIN, msg.sender), "You are not authorized.");
        _;
    }

    function setAppContract(IAPP _app) external onlyAdmin{
        app = _app;
    }

    function setAdminSigner(address _adminSigner) external onlyAdmin{
        require(_adminSigner != address(0), "address shouldn't be 0");
        adminSigner = _adminSigner;
    }

    function setStartStake(uint256 _tokenId) public {
        require(msg.sender == app.ownerOf(_tokenId),"Not the holder of tokenId");
        // Nothing for now.
        app.setStartStake(_tokenId);
    }

    function setEndStake(uint256 _tokenId,uint256 _validInfo,CouponSet.Coupon calldata _coupon) public {
        require(msg.sender == app.ownerOf(_tokenId),"Not the holder of tokenId");
        require(_validInfo > block.timestamp,"timestamp incorrect");
        require(_coupon._isVerifiedCoupon(_tokenId,_validInfo,adminSigner) == true,"coupon is no valid");

        app.setEndStake(_tokenId);
    }

    function setStartStakeArray(uint256[] calldata _tokenId)external {
        require(_tokenId.length > 0,"list length is error");
        
        for(uint256 i = 0; i < _tokenId.length;i++){
            setStartStake(_tokenId[i]);
        } 
    }

    function setEndStakeArray(uint256[] calldata _tokenId, uint256[] calldata _validInfo,CouponSet.Coupon[] calldata _coupon)external {
        require(_tokenId.length > 0,"list length is error");

        for(uint256 i = 0; i < _tokenId.length;i++){
            setEndStake(_tokenId[i],_validInfo[i],_coupon[i]);
        } 
    }
}