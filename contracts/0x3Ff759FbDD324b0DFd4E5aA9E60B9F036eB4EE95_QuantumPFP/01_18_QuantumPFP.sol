// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/*
        _   _ ______ _______ 
       | \ | |  ____|__   __|
   __ _|  \| | |__     | |   
  / _` | . ` |  __|    | |   
 | (_| | |\  | |       | |   
  \__, |_| \_|_|       |_|   
     | |                     
     |_|     
*/

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "./Namehash.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract ENS {
  function resolver(bytes32 node) public view virtual returns (Resolver);

  function setSubnodeRecord(
    bytes32 node,
    bytes32 label,
    address owner,
    address resolver,
    uint64 ttl
  ) external virtual;

  function owner(bytes32 node) external view virtual returns (address);
}

abstract contract Resolver {
  function addr(bytes32 node) public view virtual returns (address);

  function text(bytes32 node, string calldata key)
    external
    view
    virtual
    returns (string memory);

  function setText(
    bytes32 node,
    string calldata key,
    string calldata value
  ) external virtual;

  function setAddr(bytes32 node, address a) external virtual;

  function setAuthorisation(
    bytes32 node,
    address target,
    bool isAuthorised
  ) external virtual;
}

contract QuantumPFP is
  Initializable,
  UUPSUpgradeable,
  ERC721Upgradeable,
  OwnableUpgradeable,
  Namehash
{
  string public baseURI;
  string _terminatedURI;
  string public constant BASEDOMAIN = "quantum.tech";
  uint256 public historicalMemberCount;

  ENS public ens;
  struct Member {
    string initial;
    bool terminated;
    bool isActive;
  }
  mapping(uint256 => Member) public memberList;

  function initialize(
    string memory __baseURI,
    string memory __terminatedURI,
    address ensRegistrar
  ) public initializer {
    __ERC721_init("Quantum Team", "QT");
    __Ownable_init();
    __UUPSUpgradeable_init();
    baseURI = __baseURI;
    _terminatedURI = __terminatedURI;
    ens = ENS(ensRegistrar);
  }

  //proxy requirement
  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyOwner
  {}

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function addMember(
    string calldata _initial,
    address targetAddress,
    string calldata email,
    string calldata designation,
    string calldata specialty,
    uint256 tokenId
  ) external onlyOwner {
    memberList[tokenId] = Member(_initial, false, true);

    bytes32 rootNodeId = computeNamehash(abi.encodePacked(BASEDOMAIN));
    Resolver rootResolver = ens.resolver(rootNodeId);
    ens.setSubnodeRecord(
      computeNamehash(abi.encodePacked(BASEDOMAIN)),
      keccak256(abi.encodePacked(_initial)),
      address(this),
      address(rootResolver),
      0
    );

    bytes32 nodeId = computeNamehash(
      abi.encodePacked(_initial, ".", BASEDOMAIN)
    );
    Resolver resolver = ens.resolver(nodeId);
    resolver.setAuthorisation(nodeId, ens.owner(rootNodeId), true);
    resolver.setAddr(nodeId, targetAddress);
    resolver.setText(nodeId, "email", email);
    resolver.setText(nodeId, "designation", designation); //Trainee Specialist Agent Mr. Ms.
    resolver.setText(nodeId, "specialty", specialty);
    resolver.setText(nodeId, "description", "");
    resolver.setText(nodeId, "status", "");

    _mint(targetAddress, tokenId);
    historicalMemberCount++;
  }

  function toggleStatus(uint256 tokenId, bool status) external onlyOwner {
    // true to terminate
    require(_exists(tokenId), "Nonexistent token");
    if (status) {
      memberList[tokenId].terminated = true;
      memberList[tokenId].isActive = false;
      ens.setSubnodeRecord(
        computeNamehash(abi.encodePacked(BASEDOMAIN)),
        keccak256(abi.encodePacked(memberList[tokenId].initial)),
        address(0),
        address(0),
        0
      );
    } else {
      memberList[tokenId].terminated = false;
    }
  }

  function updateMemberData(
    uint256 tokenId,
    string memory email,
    string calldata designation,
    string memory specialty,
    address newEnsAddress,
    bool _isActive
  ) external onlyOwner {
    require(_exists(tokenId), "Nonexistent token");

    bytes32 nodeId = computeNamehash(
      abi.encodePacked(memberList[tokenId].initial, ".", BASEDOMAIN)
    );
    Resolver resolver = ens.resolver(nodeId);

    memberList[tokenId].isActive = _isActive;
    if (bytes(email).length > 0) resolver.setText(nodeId, "email", email);
    if (bytes(designation).length > 0)
      resolver.setText(nodeId, "designation", designation);
    if (bytes(specialty).length > 0)
      resolver.setText(nodeId, "specialty", specialty);
    if (newEnsAddress != address(0)) resolver.setAddr(nodeId, newEnsAddress);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(_exists(tokenId), "Nonexistent token");
    return super.tokenURI(tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyOwner {
    _transfer(from, to, tokenId);
  }

  function safeTransferFrom(
    address,
    address,
    uint256,
    bytes memory
  ) public pure override {
    revert();
  }

  function setBaseURI(string memory _newURI) public onlyOwner {
    baseURI = _newURI;
  }

  function setEns(address _newENS) public onlyOwner {
    ens = ENS(_newENS);
  }

  function setTerminatedURI(string memory _newURI) public onlyOwner {
    _terminatedURI = _newURI;
  }

  function burn(uint256 tokenId) public onlyOwner {
    ens.setSubnodeRecord(
      computeNamehash(abi.encodePacked(BASEDOMAIN)),
      keccak256(abi.encodePacked(memberList[tokenId].initial)),
      address(0),
      address(0),
      0
    );
    delete memberList[tokenId];
    historicalMemberCount--;
    _burn(tokenId);
  }

  function getMemberMetaData(uint256 tokenId)
    external
    view
    returns (string[4] memory data)
  {
    require(_exists(tokenId), "Nonexistent token");
    bytes32 nodeId = computeNamehash(
      abi.encodePacked(memberList[tokenId].initial, ".", BASEDOMAIN)
    );
    Resolver resolver = ens.resolver(nodeId);
    string memory email = resolver.text(nodeId, "email");
    string memory specialty = resolver.text(nodeId, "specialty");
    string memory designation = resolver.text(nodeId, "designation");
    return [email, specialty, designation, memberList[tokenId].initial];
  }
}