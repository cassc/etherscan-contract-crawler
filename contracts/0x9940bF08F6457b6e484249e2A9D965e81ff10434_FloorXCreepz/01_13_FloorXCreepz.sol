// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


// $$$$$$$$\ $$\       $$$$$$\   $$$$$$\  $$$$$$$\            
// $$  _____|$$ |     $$  __$$\ $$  __$$\ $$  __$$\           
// $$ |      $$ |     $$ /  $$ |$$ /  $$ |$$ |  $$ |          
// $$$$$\    $$ |     $$ |  $$ |$$ |  $$ |$$$$$$$  |          
// $$  __|   $$ |     $$ |  $$ |$$ |  $$ |$$  __$$<           
// $$ |      $$ |     $$ |  $$ |$$ |  $$ |$$ |  $$ |          
// $$ |      $$$$$$$$\ $$$$$$  | $$$$$$  |$$ |  $$ |          
// \__|      \________|\______/  \______/ \__|  \__|                                            
                                                           
//                   $$\   $$\                                
//                   $$ |  $$ |                               
//                   \$$\ $$  |                               
//                    \$$$$  /                                
//                    $$  $$<                                 
//                   $$  /\$$\                                
//                   $$ /  $$ |                               
//                   \__|  \__|                                                                     
                                                           
//  $$$$$$\  $$$$$$$\  $$$$$$$$\ $$$$$$$$\ $$$$$$$\ $$$$$$$$\ 
// $$  __$$\ $$  __$$\ $$  _____|$$  _____|$$  __$$\\____$$  |
// $$ /  \__|$$ |  $$ |$$ |      $$ |      $$ |  $$ |   $$  / 
// $$ |      $$$$$$$  |$$$$$\    $$$$$\    $$$$$$$  |  $$  /  
// $$ |      $$  __$$< $$  __|   $$  __|   $$  ____/  $$  /   
// $$ |  $$\ $$ |  $$ |$$ |      $$ |      $$ |      $$  /    
// \$$$$$$  |$$ |  $$ |$$$$$$$$\ $$$$$$$$\ $$ |     $$$$$$$$\ 
//  \______/ \__|  \__|\________|\________|\__|     \________|                                        
                                                           
                                                           
contract FloorXCreepz is ERC1155Supply, Ownable {
    using ECDSA for bytes32;

    uint256 public constant FLOOR_X_CREEPZ = 0;
    uint256 public constant MAX_SUPPLY = 2223;
    uint256 public constant PER_WALLET_LIMIT = 50;

    uint256 public tokenPrice;
    bool public saleIsActive;
    bool public isPaused;

    string private name_;
    string private symbol_; 

    address public signerAddress;

    address public royaltyAddress;
    uint256 public ROYALTY_SIZE = 500; // 5%
    uint256 public ROYALTY_DENOMINATOR = 10000;

    mapping(uint256 => address) private _royaltyReceivers;
    mapping (address => uint256) private _mintedPerAddress;

    event TokensMinted(
      address mintedBy,
      uint256 tokensNumber
    );

    constructor(
      string memory _name,
      string memory _symbol,
      string memory _uri,
      address _signer,
      address _royalty
    ) ERC1155(_uri) {
      name_ = _name;
      symbol_ = _symbol;
      signerAddress = _signer;
      royaltyAddress = _royalty;

      tokenPrice = 0.069 ether;
    }
    
    function name() public view returns (string memory) {
      return name_;
    }

    function symbol() public view returns (string memory) {
      return symbol_;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
      uint256 amount = _salePrice * ROYALTY_SIZE / ROYALTY_DENOMINATOR;
      address royaltyReceiver = _royaltyReceivers[_tokenId] != address(0) ? _royaltyReceivers[_tokenId] : royaltyAddress;
      return (royaltyReceiver, amount);
    }

    function addRoyaltyReceiverForTokenId(address receiver, uint256 tokenId) public onlyOwner {
      _royaltyReceivers[tokenId] = receiver;
    }

    function purchase(uint256 tokensNumber, bytes calldata signature) public payable {
      require(saleIsActive, "The mint has not started yet");
      require(tokensNumber > 0, "Wrong amount requested");
      require(totalSupply(FLOOR_X_CREEPZ) + tokensNumber <= MAX_SUPPLY, "You tried to mint more than the max allowed");

      if (_msgSender() != owner()) {
        require(_mintedPerAddress[_msgSender()] + tokensNumber <= PER_WALLET_LIMIT, "You have hit the max tokens per wallet");
        require(_validateSignature(signature, _msgSender()), "Your wallet is not whitelisted");
        require(tokensNumber * tokenPrice == msg.value,
          "You have not sent enough ETH"
        );
        _mintedPerAddress[_msgSender()] += tokensNumber;
      }

      _mint(_msgSender(), FLOOR_X_CREEPZ, tokensNumber, "");
      emit TokensMinted(_msgSender(), tokensNumber);
    }

    function checkIfWhitelisted(bytes calldata signature, address caller) public view returns (bool) {
        return (_validateSignature(signature, caller));
    }

    function _validateSignature(bytes calldata signature, address caller) internal view returns (bool) {
      bytes32 dataHash = keccak256(abi.encodePacked(caller));
      bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);

      address receivedAddress = ECDSA.recover(message, signature);
      return (receivedAddress != address(0) && receivedAddress == signerAddress);
    }

    function updateSaleStatus(bool status) public onlyOwner {
      require(tokenPrice != 0, "Price is not set");
      saleIsActive = status;
    }
    
    function setTokenPrice(uint256 _tokenPrice) public onlyOwner {
      require(!saleIsActive, "Price cannot be changed while sale is active");
      tokenPrice = _tokenPrice;
    }

    function withdraw() external onlyOwner {
      uint256 balance = address(this).balance;
      payable(owner()).transfer(balance);
    }

    function pause(bool _isPaused) external onlyOwner {
      isPaused = _isPaused;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        require(!isPaused, "ERC1155Pausable: token transfer while paused");
    }
}