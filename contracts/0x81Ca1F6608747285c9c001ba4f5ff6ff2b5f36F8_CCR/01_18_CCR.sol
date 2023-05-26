// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CCR is AccessControlEnumerable, ERC721Enumerable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    uint public constant MINT_PRICE = 0.04 ether;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint public constant _DEC_1_2021_16_00_00 = 1_638_345_600;

    string private _baseTokenURI;

    uint256 public _whitelistEndDate;
    uint256 public _maxSupply;
    address private _fundAddress;
    mapping (address => bool) public whitelist;
    mapping (address => uint) public minted;

    constructor(string memory baseTokenURI) ERC721("CryptoChasers Robot", "CCR"){
      _maxSupply = 500;
      _fundAddress = msg.sender;
      _baseTokenURI = baseTokenURI;
      _whitelistEndDate = _DEC_1_2021_16_00_00;
      _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
      _setupRole(MINTER_ROLE, _msgSender());
    }

    // modifier admin has admin role can call this function
    modifier onlyAdmin {
      require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Only admin can call function");
      _;
    }

    // get token URL
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
       return string(super.tokenURI(tokenId));
    }

    function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
    }

    // admin can change baseTokenURI
    function setBaseTokenURI(string memory baseTokenURI) onlyAdmin external{
      _baseTokenURI = baseTokenURI;
    }

    function _mintProxy(address to) internal {
      _mint(to, _tokenIdTracker.current());
      _tokenIdTracker.increment();
      minted[to] += 1;
    }

    // admin can direct mint NFT to any address
    function mintByAdmin(address[] calldata recievers) onlyAdmin external {
      require(_maxSupply >= totalSupply() + recievers.length, "Max supply reached");
      for (uint i = 0; i < recievers.length; i++) {
        _mintProxy(recievers[i]);
      }
    }

    // Users will have to spend ETH to mint NFT
    // max mint 2 per sender
    // should set a blockheight, before height should verify if in whitelist, 
    // after it any address can mint freely
    function mint() external payable {
      require(minted[msg.sender] < 2, "Max mint 2 per sender");
      require(_maxSupply >= totalSupply(), "Max supply reached");

      if(whitelist[msg.sender]) {
        require(hasRole(MINTER_ROLE, _msgSender()), "must have minter role to mint");
        if(minted[msg.sender] == 0){
          _mintProxy(msg.sender); 
        }else{
          require(msg.value == MINT_PRICE, "Need to send 0.04 ether");
          _mintProxy(msg.sender);
        }
      }
      else{
        require(block.timestamp >= _whitelistEndDate, "only in whitelist can mint now");
        require(msg.value == MINT_PRICE, "Need to send 0.04 ether");
        _mintProxy(msg.sender);
      }
    }
    // admin can set whitelistEndDate
    function setwhitelistEndDate(uint256 whitelistEndDate) onlyAdmin external {
      _whitelistEndDate = whitelistEndDate;
    }


    // admin can set maxSupply
    function setMaxSupply(uint256 maxSupply) onlyAdmin external {
      _maxSupply = maxSupply;
    }

    // admin can set addresses array as MINTER_ROLE
    function addToWhitelist(address[] memory _whiteListAddresses) onlyAdmin external {
      for (uint i = 0; i < _whiteListAddresses.length; i++) {
        whitelist[_whiteListAddresses[i]] = true;
        super.grantRole(MINTER_ROLE, _whiteListAddresses[i]);
      }
    }

    // check if address is in whitelist
    function isInWhitelist(address _address) external view returns (bool) {
      return whitelist[_address];
    }

    // get remaining supply
    function getRemainingSupply() external view returns (uint256) {
      return _maxSupply - totalSupply();
    }

    // get minted count
    function getMintedCount(address _address) external view returns (uint256) {
      return minted[_address];
    }

    // withdraw ethers
    function withdrawAll() external onlyAdmin {
        payable(_fundAddress).transfer(address(this).balance);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}