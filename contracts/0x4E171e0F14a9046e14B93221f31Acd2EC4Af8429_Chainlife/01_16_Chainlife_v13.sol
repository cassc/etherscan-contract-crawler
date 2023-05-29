// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**


   □□□□    □□    □□     □□□     □□□□  □□□    □□  □□       □□□□  □□□□□□□  □□□□□□□
 □□    □□  □□    □□   □□   □□    □□   □□□□   □□  □□        □□   □□       □□     
□□         □□    □□  □□     □□   □□   □□ □□  □□  □□        □□   □□□□□    □□□□□  
□□         □□□□□□□□  □□□□□□□□□   □□   □□  □□ □□  □□        □□   □□       □□     
 □□    □□  □□    □□  □□     □□   □□   □□   □□□□  □□        □□   □□       □□     
   □□□□    □□    □□  □□     □□  □□□□  □□    □□□  □□□□□□□  □□□□  □□       □□□□□□□


                                                                        by Matto
*/

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface i_ArtBlocks {
    function ownerOf(uint256 fullTokenId) external view returns (address);
}

/** 
 * @title Chainlife
 * @notice This is a customized ERC-721 contract for Chainlife. All tokens
 * created and controlled by this contract are licensed CC BY-NC 4.0.
 * @author Matto
 * @custom:security-contact [email protected] / @MonkMatto on Twitter
 */ 
