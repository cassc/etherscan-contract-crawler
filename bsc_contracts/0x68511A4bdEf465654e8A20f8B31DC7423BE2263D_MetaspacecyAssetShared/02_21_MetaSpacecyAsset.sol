// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Custom.sol";

contract MetaspacecyAsset is ERC1155Custom {
  uint256 constant TOKEN_SUPPLY_CAP = 1;
  string public templateURI;

  mapping(uint256 => string) private _tokenURI;
  mapping(uint256 => bool) private _isPermanentURI;

  event PermanentURI(string _value, uint256 indexed _id);

  modifier onlyTokenAmountOwned(
    address _from,
    uint256 _id,
    uint256 _quantity
  ) {
    require(_ownsTokenAmount(_from, _id, _quantity), "MSA: only owner token");
    _;
  }

  modifier onlyImpermanentURI(uint256 id) {
    require(!isPermanentURI(id), "MSA: URI cannot be changed");
    _;
  }

  constructor(
    string memory _name,
    string memory _symbol,
    address _proxyRegistryAddress,
    string memory _templateURI
  ) ERC1155Custom(_name, _symbol, "", _proxyRegistryAddress) {
    if (bytes(_templateURI).length > 0) {
      setTemplateURI(_templateURI);
    }
  }

  function _ownsTokenAmount(
    address _from,
    uint256 _id,
    uint256 _quantity
  ) internal view returns (bool) {
    return balanceOf(_from, _id) >= _quantity;
  }

  function supportsFactoryInterface() public pure returns (bool) {
    return true;
  }

  function setTemplateURI(string memory _uri) public onlyOwnerOrProxy {
    templateURI = _uri;
  }

  function setURI(uint256 _id, string memory _uri)
    public
    virtual
    onlyOwnerOrProxy
    onlyImpermanentURI(_id)
  {
    _setURI(_id, _uri);
  }

  function setPermanentURI(uint256 _id, string memory _uri)
    public
    virtual
    onlyOwnerOrProxy
    onlyImpermanentURI(_id)
  {
    _setPermanentURI(_id, _uri);
  }

  function isPermanentURI(uint256 _id) public view returns (bool) {
    return _isPermanentURI[_id];
  }

  function uri(uint256 _id) public view override returns (string memory) {
    string memory tokenUri = _tokenURI[_id];
    if (bytes(tokenUri).length != 0) {
      return tokenUri;
    }
    return templateURI;
  }

  function balanceOf(address _owner, uint256 _id)
    public
    view
    virtual
    override
    returns (uint256)
  {
    uint256 balance = super.balanceOf(_owner, _id);
    return
      _isCreatorOrProxy(_id, _owner)
        ? balance + _remainingSupply(_id)
        : balance;
  }

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes memory _data
  ) public override {
    uint256 mintedBalance = super.balanceOf(_from, _id);
    if (mintedBalance < _amount) {
      mint(_to, _id, _amount - mintedBalance, _data);
      if (mintedBalance > 0) {
        super.safeTransferFrom(_from, _to, _id, mintedBalance, _data);
      }
    } else {
      super.safeTransferFrom(_from, _to, _id, _amount, _data);
    }
  }

  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data
  ) public override {
    require(_ids.length == _amounts.length, "MSA: invalid array length");
    for (uint256 i = 0; i < _ids.length; i++) {
      safeTransferFrom(_from, _to, _ids[i], _amounts[i], _data);
    }
  }

  function _beforeMint(uint256 _id, uint256 _quantity)
    internal
    view
    override
  {
    require(_quantity <= _remainingSupply(_id), "MSA: exceeds cap");
  }

  function burn(
    address _from,
    uint256 _id,
    uint256 _quantity
  ) public override onlyTokenAmountOwned(_from, _id, _quantity) {
    super.burn(_from, _id, _quantity);
  }

  function batchBurn(
    address _from,
    uint256[] memory _ids,
    uint256[] memory _quantities
  ) public override {
    for (uint256 i = 0; i < _ids.length; i++) {
      require(
        _ownsTokenAmount(_from, _ids[i], _quantities[i]),
        "MSA: burn amount > owned token"
      );
    }
    super.batchBurn(_from, _ids, _quantities);
  }

  function _mint(
    address _to,
    uint256 _id,
    uint256 _quantity,
    bytes memory _data
  ) internal override {
    super._mint(_to, _id, _quantity, _data);
    if (_data.length > 1) {
      _setURI(_id, string(_data));
    }
  }

  function _isCreatorOrProxy(uint256, address _address)
    internal
    view
    virtual
    returns (bool)
  {
    return _isOwnerOrProxy(_address);
  }

  function _remainingSupply(uint256 _id)
    internal
    view
    virtual
    returns (uint256)
  {
    return TOKEN_SUPPLY_CAP - totalSupply(_id);
  }

  function _origin() internal view virtual returns (address) {
    return owner();
  }

  function _batchMint(
    address _to,
    uint256[] memory _ids,
    uint256[] memory _quantities,
    bytes memory _data
  ) internal virtual override {
    super._batchMint(_to, _ids, _quantities, _data);
    if (_data.length > 1) {
      for (uint256 i = 0; i < _ids.length; i++) {
        _setURI(_ids[i], string(_data));
      }
    }
  }

  function _setURI(uint256 _id, string memory _uri) internal {
    _tokenURI[_id] = _uri;
    emit URI(_uri, _id);
  }

  function _setPermanentURI(uint256 _id, string memory _uri)
    internal
    virtual
  {
    require(bytes(_uri).length > 0, "MSA: invalid URI");
    _isPermanentURI[_id] = true;
    _setURI(_id, _uri);
    emit PermanentURI(_uri, _id);
  }
}