// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { ERC1155 } from "./ERC1155.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./interfaces/ILayerrToken.sol";
import "./interfaces/ILayerrVariables.sol";


contract Layerr1155 is DefaultOperatorFilterer, Initializable, ERC1155, ERC2981, ILayerrToken {
  struct Details {
      uint72 price;
      uint32 saleStarts;
      uint32 saleEnds;
      uint24 editionCounts;
      uint24 maxMintsPerTx;
      uint24 tokenEditionMints;
      bool isClaim;
  }

  mapping(uint => string) public URIs;
  mapping(uint => Details) public tokenDetails;
  mapping(uint => uint[]) public requiredBurnIds;
  mapping(uint => uint256[]) public requiredBurnAmounts;
  mapping(uint => uint[]) public requiredClaimIds;
  mapping(uint => uint256[]) public requiredClaimAmounts;

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
  * @dev returns the uri for a token, see: https://docs.opensea.io/docs/metadata-standards
  */
  function uri(uint256 id) public view virtual override returns (string memory) {
    return URIs[id];
  }

  /*
  * @dev returns contract details for marketplaces, see https://docs.opensea.io/docs/contract-level-metadata
  */
  function contractURI() public view returns (string memory) {
    return contractURI_;
  }

  /*
  * @dev standard mint function, including burn & redeem tokens. For fee structures, see {ILayerrVariables}
  */
  function mint(uint _id, uint256 _amount) public payable {
    Details storage _details = tokenDetails[_id];
    require(!_details.isClaim && block.timestamp >= _details.saleStarts && block.timestamp <= _details.saleEnds, "This token is a claim");
    require(_details.tokenEditionMints + uint24(_amount) <= _details.editionCounts, "Not enough editions left");

    uint flatTotal = viewFlatFee() * _amount;
    uint totalPrice = _details.price * _amount;
    require(totalPrice + flatTotal <= msg.value, "Incorrect amount sent");
    require(_amount <= _details.maxMintsPerTx, "Exceeds max mints per tx");

    if (totalPrice > 0) {
      payable(owner).transfer(totalPrice * (1000 - viewFee()) / 1000);
    }

    if (requiredBurnIds[_id].length > 1) {
      uint256[] memory burnAmounts = new uint256[](requiredBurnAmounts[_id].length);
      for (uint i = 0; i < requiredBurnAmounts[_id].length;) {
        burnAmounts[i] = requiredBurnAmounts[_id][i] * _amount;
        unchecked { i++; }
      }
      _batchBurn(msg.sender, requiredBurnIds[_id], burnAmounts);
    } else if (requiredBurnIds[_id].length == 1) {
      _burn(msg.sender, requiredBurnIds[_id][0], requiredBurnAmounts[_id][0] * _amount);
    }

    _details.tokenEditionMints += uint24(_amount);
    _mint(msg.sender, _id, _amount, "");
  }

  /*
  * @dev standard batch mint function, including burn & redeem tokens. For fee structures, see {ILayerrVariables}
  */
  function batchMint(uint[] memory _ids, uint256[] memory _amounts) public payable {
    require(_ids.length == _amounts.length, "ERROR");
    uint totalCost;
    uint totalFees;
    for (uint i = 0; i < _ids.length;) {
      uint id = _ids[i];
      uint256 amount = _amounts[i];
      Details memory _details = tokenDetails[id];
      require(!_details.isClaim && block.timestamp >= _details.saleStarts && block.timestamp <= _details.saleEnds, "This token is a claim");
      require(_details.tokenEditionMints + amount <= _details.editionCounts, "Not enough editions left");
      require(amount <= _details.maxMintsPerTx, "Exceeds max mints per tx");
      totalCost += _details.price * amount;
      totalFees += viewFlatFee() * amount;
      _details.tokenEditionMints += uint24(amount);
      tokenDetails[id] = _details;

      if (requiredBurnIds[id].length > 1) {
        uint256[] memory burnAmounts = new uint256[](requiredBurnAmounts[id].length);
        for (uint j = 0; j < requiredBurnAmounts[id].length;) {
          burnAmounts[j] = requiredBurnAmounts[id][j] * amount;
          unchecked {
            j++;
          }
        }
        _batchBurn(msg.sender, requiredBurnIds[id], burnAmounts);
      } else if (requiredBurnIds[id].length == 1) {
        _burn(msg.sender, requiredBurnIds[id][0], requiredBurnAmounts[id][0] * amount);
      }

      unchecked {
        i++;
      }
    }

    require(totalCost + totalFees <= msg.value, "Incorrect amount sent");
    payable(owner).transfer(totalCost * (1000 - viewFee()) / 1000);
    _batchMint(msg.sender, _ids, _amounts, "");
  }

  /*
  * @dev mints the tokens required for a claim, and claims the token in a single transaction
  */
  function mintAndClaim(uint _id, uint256 _amount) public payable {
    Details storage _details = tokenDetails[_id];
    require(_details.isClaim && block.timestamp >= _details.saleStarts && block.timestamp <= _details.saleEnds, "Sale is not active for this token");
    require(_details.tokenEditionMints + _amount <= _details.editionCounts, "Not enough editions left");

    _details.tokenEditionMints += uint24(_amount);

    if (_amount > 1) {
      uint256[] memory claimAmounts = new uint256[](requiredClaimAmounts[_id].length);
      for (uint i = 0; i < requiredClaimAmounts[_id].length;) {
        claimAmounts[i] = requiredClaimAmounts[_id][i] * _amount;
        unchecked {
          i++;
        }
      }
      batchMint(requiredClaimIds[_id], claimAmounts);
    } else {
      batchMint(requiredClaimIds[_id], requiredClaimAmounts[_id]);
    }

    _mint(msg.sender, _id, _amount, "");
  }

  /*
  * @dev claims a token, requires the user to have the required tokens in their wallet
  */
  function claim(uint _id, uint256 _amount) public payable {
    Details storage _details = tokenDetails[_id];
    require(_details.isClaim && block.timestamp >= _details.saleStarts && block.timestamp <= _details.saleEnds, "Sale is not active for this token");
    require(_details.tokenEditionMints + _amount <= _details.editionCounts, "Not enough editions left");
    require(viewFlatFee() * _amount <= msg.value, "Incorrect amount sent");
    uint[] memory requiredIds = requiredClaimIds[_id];
    uint[] memory requiredAmounts = requiredClaimAmounts[_id];
    for (uint i = 0; i < requiredClaimIds[_id].length;) {
      require(balanceOf[msg.sender][requiredIds[i]] >= requiredAmounts[i] * _amount, "Not enough required tokens");
      unchecked {
        i++;
      }
    }
    _details.tokenEditionMints += uint24(_amount);


    _mint(msg.sender, _id, _amount, "");
  }

  ////////////////////////////////////////////////////////////
  ///////////   OWNER FUNCTIONS   ////////////////////////////
  ////////////////////////////////////////////////////////////

  /*
  * @dev sets the contract URI
  */
  function setContractURI(string memory _contractURI) public onlyOwner {
    contractURI_ = _contractURI;
  }

  /*
  * @dev allows the contract owner to mint tokens, not subject to fees. Can be used outside the sale period
  * but must be used within the edition count
  */
  function ownerMint(uint _id, uint256 _amount, address _to) public onlyOwner {
    Details storage _details = tokenDetails[_id];
    require(_details.tokenEditionMints + _amount <= _details.editionCounts, "Not enough editions left");
    _details.tokenEditionMints += uint24(_amount);
    _mint(_to, _id, _amount, "");
  }
  
  /*
  * @dev see {ILayerrToken - initialize}
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
  * @dev adds a token to the contract by initializing its details
  */
  function addToken(
    uint _id,
    string memory _uri,
    uint72 _price,
    uint32 _saleStart,
    uint32 _saleEnd,
    uint24 _editionCount,
    uint24 _maxMintsPerTx,
    uint[] memory _requiredBurnIds,
    uint256[] memory _requiredBurnAmounts,
    bool _isClaim,
    uint[] memory _requiredClaimIds,
    uint256[] memory _requiredClaimAmounts
  ) public onlyOwner {
    URIs[_id] = _uri;

    Details memory _details;
    _details.price = _price;
    _details.saleStarts = _saleStart;
    _details.saleEnds = _saleEnd;
    _details.editionCounts = _editionCount;
    _details.maxMintsPerTx = _maxMintsPerTx;
    _details.tokenEditionMints = 0;
    _details.isClaim = _isClaim;
    tokenDetails[_id] = _details;

    if (_requiredBurnIds.length > 0) {
      requiredBurnIds[_id] = _requiredBurnIds;
      requiredBurnAmounts[_id] = _requiredBurnAmounts;
    }

    if (_isClaim) {
      requiredClaimIds[_id] = _requiredClaimIds;
      requiredClaimAmounts[_id] = _requiredClaimAmounts;
    }
  }

  /*
  * @dev adds a batch of tokens to the contract
  */
  function addTokenBatch (
    uint[] memory _ids,
    string[] memory _uris,
    uint72[] memory _prices,
    uint32[] memory _saleStarts,
    uint32[] memory _saleEnds,
    uint24[] memory _editionCounts,
    uint24[] memory _maxMintsPerTx,
    uint[][] memory _requiredBurnIds,
    uint256[][] memory _requiredBurnAmounts,
    bool[] memory _isClaim,
    uint[][] memory _requiredClaimIds,
    uint256[][] memory _requiredClaimAmounts
  ) public onlyOwner {
    for (uint i = 0; i < _ids.length;) {
      addToken(
        _ids[i],
        _uris[i],
        _prices[i],
        _saleStarts[i],
        _saleEnds[i],
        _editionCounts[i],
        _maxMintsPerTx[i],
        _requiredBurnIds[i],
        _requiredBurnAmounts[i],
        _isClaim[i],
        _requiredClaimIds[i],
        _requiredClaimAmounts[i]
      );
      unchecked {
        i++;
      }
    }
  }

  /*
  * @dev allows the contract owner to modify the token sale period
  * this is the only allowed modification to an existing token
  */
  function modifySalePeriod(uint _id, uint32 _saleStart, uint32 _saleEnd) public onlyOwner {
    Details storage _details = tokenDetails[_id];
    _details.saleStarts = _saleStart;
    _details.saleEnds = _saleEnd;
  }

  /*
  * @dev allows the contract owner to modify the name, symbol, and royalties of the contract
  */
  function editContract (address receiver, uint96 feeNumerator, string memory _name, string memory _symbol) external onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
    name = _name;
    symbol = _symbol;
  }

  /*
  * @dev see {ILayerrVariables}
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
    require(msg.sender == tx.origin, "Cannot withdraw from a contract");

    payable(viewWithdraw()).transfer(address(this).balance);
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