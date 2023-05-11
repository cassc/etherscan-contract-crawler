// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ERC20 } from 'openzeppelin-contracts/token/ERC20/ERC20.sol';
import { Ownable2Step } from 'openzeppelin-contracts/access/Ownable2Step.sol';
import { ERC1155Holder } from 'openzeppelin-contracts/token/ERC1155/utils/ERC1155Holder.sol';
import { IERC1155 } from 'openzeppelin-contracts/token/ERC1155/IERC1155.sol';

contract FEELSGOODMAN is ERC20, Ownable2Step, ERC1155Holder {

    address public RARE_PEPE_CURATED_CONTRACT = 0x7E6027a6A84fC1F6Db6782c523EFe62c923e46ff;
    uint256 public RARE_PEPE_CURATED_TOKENID = 95324163023919305276761207962515000790081991558268571754514696696965526792531;

    uint256 public TOKENS_PER_FEELSGOODMAN = 10_000_000_000 * 10 ** decimals();

    event Deposit(address indexed caller, uint256 indexed tokenId);
    event Redeem(address indexed caller, uint256 indexed tokenId);

    constructor() ERC20("FEELS GOOD MAN", "FEELS") {
    }

    /**
     * @dev Deposit a FEELSGOODMAN? Receive 10b FEELS 
     */
    function depositNft() external {
        
        bool isOwner = IERC1155(RARE_PEPE_CURATED_CONTRACT).balanceOf(_msgSender(), RARE_PEPE_CURATED_TOKENID) != 0;
        require(isOwner, "Only nft owner can call");

        IERC1155(RARE_PEPE_CURATED_CONTRACT).safeTransferFrom(_msgSender(), address(this), RARE_PEPE_CURATED_TOKENID, 1, "");

        _mint(_msgSender(), TOKENS_PER_FEELSGOODMAN);
        emit Deposit(_msgSender(), RARE_PEPE_CURATED_TOKENID);
    }

    /**
     * @dev Got 10b FEELS? Redeem a FEELSGOODMAN
     */
    function redeemNft() external {

        bool isInContract = IERC1155(RARE_PEPE_CURATED_CONTRACT).balanceOf(address(this), RARE_PEPE_CURATED_TOKENID) != 0;
        require(isInContract, "Nft not held in contract");

        IERC1155(RARE_PEPE_CURATED_CONTRACT).safeTransferFrom(address(this), _msgSender(), RARE_PEPE_CURATED_TOKENID, 1, "");

        _burn(_msgSender(), TOKENS_PER_FEELSGOODMAN);
        emit Redeem(_msgSender(), RARE_PEPE_CURATED_TOKENID);
    }
}