contract Chainlife is ERC721Royalty, Ownable, ReentrancyGuard {
  using Counters for Counters.Counter;
  using Strings for string;

  Counters.Counter public tokensMinted;
  string public baseURI;
  string public description;
  uint8 public mintStage;
  bool public scriptsLocked;
  address public paymentsAddress;
  uint96 public royaltyBPS;
  uint256 public mintFee;
  uint256 public shiftFee;
  uint16 public maxSupply = 4096;
  mapping(uint256 => string) public scriptData;
  mapping(uint256 => uint8) public preMintWithEnso;
  mapping(uint256 => uint8) public preMintWithFOCUS;
  mapping(uint256 => int256) public levelShiftOf;
  mapping(uint256 => string) public customRuleOf;
  mapping(uint256 => bytes32) private tokenEntropyOf;
  mapping(uint256 => address) private previousOwnerOf;
  mapping(uint256 => uint256) private transferCountOf;
  address private ABcontract = 0xa7d8d9ef8D8Ce8992Df33D8b8CF4Aebabd5bD270;

  constructor() ERC721("Chainlife", "CHNLF") {}

  /** 
   * CUSTOM EVENTS
   * @notice These events are emitted by functions 'SET_CUSTOM_RULE' and 
   * 'writeScriptData'.
   * @dev These will be monitored by the custom backend. They will trigger
   * updating the API with data stored in scriptData, as well as data returned
   * by the scriptInputsOf() function.
   *
   * CustomRule Event
   * @notice This is emitted whenever SET_CUSTOM_RULE is successfully called.
   * @dev indexed keyword is added for later searchability.
   * @param tokenId is the token that had a change to its CustomRule.
   * @param rule is the rule string that was written to chain.   
   * @param byAddress is the address that set the CustomRule (unless set by 
   * Matto on their behalf).
   */
  event CustomRule(
      uint256 indexed tokenId,
      string rule,
      address indexed byAddress
  );

  /**
   * ScriptData Event
   * @notice This is emitted whenever writeScriptData is successfully called.
   * @dev indexed keyword is added to scriptIndex for searchability.
   * @param scriptIndex is index in the mapping that is being updated.
   * @param oldScript is the data being replaced, potentially "".
   * @param newScript is the new data stored to chain.
   */  
  event ScriptData(
      uint256 indexed scriptIndex,
      string oldScript,
      string newScript
  );

  /**
   * ShiftLevel Event
   * @notice This is emitted whenever SHIFT_LEVEL is successfully called.
   * @dev indexed keyword is added for later searchability.
   * @param tokenId is the token that had a change to its level shift.
   * @param shift is the amount that the token is being shifted.
   * @param totalShift is the cumulative shift amount.
   * @param byAddress is the address that called SHIFT_LEVEL (unless set by 
   * Matto on their behalf).
   */  
  event ShiftLevel(
      uint256 indexed tokenId,
      int256 shift,
      int256 totalShift,
      address indexed byAddress
  );

  /**
   * MODIFIERS
   * @notice These are reusable code to control function execution.
   *
   * @notice callerIsUser modifier prohibits contracts.
   * @dev This modifier will cause transactions to fail if they come from a
   * contract because the transaction origin will not match the message sender.
   */
  modifier callerIsUser() {
      require(tx.origin == msg.sender);
      _;
  }

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
      previousOwnerOf[_tokenId] = _from;
      super._transfer(_from, _to, _tokenId);
  }

  /**
   * MINTING
   * @notice These are functions needed to mint tokens.
   * @dev various external functions call the same internal function (_minter)
   * if requirements are met.
   *
   * @notice PREMINT is the restricted access public mint function.
   * @dev This allows previous collectors of Art Blocks projects #34 and #181 to
   * mint at an earlier stage. Ownership is verified via the ArtBlocks contract
   * controlling these tokens. Art Blocks tokenIds are the
   * project number * 1 million, plus that project's token 'number.'
   * The preMintWith* mappings tracks tokens so they can only be used once.
   * The contract owner can bypass the perMintActive requirement.
   * MAINNET FOCUS tokenBase: 181000000 | GOERLI tokenBase: 94000000.
   * @param projectNumber is the Art Blocks project number of a Matto project,
   * either 34 or 181 are acceptable.
   * @param tokenNumber is the owned token from the project corresponding
   * to the projectNumber that is being used for the premint.
   */
  function PREMINT(
      uint256 projectNumber, 
      uint256 tokenNumber
  )
      external
      payable
      nonReentrant
      callerIsUser
  {
      require(mintStage == 1);
      require(projectNumber == 34 || projectNumber == 181);
      require(
          msg.sender ==
              i_ArtBlocks(ABcontract).ownerOf(
                  (projectNumber * 1000000) + tokenNumber
              )
      );
      if (projectNumber == 34) {
          require(
              preMintWithEnso[tokenNumber] == 0,
              "Enso already used."
          );
          preMintWithEnso[tokenNumber] = 1;
      } else {
          require(
              preMintWithFOCUS[tokenNumber] == 0,
              "FOCUS already used."
          );
          preMintWithFOCUS[tokenNumber] = 1;
      }
      _minter(msg.sender);
  }

  /**
   * @notice MINT is the regular access public mint function that mints to the
   * caller's address.
   * @dev Variation of a mint function that uses the msg.sender address as the
   * account to mint to. The contract owner can bypass the publicMintActive 
   * requirement.
   */
  function MINT() 
      external 
      payable 
      nonReentrant 
      callerIsUser 
  {
      require(mintStage == 2 || msg.sender == owner());
      _minter(msg.sender);
  }

  /**
   * @notice MINT_TO_ADDRESS is the regular access public mint function that 
   * mints to a specified address.
   * @dev Variation of a mint function that uses a submitted address as the
   * account to mint to. The contract owner can bypass the publicMintActive 
   * requirement.
   * @param to is the address to send the token to.
   */
  function MINT_TO_ADDRESS(
    address to
  )
      external
      payable
      nonReentrant
      callerIsUser
  {
      require(mintStage == 2 || msg.sender == owner());
      _minter(to);
  }

  /**
   * @notice _minter is the internal function that generates mints.
   * @dev Minting function called by all other public 'MINT' functions.
   * The contract owner can bypass the payment requirement.
   * @param _to is the address to send the token to.
   */
  function _minter(
      address _to
  ) 
      internal 
  {
      require(
          msg.value == mintFee || msg.sender == owner(),
          "Incorrect value."
      );
      require(
          tokensMinted.current() < maxSupply,
          "All minted."
      );
      uint256 tokenId = tokensMinted.current();
      tokensMinted.increment();
      _assignTokenData(tokenId);
      _safeMint(_to, tokenId);
  }

  /**
   * @notice _assignTokenData generates the token's entropy.
   * @dev This creates a hash that will be used as token entropy, created
   * from various data inputs. Even with concurrent mints in a single block,
   * each _tokenId will be unique, resulting in unique hashes.
   * @param _tokenId is the token that the data will get assigned to.
   */
  function _assignTokenData(
      uint256 _tokenId
  ) 
      internal 
  {
      tokenEntropyOf[_tokenId] = keccak256(
          abi.encodePacked(
              "Chainlife",
              _tokenId,
              block.number,
              block.timestamp,
              tx.gasprice
          )
      );
  }

  /**
   * CUSTOM
   * @notice These are custom functions for Chainlife.
   * 
   * @notice CUSTOM_RULE allows owners to set a rule on-chain. 
   * @dev This allows token owners to submit and record data on the blockchain.
   * The contract owner can also set these rules on the token owner's behalf.
   * Each Chainlife token has the ability to utilize custom rules, but only
   * after evolution. Chainlife tokens use the B/S notation for rules:
   *
   * B{number list}/S{number list}
   *
   * For example, the rulestring for Conway's Game of Life is B3/S23, meaning 
   * that any dead cell with 3 living neighbors will be born (B3), and any 
   * live cells with 2 or 3 neighbors will survive (S23). All other cells 
   * will die or remain dead.
   * @param tokenId is the token whose CustomRule is being updated.
   * @param rule is a string that gets stored as a state value. The input string
   * should not include any quotation marks.
   */
  function CUSTOM_RULE(
      uint256 tokenId, 
      string memory rule
  ) 
      external 
  {
      require(
          msg.sender == ownerOf(tokenId) || msg.sender == owner(),
          "Unauthorized."
      );
      emit CustomRule(tokenId, rule, ownerOf(tokenId));
      customRuleOf[tokenId] = rule;
  }

  /**
   * @notice RESET_RULE allows owners to remove a custom rule. 
   * @dev This replaces the customRuleOf[tokenId] data with an empty string.
   * When the generative script receives an empty string, it uses the rule
   * that was determined by the token hash at mint.
   * @param tokenId is the token whose custom rule is being reset.
   */
  function RESET_RULE(
      uint256 tokenId
  ) 
      external 
  {
      require(
          msg.sender == ownerOf(tokenId) || msg.sender == owner(),
          "Unauthorized."
      );
      emit CustomRule(tokenId, "", ownerOf(tokenId));
      customRuleOf[tokenId] = "";
  }

  /**
   * @notice SHIFT_LEVEL allows owners to adjust the level shift value that is 
   * stored on-chain. Level shifts are additive, eg. submitting a transaction 
   * with shift value of -5 will subtract 5 from the current level shift value. 
   * @dev This allows token owners to submit and record data on the blockchain.
   * The contract owner can also set these rules on the token owner's behalf.
   * Each Chainlife token tracks its level, which is determined by transfer
   * count and shift amount.
   * @param tokenId is the token whose shift amount is being updated.
   * @param shift is a signed integer that gets stored as a state value.
   */
  function SHIFT_LEVEL(
      uint256 tokenId, 
      int256 shift
  ) 
      external 
      payable
      nonReentrant
      callerIsUser      
  {
      require(
          msg.sender == ownerOf(tokenId) || msg.sender == owner(),
          "Unauthorized."
      );
      uint256 absShift = (shift < 0) ? uint256(-shift) : uint256(shift);
      require(
          msg.value == absShift * shiftFee || msg.sender == owner(),
          "Incorrect value."
      );
      int256 totalShift = levelShiftOf[tokenId] + shift;
      emit ShiftLevel(tokenId, shift, totalShift, ownerOf(tokenId));
      levelShiftOf[tokenId] = totalShift;
  }

  /**
   * @notice writeScriptData allows storage of the generative script on-chain.
   * @dev This will store the generative script needed to reproduce Chainlife
   * tokens, along with other information and instructions. Vanilla JavaScript
   * and p5.js v1.0.0 are other dependencies.
   * @param index identifies where the script data should be stored.
   * @param newScript is the new script data.
   */
  function writeScriptData(
      uint256 index, 
      string memory newScript
  )
      external
      onlyOwner
  {
      require(!scriptsLocked);
      emit ScriptData(index, scriptData[index], newScript);
      scriptData[index] = newScript;
  }

  /**
   * @notice scriptInputsOf returns the input data necessary for the generative
   * script to create/recreate a Chainlife token. 
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
      string memory entropyString = BytesToHexString.toHex(tokenEntropyOf[tokenId]);
      string memory sign = (levelShiftOf[tokenId] < 0) ? "-" : "";
      uint256 absLevelShift = (levelShiftOf[tokenId] < 0) ? uint256(-levelShiftOf[tokenId]) : uint256(levelShiftOf[tokenId]);
      return
          string(
              abi.encodePacked(
                  '{"token_id":"',
                  Strings.toString(tokenId),
                  '","token_entropy":"',
                  entropyString,
                  '","previous_owner":"',
                  Strings.toHexString(uint160(previousOwnerOf[tokenId]), 20),
                  '","current_owner":"',
                  Strings.toHexString(uint160(ownerOf(tokenId)), 20),
                  '","transfer_count":"',
                  Strings.toString(transferCountOf[tokenId]),
                  '","level_shift":"',
                  sign, Strings.toString(absLevelShift),                  
                  '","custom_rule":"',
                  customRuleOf[tokenId],
                  '"}'
              )
          );
  }

  /**
   * CONTROLS
   * @notice These are contract-level controls.
   * @dev all should use the onlyOwner modifier.
   *
   * @notice lockScripts freezes the scriptData storage.
   * @dev The project must be fully minted before this function is callable.
   */
  function lockScripts() 
      external 
      onlyOwner 
  {
      require(tokensMinted.current() == maxSupply);
      scriptsLocked = true;
  }

  /**
   * @notice lowerMaxSupply allows changes to the maximum iteration count,
   * a value that is checked against during mint.
   * @dev This function will only update the maxSupply variable if the 
   * submitted value is lower. maxSupply is used in the internal _minter 
   * function to cap the number of available tokens.
   * @param _maxSupply is the new maximum supply.
   */
  function lowerMaxSupply(
      uint16 _maxSupply
  ) 
      external 
      onlyOwner 
  {
      require(_maxSupply < maxSupply && _maxSupply >= tokensMinted.current());
      maxSupply = _maxSupply;
  }

  /**
   * @notice setMintStage sets the stage of the mint.
   * @dev This is used instead of public view booleans to save contract size.
   * @param _mintStage is the new stage for the mint: 0 for disabled, 1 for 
   * premint only, 2 for public mint.
   */
  function setMintStage(
    uint8 _mintStage
  ) 
      external 
      onlyOwner 
  {
      mintStage = _mintStage;
  }

  /**
   * @notice setRoyalties updates the royalty address and BPS for the project.
   * @dev This function allows changes to the payments address and secondary sale
   * royalty amount. After setting values, _setDefaultRoyalty is called in 
   * order to update the imported EIP-2981 contract functions.
   * @param _paymentsAddress is the new payments address.
   * @param _royaltyBPS is the new projet royalty amount, measured in 
   * base percentage points.
   */
  function setRoyalties(
      address _paymentsAddress, 
      uint96 _royaltyBPS
  )
      external
      onlyOwner
  {
      paymentsAddress = _paymentsAddress;
      royaltyBPS = _royaltyBPS;
      _setDefaultRoyalty(paymentsAddress, _royaltyBPS);
  }

  /**
   * @notice setMintFee sets the price per mint.
   * @dev This function allows changes to the payment amount that is required 
   * for minting.
   * @param _mintFee is the cost per mint in Wei.
   */
  function setMintFee(
      uint256 _mintFee
  ) 
      external 
      onlyOwner 
  {
      mintFee = _mintFee;
  }

  /**
   * @notice setShiftFee sets the price per level shift.
   * @dev This function allows changes to the payment amount that is required 
   * to shift a token's level.
   * @param _shiftFee is the cost per level shift in Wei.
   */
  function setShiftFee(
      uint256 _shiftFee
  ) 
      external 
      onlyOwner 
  {
      shiftFee = _shiftFee;
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
   * @notice withdraw is used to send mint and shift funds to the payments
   * address.
   * @dev Withdraw cannot be called if the payments addresses is not set. 
   * If a receiving address is a contract using callbacks, the withdraw function
   * could run out of gas. Update the receiving address if necessary.
   */
  function withdraw() 
      external 
      onlyOwner 
  {
      require(paymentsAddress != address(0));
      payable(paymentsAddress).transfer(address(this).balance);
  }
}

