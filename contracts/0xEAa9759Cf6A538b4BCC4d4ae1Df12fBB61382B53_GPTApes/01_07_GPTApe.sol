/*        
              GPTA:                       
             ?P~5GG5?~                    
             !J^~JG5?^                    
               .Y&&#Y                     
                7Y55J                     
             ...:..!J?.                   
           .:.::...:!:                    
          ....:......                     
        .::...:::...                      
        .^::!BJ!~::::                     
         .:~B&G55J5~^~.                   
           :P#P??!77BB5                   
          .^~~~::^^^~:.                   
          .^^:  ..::^.                    
          ...       .:.                   
       .:.           .                    
   ~P~ ..            .:.                  
   .PP57              ::^^?J:             
    .:!J~             :JB5^7^             
                      :?:                 
Website: https://www.gptapes.xyz/
Twitter: https://twitter.com/gptapesnft
*/
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "Ownable.sol";
import "ECDSA.sol";
import "ERC721A.sol";

interface INft is IERC721A {
    error InvalidSaleState();
    error NonEOA();
    error WithdrawFailedVault();
}

contract GPTApes is INft, Ownable, ERC721A {
    using ECDSA for bytes32;
    address private signerAddress = 0xF84f0303565De612108aC24593DeffBF124A93ef;
    uint256 public maxSupply = 10000;
    uint256 public publicPrice = 0.006 ether;
    uint256 public preSalePrice = 0.004 ether;
    uint256 public preSaleMaxMint = 10;
    uint64 public WALLET_MAX = 50;
    uint256 public maxFreeMint = 1;
    uint256 public maxFreePreMint = 1;
    string private _baseTokenURI = "ipfs://bafybeiefapxgpfg5g3e5h3ivzjsley5aikqqpzxcl2x2li7uja3w3ncnf4/";
    string private baseExtension = ".json";
    bool public pausedPresale = false;
    bool public pausedSale = true;
    event Minted(address indexed receiver, uint256 quantity);
    mapping(address => uint256) private _freeMintedCount; 
    mapping(address => uint256) private _freePreMintedCount; 

    constructor() ERC721A("GPT-Apes", "GPTA") {}


    /// @notice Verify signature
    function verifyAddressSigner(bytes memory signature) private 
    view returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender));
        return signerAddress == messageHash.toEthSignedMessageHash().recover(signature);
    }

    /// @notice Function used during the public mint
    /// @param quantity Amount to mint.
    /// @dev checkState to check sale state.
    function Mint(uint64 quantity) external payable {
    require(!pausedSale, "Sale Paused");
    uint256 price = publicPrice;
    uint256 freeMintCount = _freeMintedCount[msg.sender];
    if(quantity<=(maxFreeMint-freeMintCount)){
        price=0;
        _freeMintedCount[msg.sender] += quantity;
        }
    require(msg.value >= (price*quantity), "Not enough ether to purchase NFTs.");
    require((_numberMinted(msg.sender) - _getAux(msg.sender)) + quantity <= WALLET_MAX, "Wallet limit exceeded");
    require((_totalMinted()+ quantity) <= maxSupply, "Supply exceeded");

    _mint(msg.sender, quantity);
    emit Minted(msg.sender, quantity);
    }

    // Presale mints
    function preSaleMint(uint64 quantity, bytes memory signature) external payable {
    require(!pausedPresale, "Presale Paused");
    require((_totalMinted()+ quantity) <= maxSupply, "Supply exceeded");
    require((_numberMinted(msg.sender) - _getAux(msg.sender)) + quantity <= preSaleMaxMint, "Presale limit exceeded");
    uint256 payForCount = quantity;
        uint256 freePreMintCount = _freePreMintedCount[msg.sender];
        if (freePreMintCount < maxFreePreMint) {
         if (quantity > maxFreePreMint-freePreMintCount) {
         payForCount = quantity - maxFreePreMint + freePreMintCount;
      } else {payForCount = 0;}
      _freePreMintedCount[msg.sender] = freePreMintCount + quantity - payForCount;
    }
    require(msg.value >= (preSalePrice*payForCount), "Not enough ether to purchase NFTs.");
    require(verifyAddressSigner(signature), "Address is not allowlisted");
    _mint(msg.sender, quantity);
    emit Minted(msg.sender, quantity);
}

    /// @notice Fail-safe withdraw function, incase withdraw() causes any issue.
    /// @param receiver address to withdraw to.
    function withdrawTo(address receiver) public onlyOwner {        
        (bool withdrawalSuccess, ) = payable(receiver).call{value: address(this).balance}("");
        if (!withdrawalSuccess) revert WithdrawFailedVault();
    }


    /// @notice Function used to change mint public price.
    /// @param newPublicPrice Newly intended `publicPrice` value.
    /// @dev Price can never exceed the initially set mint public price (0.069E), and can never be increased over it's current value.

    function setRound(uint256 _maxFreeMint, uint64 newMaxWallet, uint256 newPublicPrice) external onlyOwner {
      maxFreeMint = _maxFreeMint;
      WALLET_MAX = newMaxWallet;
      publicPrice = newPublicPrice;
    }

    function setPresaleState(bool _state) external onlyOwner {
        pausedPresale = _state;
    }

    function setSaleState(bool _state) external onlyOwner {
        pausedSale = _state;
    }


    /// @notice Function used to check the number of tokens `account` has minted.
    /// @param account Account to check balance for.
    function balance(address account) external view returns (uint256) {
        return _numberMinted(account);
    }


    /// @notice Function used to view the current `_baseTokenURI` value.
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /// @notice Sets base token metadata URI.
    /// @param baseURI New base token URI.
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }


    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
            string memory baseURI = _baseURI();
            return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId),baseExtension)) : ''; 
    }
}