//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// Prior art.

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { ERC2981 } from "@openzeppelin/contracts/token/common/ERC2981.sol";
import { ERC721A } from "erc721a/contracts/ERC721A.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

// Contract art.

/*
                                                                                  ..    ' .
                                                                             .l-?}cQd*#MB*r.
                                                              ...,,i><]u0b%%[email protected]@[email protected][email protected]@@8p/`
        -U                                       .    .'i<)0do%8%@@[email protected][email protected]@@[email protected]@@@@@@@&ji.
       ;ob^                               'Il_-/[email protected]@@@[email protected]@@[email protected]%bf,
      'UBX             ..    . .'I_xYOhM&8B$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$B%t
      i#MI      ..'"l_/rjzOM8&@@@@@@[email protected]@@@@@[email protected]*"
     I&@M_rwOpa*&%[email protected]@@[email protected]@@@@[email protected]@@[email protected]~
    [email protected]@@@@@BB%#oahmCz/1-. .      [email protected]@@[email protected])
    '[email protected]@Bd'' . .              `[email protected][email protected]%j
          [email protected]@M"                  .'[email protected]
          [email protected]@_                   `[email protected][
           [email protected]$z                   '[email protected]&]
           '[email protected]@%|.                  t%@@[email protected]#;
          . ([email protected]@Z`                  ~*@@[email protected]
            ^[email protected]@B/                  "[email protected]@$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$B|
             <*@@@? .                ;[email protected][email protected]@@U
              [email protected]}                  [email protected][email protected]@ai
               [email protected]@8_                 'v%@@[email protected]@J'
                (%@@@J`.               `[email protected]@[email protected])
                [email protected]@k>                ^mB$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$8!
                  ,LBBB8X^.             .'[email protected][email protected]@a<.
                   .]%@BBBO`             ..-#@@@[email protected]@@o!
                     "[email protected]@@8v`             .,Y%@@[email protected]@@Q`
                      ."Y&[email protected]@Bd1^  .          [email protected]@[email protected]@@BW).
                         '[email protected]@@@BMJ[:          ."[email protected]&t'
                           .[L#[email protected]@@BMn+>^.        ^juJ*&[email protected]@BW/.
                              [email protected]@@@@@WWdCxf)/[email protected]@@@[email protected]%f:
                               . .."Yw*[email protected]@[email protected]@@@[email protected]@[email protected]@[email protected]
                                        ,<{/0qmW%%B#aQv(-;'
                                                .
*/

// Silhouettes.

interface IInventory {
  function supplyPaidAgents(address _to, uint _amount) external;
  function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}

