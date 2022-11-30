// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./lib/Admin.sol";

interface nftMinter {
    function setApprovalForAll(address operator, bool _approved) external;
    function adminMintsTo(address[] memory _tos, uint256[] memory _tokenIds) external;
}

interface bridger {
    function sendTo(address _nft,uint256 _id,uint64 _dstChid,address _receiver) external payable;
    function totalFee(uint64 _dstChid,address _nft,uint256 _id) external view returns(uint256);
}

contract NftToBridge is Admin {
    nftMinter public nftMintAddr;
    bridger public bridge;

    function initialize(nftMinter _nftMintAddr, bridger _bridge)public initializer
    {
        nftMintAddr = _nftMintAddr;
        bridge = _bridge;
        nftMintAddr.setApprovalForAll(address(bridge), true);
        __Ownable_init();
    }

    function setNftMinterAndBridger(nftMinter _nftMintAddr, bridger _bridge)  external onlyAdmin {
        nftMintAddr.setApprovalForAll(address(bridge), false);
        nftMintAddr = _nftMintAddr;
        bridge = _bridge;
        nftMintAddr.setApprovalForAll(address(bridge), true);
    }

    function nftMint(uint256[] memory _tokenIds) external onlyAdmin{
        address[] memory tos_ = new address[](_tokenIds.length);
        for(uint256 i =0 ;i<_tokenIds.length; i++){
            tos_[i] = address(this);
        }
        nftMintAddr.adminMintsTo(tos_, _tokenIds);
    }

    function sendTo(uint256[] memory _tokenIds, address _receiver, uint64 _dstChid) external payable onlyAdmin{
        uint256 totalfee_ = totalFee(_tokenIds, _dstChid);
        require(msg.value >= totalfee_, "invalid amount");
        for(uint256 i = 0;i<_tokenIds.length; i++){
            bridge.sendTo{value: bridge.totalFee(_dstChid, address(nftMintAddr), _tokenIds[i])}(address(nftMintAddr), _tokenIds[i], _dstChid, _receiver);
        }
    }

    function totalFee(uint256[] memory _tokenIds, uint64 _dstChid)  public view returns (uint256 total_) {
        for(uint256 i =0 ; i < _tokenIds.length; i++){
            total_ += bridge.totalFee(_dstChid, address(nftMintAddr), _tokenIds[i]);
        }
        return total_;
    }

}