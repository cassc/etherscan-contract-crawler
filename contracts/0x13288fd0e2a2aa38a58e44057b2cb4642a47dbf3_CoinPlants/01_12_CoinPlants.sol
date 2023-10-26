pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/ERC721A.sol";

contract CoinPlants is ERC721A, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    enum SaleState {
        CLOSED,
        PRESALE, 
        PUBLIC
    }

    struct Config {
        uint8 presaleMax;
        uint8 publicMax;
        uint16 supply;
        uint256 presalePrice;
        uint256 publicPrice;
    }
    
    //@notice Support for ERC2981
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    //@notice Royalty Variables
    address private _royaltyAddress;
    uint256 private _royaltyPercentage;
    
    SaleState public currentState;
    Config public saleConfig;

    string private _baseTokenURI;

    address public signer;
    address public treasury = 0xc4E2F2132971ad462bc4e5eC3B068700B465FFFe;

    mapping (address => uint256) whitelistUserClaims;

    constructor(
      address _signer,
      address royaltyAddress,
      uint256 royaltyPercentage,
      string memory _base
      ) ERC721A("CoinPlants", "PLANT") {
          saleConfig = Config({
              presaleMax: 5,
              publicMax: 25,
              supply: 2500,
              presalePrice: 0.04 ether,
              publicPrice: 0.08 ether
          });
          signer = _signer;
          _royaltyAddress = royaltyAddress;
          _royaltyPercentage = royaltyPercentage;
          _baseTokenURI = _base;

          _safeMint(treasury, 5);
          _safeMint(0xe8796456414FfeB393AA3D943976c3B4231Ff370, 10);
          _safeMint(0xD801c20cfE544886a348192b0D95417C095Fef06, 10);
          _safeMint(0xB28420176c240f0fa7C4Ce77F54aA65889373a1D, 3);
          
    }

    function whitelistBuy(bytes calldata signature, uint256 quantity) public payable {
        require(currentState == SaleState.PRESALE, "NOT_LIVE");
        require(totalSupply() + quantity <= saleConfig.supply, "OVER_SUPPLY");
        require(whitelistUserClaims[msg.sender] + quantity <= saleConfig.presaleMax, "OVER_WHITELIST_LIMIT");
        require(keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(msg.sender))
            )).recover(signature) == signer, "SIG_FAILED");
        require(msg.value >= saleConfig.presalePrice * quantity, "NOT_ENOUGH_ETHER");
        whitelistUserClaims[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function publicBuy(uint256 quantity) public payable {
      require(currentState == SaleState.PUBLIC, "NOT_LIVE");
      require(quantity <= saleConfig.publicMax && totalSupply() + quantity <= saleConfig.supply, "OVER_SUPPLY");
      require(msg.value >= saleConfig.publicPrice * quantity, "NOT_ENOUGH_ETHER");
      _safeMint(msg.sender, quantity);
    }

    function withdraw() external onlyOwner {
        (bool sent, ) = payable(treasury).call{value: address(this).balance }("");
        require(sent, "FAILED_TO_SEND_ETHER");
    }

    function airdropUsers(address[] memory users, uint256[] memory amounts) external onlyOwner {
        for(uint i; i < users.length; i++) {
            _safeMint(users[i], amounts[i]);
        }
    }
    function setBaseURI(string calldata baseURI) external onlyOwner {
      _baseTokenURI = baseURI;
    }

    function setState(SaleState _state) external onlyOwner {
        currentState = _state;
    }

    function setSigner(address user) external onlyOwner {
        signer = user;
    }

    //@notice Update royalty percentage
    //@param percentage to edit
    function editRoyaltyFee(uint256 percent) external onlyOwner {
        _royaltyPercentage = percent;
    }

    //@notice View royalty info for tokens
    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
        return (_royaltyAddress, value * _royaltyPercentage / 10000);
    }

    function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"));
    }
    
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

}