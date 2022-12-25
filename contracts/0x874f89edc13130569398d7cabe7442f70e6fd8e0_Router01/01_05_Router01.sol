pragma solidity 0.8.3;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/WETH.sol";

interface ERC721LendingPool02 {

  function _supportedCurrency() external view returns (address);

  function borrow(
      uint256[5] memory x,
      bytes memory signature,
      bool proxy,
      address pineWallet
  ) external returns (bool);

  function repay(
      uint256 nftID,
      uint256 repayAmount,
      address pineWallet
  ) external returns (bool);

}

contract Router01 is Ownable {

  address immutable WETHaddr;
  address payable immutable controlPlane;

  constructor (address w, address payable c) {
    WETHaddr = w;
    controlPlane = c;
  }

  uint fee = 0.01 ether;

  function setFee(uint f) public onlyOwner {
    fee = f;
  }

  function batchBorrowETH(
    address payable[] memory targets, 
    uint256[] memory valuation,
    uint256[] memory nftID,
    uint256[] memory loanDurationSeconds,
    uint256[] memory expireAtBlock,
    uint256[] memory borrowedWei,
    bytes[] memory signature,
    address pineWallet
  ) public {
    for (uint16 i = 0; i < targets.length; i ++) {
      address currency = ERC721LendingPool02(targets[i])._supportedCurrency();
      require(currency == WETHaddr, "only works for WETH");
      ERC721LendingPool02(targets[i]).borrow([valuation[i], nftID[i], loanDurationSeconds[i], expireAtBlock[i], borrowedWei[i]], signature[i], true, pineWallet);
    }

    WETH9(payable(WETHaddr)).transfer(controlPlane, fee);

    WETH9(payable(WETHaddr)).withdraw(IERC20(WETHaddr).balanceOf(address(this)));
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "cannot send ether");
  }

  function batchRepayETH(address payable[] memory targets, uint[] memory nftIDs, uint256[] memory repayAmounts, address pineWallet) payable public {
    require(targets.length == nftIDs.length, "targets length should be same as nftIDs length");

    uint256 totalAmount = 0;
    
    for (uint16 i = 0; i < targets.length; i += 1) {
      address currency = ERC721LendingPool02(targets[i])._supportedCurrency();
      require(currency == WETHaddr, "only works for WETH");
      totalAmount += repayAmounts[i];
    }
    require(msg.value >= totalAmount, "invalid repay amounts");

    WETH9(payable(WETHaddr)).deposit{value: msg.value}();

    for (uint16 i = 0; i < targets.length; i += 1) {
      _repay(targets[i], nftIDs[i], repayAmounts[i], pineWallet);
    }

    WETH9(payable(WETHaddr)).withdraw(IERC20(WETHaddr).balanceOf(address(this)));
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "cannot send ether");
  }

  function _repay(address payable target, uint nftID, uint256 repayAmount, address pineWallet) internal {
    address currency = ERC721LendingPool02(target)._supportedCurrency();
    IERC20(currency).approve(target, repayAmount);
    ERC721LendingPool02(target).repay(nftID, repayAmount, pineWallet);
  }

  function withdraw(uint256 amount) external onlyOwner {
      (bool success, ) = owner().call{value: amount}("");
      require(success, "cannot send ether");
  }

  function withdrawERC20(address currency, uint256 amount) external onlyOwner {
      IERC20(currency).transfer(owner(), amount);
  }
  
}