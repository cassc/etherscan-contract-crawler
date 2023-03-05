//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract InfiniteLauncherBulkTransfer is Ownable, IERC721Receiver {

    struct Transfer {
        address to;
        uint256 amount;
    }

    function bulkTransfers(IERC20 token, Transfer[] calldata transfers) external {
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < transfers.length; i++) {
            totalAmount += transfers[i].amount;
        }
        require(token.approve(address(this), totalAmount), "approve failed");

        for (uint256 i = 0; i < transfers.length; i++) {
            address _to = transfers[i].to;
            require(_to != address(0), "zero address");
            uint256 _amount = transfers[i].amount;
            require(token.transferFrom(msg.sender, _to, _amount), "transfer failed");
        }
    }


    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // To withdraw tokens from contract, to deposit directly transfer to the contract
    function withdrawToken(address token, uint256 value) external onlyOwner()
    {
        // Check if contract is having required balance
        require(ERC20(token).balanceOf(address(this)) >= value, "Not enough balance in the contract");
        require(ERC20(token).transfer(msg.sender, value), "Unable to transfer token to the owner account");
    }

    // To withdraw NFTs from contract, to deposit directly transfer to the contract
    function withdrawNFT721(address user, address token721, uint256 tokenId) external onlyOwner()
    {
        // Check if contract is having required balance
        // transferFrom(seller, buyer, tokenId);
        ERC721(token721).safeTransferFrom(address(this) , user,tokenId );
    }

    function withdrawNativeToken(address payable _wallet, uint256 amount) external onlyOwner() {
        uint256 nativeTokenBalance = address(this).balance;
        require(nativeTokenBalance >= amount, "Native: insufficient token balance" );
        _wallet.transfer(amount);
    }

}