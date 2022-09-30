// SPDX-License-Identifier: MIT
//
//
//        MOLFAR by Ukraines
//
//    Smart Contract v2 by Ryan Meyers
//
//    Generosity attracts generosity
//   The world will be saved by beauty
//
//

pragma solidity ^0.8.16;

import "ERC1155Burnable.sol";

import "Ownable.sol";

import "ERC2981.sol";

import "draft-EIP712.sol";
import "ECDSA.sol";

import "Base64.sol";
import "Strings.sol";


contract MOLFAR666 is ERC2981, EIP712, ERC1155Burnable, Ownable {

  error ExceedsMaxSupply();
  error AlreadyMinted();
  error NotAllowed();
  error BadTiming();
  // error NeedMoreEther();
  error BadMintKey();

  struct MintKey {
    address wallet;
    uint8 generation;
  }

  bytes32 private constant MINTKEY_TYPE_HASH = keccak256("MintKey(address wallet,uint8 generation)");

  address private _signer;

  uint16 public MAX_SUPPLY = 666;
  uint16 public TOTAL_SUPPLY = 40;
  uint8 public GENERATION = 6;
  bool public MINT_OPEN = false;

  mapping(address => bool) private _minted;
  
  string public imageURI = "ipfs://bafybeibdd4hnmikjaly7pgl5zjhgxq2knvy6kbrmxdkgb5cdk2amlsg47a/molfar.gif";

  string public name;
  string public symbol;

  constructor(
      string memory name_,
      string memory symbol_,
      address signer,
      address receiver
    )
     ERC1155("")
     EIP712(name_, "1")
    {
      setSigner(signer);
      symbol = symbol_;
      name = name_;
      _mint(msg.sender, 666, TOTAL_SUPPLY, "");
      
      _setDefaultRoyalty(receiver, 1000);

    }

    
    function mint(bytes calldata signature) public {
      if (!MINT_OPEN) revert BadTiming();
      // if (msg.sender.balance < 0.15 ether) revert NeedMoreEther();
      if (_minted[msg.sender]) revert AlreadyMinted();
      if (!verify(signature)) revert BadMintKey();
      if (TOTAL_SUPPLY >= MAX_SUPPLY) revert ExceedsMaxSupply();
      
      _minted[msg.sender] = true;
      TOTAL_SUPPLY += 1;

      _mint(msg.sender, 666, 1, "");
      
      

      if(TOTAL_SUPPLY == MAX_SUPPLY){
        MINT_OPEN = false;
        GENERATION += 1;
      }

    }

    function hasMinted(address minter) public view returns (bool) {
      return _minted[minter];
    }


    // Setter methods
    function setSigner(address signer) public onlyOwner {
      _signer = signer;
    }
    
    function setImageURI(string memory uri_) public onlyOwner {
      imageURI = uri_;
    }

    function openMint() public onlyOwner {
      MINT_OPEN = true;
    }

    function closeMint() public onlyOwner {
      MINT_OPEN = false;
    }

    function setRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
      _setDefaultRoyalty(receiver, feeNumerator);
    }

    function SEED_PUZZLE_HINT() public pure returns (string memory) {
      return "Roget+BIP39";
    }

    function verify(bytes calldata signature) public view returns (bool) {
    bytes32 digest = _hashTypedDataV4(
        keccak256(
            abi.encode(
                MINTKEY_TYPE_HASH,
                msg.sender,
                GENERATION
            )
        )
      );

      return ECDSA.recover(digest, signature) == _signer;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256) public view virtual returns (string memory) {
        string memory baseURI = "data:application/json;base64,";
        string memory json = string(
            abi.encodePacked(
                '{"name": "DARK MOLFAR", "description": "MOLFAR is considered a powerful magician who is capable of many miracles. However, what exactly this magician is hiding, and what secrets are hidden under his cloak? What will happen next and what opportunities will be opened? The only way is to join the story or leave with nothing...", "image":"',
                imageURI,
                '", "attributes": [{"trait_type": "Magic", "value": "Dark"}]}'
            )
        );
        string memory jsonBase64Encoded = Base64.encode(bytes(json));
        return string(abi.encodePacked(baseURI, jsonBase64Encoded));
    }

    function uri(uint256 _id) public view virtual override returns (string memory) {
        return tokenURI(_id);
    }

   

    // Override to support royalties via ERC2981
    function supportsInterface(
    bytes4 interfaceId
    ) public view virtual override(ERC1155, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return 
            ERC1155.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

}

// if you made it this far, you deserve a good fork.
// go mint one at forkhunger.art and feed someone real food