/**
 * The following library is licensed CC BY-SA 4.0.
 * @title BytesToHexString Library
 * @notice Provides a function for converting bytes into a hexidecimal string.
 * @author Mikhail Vladimirov (with edits by Matto)
 * @dev Code in this library is based on the thorough example and walkthrough
 * posted by Mikhail Vladimirov on https://stackoverflow.com/ using the 
 * CC BY-SA 4.0 license.
 */
library BytesToHexString {

  /**
   * @notice toHex takes bytes data and returns the data as a string.
   * @dev This is needed to convert the token entropy (bytes) into a string for
   * return in the scriptInputsOf function. This is the function that is called
   * first, and it calls toHex16 while processing the return.
   * @param _data is the bytes data to convert.
   * @return (string)
   */
  function toHex(bytes32 _data)
    internal
    pure
    returns (string memory) 
  {
    return string(
        abi.encodePacked(
            "0x",
            toHex16(bytes16(_data)),
            toHex16(bytes16(_data << 128))
        )
    );
  }

  /**
   * @notice toHex16 is a helper function of toHex.
   * @dev For an explanation of the operations, see Mikhail Vladimirov's 
   * walkthrough for converting bytes to string on https://stackoverflow.com/.
   * @param _input is a bytes16 data chunk.
   * @return output is a bytes32 data chunk.
   */
  function toHex16(bytes16 _input)
    internal
    pure
    returns (bytes32 output) 
  {
    output = bytes32(_input) & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000 |
      (bytes32(_input) & 0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >> 64;
    output = output & 0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000 |
      (output & 0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >> 32;
    output = output & 0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000 |
      (output & 0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >> 16;
    output = output & 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000 |
      (output & 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >> 8;
    output = (output & 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >> 4 |
      (output & 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >> 8;
    output = bytes32 (0x3030303030303030303030303030303030303030303030303030303030303030 +
      uint256(output) +
      (uint256(output) + 0x0606060606060606060606060606060606060606060606060606060606060606 >> 4 &
      0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) * 7);
  }
}