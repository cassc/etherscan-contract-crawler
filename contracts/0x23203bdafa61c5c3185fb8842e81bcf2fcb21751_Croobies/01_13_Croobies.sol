// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Croobies is ERC721A, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    enum SaleState {
        CLOSED,
        ALLOW_LIST,
        PUBLIC
    }

    struct SaleConfig {
        uint112 publicPrice;
        uint16 maxSupply;
        uint8 maxPerWallet;
        SaleState currentState;
    }

    //@notice mapping to store claimed 
    mapping(address => bool) public claimed;
    
    //@notice Contract Variables
    SaleConfig public config;

    bool public revealed;

    //@notice Signer for allow list
    address public signer;

    //@notice Metadata URL
    string private _baseTokenURI;

    //@notice Support for ERC2981
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    //@notice Royalty Variables
    address private _royaltyAddress;
    uint256 private _royaltyPercentage;

    constructor(
      address _signer,
      address royaltyAddress,
      uint256 royaltyPercentage,
      string memory _base
      ) ERC721A("Croobies", "CROOBIE") {

          config = SaleConfig({
              publicPrice: 0.02 ether,
              maxSupply: 3333,
              maxPerWallet: 10,
              currentState: SaleState.CLOSED
          });

          signer = _signer;
          _royaltyAddress = royaltyAddress;
          _royaltyPercentage = royaltyPercentage;
          _baseTokenURI = _base;
    }

    function allowlistBuy(bytes calldata signature, uint256 quantity) external {
        require(config.currentState == SaleState.ALLOW_LIST, "NOT_LIVE");
        require(totalSupply() + quantity <= config.maxSupply, "MAX_SUPPLY");
        require(!claimed[msg.sender], "USER_CLAIMED");
        require(keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(msg.sender, quantity))
            )).recover(signature) == signer, "SIG_FAILED");
        claimed[msg.sender] = true;
        _safeMint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable {
        require(config.currentState == SaleState.PUBLIC, "NOT_LIVE");
        require(totalSupply() + quantity <= config.maxSupply, "MAX_SUPPLY");
        require(quantity <= config.maxPerWallet, "MAX_WALLET_LIMIT");
        require(msg.value >= quantity * config.publicPrice, "NOT_ENOUGH_ETHER");
        _safeMint(msg.sender, quantity);
    }

    function withdraw() external onlyOwner {
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance }("");
        require(sent, "FAILED_TO_SEND_ETHER");
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
      _baseTokenURI = baseURI;
    }

    function setState(SaleState _state) external onlyOwner {
        config.currentState = _state;
    }

    function setSigner(address user) external onlyOwner {
        signer = user;
    }

    function setCost(uint112 _cost) external onlyOwner {
        config.publicPrice = _cost;
    }

    function setSupply(uint16 supply) external onlyOwner {
        config.maxSupply = supply;
    }

    function revealCroobies(bool _reveal, string memory newURI) external onlyOwner {
        revealed = _reveal;
        _baseTokenURI = newURI;
    }

    function editRoyaltyFee(uint256 percent) external onlyOwner {
        _royaltyPercentage = percent;
    }

    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
        return (_royaltyAddress, value * _royaltyPercentage / 10000);
    }

    function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        if(revealed) {
            return string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"));
        } else {
            return currentBaseURI;
        }
    }
    
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

}