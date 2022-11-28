pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721 {
  function mint(address to, uint256 quantity) external;

  function max() external view returns (uint256);

  function totalSupply() external view returns (uint256);
}

contract MinterWhitelist2 is Ownable {
  IERC721 public erc721;

  uint256 public mintQuantity;

  mapping(address => bool) public whitelist;

  bool public publicMint;
  bool public wlMint;

  constructor(IERC721 _erc721) public {
    erc721 = _erc721;
    mintQuantity = 1;
  }

  function mint() public {
    require(wlMint, "mint not started");
    require(whitelist[msg.sender], "Address not whitelisted");
    erc721.mint(msg.sender, mintQuantity);
    whitelist[msg.sender] = false;
  }

  function mintPublic() public {
    require(publicMint, "public mint not started");
    erc721.mint(msg.sender, mintQuantity);
  }

  function setERC721(IERC721 _erc721) public onlyOwner {
    erc721 = _erc721;
  }

  function setMintQuantity(uint256 _quantity) public onlyOwner {
    mintQuantity = _quantity;
  }

  function setWLMint(bool _isTrue) public onlyOwner {
    wlMint = _isTrue;
  }

  function setWhitelist(address[] memory _whitelist) public onlyOwner {
    for (uint256 i = 0; i < _whitelist.length; i++) {
      whitelist[_whitelist[i]] = true;
    }
  }

  function revokeWhitelist(address[] memory _whitelist) public onlyOwner {
    for (uint256 i = 0; i < _whitelist.length; i++) {
      whitelist[_whitelist[i]] = false;
    }
  }
}