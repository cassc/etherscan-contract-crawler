// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4 < 0.9.0;

import "./ERC721A.sol";
import "./IDDW.sol";
import "./OpenSeaListing.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract DDWSimp is ERC721A, EIP712, ERC2981, Ownable, Pausable, ReentrancyGuard {

    IDDW public chadCardContract;

    constructor(address chadCardAddress_) 
                ERC721A("DDW: Chad Card", "DDW")
                EIP712("DreamDateWorld", "1") 
                {
                    chadCardContract = IDDW(chadCardAddress_);
                }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Only Humans can become a Chad");
        _;
    }

    function chadMint(uint256 tokenId) external payable callerIsUser {
        require(chadCardContract.balanceOf(msg.sender) > 0, "Sorry, only real chads allowed");
        // require(chadCardContract.isTokenPrivileged(tokenId), "Wrong Token");
        // address payable referrer = payable(chadCardContract.ownerOf(tokenId));
        chadCardContract.safeTransferFrom(chadCardContract.ownerOf(tokenId), msg.sender, tokenId);
        _safeMint(msg.sender, 1);
        // (bool success, bytes memory returnData) = referrer.call{
        //         value: msg.value*50/10000
        //     }("");
        // require(success, string(returnData));

    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}