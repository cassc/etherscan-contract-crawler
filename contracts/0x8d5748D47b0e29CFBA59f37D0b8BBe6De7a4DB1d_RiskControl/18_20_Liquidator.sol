// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/ImToken.sol";

contract Liquidator {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event FundsClaimed(IERC20 indexed token, address to, uint256 amount);

    IERC20 public funds;

    ImToken public mtoken;

    uint256 public totalReceived;

    IERC721 public nft;

    mapping(uint256 => uint256) isClaimed;

    function liquidate(address funds_, address mtoken_, address nft_, uint256 amount) public {
        require(totalReceived == 0, "Liquidator: repeated call liquidate");
        require(amount != 0, "Liquidator: invalid liquidate amount");
        funds = IERC20(funds_);
        mtoken = ImToken(mtoken_);

        funds.safeTransferFrom(msg.sender, address(this), amount);
        totalReceived = funds.balanceOf(address(this));
        nft = IERC721(nft_);
    }

    function claims(uint256 tokenId) public {
      require(isClaimed[tokenId] == 0, "Liquidator: tokenId already claimed");
      uint256 amount = totalReceived.mul(mtoken.shares(address(nft), tokenId)).div(mtoken.totalShares());
      isClaimed[tokenId] = amount;
      address to = nft.ownerOf(tokenId);
      funds.safeTransfer(to, amount);
      emit FundsClaimed(funds, to, amount);
    }
}