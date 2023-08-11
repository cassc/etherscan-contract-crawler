//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./MentaportERC721.sol";
/**                                            
       
             ___           ___           ___                         ___           ___         ___           ___                   
     /\  \         /\__\         /\  \                       /\  \         /\  \       /\  \         /\  \                  
    |::\  \       /:/ _/_        \:\  \         ___         /::\  \       /::\  \     /::\  \       /::\  \         ___     
    |:|:\  \     /:/ /\__\        \:\  \       /\__\       /:/\:\  \     /:/\:\__\   /:/\:\  \     /:/\:\__\       /\__\    
  __|:|\:\  \   /:/ /:/ _/_   _____\:\  \     /:/  /      /:/ /::\  \   /:/ /:/  /  /:/  \:\  \   /:/ /:/  /      /:/  /    
 /::::|_\:\__\ /:/_/:/ /\__\ /::::::::\__\   /:/__/      /:/_/:/\:\__\ /:/_/:/  /  /:/__/ \:\__\ /:/_/:/__/___   /:/__/     
 \:\~~\  \/__/ \:\/:/ /:/  / \:\~~\~~\/__/  /::\  \      \:\/:/  \/__/ \:\/:/  /   \:\  \ /:/  / \:\/:::::/  /  /::\  \     
  \:\  \        \::/_/:/  /   \:\  \       /:/\:\  \      \::/__/       \::/__/     \:\  /:/  /   \::/~~/~~~~  /:/\:\  \    
   \:\  \        \:\/:/  /     \:\  \      \/__\:\  \      \:\  \        \:\  \      \:\/:/  /     \:\~~\      \/__\:\  \   
    \:\__\        \::/  /       \:\__\          \:\__\      \:\__\        \:\__\      \::/  /       \:\__\          \:\__\  
     \/__/         \/__/         \/__/           \/__/       \/__/         \/__/       \/__/         \/__/           \/__/  
       
       
                                                   
**/

/**
 * @title MentaportMint
 * @dev Extending MentaportERC721
   Adds functionality to check rules of who, when and where user can mint NFT
**/

contract MentaportMint is MentaportERC721 {
 
  using Strings for uint256;

  struct MintRequest {
      bytes signature;
      uint256 locationRuleId;
      uint256 timestamp;
      address receiver;
      string tokenURI;
  }

  mapping(bytes => bool) internal _usedMintSignatures;
  bool public useMintRules = true;
  address internal initMentaportAccount = 0x163f3475D1C4F194BD381B230a543DAA8D3f7c0d;

  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _maxSupply,
    address _admin,
    address _minter,
    address _signer
    ) MentaportERC721(_name, _symbol, _maxSupply, false, _admin, _minter, _signer, initMentaportAccount)
  {}
  //----------------------------------------------------------------------------
  // External functions
  /**
  * @dev Mint function as in {ERC721}
  *
  *   - Follows `mintCompliance` from {MentaportERC721}
  *   - Checks if the contact is using mint rules, if it is it will fail and
  *       let caller know to use `MintMenta` instead.
  *
  */
  function mint(string memory _tokenURI)
    virtual 
    external 
    payable
    nonReentrant
    whenNotPaused()
    mintCompliance(msg.sender, msg.value, 1) 
    returns (uint256)
  {
    require(!useMintRules, "Failed using mint rules, use mintLocation.");

    return _mintNFT(msg.sender, _tokenURI);
  }

  /**
  * @dev mintLocation function controls signature of rules being passed
  *
  *   - Follows `mintCompliance` from {MentaportERC721}
  *   - Checks `onlyValidMessage` 
  *       - signature approves time / location rule passed
  *   - Checks that the signature ahsnt been used before
  */
  function mintLocation( MintRequest calldata _mintRequest)
    virtual
    external
    payable
    nonReentrant
    whenNotPaused()
    mintCompliance(_mintRequest.receiver, msg.value, 1)
    onlyValidSigner(_mintRequest.receiver, _mintRequest.timestamp, _mintRequest.locationRuleId, _mintRequest.signature)
    returns (uint256)
  {
    require(useMintRules, "Failed not using mint rules, use normal mint function.");

    require(_checkMintSignature(_mintRequest.signature), "Signature already used, not valid anymore.");
    
    return _mintNFT(_mintRequest.receiver, _mintRequest.tokenURI);
  }

  /**
  * @dev MINTER_ROLE of contract mints 1 token for address `_receiver`, with `_tokenURI`
  *
  *  - Emits a {MintForAddress} event.
  */
  function mintForAddress(string memory _tokenURI, address _receiver) 
    virtual 
    external 
    nonReentrant 
    mintCompliance(_receiver, cost,1) 
    onlyMinter {
    
    _mintNFT(_receiver, _tokenURI);
    emit MintForAddress(msg.sender, 1, _receiver);
  }

  //----------------------------------------------------------------------------
  // External Only Admin / owner
 /**
  * @dev Set use of mint rules in contracty 
  *  Owner con contract can turn off / on the use of mint rules only
  *  
  *  - Emits a {RuleUpdate} event.
  */
  function useUseMintRules(bool _state) external onlyOwner {
    useMintRules = _state;
    uint state = useMintRules ? uint(1) : uint(0);

    emit RuleUpdate(msg.sender, string.concat("Setting mint rules: ",state.toString()));
  }


  //----------------------------------------------------------------------------
  // Internal Functions
  function _checkMintSignature(bytes memory _signature) internal returns (bool) {
    require(!_usedMintSignatures[_signature], "Signature already used, not valid anymore.");

    _usedMintSignatures[_signature] = true;
    return true;
  }
}