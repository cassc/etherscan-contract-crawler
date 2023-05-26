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

contract FuturisticPortalPassMinter is Context, Ownable {

    address constant private _burnerAddress = 0x000000000000000000000000000000000000dEaD;

    IERC721 public passes;
    IERC721 public puppies;

    uint256 public immutable startTime;

    bool public openMint = false;

    constructor(
        address passesAddress,
        address puppiesAddress,
        uint256 startTime_
    ) {
        passes = IERC721(passesAddress);
        puppies = IERC721(puppiesAddress);
        startTime = startTime_;
    }

    function mint(uint256[5] calldata puppiesId) public {
        require(this.isMintOpen(), "Claiming has not started");

        for(uint256 i = 0; i < puppiesId.length; i++) {
            uint256 id = puppiesId[i];
            require(puppies.ownerOf(id) == _msgSender(), "Sender should own the puppies");
            puppies.safeTransferFrom(_msgSender(), _burnerAddress, id);
        }
        passes.mint(_msgSender());
    }

    function setOpenMint(bool openMint_) public onlyOwner {
        openMint = openMint_;
    }

    function isMintOpen() public view returns (bool) {
        return block.timestamp >= startTime || openMint;
    }

}