interface SevenTwentyOne {
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface ElevenFiftyFive {
  function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}

// Whoops.

error AlreadyRecruited();
error AlreadyMintedEarly();
error EarlyRecruitmentClosed();
error EarlyRecruitsTaken();
error ItemsContractAddressNotSet();
error ItemsNotUpgradeable();
error NotRecruitingSeason();
error NoContracts();
error NotOnTheList();
error MissionsNotYetBegun();
error RecruitingFull();
error WrongAmount();
error WrongPrice();

// An agreement. A contract, if you will.

contract SSAInternational is ERC721A, ERC2981, Ownable {

  uint constant EARLY_SUPPLY = 5_000;
  uint constant MAX_SUPPLY = 7_700;
  uint constant TEAM_MINT_SUPPLY = 200;

  uint public price = 0.07 ether;

  uint public max_per_txn = 7;

  address theAgency = 0x4D5949BE178270B031c18FE86663d8bA5Ea97204;
  address public itemContractAddress;

  bool public earlyRecruitmentIsOpen;
  bool public itemsAreUpgradeable;
  bool public itsRecruitingSeason;
  bool public missionsAreGo;
  bool public teamHasBeenRecruited;

  mapping(address => bool) public addressHasMinted;
  mapping(address => uint) public theSpecialists;

  string public _baseTokenURI;

  bytes32 public merkleRoot;

  // Happenings.

  event AgentShouldReceiveUpdate(address indexed _fromAndTo, uint256 indexed _tokenId);
  event ItemShouldReceiveUpdate(address indexed _fromAndTo, uint256 indexed _tokenId);

  // Have a seat. Let's begin.

  constructor() ERC721A("SSA INTERNATIONAL", "SSA") {
    // Hello, Agent 0
    _mint(theAgency, 1);
  }

  // You're Early.

  function earlyRecruit(bytes32[] calldata _proof)
    external
  {
    if (earlyRecruitmentIsOpen == false) revert EarlyRecruitmentClosed();
    if (addressHasMinted[msg.sender]) revert AlreadyMintedEarly();
    if (msg.sender != tx.origin) revert NoContracts();
    if (MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))) == false) revert NotOnTheList();

    uint count = theSpecialists[msg.sender] > 0 ? theSpecialists[msg.sender] : 1;

    if (totalSupply() + count > EARLY_SUPPLY) revert EarlyRecruitsTaken();

    addressHasMinted[msg.sender] = true;

    _mint(msg.sender, count);
  }

  // Welcome, Recruits.

  function recruitYourAgent(uint _count)
    external
    payable
  {
    if (itemContractAddress == address(0)) revert ItemsContractAddressNotSet();
    if (itsRecruitingSeason == false) revert NotRecruitingSeason();
    if (msg.sender != tx.origin) revert NoContracts();
    if (_count > max_per_txn) revert WrongAmount();
    if (totalSupply() + _count > MAX_SUPPLY) revert RecruitingFull();
    if (msg.value != (price * _count)) revert WrongPrice();

    _mint(msg.sender, _count);

    IInventory inventory = IInventory(itemContractAddress);
    inventory.supplyPaidAgents(msg.sender, _count);
  }

  function giftAnAgent(address _to, uint _count)
    external
    onlyOwner
  {
    if (totalSupply() + _count > MAX_SUPPLY) revert RecruitingFull();
    _mint(_to, _count);
  }

  // Go, Team.

  function recruitTeamAgents()
    external
    onlyOwner
  {
    if (teamHasBeenRecruited) revert AlreadyRecruited();

    _mint(theAgency, TEAM_MINT_SUPPLY);
    teamHasBeenRecruited = true;
  }

  // Set.

  function setEarlyRecruitmentIsOpen(bool _val)
    external
    onlyOwner
  {
    earlyRecruitmentIsOpen = _val;
  }

  function setItsRecruitingSeason(bool _val)
    external
    onlyOwner
  {
    itsRecruitingSeason = _val;
  }

  function setTheSpecialists(address[] calldata _whom, uint8[] calldata _counts)
    external
    onlyOwner
  {
    require(_whom.length == _counts.length, "Length mismatch");
    for(uint i; i < _whom.length;)
    {
      theSpecialists[_whom[i]] = _counts[i];
      unchecked { ++i; }
    }
  }

  function setNewAgency(address _where)
    external
    onlyOwner
  {
    theAgency = _where;
  }

  function setMaxPerTxn(uint _val)
    external
    onlyOwner
  {
    max_per_txn = _val;
  }

  function setBaseURI(string calldata _base)
    external
    onlyOwner
  {
    _baseTokenURI = _base;
  }

  function setPrice(uint _val)
    external
    onlyOwner
  {
    price = _val;
  }

  function setMerkleRoot(bytes32 _root)
    external
    onlyOwner
  {
    merkleRoot = _root;
  }

  function setMissionsAreGo(bool _val)
    external
    onlyOwner
  {
    missionsAreGo = _val;
  }

  function setItemsAreUpgradeable(bool _val)
    external
    onlyOwner
  {
    itemsAreUpgradeable = _val;
  }

  function setItemsContractAddress(address _address)
    external
    onlyOwner
  {
    itemContractAddress = _address;
  }

  // Details.

  function _baseURI()
    internal
    view
    virtual
    override
    returns (string memory)
  {
    return _baseTokenURI;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721A, ERC2981)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  // Receive. Send right back. (Use at your own risk)

  function onERC721Received(address, address from, uint256 tokenId, bytes memory)
    public
    returns(bytes4)
  {
    if (missionsAreGo == false) revert MissionsNotYetBegun();

    // Transfer it back to the address that sent it to this contract
    safeTransferFrom(address(this), from, tokenId);

    emit AgentShouldReceiveUpdate(from, tokenId);

    return this.onERC721Received.selector;
  }

  function onERC1155Received(address, address from, uint256 id, uint256, bytes calldata)
    external
    returns (bytes4)
  {
    if (itemsAreUpgradeable == false) revert ItemsNotUpgradeable();

    // Send it back
    IInventory inventory = IInventory(itemContractAddress);
    inventory.safeTransferFrom(address(this), from, id, 1, "");

    emit ItemShouldReceiveUpdate(from, id);

    return this.onERC1155Received.selector;
  }

  // W.

  function withdraw()
    external
    onlyOwner
  {
    (bool success, ) = payable(theAgency).call{value: address(this).balance}("");
    require(success, "Withdraw failed");
  }

}