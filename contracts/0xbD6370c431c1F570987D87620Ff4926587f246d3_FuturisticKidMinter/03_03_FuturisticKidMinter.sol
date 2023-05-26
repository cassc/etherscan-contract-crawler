// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);
    function mint(address to) external;
}

contract FuturisticKidMinter is Context, Ownable {

    address constant private _burnerAddress = 0x000000000000000000000000000000000000dEaD;

    IERC721 public immutable futuristicKids;
    IERC721 public immutable passes;
    IERC721 public immutable kids;

    uint256 public immutable startTime;

    bool public openMint = false;

    constructor(
        address futuristicKidsAddress,
        address passesAddress,
        address kidsAddress,
        uint256 startTime_
    ) {
        futuristicKids = IERC721(futuristicKidsAddress);
        passes = IERC721(passesAddress);
        kids = IERC721(kidsAddress);
        startTime = startTime_;
    }

    function mint(uint256 kidId, uint256 passId) public {
        require(this.isMintOpen(), "Claiming has not started");

        require(kids.ownerOf(kidId) == _msgSender(), "Sender should own the kid");
        require(passes.ownerOf(passId) == _msgSender(), "Sender should own the pass");

        kids.safeTransferFrom(_msgSender(), _burnerAddress, kidId);
        passes.safeTransferFrom(_msgSender(), _burnerAddress, passId);

        futuristicKids.mint(_msgSender());
    }

    function setOpenMint(bool openMint_) public onlyOwner {
        openMint = openMint_;
    }

    function isMintOpen() public view returns (bool) {
        return block.timestamp >= startTime || openMint;
    }

}