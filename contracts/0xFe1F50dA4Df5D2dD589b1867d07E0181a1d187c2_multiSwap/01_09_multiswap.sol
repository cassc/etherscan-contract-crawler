// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Whitelist is Ownable{
    mapping(address => bool) whitelistedAddresses;

    modifier isWhitelisted(address _address) {
      require(whitelistedAddresses[_address], "Whitelist: You need to be whitelisted");
      _;
    }
    function whitelist(address _addressToWhitelist) public onlyOwner {
      whitelistedAddresses[_addressToWhitelist] = true;
    }
    function batchWhitelist(address[] memory _addressToWhitelist) public onlyOwner {
      uint size = _addressToWhitelist.length;
      for(uint256 i=0; i< size; i++){
          address user = _addressToWhitelist[i];
          whitelistedAddresses[user] = true;
        }
    }
    function verifyWhitelistedAddress(address _whitelistedAddress) public view returns(bool) {
      bool userIsWhitelisted = whitelistedAddresses[_whitelistedAddress];
      return userIsWhitelisted;
    }
}

contract multiSwap is Whitelist{
    using SafeERC20 for IERC20;

    receive() external payable {
    }

    function swapExactETHForTokens(address weth, address tokenAddress, address dexRouterAddress, uint256 amountOutMin) external payable isWhitelisted(msg.sender){
        require(weth !=  address(0),"Invalid weth address");
        require(tokenAddress !=  address(0),"Invalid token address");
        require(dexRouterAddress !=  address(0),"Invalid router address");
        require(amountOutMin != 0,"amountOutMin cannot be zero.");
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = tokenAddress;
        uint256 deadline = block.timestamp + 1000;
        IUniswapV2Router02(dexRouterAddress).swapExactETHForTokens{value: msg.value}(amountOutMin, path, address(this), deadline);
    }

    function swapExactTokensForETH(address tokenAddress, address weth, address dexRouterAddress, uint256 amountIn, uint256 amountOutMin) external isWhitelisted(msg.sender){
        require(tokenAddress !=  address(0),"Invalid token address");
        require(weth !=  address(0),"Invalid weth address");
        require(dexRouterAddress !=  address(0),"Invalid router address");
        require(amountIn != 0,"amountIn cannot be zero.");
        require(amountOutMin != 0,"amountOutMin cannot be zero.");
        IERC20 token = IERC20(tokenAddress);
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = weth;
        uint256 deadline = block.timestamp + 1000;
        token.safeApprove(dexRouterAddress, amountIn);
        IUniswapV2Router02(dexRouterAddress).swapExactTokensForETH(amountIn, amountOutMin, path, msg.sender, deadline);
    }

    function withdrawToken(address token) external onlyOwner {
        require(token !=  address(0),"Invalid token address");
        IERC20 tokenAddress = IERC20(token);
        uint256 amountToken = IERC20(token).balanceOf(address(this));
        tokenAddress.safeTransfer(msg.sender, amountToken);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawETH() external onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(getBalance());
    }
}