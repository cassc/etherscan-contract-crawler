// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IBits.sol";

contract Gridcraft_GoldenTickets is ERC1155, Ownable {
  address public admin;
  string public name;
  string public symbol;
  string public metadata;

  address public bits = 0xcbc6922BB75e55d7cA5DAbcF0EA2D7787Fd023f6;
  address public mainLandContract;

  uint256[] public supply = [20,500,250,100,5];
  uint256[] public prices = [2000000 ether, 175000 ether, 750000 ether, 3500000 ether, 8500000 ether];

  bool public saleActive;

  constructor() ERC1155("") {
    name = "Gridcraft Network Golden Tickets";
    symbol = "GTICKETS";
  }

  function mint(uint256[] memory _amounts) public {
    require(saleActive, "Sale not active");
    uint price = priceOfBundle(_amounts);
    require(price > 0, "Nothing to buy");
    IERC20(bits).transferFrom(msg.sender, address(this), price);
    for (uint i; i < 5; ){
      if (_amounts[i] > 0){
        require(_amounts[i] <= supply[i], "Out of stock");
        unchecked { supply[i] -= _amounts[i]; }
        _mint(msg.sender, i, _amounts[i], "");
      }
      unchecked { ++i; }
    }
  }

  // anyone can do it!
  function burnRaised() external {
    IBits(bits).deposit(IERC20(bits).balanceOf(address(this)));
  }


  // amounts for each of the 5 ids, as array
  function priceOfBundle(uint256[] memory _amounts) public view returns (uint256 totalPrice) {
    for (uint i; i < 5 ; ) {
      unchecked { totalPrice += prices[i] * _amounts[i]; }
      unchecked { ++i; }
    }
  }

  function toggleSale() external onlyOwner {
    saleActive = !saleActive;
  }

  function updateMainLandContract(address _newAddress) external onlyOwner {
    mainLandContract = _newAddress;
  }

  function updateMetadata(string memory _metadata) external onlyOwner{
    metadata = _metadata;
  }

  function updatePrices(uint256[] memory _newPrices) external onlyOwner {
    for (uint i; i < 5; ){
      prices[i] = _newPrices[i];
      unchecked{ ++i; }
    }
  }

  // to be used by the Land contract later
  function burn(address _user, uint256[] memory _nftIds, uint256[] memory _amounts) external {
    require(msg.sender == mainLandContract, "Not allowed");
    for (uint i; i < _nftIds.length; ){
      _burn(_user, _nftIds[i], _amounts[i]);
      unchecked { ++i; }
    }
  }

  function uri(uint256 _id) public view override returns (string memory) {
    return string(abi.encodePacked(metadata, uint2str(_id), ".json"));
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC1155)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return "0";
    }
    uint j = _i;
    uint len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len;
    while (_i != 0) {
      k = k-1;
      uint8 temp = (48 + uint8(_i - _i / 10 * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }
}