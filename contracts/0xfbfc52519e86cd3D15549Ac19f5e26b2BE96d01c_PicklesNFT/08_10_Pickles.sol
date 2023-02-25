// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

contract PicklesNFT is ERC721A, Ownable {

    address public treasury = 0x89191BC856363Dfe89BdC9c3b4288eeC30dD80c3;

    constructor() ERC721A("Pickles", "PKLS") {
    }

    function mint(uint256 quantity) external onlyOwner payable {
        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
        _mint(treasury, quantity);
    }

    function claimBalance() external onlyOwner {
        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
        require(sent, "transfer failed");
    }

    function reclaimERC20(IERC20 erc20Token) external onlyOwner {
		erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
	}

    function reclaimERC721(IERC721 erc721Token, uint256 id) external onlyOwner {
        erc721Token.safeTransferFrom(address(this), msg.sender, id);
	}

    // metadata URI
    string private _baseTokenURI = "ipfs://QmfHyAsw2tPWFQwR2AiKwpat6cTPYHeUiEK2vxv3z8XBqZ/";
    string private _defaultURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return bytes(_baseTokenURI).length == 0 ? _defaultURI : _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setDefaultURI(string calldata baseURI) external onlyOwner {
        _defaultURI = baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (bytes(_baseTokenURI).length == 0) {
            return _defaultURI;
        }
        return super.tokenURI(tokenId);
    }
}