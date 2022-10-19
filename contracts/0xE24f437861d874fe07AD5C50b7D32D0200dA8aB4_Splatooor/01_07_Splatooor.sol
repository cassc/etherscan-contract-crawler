//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./ISplat.sol";

contract Splatooor is IERC721Receiver, Ownable {
    uint256 public depositedTokenId;
    address public immutable splatAddress;
    bool public isEnabled;

    constructor(address _splatAddress) {
        splatAddress = _splatAddress;
        isEnabled = true;
    }

    // ONLY OWNER

    function setIsEnabled(bool _isEnabled) external onlyOwner {
        isEnabled = _isEnabled;
    }

    function deposit(address ownerAddress, uint256 tokenId) external onlyOwner {
        require(depositedTokenId == 0, "Already a splat deposited");
        depositedTokenId = tokenId;
        IERC721(splatAddress).safeTransferFrom(
            ownerAddress,
            address(this),
            tokenId
        );
    }

    function widthdraw(address targetAddress)
        external
        onlyOwner
    {
        require(depositedTokenId != 0, "You should deposit a splat first");
        depositedTokenId = 0;
        IERC721(splatAddress).safeTransferFrom(
            address(this),
            targetAddress,
            depositedTokenId
        );
    }
    
    // PUBLIC

    function splat(address collectionAddress, uint256 tokenId) public {
        require(isEnabled, "Splatting is not enabled");
        ISplat(splatAddress).splat(depositedTokenId, collectionAddress, tokenId);
    }

    // ERC721 Receiever

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}