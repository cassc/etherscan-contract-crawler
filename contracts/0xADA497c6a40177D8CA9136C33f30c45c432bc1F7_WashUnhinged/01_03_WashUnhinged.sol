// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;
import "erc721a/contracts/ERC721A.sol";

contract WashUnhinged is ERC721A {
    address private _owner;
    string public uri;
    uint256 public salePrice = 404 * 10 ** 14;
    uint256 public minXferPrice = 10 ** 16;
    address public royal;
    uint16 public royalty = 404;

    constructor(
        string memory _uri,
        address _royal
    ) ERC721A("WashUnhinged", "W404") {
        uri = _uri;
        royal = _royal;
        _owner = msg.sender;
    }

    function wash(address recipient) public payable {
        uint256 amount = msg.value / salePrice;
        require(amount >= 1, "PAY MORE :)");
        _mint(recipient, amount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        require(msg.value >= minXferPrice, "ALL XFERS MUST HAVE VALUE");
        (bool success, ) = address(royal).call{
            value: (msg.value * 404) / 10000
        }("");
        require(success, "YOU MUST PAY :)");
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return uri;
    }

    function changeURI(string memory _uri) public {
        require(msg.sender == _owner);
        uri = _uri;
    }

    function rinse() public {
        address payable to = payable(royal);
        to.transfer(address(this).balance);
    }
}