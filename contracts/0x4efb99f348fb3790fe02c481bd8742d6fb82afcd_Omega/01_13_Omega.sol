// SPDX-License-Identifier: UNLICENSED
/*
            _              __                    
           | |            / _|                   
  _ __ ___ | |__   ___   | |_ _ __ ___ _ __  ___ 
 | '__/ _ \| '_ \ / _ \  |  _| '__/ _ \ '_ \/ __|
 | | | (_) | |_) | (_) | | | | | |  __/ | | \__ \
 |_|  \___/|_.__/ \___/  |_| |_|  \___|_| |_|___/
                                                 
                                                 
*/
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Omega is ERC721A, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    enum SaleState {
        CLOSED,
        ALLOWLIST,
        PRESALE,
        PUBLIC
    }

    struct SaleConfig {
        uint8 maxWLPer;
        uint16 maxSupply;
        uint112 publicPrice;
        uint112 presalePrice;
        SaleState currentState;
    }

    //@notice mapping for WL count users 
    mapping(address => uint256) public claimed;

    //@notice mapping for free users
    mapping(address => bool) public allowClaimed;
    
    //@notice Contract Variables
    SaleConfig public config;

    //@notice metadata revealed
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
      ) ERC721A("robo frens (OMEGA)", "OMEGA") {
          _safeMint(0x556b25640a632695150200F1c83E04108d60Ed4b, 100);

          config = SaleConfig({
              maxWLPer: 5,
              maxSupply: 7777, 
              publicPrice: 0.04 ether,
              presalePrice: 0.02 ether,
              currentState: SaleState.CLOSED
          });

          signer = _signer;
          _royaltyAddress = royaltyAddress;
          _royaltyPercentage = royaltyPercentage;
          _baseTokenURI = _base;
    }

    function allowlistBuy(bytes calldata signature, uint256 quantity) external {
        require(config.currentState == SaleState.ALLOWLIST || config.currentState == SaleState.PRESALE, "NOT_LIVE");
        require(totalSupply() + quantity <= config.maxSupply, "MAX_SUPPLY");
        require(!allowClaimed[msg.sender], "USER_CLAIMED");
        require(keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(msg.sender, quantity))
            )).recover(signature) == signer, "SIG_FAILED");
        allowClaimed[msg.sender] = true;
        _safeMint(msg.sender, quantity);
    }

    function presaleBuy(uint256 quantity) external payable {
        require(config.currentState == SaleState.PRESALE, "NOT_LIVE");
        require(totalSupply() + quantity <= config.maxSupply, "MAX_SUPPLY");
        require(claimed[msg.sender] + quantity <= config.maxWLPer, "USER_CLAIMED_MAX");
        require(msg.value >= quantity * config.presalePrice, "NOT_ENOUGH_ETHER");
        claimed[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable {
        require(config.currentState == SaleState.PUBLIC, "NOT_LIVE");
        require(totalSupply() + quantity <= config.maxSupply, "MAX_SUPPLY");
        require(msg.value >= quantity * config.publicPrice, "NOT_ENOUGH_ETHER");
        _safeMint(msg.sender, quantity);
    }

    function ownerMint() external onlyOwner {
        _safeMint(0x556b25640a632695150200F1c83E04108d60Ed4b, 100);

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
    
    function editConfig(SaleConfig memory newConfig) external onlyOwner {
        config = newConfig;
    }

    function revealOmega(bool _reveal, string memory newURI) external onlyOwner {
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