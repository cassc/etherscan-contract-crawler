// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <=0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ToyBoogersSpecials is Ownable, ERC1155 {
  using Strings for uint256;
  address[] private addressList = [
    0x6ed5a435495480774Dfc44cc5BC85333f1b0646A,
    0x1660207BF5681c9cDB8AFe3A16C03A497A438753
  ];
  constructor(string memory uri_) ERC1155(uri_) {
	_mint(msg.sender, 1, 154, "OG Booger for Life");
	_mint(msg.sender, 2, 1312, "Boogers Stick Together");
	_mint(msg.sender, 3, 1000, "Toy Boogers Fam");
	_mint(addressList[0], 1, 159, "OG Booger for Life");
	_mint(addressList[1], 1, 20, "OG Booger for Life");
	_mint(addressList[0], 2, 38, "Boogers Stick Together");
	_mint(addressList[1], 2, 150, "Boogers Stick Together");
	_mint(addressList[0], 3, 200, "Toy Boogers Fam");
	_mint(addressList[1], 3, 200, "Toy Boogers Fam");
  }
  function mint(
    uint256 id_,
    uint256 amount_
    ) public onlyOwner{
      _mint(_msgSender(), id_, amount_, "");
  }
  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
    ) public virtual onlyOwner {
    _mintBatch(to, ids, amounts, data);
  }
  function setURI(string memory newUri) public onlyOwner {
    _setURI(newUri);
  }
  function uri(uint256 _tokenId) public view virtual override returns (string memory) {
	return string(abi.encodePacked(ERC1155.uri(_tokenId), _tokenId.toString()));
  }
}