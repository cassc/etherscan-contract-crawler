// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./interfaces/ILayerrToken.sol";
import "./interfaces/ILayerrVariables.sol";


contract Layerr721 is DefaultOperatorFilterer, Initializable, ERC721, ERC2981, ILayerrToken {
  struct Details {
      uint72 price;
      uint32 saleStarts;
      uint32 saleEnds;
  }

  mapping(uint => string) public URIs;
  mapping(uint => Details) public tokenDetails;

  address public owner;
  address public LayerrXYZ;

  string public name;
  string public contractURI_;
  string public symbol;

  modifier onlyOwner() {
    require(msg.sender == owner, "ERROR");
    _;
  }

  /*
  * @dev: standard mint function, for fee structure see {ILayerrVariables}
  */
  function mintFixedPrice(uint _id) public payable {
    Details storage _details = tokenDetails[_id];
    require(block.timestamp >= _details.saleStarts && block.timestamp <= _details.saleEnds, "Sale is not active for this token");
    require(_details.price + viewFlatFee() <= msg.value, "Incorrect amount sent");
    
    payable(owner).transfer(_details.price * (1000 - viewFee()) / 1000);

    _mint(msg.sender, _id);
  }

  ////////////////////////////////////////////////////////////
  ///////////   OWNER FUNCTIONS   ////////////////////////////
  ////////////////////////////////////////////////////////////

  /* 
  * @dev: sets the contract URI
  */
  function setContractURI(string memory _contractURI) public onlyOwner {
    contractURI_ = _contractURI;
  }

  /*
  * @dev: allows the contract owner to mint tokens, not subject to fees. Can be used outside the sale period
  */
  function ownerMint(uint _id, address _to) public onlyOwner {
    _mint(_to, _id);
  }

  /*
  * @dev: see {ILayerrToken - initialize}
  */
  function initialize (
    bytes calldata data,
    address _LayerrXYZ
  ) public initializer {
    uint96 pct;
    address royaltyReciever;
    bool subscribeOpensea;

    owner = tx.origin;
    LayerrXYZ = _LayerrXYZ;
    (name, symbol, contractURI_, pct, royaltyReciever, subscribeOpensea) = abi.decode(data, (string, string, string, uint96, address, bool));

    _setDefaultRoyalty(royaltyReciever, pct);

    if (subscribeOpensea) {
      OperatorFilterer.OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6));
    }
  }

  /*
  * @dev: adds a token to the contract by initializing its details
  */
  function addToken(
    uint _id,
    string memory _uri,
    uint72 _price,
    uint32 _saleStart,
    uint32 _saleEnd
  ) public onlyOwner {
    URIs[_id] = _uri;
    Details memory details;
    details.price = _price;
    details.saleStarts = _saleStart;
    details.saleEnds = _saleEnd;
    tokenDetails[_id] = details;
  }

  /*
  * @dev: adds a batch of tokens to the contract
  */
  function addTokenBatch (
    uint[] memory _ids,
    string[] memory _uris,
    uint72[] memory _prices,
    uint32[] memory _saleStarts,
    uint32[] memory _saleEnds
  ) public onlyOwner {
    for (uint i = 0; i < _ids.length; i++) {
      addToken(_ids[i], _uris[i], _prices[i], _saleStarts[i], _saleEnds[i]);
    }
  }

  /*
  * @dev: allows the contract owner to modify the token sale period
  * this is the only allowed modification to an existing token
  */
  function modifySalePeriod(uint _id, uint32 _saleStart, uint32 _saleEnd) public onlyOwner {
    Details storage _details = tokenDetails[_id];
    _details.saleStarts = _saleStart;
    _details.saleEnds = _saleEnd;
  }

  /*
  * @dev: allows the contract owner to modify the name, symbol, and royalties of the contract
  */
  function editContract (address receiver, uint96 feeNumerator, string memory _name, string memory _symbol) external onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
    name = _name;
    symbol = _symbol;
  }

  /*
  * @dev: see {ILayerrVariables}
  */
  function viewWithdraw() public view returns (address returnWallet) {
    returnWallet = ILayerrVariables(LayerrXYZ).viewWithdraw();
  }

  /*
  * @dev: see {ILayerrVariables}
  */
  function viewFee() public view returns (uint returnFee) {
    returnFee = ILayerrVariables(LayerrXYZ).viewFee(address(this));
  }

  /*
  * @dev: see {ILayerrVariables}
  */
  function viewFlatFee() public view returns (uint returnFee) {
    returnFee = ILayerrVariables(LayerrXYZ).viewFlatFee(address(this));
  }

  /*
  * @dev: withdraws all of layerr's funds
  * creator funds are distributed at the time of mint
  */
  function withdraw() public {
    require(msg.sender == owner || msg.sender == viewWithdraw(), "Not owner or Layerr");
    payable(viewWithdraw()).transfer(address(this).balance);
  }

  ////////////////////////////////////////////////////////////
  ///////////   METADATA FUNCTIONS   /////////////////////////
  ////////////////////////////////////////////////////////////

  /*
  * @dev: returns contract details for marketplaces, see https://docs.opensea.io/docs/contract-level-metadata
  */
  function contractURI() public view returns (string memory) {
    return contractURI_;
  }

  /*
  * @dev: returns the uri for a token, see: https://docs.opensea.io/docs/metadata-standards
  */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_ownerOf[tokenId] != address(0), "NOT_MINTED");
    return URIs[tokenId];
  }

  /** OPENSEA OVERRIDES */
  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
      super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
      super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
      super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId, data);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
    return 
      ERC721.supportsInterface(interfaceId) ||
      ERC2981.supportsInterface(interfaceId);
  }
}