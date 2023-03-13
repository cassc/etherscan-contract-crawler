pragma solidity 0.8.15;
import "@openzeppelin/contracts-v4/access/Ownable.sol";
import "@openzeppelin/contracts-v4/utils/Address.sol";
import "@openzeppelin/contracts-v4/utils/math/Math.sol";
import "@openzeppelin/contracts-v4/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IGauge.sol";
import "./interfaces/IVault.sol";


contract GaugeZap is Ownable {

  using SafeERC20 for IERC20;
  using Address for address;
  // using SafeMath for uint256;
  
  function deposit(address _gauge, uint256 _amount) public {
    address _vault = address(IGauge(_gauge).asset());
    address _token = IVault(_vault).token();

    uint256 _preToken = IERC20(_token).balanceOf(address(this));
    IERC20(_token).transferFrom(msg.sender, address(this), _amount);
    uint256 _postToken = IERC20(_token).balanceOf(address(this));

    uint256 _preShare = IVault(_vault).balanceOf(address(this));
    IERC20(_token).approve(_vault, _postToken - _preToken);
    IVault(_vault).deposit(_postToken - _preToken);
    uint256 _postShare = IVault(_vault).balanceOf(address(this));

    IVault(_vault).approve(_gauge, _postShare - _preShare);
    IGauge(_gauge).deposit(_postShare - _preShare, msg.sender);
  }

  function withdrawal(address _gauge, uint256 _share) public {

    address _vault = address(IGauge(_gauge).asset());
    address _token = IVault(_vault).token();

    uint256 _preVault = IVault(_vault).balanceOf(address(this));
    IGauge(_gauge).withdraw(_share, address(this), msg.sender);
    uint256 _postVault = IVault(_vault).balanceOf(address(this));


    uint256 _preToken = IERC20(_token).balanceOf(address(this));
    IVault(_vault).withdraw(_postVault - _preVault);
    uint256 _postToken = IERC20(_token).balanceOf(address(this));

    IERC20(_token).transfer(msg.sender, _postToken - _preToken);

  }

}