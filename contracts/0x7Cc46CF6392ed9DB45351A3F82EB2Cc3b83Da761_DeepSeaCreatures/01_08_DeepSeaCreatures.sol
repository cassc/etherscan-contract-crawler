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
    bool private isMintable;
    bool private isBurnable;

    constructor(
      string memory baseURI,
      bool _isMintable,
      bool _isBurnable
    ) ERC721A("Deep Sea Creatures", "DSC") {
      _baseTokenURI = baseURI;
      isMintable = _isMintable;
      isBurnable = _isBurnable;
    }

    function devMint(address _address, uint256 quantity) external onlyOwner {
      require(isMintable, "minting is not enabled");
      require(totalSupply() + quantity <= maxSupply, "Max supply reached");
      _mint(_address, quantity);
    }

    function mint(uint256 quantity) external {
        require(
            fishyFamContract.balanceOf(msg.sender) > 0,
            "You do not own any Fishy Fam NFTs"
        );
        require(
            baitToken.transferFrom(msg.sender, address(this), quantity * 1e18),
            "Bait token transfer failed"
        );
        require(totalSupply() + quantity <= maxSupply, "reached max supply");
        require(isMintable, "minting is not enabled");

        _mint(msg.sender, quantity);
    }

    function setMintable(bool _isMintable) external onlyOwner {
        isMintable = _isMintable;
    }

    function setBurnable(bool _isBurnable) external onlyOwner {
        isBurnable = _isBurnable;
    }
    
    //burn by tokenId
    function burn(uint256 tokenId) external {
        require(isBurnable, "burning is not enabled");

        _burn(tokenId, true);

        //transfer back 0.5 BAIT to user for burning
        baitToken.transfer(msg.sender, 0.5e18);
    }

    //bulk burn by tokenId
    function bulkBurn(uint256[] calldata tokenIds) external {
        require(isBurnable, "burning is not enabled");

        for (uint256 i; i < tokenIds.length;) {
            _burn(tokenIds[i], true);
            unchecked { i++; }
        }

        //transfer back 0.5 BAIT to user for burning
        baitToken.transfer(msg.sender, 0.5e18 * tokenIds.length);
    }

    //bulk transferFrom
    function bulkTransferFrom(address from, address[] calldata addresses, uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length;) {
            transferFrom(from, addresses[i], tokenIds[i]);
            unchecked { i++; }
        }
    }

    // metadata URI
    function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
      _baseTokenURI = baseURI;
    }
}