pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721 {
  function mint(address to, uint256 quantity) external;

  function max() external view returns (uint256);

  function totalSupply() external view returns (uint256);
}

contract MinterWhitelist is Ownable {
  IERC721 public erc721;
  mapping(address => uint256) public whitelistA;
  mapping(address => bool) public whitelistB;

  uint256 public whitelistSize;
  uint256 public mintedA;
  uint256 public mintedB;
  uint256 public mintQuantityB;

  bool public publicMint;
  bool public wlMint;

  constructor(IERC721 _erc721) public {
    erc721 = _erc721;
    mintQuantityB = 1;
  }

  function viewAllocationB() public view returns (uint256) {
    return erc721.max() - erc721.totalSupply() - whitelistSize;
  }

  function mint() public {
    require(wlMint, "mint not started");
    require(
      whitelistA[msg.sender] > 0 || whitelistB[msg.sender],
      "Address not whitelisted"
    );
    if (whitelistA[msg.sender] > 0) {
      erc721.mint(msg.sender, whitelistA[msg.sender]);
      mintedA = mintedA + whitelistA[msg.sender];
      whitelistSize = whitelistSize - whitelistA[msg.sender];
      whitelistA[msg.sender] = 0;
      return;
    }
    require(viewAllocationB() <= 0, "Only reserved mints left");
    uint256 quantity = mintQuantityB;
    if (viewAllocationB() - mintedB < mintQuantityB) {
      quantity = viewAllocationB() - mintedB;
    }
    erc721.mint(msg.sender, quantity);
    whitelistB[msg.sender] = false;
    mintedB = mintedB + quantity;
  }

  function setERC721(IERC721 _erc721) public onlyOwner {
    erc721 = _erc721;
  }

  function setMintQuantityB(uint256 _quantity) public onlyOwner {
    mintQuantityB = _quantity;
  }

  function setWLMint(bool _isTrue) public onlyOwner {
    wlMint = _isTrue;
  }

  function setWhitelistA(
    address[] memory _whitelist,
    uint256[] memory _quantities
  ) public onlyOwner {
    for (uint256 i = 0; i < _whitelist.length; i++) {
      whitelistSize =
        whitelistSize +
        _quantities[i] -
        whitelistA[_whitelist[i]];
      whitelistA[_whitelist[i]] = _quantities[i];
    }
  }

  function revokeWhitelistA(address[] memory _whitelist) public onlyOwner {
    for (uint256 i = 0; i < _whitelist.length; i++) {
      whitelistSize = whitelistSize - whitelistA[_whitelist[i]];
      whitelistA[_whitelist[i]] = 0;
    }
  }

  function setWhitelistB(address[] memory _whitelist) public onlyOwner {
    for (uint256 i = 0; i < _whitelist.length; i++) {
      whitelistB[_whitelist[i]] = true;
    }
  }

  function revokeWhitelistB(address[] memory _whitelist) public onlyOwner {
    for (uint256 i = 0; i < _whitelist.length; i++) {
      whitelistB[_whitelist[i]] = false;
    }
  }
}