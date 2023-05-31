// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

//                                                       (&&&&&&&&&&&&&&&&&&&&&&&&&&
//                                                         &&&&&&&&&&&&&&&&&&&&&&&&&&%&&&&&&&&&&
//                                 &&&&&&&&                      &&&&&&&&&&&&&&&&&&&&&&&&  &&&&&&&&&
//                                   .&&&&&&&&                           /&%    &&&&&&&&&&&&&&&&&&&&&&
//                                &&&&&&&&&&&&&&&&                          &&&&&&&&&&&&&&&&&&&&&&&&&
//          &&&&&              &&&&&&&&&&&&&&&&&&&&&&&&               &&&&&&&&&&&&&&&&&&&&&&&&&
//            &&&&&&&&&&/  &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
//                    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&* .&&&&&&&&
//  &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& &&&&
//    %&&&&&&&&&&&&   &&&&&&&&&&&&&&&&&&&  &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& &&&&&&&&&&&&&&&&
//                                       &&&&   &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&               &&&&
//                                           %&&&&&   &&&&&&&&&&&&&&&&&&&&&                       &
//                                                  &&&&&&&&&&&&&&&&

contract PacemakerHonoraries is DefaultOperatorFilterer, ERC721Enumerable, Ownable {
  uint256 public tokenCounter;
  uint256 public immutable MAX_AMOUNT;
  bool public claimIsActive;
  bool public burnIsActive;
  bytes32 private root;
  string private nftBaseURI;
  IERC721AQueryable immutable Pacemaker;

  mapping(address => uint) public minted;
  mapping(uint256 => bool) public claimedTokens;

  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _maxAmount,
    address Pacemaker_
  ) ERC721(_name, _symbol) {
    Pacemaker = IERC721AQueryable(Pacemaker_);
    MAX_AMOUNT = _maxAmount;
  }

  /**
   * @dev function for setting the root
   * @param root_ the root for the merkle tree
   */
  function setRoot(bytes32 root_) public onlyOwner {
    root = root_;
  }

  /**
   * @dev set the uri for the tokens
   * @param nftBaseURI_ the token uri
   */
  function setBaseURI(string calldata nftBaseURI_) public onlyOwner {
    nftBaseURI = nftBaseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return nftBaseURI;
  }

  /**
   * @dev activate or deactivate claim
   *
   */
  function flipClaimState() public onlyOwner {
    claimIsActive = !claimIsActive;
  }

  /**
   * @dev activate or deactivate burning
   *
   */
  function flipBurnState() public onlyOwner {
    burnIsActive = !burnIsActive;
  }

  /**
   * @dev function for claiming with tokens from pacemaker collection
   * @param tokenIds_  the token ids which should be claimed
   */
  function claimWithTokens(uint256[] memory tokenIds_) public payable {
    require(claimIsActive, "Claim is not active");
    require(tokenCounter + tokenIds_.length <= MAX_AMOUNT, "Supply is limited");

    for (uint i = 0; i < tokenIds_.length; i++) {
      require(!claimedTokens[tokenIds_[i]], "Token is already claimed");
      require(
        Pacemaker.ownerOf(tokenIds_[i]) == msg.sender,
        "Must own that token"
      );
    }

    for (uint i = 0; i < tokenIds_.length; i++) {
      claimedTokens[tokenIds_[i]] = true;
      tokenCounter++;
      _safeMint(msg.sender, tokenCounter);
    }
  }

  /**
   * @dev check if a user is eligible to mint in allowlist
   * @param _address the address of the minting user
   * @param _max the max discounted mints (depending on masks)
   * @param _merkleProof the merkle proof sent by the frontend
   */
  function isWhitelisted(
    address _address,
    uint256 _max,
    bytes32[] calldata _merkleProof
  ) public view returns (bool) {
    bytes32 leaf = keccak256(abi.encode(_address, _max));
    return MerkleProof.verify(_merkleProof, root, leaf);
  }

  /**
   * @dev claim with a merkle tree whitelist
   * @param _merkleProof the proof calculated
   * @param _amount the amount which should be minted
   * @param _max the max allowed amount per wallet
   */
  function claimWithWhitelist(
    bytes32[] calldata _merkleProof,
    uint256 _amount,
    uint256 _max
  ) public payable {
    require(minted[msg.sender] + _amount <= _max, "Mint limit reached");
    require(claimIsActive, "Claim is not open");
    require(
      isWhitelisted(msg.sender, _max, _merkleProof),
      "Invalid Merkle Proof"
    );

    require(tokenCounter + _amount <= MAX_AMOUNT, "Supply is limited");

    minted[msg.sender] += _amount;

    for (uint i = 0; i < _amount; i++) {
      tokenCounter++;
      _safeMint(msg.sender, tokenCounter);
    }
  }

  /**
   * @dev airdropping tokens to owners
   * @param addr_ target address for airdrop
   */
  function airdropMany(address[] memory addr_) public onlyOwner {
    require(tokenCounter + addr_.length <= MAX_AMOUNT, "Supply is limited");

    for (uint256 i = 0; i < addr_.length; i++) {
      tokenCounter++;
      _safeMint(addr_[i], tokenCounter);
    }
  }

  function burn(uint256 tokenId) public virtual {
    require(burnIsActive, "Burn is not active");
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "ERC721: caller is not token owner or approved"
    );
    _burn(tokenId);
  }

  /**
   * listing all tokens of a user
   * @param _owner the address to check
   */
  function tokensOfOwner(
    address _owner
  ) public view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);

    uint256[] memory tokensId = new uint256[](tokenCount);
    for (uint256 i; i < tokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokensId;
  }

  /*
    Opensea Filter
  */
  function setApprovalForAll(
    address operator,
    bool approved
  ) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(
    address operator,
    uint256 tokenId
  ) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}