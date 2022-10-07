//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title LydiaCitizenshipNFT
 * @author gotbit
 */

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract LydiaCitizenshipNFT is ERC1155(''), Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    uint256 public immutable totalSupply;
    address public holder;
    uint256 public price;

    uint256 public minted;

    constructor(
        IERC20 token_,
        uint256 price_,
        uint256 totalSupply_,
        address holder_
    ) {
        token = token_;
        price = price_;

        totalSupply = totalSupply_;
        holder = holder_;
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        require(id == 0, 'Unreachable token id');
        return
            'https://gateway.pinata.cloud/ipfs/QmYkKjcRey6yNKGJjQ33oNAmkFRP7pxzUti5cgR2k2mSc8';
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setHolder(address newHolder) external onlyOwner {
        holder = newHolder;
    }

    function buyNft() external {
        require(minted < totalSupply);
        minted++;
        token.safeTransferFrom(msg.sender, holder, price);
        _mint(msg.sender, 0, 1, '');
    }
}