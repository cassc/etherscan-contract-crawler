// SPDX-License-Identifier: MIT

///////////////////////////
// Developed by Hirshey //
/////////////////////////

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DeepSeaCreatures is ERC721A, Ownable {
    uint256 public immutable maxSupply = 10000;
    
    IERC20 public immutable baitToken = IERC20(0x77BD077fFFe51EdFC4913Ee50506a3e59063bbEa);
    IERC721 public immutable fishyFamContract = IERC721(0x63FA29Fec10C997851CCd2466Dad20E51B17C8aF);

    string private _baseTokenURI;

    constructor(
      string memory baseURI
    ) ERC721A("Deep Sea Creatures", "DSC") {
      _baseTokenURI = baseURI;
    }

    function mint(uint256 quantity) external payable {
        require(
            fishyFamContract.balanceOf(msg.sender) > 0,
            "You do not own any Fishy Fam NFTs"
        );
        require(
            baitToken.transferFrom(msg.sender, address(this), quantity * 1e18),
            "Bait token transfer failed"
        );
        require(totalSupply() + quantity <= maxSupply, "reached max supply");

        _mint(msg.sender, quantity);
    }
    
    //burn by tokenId
    function burn(uint256 tokenId) external {
        _burn(tokenId);

        //transfer back 0.5 BAIT to user for burning
        baitToken.transfer(msg.sender, 0.5e18);
    }

    // metadata URI
    function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
      _baseTokenURI = baseURI;
    }
}