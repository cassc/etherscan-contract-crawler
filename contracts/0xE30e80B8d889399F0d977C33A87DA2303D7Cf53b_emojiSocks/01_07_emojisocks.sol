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

contract emojiSocks is INft, Ownable, ERC721A {
    using ECDSA for bytes32;
    uint256 public maxSupply = 3000;
    uint256 public publicPrice = 0.005 ether;
    uint64 public WALLET_MAX = 100;
    uint256 public maxFreeMint = 0;
    string private _baseTokenURI = "";
    string private baseExtension = ".json";
    bool public pausedSale = true;
    event Minted(address indexed receiver, uint256 quantity);
    mapping(address => uint256) private _freeMintedCount; 

    constructor() ERC721A("EmojiSocks", "EMOJISOCKS") {}


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