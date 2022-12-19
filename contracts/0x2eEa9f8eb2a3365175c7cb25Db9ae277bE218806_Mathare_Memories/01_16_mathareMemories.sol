// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/** 
 * @title Mathare Memories 
 * @notice This is a customized ERC-721 contract for Mathare_Memories.
 * @author Matto
 * @custom:security-contact [email protected]
 */ 
contract Mathare_Memories is ERC721Royalty, Ownable, ReentrancyGuard {
  using Strings for string;
  string public baseURI;
  string public description;
  bool public projectLocked;
  uint16 public maxSupply = 68;
  string public imageURIbase;
  string public audioURIbase;
  mapping(uint256 => string) public projectData;
  mapping(uint256 => uint256) public transferCountOf;  
  address public auctionAddress;
  address public secondaryAddress;
  address public charityAddress;
  uint96 public royaltyBPS;

  constructor() ERC721("Mathare Memories", "MAMEM") {}

  /** 
   * RECEIVING FUNCTIONS
   * @notice These functions are required for the contract to be able to
   * receive Ether.
   * @dev The receive() function receives Ether when msg.data is empty.
   * The fallback() function receives Ether when msg.data is not empty.
   */
  receive() external payable {}
  fallback() external payable {}

  /** 
   * CUSTOM EVENTS
   * @notice These events are emitted by the 'writeProjectData' function.
   * @dev These will be monitored by the custom backend. They will trigger
   * updating the API with data stored in projectData, as well as data returned
   * by the scriptInputsOf() function.
   *
   * ProjectData Event
   * @notice This is emitted whenever writeProjectData is successfully called.
   * @dev indexed keyword is added to scriptIndex for searchability.
   * @param scriptIndex is index in the mapping that is being updated.
   * @param oldScript is the data being replaced, potentially "".
   * @param newScript is the new data stored to chain.
   */  
  event ProjectData(
      uint256 indexed scriptIndex,
      string oldScript,
      string newScript
  );

  /**
   * OVERRIDES
   * @notice These functions are declared as overrides because functions of the 
   * same name exist in imported contracts.
   * @dev 'super._transfer' calls the overridden function.
   *
   * @notice _baseURI is an internal function that returns a state value.
   * @dev This override is needed when using a custom baseURI.
   * @return baseURI, which is a state value.
   */
  function _baseURI()
      internal 
      view 
      override 
      returns (string memory) 
  {
      return baseURI;
  }

  /**
   * @notice _transfer override adds logic to track transfer counts as well as
   * the prior owner.
   * @dev This override updates mappings and then calls the overridden function.
   * @param  _from is the address the token is being sent from.
   * @param  _to is the address the token is being sent to.
   * @param  _tokenId is the token being transferred.
   */
  function _transfer(
      address _from,
      address _to,
      uint256 _tokenId
  ) 
      internal 
      virtual 
      override 
  {
      transferCountOf[_tokenId]++;
      super._transfer(_from, _to, _tokenId);
  }

  /**
   * MINTING
   * @notice This function mints all tokens to the contract owner's wallet
   */
  function mintAllTokens() 
      external 
      onlyOwner
  {
      require(auctionAddress != address(0));
      for (uint i = 1; i <= maxSupply; i++) {
        _safeMint(auctionAddress, i);
      }
  }

  /**
   * CUSTOM
   * @notice These are custom functions for Mathare_Memories.
   * 
   * @notice writeProjectData allows storage of the generative script on-chain.
   * @dev This will store the generative script needed to reproduce Mathare_Memories
   * tokens, along with other information and instructions. Vanilla JavaScript
   * and p5.js v1.0.0 are other dependencies.
   * @param index identifies where the script data should be stored.
   * @param newScript is the new script data.
   */
  function writeProjectData(
      uint256 index, 
      string memory newScript
  )
      external
      onlyOwner
  {
      require(!projectLocked);
      emit ProjectData(index, projectData[index], newScript);
      projectData[index] = newScript;
  }

  /**
   * @notice scriptInputsOf returns the input data necessary for the generative
   * script to create/recreate a Mathare_Memories token. 
   * @dev For any given token, this function returns all the on-chain data that
   * is needed to be inputted into the generative script to deterministically 
   * reproduce both the token's artwork and metadata.
   * @param tokenId is the token whose inputs will be returned.
   * @return scriptInputs are returned in JSON format.
   */
  function scriptInputsOf(
      uint256 tokenId
  )
      external
      view
      returns (string memory)
  {
      return
          string(
              abi.encodePacked(
                  '{"token_id":"',
                  Strings.toString(tokenId),               
                  '","transfer_count":"',
                  Strings.toString(transferCountOf[tokenId]),    
                  '","imageURI_base":"',
                  imageURIbase,
                  '","audioURI_base":"',
                  audioURIbase,              
                  '"}'
              )
          );
  }

  /**
   * CONTROLS
   * @notice These are contract-level controls.
   * @dev all should use the onlyOwner modifier.
   *
   * @notice lockScripts freezes the projectData storage.
   * @dev The project must be fully minted before this function is callable.
   */
  function lockScripts() 
      external 
      onlyOwner 
  {
      projectLocked = true;
  }

  /**
   * @notice setMediaURIs updates the media URI strings.
   * @dev This function allows changes to URIs for the token media.
   * @param _imageURIbase is the new image URI base.
   * @param _audioURIbase is the new audio URI base.
   */
  function setMediaURIs(
      string memory _imageURIbase,
      string memory _audioURIbase
  )
      external
      onlyOwner
  {
      imageURIbase = _imageURIbase;
      audioURIbase = _audioURIbase;
  }

  /**
   * @notice setAuctionAddress updates the auction address.
   * @dev This function allows changes to the address tokens are minted to.
   * This address will conduct the auctions and transfer funds to the charity.
   * @param _auctionAddress is the new payments address.
   */
  function setAuctionAddress(
      address _auctionAddress 
  )
      external
      onlyOwner
  {
      auctionAddress = _auctionAddress;
  }

  /**
   * @notice setCharityAddress updates the charity address.
   * @dev This function allows changes to the address royalty funds are sent to.
   * @param _charityAddress is the new charity address.
   */
  function setCharityAddress(
      address _charityAddress 
  )
      external
      onlyOwner
  {
      charityAddress = _charityAddress;
  }

  /**
   * @notice setSecondaryData updates the royalty address and BPS for the project.
   * @dev This function allows changes to the payments address and secondary sale
   * royalty amount. After setting values, _setDefaultRoyalty is called in 
   * order to update the imported EIP-2981 contract functions.
   * @param _secondaryAddress is the new payments address.
   * @param _royaltyBPS is the new projet royalty amount, measured in 
   * base percentage points.
   */
  function setSecondaryData(
      address _secondaryAddress, 
      uint96 _royaltyBPS
  )
      external
      onlyOwner
  {
      secondaryAddress = _secondaryAddress;
      royaltyBPS = _royaltyBPS;
      _setDefaultRoyalty(secondaryAddress, _royaltyBPS);
  }

  /**
   * @notice setDescription updates the on-chain description.
   * @dev This is separate from other update functions because the description
   * size may be large and thus expensive to update.
   * @param _description is the new description. Quotation marks are not needed.
   */
  function setDescription(
      string memory _description
  ) 
      external 
      onlyOwner 
  {
      description = _description;
  }

  /**
   * @notice setURI sets/updates the project's baseURI.
   * @dev baseURI is appended with tokenId and is returned in tokenURI calls.
   * @dev _newBaseURI is used instead of _baseURI because an override function
   * with that name already exists.
   * @param _newBaseURI is the API endpoint base for tokenURI calls.
   */
  function setURI(
      string memory _newBaseURI
  ) 
      external 
      onlyOwner 
  {
      baseURI = _newBaseURI;
  }

  /**
   * FUND ACCESS
   * @dev this function allows three addresses to call the withdrawal function:
   * contract owner, charity, and auctioner.
   *  
   * @notice withdraw is used to send funds to the charity address.
   * @dev Withdraw cannot be called if the charity addresses is not set. 
   * If a receiving address is a contract using callbacks, the withdraw function
   * could run out of gas. Update the receiving address if necessary.
   */
  function withdraw() 
      external 
  {
      require(msg.sender == owner() || 
          msg.sender == charityAddress || 
          msg.sender == auctionAddress);
      require(charityAddress != address(0));
      payable(charityAddress).transfer(address(this).balance);
  }
}