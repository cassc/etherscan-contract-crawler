//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import './Polly.sol';
import './PollyAux.sol';
import './modules/Meta.sol';


/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param id_ - the NFT asset queried for royalty information
    /// @param value_ - the sale price of the NFT asset specified by id_
    /// @return receiver_ - address of who should be sent the royalty payment
    /// @return amount_ - the royalty payment amount for value sale price
    function royaltyInfo(uint256 id_, uint256 value_)
        external
        view
        returns (address receiver_, uint256 amount_);
}



contract PollyToken is PMClone, PollyAuxParent, ERC165, IERC2981Royalties {

  /// DEFINITIONS

  struct MetaEntry {
    string _key;
    Polly.Param _value;
  }

  Meta internal _meta;

  uint[] internal _tokens;
  uint public highestId;

  event TokenCreated(uint id);


  /// @dev get the name of the module
  function PMNAME() external pure override virtual returns (string memory) {
    return 'PollyToken';
  }

  /// @dev get the version of the module
  function PMVERSION() external pure override virtual returns (uint) {
    return 1;
  }



  function _call(address target_, bytes memory data_) internal returns (bytes memory) {

      (bool success_, bytes memory result_) = target_.call(data_);

      if(!success_){
        if(result_.length < 68) revert();
        assembly {
          result_ := add(result_, 0x04)
        }
        revert(abi.decode(result_, (string)));
      }

      return result_;

  }

  function _staticcall(address target_, bytes memory data_) internal view returns (bytes memory) {

      (bool success_, bytes memory result_) = target_.staticcall(data_);

      if(!success_){
        if(result_.length < 68) revert();
        assembly {
          result_ := add(result_, 0x04)
        }
        revert(abi.decode(result_, (string)));
      }

      return result_;

  }


  /////////////////////////
  // AUX
  /////////////////////////

  /// @dev register aux
  /// @param aux_ the aux to register
  function registerAux(address aux_) public override virtual {
    _requireRole('admin', msg.sender);
    _registerHooks(PollyAux(aux_).hooks(), aux_);
  }


  /////////////////////////
  // META
  /////////////////////////


  /// @dev set meta handler
  /// @param handler_ the address of the meta handler
  function setMetaHandler(address handler_) public {
    _requireRole('admin', msg.sender);
    require(address(_meta) == address(0), 'META_HANDLER_SET');
    _meta = Meta(handler_);
  }


  /// @dev get meta handler attached to this contract
  function getMetaHandler() public view returns (Meta) {
    return _meta;
  }


  function getMeta(uint id_, string memory key_) public view returns (Polly.Param memory) {

    // Check for token specific filter
    string memory hook_ = string(abi.encodePacked('filter_Meta_', key_));
    address filter_ = getHookAddress(hook_);

    Polly.Param memory meta_ = _meta.get(id_, key_);

    if(filter_ != address(0)){
      bytes memory data_ = _staticcall(filter_, abi.encodeWithSignature(string(abi.encodePacked(hook_, '(uint256,(uint256,int256,bool,string,address))')), id_, _meta.get(id_, key_)));
      meta_ = abi.decode(data_, (Polly.Param));
    }

    return meta_;

  }




  /////////////////////////
  // TOKENS
  /////////////////////////


  /// @dev create a new token
  function _createToken(MetaEntry[] memory meta_) internal returns (uint) {

    uint id_ = highestId + 1;

    address hook_ = getHookAddress('action_BeforeCreateToken');
    if(hook_ != address(0))
      _call(hook_, abi.encodeWithSignature('action_BeforeCreateToken(uint256,(uint256,int256,bool,string,address)[])', id_, meta_));

    for(uint i = 0; i < meta_.length; i++) {
      _meta.set(id_, meta_[i]._key, meta_[i]._value);
    }

    _tokens.push(id_);
    _meta.setBool(id_, 'created', true);
    _meta.lockIdKey(id_, 'created');

    hook_ = getHookAddress('action_AfterCreateToken');
    if(hook_ != address(0))
      _call(hook_, abi.encodeWithSignature('action_AfterCreateToken(uint256)', id_, meta_));

    emit TokenCreated(id_);
    if(id_ > highestId) highestId = id_;
    return id_;

  }


  function getTokens(uint limit_, uint page_) public view returns (uint[] memory) {

    uint[] memory tokens_ = new uint[](limit_);
    uint count_ = 0;
    uint offset_ = page_ > 1 ? page_-1 * limit_ : 0;
    for(uint i = offset_; i < _tokens.length; i++){
      if(count_ == limit_) break;
      tokens_[count_] = _tokens[i];
      count_++;
    }

    return tokens_;

  }


  function _tokenUri(uint id_) internal view returns (string memory){
    return getMeta(id_, 'tokenUri')._string;
  }




  /////////////////////////
  // MISC
  /////////////////////////



  /// @dev get the contract metadata uri
  function contractURI() public view returns(string memory) {
    return getMeta(0, 'collectionUri')._string;
  }


  /// @dev get the royalty info
  /// @param id_ the id of the token
  /// @param value_ the value of the sale
  function royaltyInfo(uint id_, uint value_) public view override returns (address recipient_, uint amount_) {

     // Get royalty base and recipient for the token
    uint base_ = getMeta(id_, 'royaltyBase')._uint;
    recipient_ = getMeta(id_, 'royaltyRecipient')._address;

    // Use default royalty if no royalty is set for the token
    if(base_ == 0 && getMeta(0, 'royaltyBase')._uint > 0)
      base_ = getMeta(0, 'royaltyBase')._uint;

    // Use default recipient if no recipient is set for the token
    if(recipient_ == address(0) && getMeta(0, 'royaltyRecipient')._address != address(0))
      recipient_ = getMeta(0, 'royaltyRecipient')._address;

    // If either base or recipient is not set, return 0
    if(base_ == 0 || recipient_ == address(0) || value_ == 0)
      return (recipient_, 0);

    // Limit base to 10000 (100%)
    if(base_ > 10000)
      base_ = 10000;

    // Calculate and return royalty
    return (recipient_, (value_ * base_) / 10000);

  }


  // Withdraw all ETH from this contract
  function withdraw() public {
    _requireRole('admin', msg.sender);
    payable(msg.sender).transfer(address(this).balance);
  }


  function _postMintTransfer(uint id_, uint amount_) internal {

    // Send msg.value to the recipient address for token
    if(amount_ > 0){

      Meta meta_ = getMetaHandler();
      // Check if the token has a recipient address
      address recipient_ = meta_.getAddress(id_, 'collectionRecipient');
      // If not, check if contract has a recipient address
      if(recipient_ == address(0))
        recipient_ = meta_.getAddress(0, 'collectionRecipient');

      if(recipient_ != address(0))
        payable(recipient_).transfer(amount_);

    }

  }


  /// Override
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool){
      return interfaceId == type(IERC2981Royalties).interfaceId;
  }


}