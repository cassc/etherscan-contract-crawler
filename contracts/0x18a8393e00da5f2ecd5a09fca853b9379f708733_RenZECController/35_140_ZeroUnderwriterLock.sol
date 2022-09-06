// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import { IZeroModule } from "../interfaces/IZeroModule.sol";
import { Initializable } from "oz410/proxy/Initializable.sol";
import { IERC20 } from "oz410/token/ERC20/ERC20.sol";
import { IERC721 } from "oz410/token/ERC721/IERC721.sol";
import { SafeMath } from "oz410/math/SafeMath.sol";
import { IyVault } from "../interfaces/IyVault.sol";
import { ZeroController } from "../controllers/ZeroController.sol";
import { ZeroLib } from "../libraries/ZeroLib.sol";
import { SafeERC20 } from "oz410/token/ERC20/SafeERC20.sol";

import "hardhat/console.sol";

/**
@title contract to hold locked underwriter funds while the underwriter is active
@author raymondpulver
*/
contract ZeroUnderwriterLock is Initializable {
  using SafeMath for *;
  using SafeERC20 for *;
  ZeroController public controller;
  address public vault;
  ZeroLib.BalanceSheet internal _balanceSheet;

  modifier onlyController() {
    require(msg.sender == address(controller), "!controller");
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == owner(), "must be called by owner");
    _;
  }

  function balanceSheet()
    public
    view
    returns (
      uint256 loaned,
      uint256 required,
      uint256 repaid
    )
  {
    (loaned, required, repaid) = (uint256(_balanceSheet.loaned), uint256(_balanceSheet.required), _balanceSheet.repaid);
  }

  function owed() public view returns (uint256 result) {
    if (_balanceSheet.loaned >= _balanceSheet.repaid) {
      result = uint256(_balanceSheet.loaned).sub(_balanceSheet.repaid);
    } else {
      result = 0;
    }
  }

  function reserve() public view returns (uint256 result) {
    result = IyVault(vault).balanceOf(address(this)).mul(IyVault(vault).getPricePerFullShare()).div(uint256(1 ether));
  }

  function owner() public view returns (address result) {
    result = IERC721(address(controller)).ownerOf(uint256(uint160(address(this))));
  }

  /**
  @notice sets the owner to the ZeroUnderwriterNFT
  @param _vault the address of the LP token which will be either burned or redeemed when the NFT is destroyed
  */
  function initialize(address _vault) public {
    controller = ZeroController(msg.sender);
    vault = _vault;
  }

  /**
  @notice send back non vault tokens if they are stuck
  @param _token the token to send the entire balance of to the sender
  */
  function skim(address _token) public {
    require(address(vault) != _token, "cannot skim vault token");
    IERC20(_token).safeTransfer(msg.sender, IERC20(_token).balanceOf(address(this)));
  }

  /**
  @notice destroy this contract and send all vault tokens to NFT contract
  */
  function burn(address receiver) public onlyController {
    require(
      IyVault(vault).transfer(receiver, IyVault(vault).balanceOf(address(this))),
      "failed to transfer vault token to receiver"
    );
    selfdestruct(payable(msg.sender));
  }

  function trackOut(address module, uint256 amount) public {
    require(msg.sender == address(controller), "!controller");
    uint256 loanedAfter = uint256(_balanceSheet.loaned).add(amount);
    uint256 _owed = owed();
    (_balanceSheet.loaned, _balanceSheet.required) = (
      uint128(loanedAfter),
      uint128(
        uint256(_balanceSheet.required).mul(_owed).div(uint256(1 ether)).add(
          IZeroModule(module).computeReserveRequirement(amount).mul(uint256(1 ether)).div(_owed.add(amount))
        )
      )
    );
  }

  function _logSheet() internal view {
    console.log("required", _balanceSheet.required);
    console.log("loaned", _balanceSheet.loaned);
    console.log("repaid", _balanceSheet.repaid);
  }

  function trackIn(uint256 amount) public {
    require(msg.sender == address(controller), "!controller");
    uint256 _owed = owed();
    uint256 _adjusted = uint256(_balanceSheet.required).mul(_owed).div(uint256(1 ether));
    _balanceSheet.required = _owed < amount || _adjusted < amount
      ? uint128(0)
      : uint128(_adjusted.sub(amount).mul(uint256(1 ether)).div(_owed.sub(amount)));
    _balanceSheet.repaid = _balanceSheet.repaid.add(amount);
  }
}