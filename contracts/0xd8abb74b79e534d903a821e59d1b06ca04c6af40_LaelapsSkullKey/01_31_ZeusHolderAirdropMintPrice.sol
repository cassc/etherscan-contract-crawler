// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC1155Base.sol";
import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";


contract LaelapsSkullKey is ERC1155Base, PermissionsEnumerable {

    uint256 public mint_price = 10000;
    bool public buybackburn = true;
    address private constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 private uniswapRouter;
    address public BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address public LAELAPS_ADDRESS = 0x6C059413686565D5aD6cce6EED7742c42DbC44CA;
    address public REWARD_WALLET = 0x7a188ee785589636059738DDA5F26e93062f473f;
    bool lock = true;

    constructor(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps
    )
        ERC1155Base(
            _defaultAdmin,
            _name,
            _symbol,
            _royaltyRecipient,
            _royaltyBps
        )
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);

    }

    function mintToPaid(
        address _to,
        uint256 _tokenId
    )  public payable  {
        require(msg.value >= mint_price, "invalid minting price");
        require(lock == false, "contract locked");
        if (buybackburn) {
            buyAndBurnLaelaps();
            _mint(_to, _tokenId, 1, "");
        }
        else {
            uint amountOut = address(this).balance;
            require(amountOut > 0, "No balance to transfer");
            payable(REWARD_WALLET).transfer(amountOut);
            _mint(_to, _tokenId, 1, "");
        }
    }


    function buyAndBurnLaelaps() internal {
        address[] memory path = new address[](2);
        uint amountOutMin = address(this).balance;
        address WETH_ADDRESS = uniswapRouter.WETH();
        path[0] = WETH_ADDRESS;
        path[1] = LAELAPS_ADDRESS;
        require(amountOutMin > 0, "you have no eth yet");
        address to = address(this);
        uint deadline = block.timestamp + 100;
        uniswapRouter.swapExactETHForTokens{ value: amountOutMin }(amountOutMin, path, to, deadline);
        IERC20 laelaps_token = IERC20(LAELAPS_ADDRESS);
        require(laelaps_token.balanceOf(address(this)) >= 0, "Insufficient funds");
        laelaps_token.transfer(BURN_ADDRESS, laelaps_token.balanceOf(address(this)));
  }

  function setBuyBackBurn(bool _mode) public onlyRole(DEFAULT_ADMIN_ROLE){
    buybackburn = _mode;
  }

  function setPrice(uint256 _price) public onlyRole(DEFAULT_ADMIN_ROLE) {
    mint_price = _price;
  }

  function setLock(bool _lock) public onlyRole(DEFAULT_ADMIN_ROLE) {
    lock = _lock;
  }

  function setLaelapsContract(address _addr) public onlyRole(DEFAULT_ADMIN_ROLE) {
    LAELAPS_ADDRESS = _addr;
  }
}