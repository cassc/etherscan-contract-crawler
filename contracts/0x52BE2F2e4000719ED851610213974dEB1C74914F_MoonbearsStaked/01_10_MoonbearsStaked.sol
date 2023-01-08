// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

//         :::   :::    ::::::::   ::::::::  ::::    ::: :::::::::  ::::::::::     :::     :::::::::   :::::::: 
//       :+:+: :+:+:  :+:    :+: :+:    :+: :+:+:   :+: :+:    :+: :+:          :+: :+:   :+:    :+: :+:    :+: 
//     +:+ +:+:+ +:+ +:+    +:+ +:+    +:+ :+:+:+  +:+ +:+    +:+ +:+         +:+   +:+  +:+    +:+ +:+         
//    +#+  +:+  +#+ +#+    +:+ +#+    +:+ +#+ +:+ +#+ +#++:++#+  +#++:++#   +#++:++#++: +#++:++#:  +#++:++#++   
//   +#+       +#+ +#+    +#+ +#+    +#+ +#+  +#+#+# +#+    +#+ +#+        +#+     +#+ +#+    +#+        +#+    
//  #+#       #+# #+#    #+# #+#    #+# #+#   #+#+# #+#    #+# #+#        #+#     #+# #+#    #+# #+#    #+#     
// ###       ###  ########   ########  ###    #### #########  ########## ###     ### ###    ###  ########       

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MoonbearsStaked is Context, IERC721Receiver, ERC20, Ownable, ReentrancyGuard {
    IERC721 immutable MOONBEARS_ERC721;

    event MoonbearStaked(address indexed owner, uint256 indexed tokenId);
    event MoonbearUnstaked(address indexed owner, uint256 indexed tokenId);

    mapping(uint256 => address) public tokens;
    
    constructor(address token) ERC20("Staked Moonbear", "sMB") {
        require(token != address(0), "E0"); // E0: addr err
        MOONBEARS_ERC721 = IERC721(token);
    }
    
    function stake(uint[] calldata tokenIds) external virtual nonReentrant {
        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            require(MOONBEARS_ERC721.ownerOf(tokenId) == _msgSender(), "E9"); // E9: Not your moonbear
            tokens[tokenId] = _msgSender();
            MOONBEARS_ERC721.safeTransferFrom(_msgSender(), address(this), tokenId);

            emit MoonbearStaked(_msgSender(), tokenId);
        }
        _mint(_msgSender(), tokenIds.length * 1e18);
    }
    
    function unstake(uint[] calldata tokenIds) external virtual nonReentrant {
        require(balanceOf(_msgSender()) >= tokenIds.length * 1e18, "EP"); // EP: sMB

        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            require(tokens[tokenId] == _msgSender(), "E9"); // E9: Not your moonbear
            tokens[tokenId] = address(0);
            MOONBEARS_ERC721.safeTransferFrom(address(this), _msgSender(), tokenId);

            emit MoonbearUnstaked(_msgSender(), tokenId);
        }
        _burn(_msgSender(), tokenIds.length * 1e18);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(from == address(0) || to == address(0), "ERC20: Non-transferrable");
        super._beforeTokenTransfer(from, to, amount);
    }
    
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external view override returns (bytes4) {
        from; tokenId; data;
        if (operator == address(this)) {
            return this.onERC721Received.selector;
        }
        else {
            return 0x00000000;
        }
    }
}