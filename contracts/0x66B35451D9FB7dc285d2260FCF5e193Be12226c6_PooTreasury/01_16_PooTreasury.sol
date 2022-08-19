//SPDX-License-Identifier: <SPDX-License>
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./utils/UpgradeableHelper.sol";

contract PooTreasury is ERC721Holder, ERC1155Holder, Initializable, UpgradeableHelper {

    receive() external payable {}
    fallback() external payable {}

    function initialize() public initializer {
        __setHelper();
    }

    function withdrawERC20(address tokenAddress, uint256 amount, address _to) public onlyHelper {
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount , "Not enought balance");
        token.transfer(_to,amount);
    }
    function withdrawNative(uint256 _amount, address _to) public onlyHelper {
        payable(_to).transfer(_amount);
    }

    function withdrawERC1155(address nftAddress, address to, uint256[] calldata ids, uint256[] calldata amounts) public onlyHelper{
        IERC1155(nftAddress).safeBatchTransferFrom(address(this),to,ids,amounts,"");
    }

    function widthdrawERC721(address nftAddress,  address _to, uint256[] calldata _tokenID) public onlyHelper {
        for(uint i=0; i < _tokenID.length;i++) {
            IERC721(nftAddress).safeTransferFrom(address(this),_to,_tokenID[i]);
        }
    }
}