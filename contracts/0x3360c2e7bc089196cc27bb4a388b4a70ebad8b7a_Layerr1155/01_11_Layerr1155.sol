// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { ERC1155 } from "./ERC1155.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Layerr1155 is DefaultOperatorFilterer, Initializable, ERC1155, ERC2981 {
  mapping(uint => string) public URIs;
  mapping(uint => uint) public tokenPrices;
  mapping(uint => uint) public tokenSaleStarts;
  mapping(uint => uint) public tokenSaleEnds;
  mapping(uint => uint) public tokenEditionCounts;
  mapping(uint => uint) public tokenEditionMints;
  mapping(uint => uint) public maxMintsPerTx;
  mapping(uint => uint[]) public requiredBurnIds;
  mapping(uint => uint[]) public requiredBurnAmounts;
  mapping(uint => bool) public isClaim;
  mapping(uint => uint[]) public requiredClaimIds;
  mapping(uint => uint[]) public requiredClaimAmounts;

  address public owner;
  address public LayerrXYZ;

  string public name;
  string public contractURI_;
  string public symbol;

  modifier onlyOwner() {
    require(msg.sender == owner, "ERROR");
    _;
  }

  function uri(uint256 id) public view virtual override returns (string memory) {
    return URIs[id];
  }

  function contractURI() public view returns (string memory) {
    return contractURI_;
  }


  function mint(uint _id, uint _amount) public payable {
    require(!isClaim[_id], "This token is a claim");
    require(block.timestamp >= tokenSaleStarts[_id], "Sale has not started");
    require(block.timestamp <= tokenSaleEnds[_id], "Sale has ended");
    require(tokenEditionMints[_id] + _amount <= tokenEditionCounts[_id], "Not enough editions left");
    require(tokenPrices[_id] * _amount <= msg.value, "Incorrect amount sent");
    require(_amount <= maxMintsPerTx[_id], "Exceeds max mints per tx");

    if (requiredBurnIds[_id].length > 1) {
      uint[] memory burnAmounts = new uint[](requiredBurnAmounts[_id].length);
      for (uint i = 0; i < requiredBurnAmounts[_id].length; i++) {
        burnAmounts[i] = requiredBurnAmounts[_id][i] * _amount;
      }
      _batchBurn(msg.sender, requiredBurnIds[_id], burnAmounts);
    } else if (requiredBurnIds[_id].length == 1) {
      _burn(msg.sender, requiredBurnIds[_id][0], requiredBurnAmounts[_id][0] * _amount);
    }

    tokenEditionMints[_id] += _amount;
    _mint(msg.sender, _id, _amount, "");
  }

  function batchMint(uint[] memory _ids, uint[] memory _amounts) public payable {
    require(_ids.length == _amounts.length, "ERROR");
    uint totalCost;
    for (uint i = 0; i < _ids.length; i++) {
      uint id = _ids[i];
      uint amount = _amounts[i];
      require(!isClaim[id], "This token is a claim");
      require(block.timestamp >= tokenSaleStarts[id], "Sale has not started");
      require(block.timestamp <= tokenSaleEnds[id], "Sale has ended");
      require(tokenEditionMints[id] + amount <= tokenEditionCounts[id], "Not enough editions left");
      require(amount <= maxMintsPerTx[id], "Exceeds max mints per tx");
      totalCost += tokenPrices[id] * amount;
      tokenEditionMints[id] += amount;

      if (requiredBurnIds[id].length > 1) {
        uint[] memory burnAmounts = new uint[](requiredBurnAmounts[id].length);
        for (uint j = 0; j < requiredBurnAmounts[id].length; j++) {
          burnAmounts[j] = requiredBurnAmounts[id][j] * amount;
        }
        _batchBurn(msg.sender, requiredBurnIds[id], burnAmounts);
      } else if (requiredBurnIds[id].length == 1) {
        _burn(msg.sender, requiredBurnIds[id][0], requiredBurnAmounts[id][0] * amount);
      }
    }
    require(totalCost <= msg.value, "Incorrect amount sent");
    _batchMint(msg.sender, _ids, _amounts, "");
  }

  function mintAndClaim(uint _id, uint _amount) public payable {
    require(isClaim[_id], "Not a claimable token");
    require(block.timestamp >= tokenSaleStarts[_id], "Sale has not started");
    require(block.timestamp <= tokenSaleEnds[_id], "Sale has ended");
    require(tokenEditionMints[_id] + _amount <= tokenEditionCounts[_id], "Not enough editions left");

    if (_amount > 1) {
      uint[] memory claimAmounts = new uint[](requiredClaimAmounts[_id].length);
      for (uint i = 0; i < requiredClaimAmounts[_id].length; i++) {
        claimAmounts[i] = requiredClaimAmounts[_id][i] * _amount;
      }
      batchMint(requiredClaimIds[_id], claimAmounts);
    } else {
      batchMint(requiredClaimIds[_id], requiredClaimAmounts[_id]);
    }

    tokenEditionMints[_id] += _amount;
    _mint(msg.sender, _id, _amount, "");
  }

  /*
  * OWNER FUNCTIONS
  */
  function setContractURI(string memory _contractURI) public onlyOwner {
    contractURI_ = _contractURI;
  }

  function initialize (
    string memory _name,
    string memory _symbol,
    string memory _contractURI,
    uint96 pct,
    address royaltyReciever,
    address _LayerrXYZ 
  ) public initializer {
    owner = tx.origin;
    name = _name;
    symbol = _symbol;
    contractURI_ = _contractURI;
    _setDefaultRoyalty(royaltyReciever, pct);
    LayerrXYZ = _LayerrXYZ;
  }

  function addToken(
    uint _id,
    string memory _uri,
    uint _price,
    uint _saleStart,
    uint _saleEnd,
    uint _editionCount,
    uint _maxMintsPerTx,
    uint[] memory _requiredBurnIds,
    uint[] memory _requiredBurnAmounts,
    bool _isClaim,
    uint[] memory _requiredClaimIds,
    uint[] memory _requiredClaimAmounts
  ) public onlyOwner {
    URIs[_id] = _uri;
    tokenPrices[_id] = _price;
    tokenSaleStarts[_id] = _saleStart;
    tokenSaleEnds[_id] = _saleEnd;
    tokenEditionCounts[_id] = _editionCount;
    maxMintsPerTx[_id] = _maxMintsPerTx;

    if (_requiredBurnIds.length > 0) {
      requiredBurnIds[_id] = _requiredBurnIds;
      requiredBurnAmounts[_id] = _requiredBurnAmounts;
    }

    if (_isClaim) {
      isClaim[_id] = true;
      requiredClaimIds[_id] = _requiredClaimIds;
      requiredClaimAmounts[_id] = _requiredClaimAmounts;
    }
  }

  function editContract (address receiver, uint96 feeNumerator, string memory _name, string memory _symbol) external onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
    name = _name;
    symbol = _symbol;
  }

  function withdraw() public {
    require(msg.sender == owner || msg.sender == LayerrXYZ, "Not owner or Layerr");
    require(msg.sender == tx.origin, "Cannot withdraw from a contract");
    uint256 contractBalance = address(this).balance;

    // Send 5% of the contract balance to the LayerrXYZ wallet address
    payable(LayerrXYZ).transfer(contractBalance * 5 / 100);

    // Send the remaining balance to the owner
    payable(owner).transfer(address(this).balance);
  }

  /*
  * OPENSEA OVERRIDES
  */
  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes calldata data)
    public
    override
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, amount, data);
  }

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data
  ) public virtual override onlyAllowedOperator(from) {
    super.safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
    return 
      ERC1155.supportsInterface(interfaceId) ||
      ERC2981.supportsInterface(interfaceId);
  }
}