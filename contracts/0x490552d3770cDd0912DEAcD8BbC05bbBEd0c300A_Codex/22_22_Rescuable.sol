// SPDX-License-Identifier: AGPL-3.0
// ©2023 Ponderware Ltd

pragma solidity ^0.8.17;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IERC721_Transfer {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract Rescuable {

    function _withdraw(address to) internal {
        payable(to).transfer(address(this).balance);
    }

    /**
    * @dev Rescue ERC20 assets sent directly to this contract.
    */
    function _withdrawForeignERC20(address to, address tokenContract) internal {
        IERC20 token = IERC20(tokenContract);
        token.transfer(to, token.balanceOf(address(this)));
        }

    /**
     * @dev Rescue ERC721 assets sent directly to this contract.
     */
    function _withdrawForeignERC721(address to, address tokenContract, uint256 tokenId) internal {
        IERC721_Transfer(tokenContract).safeTransferFrom(address(this), to, tokenId);
    }


}