// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";
interface IERC20 {
    
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    
}
contract Wooonen is ERC721A, ReentrancyGuard, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 5200;
    uint256 public FREE = 0;
    uint256 public constant FREE_SUPPLY = 2800;
    uint256 public WOOO = 0;
    uint256 public constant WOOO_SUPPLY = 2400;
    string public baseExtension = ".json";
    string private _baseTokenURI = "";
    address public  tokenAddress = 0x5A035e3F1551a15230D0cDE3357fB1bf89369261;
    uint256 public  price = 10086e18;
    mapping(address => uint256) public _claimed;
    mapping(address => uint256) public _whitelistClaimed;
    address public immutable cSigner;
    bool public state = false;

   constructor(string memory name, string memory symbol, string memory baseURI) ERC721A(name, symbol,100,MAX_SUPPLY) {
        setBaseURI(baseURI);
        cSigner = 0x97591D4C59b35b7A3842735c5C3E3D131aB32251;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }


    function whiteMint(uint256 num,uint8 v, bytes32 r, bytes32 s) external payable {
        require(state == true, "not yet open");
        require(FREE < FREE_SUPPLY, "All tokens minted");
        require(totalSupply() < MAX_SUPPLY, "All tokens minted");
        require(_claimed[msg.sender] == 0, "Claimed");
        bytes32 digest = sha256(abi.encodePacked(msg.sender, num.toString()));
        require(ecrecover(digest, v, r, s) == cSigner, "Invalid signer");
        _claimed[msg.sender] = 1;
        _safeMint(msg.sender, num);
        FREE += num ;
    }
    
    function woooMint(uint256 num) external payable {
        require(state == true, "not yet open");
        require(WOOO < WOOO_SUPPLY, "All tokens minted");
        require(totalSupply() < MAX_SUPPLY, "All tokens minted");
        require(num <= 5, "failed");
        IERC20(tokenAddress).transferFrom(msg.sender,address(this),num*price);
        _safeMint(msg.sender, num);
        WOOO += num ;
    }

    function appointMint(uint256 num) external payable {
        require(totalSupply() < MAX_SUPPLY, "All tokens minted");
        require(_whitelistClaimed[msg.sender] >= num, "failed");
        _whitelistClaimed[msg.sender] -= num;
        _safeMint(msg.sender, num);
    }

    function setWhitelist(uint256 num,address user) public onlyOwner {
        require(num > 0, " num <= 0");
        _whitelistClaimed[user] = num;
    }

    function setBaseURI(string memory val) public onlyOwner {
        _baseTokenURI = val;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    


    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }
    function setPrice(uint256 amount) public onlyOwner{
        price = amount;
    }
    function setState(bool _state) public onlyOwner{
        state = _state;
    }

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    function withdrawToken(uint256 amount) public onlyOwner{
        IERC20(tokenAddress).transfer(msg.sender,amount);
    }
}