// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Fellowship
// contract by steviep.eth

/*

███████ ███████  ██████  ██    ██ ███████ ██      ███████
██      ██      ██    ██ ██    ██ ██      ██      ██
███████ █████   ██    ██ ██    ██ █████   ██      ███████
     ██ ██      ██ ▄▄ ██ ██    ██ ██      ██           ██
███████ ███████  ██████   ██████  ███████ ███████ ███████
                    ▀▀

*/

import "./Dependencies.sol";
import "./SequelsMetadata.sol";
import "./OperatorFiltererDependencies.sol";

pragma solidity ^0.8.17;

address constant CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS = 0x000000000000AAeB6D7670E522A718067333cd4E;
address constant CANONICAL_CORI_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;

abstract contract OperatorFilterer is UpdatableOperatorFilterer {
  constructor() UpdatableOperatorFilterer(
    CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS,
    CANONICAL_CORI_SUBSCRIPTION,
    true
  ) {}
}


contract SequelsBase is ERC721, Ownable, OperatorFilterer {
  uint256 public constant maxSupply = 3652;
  uint256 private _totalSupply = 0;
  SequelsMetadata private _metadataContract;
  address public minter;

  address private royaltyBenificiary;
  uint16 private royaltyBasisPoints = 500;

  constructor() ERC721('Sequels', 'JMS') {
    royaltyBenificiary = msg.sender;
    _metadataContract = new SequelsMetadata(this);
  }

  function mint(address to, uint256 tokenId) external {
    require(minter == msg.sender, 'Caller is not the minting address');
    require(_totalSupply <= maxSupply, 'Cannot exceed max supply');
    _mint(to, tokenId);
    _totalSupply++;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    return _metadataContract.tokenURI(tokenId);
  }

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function exists(uint256 tokenId) external view returns (bool) {
    return _exists(tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    // ERC2981
    return interfaceId == bytes4(0x2a55205a) || super.supportsInterface(interfaceId);
  }

  function metadataContract() external view returns (address) {
    return address(_metadataContract);
  }

  function setMetadataContract(address _addr) external onlyOwner {
    _metadataContract = SequelsMetadata(_addr);
  }

  function setMinter(address _addr) external onlyOwner {
    minter = _addr;
  }

  function setRoyaltyInfo(
    address _royaltyBenificiary,
    uint16 _royaltyBasisPoints
  ) external onlyOwner {
    royaltyBenificiary = _royaltyBenificiary;
    royaltyBasisPoints = _royaltyBasisPoints;
  }

  function royaltyInfo(uint256, uint256 _salePrice) external view returns (address, uint256) {
    return (royaltyBenificiary, _salePrice * royaltyBasisPoints / 10000);
  }


  event ProjectEvent(
    address indexed poster,
    string indexed eventType,
    string content
  );
  event TokenEvent(
    address indexed poster,
    uint256 indexed tokenId,
    string indexed eventType,
    string content
  );

  function emitProjectEvent(string calldata eventType, string calldata content) external onlyOwner {
    emit ProjectEvent(_msgSender(), eventType, content);
  }

  function emitTokenEvent(uint256 tokenId, string calldata eventType, string calldata content) external {
    require(
      owner() == _msgSender() || ERC721.ownerOf(tokenId) == _msgSender(),
      'Only project or token owner can emit token event'
    );
    emit TokenEvent(_msgSender(), tokenId, eventType, content);
  }


  /// Operator Filterer

  function owner() public view virtual override(UpdatableOperatorFilterer, Ownable) returns (address) {
    return super.owner();
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
   */
  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  /**
   * @dev See {IERC721-approve}.
   *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
   */
  function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  /**
   * @dev See {IERC721-transferFrom}.
   *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
   */
  function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
   */
  function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
   */
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}
