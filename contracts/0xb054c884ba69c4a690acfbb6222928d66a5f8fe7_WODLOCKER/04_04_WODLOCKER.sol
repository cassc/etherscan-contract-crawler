// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract WODLOCKER is Ownable
{
    address _token;
    address public _owner;
    uint256 public _totallocked;
    using SafeMath for uint256;
    uint256 public withdrawded;
    uint256 public startRelease;
    uint256 public _totalmonth;
    constructor(address token,address owner,uint256 totallocked,uint256 start,uint256 totalmonth)
    {
        _token=token;
        _owner=owner;
        _totallocked =totallocked;
        _totalmonth= totalmonth;
        startRelease=start;//1694736000;
    }

    function setOwner(address owner) public onlyOwner 
    {
        _owner=owner;
    }

    function getReleasedToken() public view returns(uint256)
    {
        if(startRelease==0)
            return _totallocked;
        if(block.timestamp < startRelease)
            return 0;
        uint month= ((block.timestamp - startRelease) / (86400 * 30)) + 1;
        uint totalrelese=month.mul(_totallocked).div(_totalmonth);
        totalrelese = totalrelese > _totallocked ? _totallocked:totalrelese;
        return totalrelese;
    }

    function TakeOutRelesed(uint256 amount) external
    {
        require(msg.sender== _owner,"onlyOwner");
        uint256 released=getReleasedToken().subwithlesszero(withdrawded);
        require(released >= amount,"notRelesed");
        withdrawded+= amount;
        IERC20(_token).transfer(_owner, amount);
    }
}