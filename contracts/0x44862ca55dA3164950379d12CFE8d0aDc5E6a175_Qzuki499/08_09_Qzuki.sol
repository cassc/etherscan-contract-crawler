// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "Ownable.sol";
import "ERC721A.sol";
import "IQzuki.sol";
import "ERC721AQueryable.sol";
import "Strings.sol";

contract Qzuki499 is Ownable, ERC721A, ERC721AQueryable, IQzuki {

    string private _baseTokenURI;

    uint256 public constant RESERVED_TOKENS = 1;

    uint256 public maxSupply = 499;

    event Minted(address indexed receiver, uint256 quantity);

    constructor(address receiver) ERC721A("Qzuki499 Club", "Qzuki499 Club") {
        _mintERC2309(receiver, RESERVED_TOKENS);
    }

    function mint(uint256 quantity)
        external
        payable
    {
        if (_totalMinted() + quantity > maxSupply) revert SupplyExceeded();
        _mint(msg.sender, quantity);
        emit Minted(msg.sender, quantity);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");

        if (!success) revert WithdrawFailed();
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId)  public view override(ERC721A,IERC721A) returns (string memory) {
        return string(abi.encodePacked(
            _baseTokenURI,
            "/",
            Strings.toString(_tokenId),
            ".json"
        ));
    }

}
