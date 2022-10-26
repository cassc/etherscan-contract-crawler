// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract NFTPausable {

    mapping (address => mapping(uint256 => bool)) private _NFTPause;

    event Pause (address _nftaddress , uint256 _tokenid);
    event unPause (address _nftaddress , uint256 _tokenid); 

    modifier isPause (address _nftaddress , uint256 _tokenid) {
        require(!_NFTPause[_nftaddress][_tokenid], "aleady puase");
        _;
    }

    modifier isUnPause (address _nftaddress , uint256 _tokenid) {
        require(_NFTPause[_nftaddress][_tokenid] , "aleady unpause");
        _;
    }

    function _nftPause (address _nftaddress , uint256 _tokenid) internal virtual 
        isPause(_nftaddress , _tokenid)
    {
        _NFTPause[_nftaddress][_tokenid] = true;
        emit Pause(_nftaddress , _tokenid);
    }

    function _nftUnPause (address _nftaddress , uint256 _tokenid) internal virtual 
        isUnPause(_nftaddress , _tokenid)
    {
        _NFTPause[_nftaddress][_tokenid] = false;
        emit unPause(_nftaddress, _tokenid);
    }

    function Paused (address _nftaddress , uint256 _tokenid) public view virtual returns (bool) {
        return _NFTPause[_nftaddress][_tokenid];
    }
}