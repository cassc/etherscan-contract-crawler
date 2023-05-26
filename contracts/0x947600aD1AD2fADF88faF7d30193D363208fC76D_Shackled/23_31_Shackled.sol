// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/Shackled.sol";

contract XShackled is Shackled {
    constructor() {}

    function xstoreSeedHash(uint256 tokenId) external {
        return super.storeSeedHash(tokenId);
    }

    function x_transferOwnership(address newOwner) external {
        return super._transferOwnership(newOwner);
    }

    function x_beforeTokenTransfer(address from,address to,uint256 tokenId) external {
        return super._beforeTokenTransfer(from,to,tokenId);
    }

    function x_baseURI() external view returns (string memory) {
        return super._baseURI();
    }

    function x_safeTransfer(address from,address to,uint256 tokenId,bytes calldata _data) external {
        return super._safeTransfer(from,to,tokenId,_data);
    }

    function x_exists(uint256 tokenId) external view returns (bool) {
        return super._exists(tokenId);
    }

    function x_isApprovedOrOwner(address spender,uint256 tokenId) external view returns (bool) {
        return super._isApprovedOrOwner(spender,tokenId);
    }

    function x_safeMint(address to,uint256 tokenId) external {
        return super._safeMint(to,tokenId);
    }

    function x_safeMint(address to,uint256 tokenId,bytes calldata _data) external {
        return super._safeMint(to,tokenId,_data);
    }

    function x_mint(address to,uint256 tokenId) external {
        return super._mint(to,tokenId);
    }

    function x_burn(uint256 tokenId) external {
        return super._burn(tokenId);
    }

    function x_transfer(address from,address to,uint256 tokenId) external {
        return super._transfer(from,to,tokenId);
    }

    function x_approve(address to,uint256 tokenId) external {
        return super._approve(to,tokenId);
    }

    function x_setApprovalForAll(address owner,address operator,bool approved) external {
        return super._setApprovalForAll(owner,operator,approved);
    }

    function x_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function x_msgData() external view returns (bytes memory) {
        return super._msgData();
    }
}