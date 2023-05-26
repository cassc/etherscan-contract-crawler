// SPDX-License-Identifier: MIT
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  
//    cell/c0
//
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@@@@@@@@@@# ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@@@@@@@@@    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@(@@@@@@       ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@@@@@@          ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@@@@@            ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,/@@@@@@@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@@@%               ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@@                  @@@@@@@@@&&&,,,,,,,,,,,,,,,,,,@@@@@@%@@@@@@@@@
//    @@@@@@@@#@@@@@@                  @@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@
//    @@@@@@@@@@@@@                  @@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@
//    @@@@@@@@@@@@                  @@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,&@@@@@@@@@@@
//    @@@@@@@@@@&                 *@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,@@@@@@@@@@
//    @@@@@@@@@@@                  @@@@@@@@@@@@@@@@@@@@@@@.................,@@@@@@@@@@
//    @@@@@@@@@@@@                  @@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@
//    @@@@@@@@@@@@@@                  @@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@                  @@@@@@@@@@@@@@,[email protected]@@@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@@/                 [email protected]@@@@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@@@@               [email protected]@@@@@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@@@@@            [email protected]@@@@@%@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@@@@@@@         [email protected]@@@@@@@@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@@@@@@@@      [email protected]@@@@@@@@@@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@@@@@@@@@,   [email protected]@@@@@@@@@@@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@@@@@@@@@@@ [email protected]@@@@@@@@@@@@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(@@@@@@@@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
pragma solidity ^0.8.9;
import "./ERC721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
interface IRelation {
  function burned(uint256 tokenId) external view returns (address);
  function ownerOf(uint256 tokenId) external view returns (address);
  function balanceOf(address account) external view returns (uint256);
}
contract C0 is Initializable, ERC721Upgradeable, OwnableUpgradeable, EIP712Upgradeable {
  using ECDSAUpgradeable for bytes32;

  //
  // Events
  //
  event WithdrawerUpdated(Withdrawer withdrawer);
  event StateUpdated(uint indexed state);
  event BaseURIUpdated(string uri);
  event NSUpdated(string name, string symbol);
  bytes32 public constant RELATION_TYPE_HASH = keccak256("Relation(uint8 code,address addr,uint256 id)");
  bytes32 public constant BODY_TYPE_HASH = keccak256("Body(uint256 id,uint8 encoding,address sender,address receiver,uint128 value,uint64 start,uint64 end,bytes32 sendersHash,bytes32 receiversHash,bytes32 puzzleHash,Relation[] relations)Relation(uint8 code,address addr,uint256 id)");
  bytes32 private constant EMPTY_ARRAY_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470; // keccak256(abi.encodePacked(new bytes32[](0)))

  //
  // Struct declaration
  //
  struct Relation {
    uint8 code;
    address addr;   // contract address
    uint256 id;     // tokenId/value
  }
  struct Body {
    uint256 id;
    uint128 value;
    uint64 start;
    uint64 end;
    address sender;
    address receiver;
    uint8 encoding; // 0: raw, 1: dag-pb
    bytes32 sendersHash;
    bytes32 receiversHash;
    bytes32 puzzleHash;
    Relation[] relations;
    bytes signature;
  }
  struct Gift {
    uint256 id;
    address receiver;
    uint8 encoding; // 0: raw, 1: dag-pb
    Relation[] relations;
  }
  struct Input {
    address receiver;
    bytes puzzle;
    bytes32[] sendersProof;
    bytes32[] receiversProof;
  }
  struct Royalty {
    address receiver;
    uint96 amount;
  }
  struct Withdrawer {
    address account;
    bool permanent;
  }

  //
  // Member variables
  //
  mapping(uint256 => Royalty) public royalty;
  mapping(uint256 => uint8) public encoding;
  mapping(uint256 => address) public burned;
  Withdrawer public withdrawer;
  string public baseURI;
  uint public state;  // 0: open, 1: paused, 2: frozen

  //
  // Core interface functions
  //
  function initialize(string calldata name, string calldata symbol) initializer external {
    __ERC721_init(name, symbol);
    __EIP712_init(name, "1");
    __Ownable_init();
  }

  //
  // Allow direct receiving of funds
  //
  receive() external payable {}

  //
  // gift tokens (c0.gift.send())
  //
  function gift(Gift[] calldata gifts) external payable onlyOwner {
    require(state == 0, "0");   // cannot gift when the state is paused or frozen
    for(uint i=0;i<gifts.length;) {
      Gift calldata g = gifts[i];
      _mint(g.receiver, g.id);
      if (g.relations.length > 0) {
        royalty[g.id] = Royalty(g.relations[0].addr, uint96(g.relations[0].id));
      }
      unchecked { ++i; }
    }
  }

  //
  // mint tokens (c0.token.send())
  //
  function token(Body[] calldata bodies, Input[] calldata inputs) external payable {
    require(state == 0, "0");   // cannot mint when the state is paused or frozen
    uint val;
    for(uint i=0; i<bodies.length;) {
      Body calldata body = bodies[i];
      Input calldata input = inputs[i];

      //
      // 1. Burned check: disallow reminting if already burned
      //
      require(burned[body.id] == address(0), "1");    // cannot mint if it was already burned

      // Who receives the token when minted?
      // if body.receiver is set (not 0) => body.receiver
      // if body.receiver is NOT set => input.receiver
      address receiver = (body.receiver != address(0) ? body.receiver : input.receiver);

      //
      // 2. Signature check
      //
      if (body.relations.length == 0) {
        bytes32 bodyhash = keccak256(
          abi.encode(
            BODY_TYPE_HASH,
            body.id,
            body.encoding,
            body.sender,
            body.receiver,
            body.value,
            body.start,
            body.end,
            body.sendersHash,
            body.receiversHash,
            body.puzzleHash,
            EMPTY_ARRAY_HASH
          )
        );
        require(_hashTypedDataV4(bodyhash).recover(body.signature) == owner(), "2");    // check script signature
      } else {
        bytes memory relationBytes;
        uint outgoing;

        //
        // Relation handling
        // A relation is the token's relationship with another address.
        // It can be either incoming (INPUTS) or outgoing (OUTPUTS)
        //
        // Inputs: decides whether the virtual machine will accept the conditions related to other addresses
        // Outputs: dictates how payments will be sent out (either the mint revenue or the royalty revenue)
        //
        for(uint j=0; j<body.relations.length;) {
          Relation memory relation = body.relations[j];
          //
          // relation.code :=
          //  
          //    INPUTS: input conditions
          //    0: burned by sender
          //    1: burned by receiver
          //    2: owned by sender
          //    3: owned by receiver
          //    4. balance by sender
          //    5. balance by receiver
          //
          //    OUTPUTS: output transfer declarations
          //    10. mint payment handling
          //    11. royalty payment handling
          //

          // INPUT
          // 0. burned by sender
          if (relation.code == 0) {
            if (relation.addr == address(0)) {
              require(burned[relation.id] == _msgSender(), "8a");   // local burnership check for sender
            } else {
              require(IRelation(relation.addr).burned(relation.id) == _msgSender(), "8a");    // remote contract burnership check for sender
            }
          }
          // 1. burned by receiver
          else if (relation.code == 1) {
            if (relation.addr == address(0)) {
              require(burned[relation.id] == receiver, "8b");   // local burnership check for receiver
            } else {
              require(IRelation(relation.addr).burned(relation.id) == receiver, "8b");    // remote contract burnership check for receiver
            }
          }
          // 2. owned by sender
          else if (relation.code == 2) {
            if (relation.addr == address(0)) {
              require(ownerOf(relation.id) == _msgSender(), "9a");    // local ownership check for sender
            } else {
              require(IRelation(relation.addr).ownerOf(relation.id) == _msgSender(), "9a");   // remote contract ownership check for sender
            }
          }
          // 3. owned by receiver
          else if (relation.code == 3) {
            if (relation.addr == address(0)) {
              require(ownerOf(relation.id) == receiver, "9b");    // local ownership check for receiver
            } else {
              require(IRelation(relation.addr).ownerOf(relation.id) == receiver, "9b");   // remote contract ownership check for receiver
            }
          }
          //  4. balance by sender
          else if (relation.code == 4) {
            if (relation.addr == address(0)) {
              require(balanceOf(_msgSender()) >= relation.id, "10a");   // local balance check for sender
            } else {
              require(IRelation(relation.addr).balanceOf(_msgSender()) >= relation.id, "10a");    // remote contract balance check for sender
            }
          }
          //  5. balance by receiver
          else if (relation.code == 5) {
            if (relation.addr == address(0)) {
              require(balanceOf(receiver) >= relation.id, "10b");   // local balance check for receiver
            } else {
              require(IRelation(relation.addr).balanceOf(receiver) >= relation.id, "10b");    // remote contract balance check for receiver
            }
          }

          // OUTPUT
          // 10. Make a transfer (relation.id / 10^6 percent of msg.value) to the relation.receiver
          else if (relation.code == 10) {
            outgoing += relation.id;
            require(outgoing <= 1e6, "10c");  // the sum of all payment split shares must not exceed 1,000,000 (1e6)
            _transfer(relation.addr, msg.value * relation.id / 1e6);
          }
          // 11. Set EIP-2981 royalty info
          else if (relation.code == 11) {
            royalty[body.id] = Royalty(relation.addr, uint96(relation.id));
          }
          relationBytes = abi.encodePacked(relationBytes, keccak256(abi.encode(
            RELATION_TYPE_HASH,
            relation.code,
            relation.addr,
            relation.id
          )));
          unchecked {
            ++j;
          }
        }
        bytes32 bodyhash = keccak256(
          abi.encode(
            BODY_TYPE_HASH,
            body.id,
            body.encoding,
            body.sender,
            body.receiver,
            body.value,
            body.start,
            body.end,
            body.sendersHash,
            body.receiversHash,
            body.puzzleHash,
            keccak256(relationBytes)
          )
        );
        require(_hashTypedDataV4(bodyhash).recover(body.signature) == owner(), "2");    // check script signature
      }

      //
      // 3. Sender check: if body.sender is specified, the body.sender must match _msgSender()
      //
      if (body.sender != address(0)) require(body.sender == _msgSender(), "3");   // sender lock validation

      //
      // 4. Start timelock check
      //
      require(body.start <= block.timestamp, "4");    // start time lock validation

      //
      // 5. End timelock check
      //
      require(body.end >= block.timestamp, "5");    // end time lock validation

      //
      // 6. Puzzle input check => the hash of the provided preimage string (input.puzzle) must match the hash (body.puzzleHash)
      //
      if (body.puzzleHash != 0) {
        require(input.puzzle.length > 0 && keccak256(input.puzzle) == body.puzzleHash, "6");    // hash puzzle lock validation
      }

      //
      // 7. Merkle input check => The _msgSender() must be included in the merkle tree specified by the body.merkleHash (verified using merkleproof input.merkle)
      //
      if (body.sendersHash != 0) {
        require(verify(body.sendersHash, input.sendersProof, _msgSender()), "7a");    // senders merkle proof lock validation
      }
      if (body.receiversHash != 0) {
        require(verify(body.receiversHash, input.receiversProof, receiver), "7b");    // receivers merkle proof lock validation
      }


      //
      //
      // A. Token storage logic => The token is actually created
      //
      //

      //
      // A.1. Set CID encoding: 0 if raw, 1 if dag-pb
      //      (In most cases it will be "raw" since metadata JSON files are small files and will be encoded as "raw", therefore saving gas)
      //
      if (body.encoding != 0) encoding[body.id] = body.encoding;

      //
      // A.2. Mint the token
      //
      _mint(receiver, body.id);

      unchecked {
        val+=body.value;
        ++i;
      }
    }

    //
    // 10. Revert everything if not enough money was sent
    //
    require(val == msg.value, "11");    // value lock validation
  }
  function burn(uint[] calldata _tokenIds) external {
    for(uint i=0; i<_tokenIds.length;) {
      uint _tokenId = _tokenIds[i];
      require(_isApprovedOrOwner(_msgSender(), _tokenId), "15");    // only the owner or the approved can burn
      _burn(_tokenId);
      burned[_tokenId] = _msgSender();
      unchecked {
        ++i;
      }
    }
  }

  //
  // Universal tokenId engine: tokenId to CID
  //
  function tokenURI(uint tokenId) public view override(ERC721Upgradeable) returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    bytes32 data = bytes32(tokenId);
    bytes memory alphabet = bytes("abcdefghijklmnopqrstuvwxyz234567");
    string memory base = (bytes(baseURI).length > 0 ? baseURI : "ipfs://");
    bytes memory cid = bytes(abi.encodePacked(base, (encoding[tokenId] == 0 ? "bafkrei" : "bafybei")));
    uint bits = 2;
    uint buffer = 24121888;
    uint bitsPerChar = 5;
    uint mask = uint((1 << bitsPerChar) - 1);
    for(uint i=0; i<data.length; ++i) {
      bytes1 char = bytes1(bytes32(tokenId << (8*i)));
      buffer = (uint32(buffer) << 8) | uint(uint8(char));
      bits += 8;
      while (bits > bitsPerChar) {
        bits -= bitsPerChar;
        cid = abi.encodePacked(cid, alphabet[mask & (buffer >> bits)]);
      }
    }
    if (bits > 0) {
      cid = abi.encodePacked(cid, alphabet[mask & (buffer << (bitsPerChar-bits))]);
    }
    return string(cid);
  }

  //
  // Merkle proof verifier
  //
  function verify(bytes32 root, bytes32[] calldata proof, address account) internal pure returns (bool) {
    bytes32 computedHash = keccak256(abi.encodePacked(account));
    for (uint256 i = 0; i < proof.length;) {
      bytes32 proofElement = proof[i];
      if (computedHash <= proofElement) {
        computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
      } else {
        computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
      }
      unchecked { ++i; }
    }
    return computedHash == root;
  }

  //
  // Royalty functions
  //
  function royaltyInfo(uint tokenId, uint value) external view returns (address receiver, uint256 royaltyAmount) {
    Royalty memory r = royalty[tokenId];
    return (r.receiver, value * r.amount/1e6);  // total 1e6 (1,000,000)
  }
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable) returns (bool) {
    return (interfaceId == 0x2a55205a || super.supportsInterface(interfaceId));
  }

  //
  // Admin functions
  //
  function setWithdrawer(Withdrawer calldata _withdrawer) external onlyOwner {
    require(!withdrawer.permanent, "20");   // only can set withdrawer if it's not yet permanent
    withdrawer = _withdrawer; 
    emit WithdrawerUpdated(_withdrawer);
  }
  function withdraw(uint value) external payable {

    //
    // Authorization: Either the owner or the withdrawer (in case it's set) can initiate withdraw()
    //
    require(_msgSender() == owner() || _msgSender() == withdrawer.account, "30");   // only the owner or the withdrawer (if set) can trigger a withdraw

    //
    // Custom withdrawl: value + receiver
    //

    //
    // Value: If specified (value > 0), withdraw that amount. Otherwise withdraw all.
    //
    uint amount = (value > 0 ? value : address(this).balance);

    //
    // Receiver: If "withdrawer" is set, the withdrawer. Otherwise, the contract owner
    //
    _transfer((withdrawer.account == address(0) ? owner() : withdrawer.account), amount);

  }
  function setState(uint _state) external onlyOwner {
    require(state != 2, "40");    // can set state only when the state is not frozen (2)
    state = _state;
    emit StateUpdated(_state);
  }
  function setBaseURI(string calldata b) external onlyOwner {
    require(state == 0, "50");    // can set baseURI only when the state is not frozen (2)
    baseURI = b;
    emit BaseURIUpdated(b);
  }
  function setNS(string calldata name_, string calldata symbol_) external onlyOwner {
    require(state == 0, "60");    // can set name and symbol only when the state is not frozen (2)
    _name = name_; 
    _symbol = symbol_;
    emit NSUpdated(_name, _symbol);
  }
  error TransferFailed();
  function _transfer(address to, uint256 amount) internal {
    bool callStatus;
    assembly {
      callStatus := call(gas(), to, amount, 0, 0, 0, 0)
    }
    if (!callStatus) revert TransferFailed();
  }
}