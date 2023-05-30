// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "solady/utils/ECDSA.sol";
import "solady/utils/LibString.sol";
import "solmate/auth/Owned.sol";
import "solmate/tokens/ERC721.sol";
import "./GobDrops.sol";

/// @title ETH Gobblers
/// @author EtDu
/// @notice Gobble... Gobble... Gobble...

contract ETHGobblers is ERC721, Owned {
  using ECDSA for bytes32;
  using LibString for uint256;

  /*------------------------------------------------------*/
  /*                VARIABLES / CONSTANTS
  /*------------------------------------------------------*/

  uint256 public totalSupply = 0;
  // Genesis max supply, newer generations can be minted via mitosis
  uint256 constant genesisMaxSupply = 2000;
  // Supply of new ETH Gobblers from mitosis
  uint256 public mitosisSupply = 0;
  // Current Gobbler Gobbler token ID. Has the power to gobble one ETH Gobbler before declaring another Gobbler Gobbler.
  uint256 public currentGobblerGobbler;
  // ETH Gobbler action pricing
  uint256 public feedPrice = 0.001 ether;
  uint256 public groomPrice = 0.01 ether;
  uint256 public sleepPrice = 0.1 ether;
  uint256 public gobbleGobblerPrice = 1 ether;

  string public baseURI;

  bool public paused;

  GobDrops public gobDrops;
  
  // ETHGobblers signer of naughty/nice list verifications
  address public signerAddress;
  address constant burnAddress = 0x000000000000000000000000000000000000dEaD;

  // Gobbler ID to equipped traits
  // Traits can be swapped/updated, separate from base artistic traits
  // Base traits are kept track of off-chain
  // Each trait type value represents a trait tokenID from GobDrops
  // 7 trait IDs (uint32) are packed into a single uint256 variable to save on storage costs
  // Value of 2^32 - 1 means no traits
  mapping(uint256 => uint256) public equippedTraits;
  // Total amount of ETH Gobbled per Gobbler ID (in wei)
  mapping(uint256 => uint256) public ETHGobbled;
  // Current nonce per signer, prevents signature replay attacks
  // Backend should query it for creating signatures
  mapping(address => uint256) public signatureNonce;

  enum Action {
    Feed, Groom, Sleep
  }

  /*------------------------------------------------------*/
  /*                        EVENTS
  /*------------------------------------------------------*/

  // All actions are event based, the backend handles health logic based on emitted events
  event Feed(
    uint256 indexed tokenID,
    uint8 indexed amount,
    address indexed owner
  );

  event Groom(
    uint256 indexed tokenID,
    uint8 indexed amount,
    address indexed owner
  );

  event Sleep(
    uint256 indexed tokenID,
    address indexed owner
  );

  event Bury(
    uint256 indexed tokenID,
    address indexed owner
  );

  event Mitosis(
    uint256 indexed parentTokenID,
    uint256 indexed newTokenID,
    address indexed owner
  );    

  event ConfigureTraits(
    uint256 indexed tokenID,
    uint256 indexed traitIDs
  );

  event TraitUnlocked(
    uint256 indexed parentGobblerID,
    uint256 indexed newTraitTokenID,
    address indexed owner
  );

  event GobblerGobbled(
    uint256 indexed gobblerGobblerID,
    uint256 indexed victimID,
    uint256 indexed newGobblerGobblerID
  );

  /*------------------------------------------------------*/
  /*                     CONSTRUCTOR
  /*------------------------------------------------------*/

  constructor(address signer) ERC721("ETH GOBBLERS", "GOOEY") Owned(msg.sender){
    signerAddress = signer;
    gobDrops = new GobDrops(msg.sender);
  }

  modifier onlyTokenOwner(uint256 tokenID, address holder) {
    require(ownerOf(tokenID) == holder, "Must be token owner");
    _;
  }

  /*------------------------------------------------------*/
  /*                     USER ACTIONS
  /*------------------------------------------------------*/

  /// @notice Mint a gobbler. Must be on the Omakasea Naughty or Nice list to participate
  /// @param messageHash Hash of message created by the backend
  /// @param signature Signature of message hash signed by the ETH Gobblers admin address
  function mint(
    bytes32 messageHash,
    bytes calldata signature
  ) external {
    // Free mint
    require(totalSupply + 1 <= genesisMaxSupply, "Genesis max supply reached");
    // must not be paused
    require(!paused, "Must not be paused");
    // Naughty/nice list checks
    // The message should contain the msg sender, this contract address, function name sig and sig nonce
    require(
      hashMessage(
        msg.sender,
        address(this),
        bytes4(abi.encodePacked("mint")),
        signatureNonce[msg.sender]
      ) == messageHash, "Wrong message hash!"
    );
    require(verifyAddressSigner(messageHash, signature), "Invalid address signer");

    _mint(msg.sender, totalSupply);

    unchecked {
      totalSupply++;
      signatureNonce[msg.sender]++;
    }
  }

  /// @notice Feed, Groom or Sleep - any action invoked while the gobbler is alive
  /// @param action The action to invoke 
  /// @param tokenID The Gobbler tokenID to use 
  /// @param amount The of times the action should be invoked 
  /// @param messageHash Hash of message created by the backend
  /// @param signature Signature of message hash signed by the ETH Gobblers admin address
  function actionAlive(
    Action action,
    uint256 tokenID,
    uint8 amount,
    bytes32 messageHash,
    bytes calldata signature
  ) external payable onlyTokenOwner(tokenID, msg.sender) {
    // Checks required, valid message hash and signature only produced if health is above 0%
    // This smart contract has no notion of health, which is entirely managed off chain
    // The message should contain the msg sender, this contract address, function name sig and sig nonce
    require(
      hashMessage(
        msg.sender,
        address(this),
        bytes4(abi.encodePacked("actionAlive")),
        signatureNonce[msg.sender]
      ) == messageHash, "Wrong message hash!"
    );
    require(verifyAddressSigner(messageHash, signature), "Invalid address signer");


    if (action == Action.Feed) {
      require(msg.value == feedPrice * amount, "Not enough ETH Sent");
      emit Feed(tokenID, amount, msg.sender);
    } else if (action == Action.Groom) {
      require(msg.value == groomPrice * amount, "Not enough ETH Sent");
      emit Groom(tokenID, amount, msg.sender);
    } else if (action == Action.Sleep) {
      require(msg.value == sleepPrice, "Not enough ETH Sent"); 
      emit Sleep(tokenID, msg.sender);
    }

    unchecked {
      ETHGobbled[tokenID] += msg.value;
      signatureNonce[msg.sender]++;
    }
  }

  /// @notice Bury a gobbler, sending it to the burn address, eliminating it from supply permanently. Only possible if health is at 0
  /// @param tokenID The Gobbler tokenID to use 
  /// @param messageHash Hash of message created by the backend
  /// @param signature Signature of message hash signed by the ETH Gobblers admin address
  function bury(
    uint256 tokenID,
    bytes32 messageHash,
    bytes calldata signature
  ) external {
    // Checks required, valid message hash and signature only produced if health is 0%
    // This smart contract has no notion of health, which is entirely managed off chain
    // The message should contain the msg sender, this contract address, function name sig, the tokenID and sig nonce
    require(
      hashMessageBury(
        msg.sender,
        address(this),
        bytes4(abi.encodePacked("bury")),
        tokenID,
        signatureNonce[msg.sender]
      ) == messageHash, "Wrong message hash!"
    );

    require(verifyAddressSigner(messageHash, signature), "Invalid address signer");

    address currentOwner = ownerOf(tokenID);

    /*-----------ERC721-----------*/
    // custom burn logic, sends to DEAD address
    require(currentOwner != address(0), "NOT_MINTED");
    unchecked {
      _balanceOf[currentOwner]--;
      _balanceOf[burnAddress]++;
    }
    _ownerOf[tokenID] = burnAddress;
    delete getApproved[tokenID];
    emit Transfer(currentOwner, burnAddress, tokenID);
    /*-----------ERC721-----------*/

    emit Bury(tokenID, msg.sender);
    unchecked {
      signatureNonce[msg.sender]++;
    }
  }

  /// @notice Current gobbler divides into another one
  /// @param tokenID The Gobbler tokenID to use 
  /// @param messageHash Hash of message created by the backend
  /// @param signature Signature of message hash signed by the ETH Gobblers admin address
  /// @dev should not be invoked until all 2000 genesis are minted
  function mitosis(
    uint256 tokenID,
    bytes32 messageHash,
    bytes calldata signature
  ) external onlyTokenOwner(tokenID, msg.sender) {
    // Checks required, valid message hash and signature only produced if certain actions have been called a number of times
    // Action counts are tracked by emitted events
    // The message should contain the msg sender, this contract address, function name and sig nonce
    require(
      hashMessage(
        msg.sender,
        address(this),
        bytes4(abi.encodePacked("mitosis")),
        signatureNonce[msg.sender]
      ) == messageHash, "Wrong message hash!"
    );
    require(verifyAddressSigner(messageHash, signature), "Invalid address signer");

    // token IDs for mitosis gobblers start at ID 2000
    uint newTokenID = genesisMaxSupply + mitosisSupply;

    _mint(msg.sender, newTokenID);

    emit Mitosis(
      tokenID,
      newTokenID,
      msg.sender
    );

    unchecked {
      mitosisSupply++;
      totalSupply++;
      signatureNonce[msg.sender]++;
    }
  }

  /// @notice Configure NFT traits for the gobbler
  /// @param tokenID The Gobbler tokenID to use 
  /// @param traitIDs The token IDs of traits to equip (packed into one uint256) 
  /// @param messageHash Hash of message created by the backend
  /// @param signature Signature of message hash signed by the ETH Gobblers admin address
  function configureTraits(
    uint256 tokenID,
    uint256 traitIDs,
    bytes32 messageHash,
    bytes calldata signature
  ) external onlyTokenOwner(tokenID, msg.sender) {
    // checks required, cannot casually call this function from etherscan
    // The message should contain the msg sender, this contract address, function name, trait IDs and sig nonce
    require(
      hashMessageConfigureTraits(
        msg.sender,
        address(this),
        bytes4(abi.encodePacked("configureTraits")),
        traitIDs,
        signatureNonce[msg.sender]
      ) == messageHash, "Wrong message hash!"
    );
    require(verifyAddressSigner(messageHash, signature), "Invalid address signer");

    equippedTraits[tokenID] = traitIDs;

    emit ConfigureTraits(
      tokenID,
      traitIDs
    );

    unchecked {
      signatureNonce[msg.sender]++;
    }
  }

  /// @notice Unlock a new NFT trait
  /// @param tokenID The Gobbler tokenID to use 
  /// @param messageHash Hash of message created by the backend
  /// @param signature Signature of message hash signed by the ETH Gobblers admin address
  function unlockTrait(
    uint256 tokenID,
    bytes32 messageHash,
    bytes calldata signature
  ) external onlyTokenOwner(tokenID, msg.sender) {
    
    // checks required, valid signature and message hash only produced if certain actions have been called a number of times
    // The message should contain the msg sender, this contract address, function name sig, and sig nonce
    require(
      hashMessage(
        msg.sender,
        address(this),
        bytes4(abi.encodePacked("unlockTrait")),
        signatureNonce[msg.sender]
      ) == messageHash, "Wrong message hash!"
    );
    require(verifyAddressSigner(messageHash, signature), "Invalid address signer");

    uint newTraitTokenID = gobDrops.totalSupply();
    gobDrops.mint(msg.sender);

    emit TraitUnlocked(
      tokenID,
      newTraitTokenID,
      msg.sender
    );

    unchecked {
      signatureNonce[msg.sender]++;
    }
  }

  /// @notice Gobble (steal) another gobbler. Must be the Gobbler Gobbler
  /// @param gobblerGobblerTokenID The token ID of the current Gobbler Gobbler 
  /// @param victimTokenID The token ID of the Gobbler to be gobbled 
  /// @param newGobblerGobbler The token ID of the new Gobbler Gobbler 
  /// @param messageHash Hash of message created by the backend
  /// @param signature Signature of message hash signed by the ETH Gobblers admin address
  function gobbleGobbler(
    uint256 gobblerGobblerTokenID,
    uint256 victimTokenID,
    uint256 newGobblerGobbler,
    bytes32 messageHash,
    bytes calldata signature
  ) external payable onlyTokenOwner(gobblerGobblerTokenID, msg.sender) {
    require(currentGobblerGobbler == gobblerGobblerTokenID, "Must be the Gobbler Gobbler!");
    require(msg.value == gobbleGobblerPrice, "Not enough ETH sent!");

    require(
      hashMessageGobbleGobbler(
        msg.sender,
        address(this),
        bytes4(abi.encodePacked("gobbleGobbler")),
        newGobblerGobbler,
        signatureNonce[msg.sender]
      ) == messageHash, "Wrong message hash!"
    );
    require(verifyAddressSigner(messageHash, signature), "Invalid address signer");

    address currentOwnerOfVictim = ownerOf(victimTokenID);

    /*-----------ERC721-----------*/
    unchecked {
      _balanceOf[currentOwnerOfVictim]--;
      _balanceOf[msg.sender]++;
    }
    _ownerOf[victimTokenID] = msg.sender;
    delete getApproved[victimTokenID];
    emit Transfer(currentOwnerOfVictim, msg.sender, victimTokenID);
    /*-----------ERC721-----------*/

    emit GobblerGobbled(
      gobblerGobblerTokenID,
      victimTokenID,
      newGobblerGobbler
    );

    currentGobblerGobbler = newGobblerGobbler;

    unchecked {
      signatureNonce[msg.sender]++;
    }
  }

  /*------------------------------------------------------*/
  /*                        ADMIN
  /*------------------------------------------------------*/

  function changeFeedPrice(uint256 price) external onlyOwner {
    feedPrice = price;
  }

  function changeGroomPrice(uint256 price) external onlyOwner {
    groomPrice = price;
  }
  
  function changeSleepPrice(uint256 price) external onlyOwner {
    sleepPrice = price;
  }

  function changeGobbleGobblerPrice(uint256 price) external onlyOwner {
    gobbleGobblerPrice = price;
  }

  function setGobblerGobbler(uint256 tokenID) external onlyOwner {
    currentGobblerGobbler = tokenID;
  }

  function changeBaseURI(string calldata newBaseURI) external onlyOwner {
      baseURI = newBaseURI;
  }

  function changeSigner(address signer) external onlyOwner {
      signerAddress = signer;
  }

  function flipPaused() external onlyOwner {
      paused = !paused;
  }

  /*------------------------------------------------------*/
  /*                      READ ONLY
  /*------------------------------------------------------*/

  function getTraitConfiguration(uint256 tokenID) external view returns (
    uint32 wings,
    uint32 sidekick,
    uint32 food,
    uint32 accessory,
    uint32 weather,
    uint32 cushion,
    uint32 inflight,
    uint32 freeSlot
  ) {
    uint256 currentTraits = equippedTraits[tokenID];

    assembly {
      wings := and(shr(0xE0, currentTraits), 0xffffffff)
      sidekick := and(shr(0xC0, currentTraits), 0xffffffff)
      food := and(shr(0xA0, currentTraits), 0xffffffff)
      accessory := and(shr(0x80, currentTraits), 0xffffffff)
      weather := and(shr(0x60, currentTraits), 0xffffffff)
      cushion := and(shr(0x40, currentTraits), 0xffffffff)
      inflight := and(shr(0x20, currentTraits), 0xffffffff)
      freeSlot := and(currentTraits, 0xffffffff)
    }
  }

  function tokenURI(uint tokenID) public view override returns (string memory) {
      require(tokenID < totalSupply, "This token does not exist");
      return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenID.toString())) : "";
  }

  function verifyAddressSigner(bytes32 messageHash, bytes calldata signature) private view returns (bool) {
    address recovery = messageHash.toEthSignedMessageHash().recover(signature);
    return signerAddress == recovery;
  }

  function hashMessage(address sender, address thisContract, bytes4 functionNameSig, uint256 nonce) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(sender, thisContract, functionNameSig, nonce));
  }

  // special hash message for trait configuration function
  function hashMessageConfigureTraits(address sender, address thisContract, bytes4 functionNameSig, uint256 traitIDs, uint256 nonce) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(sender, thisContract, functionNameSig, traitIDs, nonce));
  }

  // special hash message for bury function
  function hashMessageBury(address sender, address thisContract, bytes4 functionNameSig, uint256 tokenID, uint256 nonce) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(sender, thisContract, functionNameSig, tokenID, nonce));
  }

  // special hash message for gobble gobbler function
  function hashMessageGobbleGobbler(address sender, address thisContract, bytes4 functionNameSig, uint256 newGobblerGobbler, uint256 nonce) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(sender, thisContract, functionNameSig, newGobblerGobbler, nonce));
  }

  /*------------------------------------------------------*/
  /*                      WITHDRAW
  /*------------------------------------------------------*/

  function withdraw() external onlyOwner {
    assembly {
        let result := call(0, caller(), selfbalance(), 0, 0, 0, 0)
        switch result
        case 0 { revert(0, 0) }
        default { return(0, 0) }
    }
  }
}