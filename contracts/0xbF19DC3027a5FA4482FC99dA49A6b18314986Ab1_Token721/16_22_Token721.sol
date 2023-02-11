//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '../Polly.sol';
import '../PollyConfigurator.sol';
import '../PollyAux.sol';
import '../PollyToken.sol';
import './Json.sol';
import './Meta.sol';

contract Token721 is PollyToken, ERC721, ReentrancyGuard {


  string public constant override PMNAME = 'Token721';
  uint public constant override PMVERSION = 1;

  uint internal _minted;

  constructor() ERC721("", "") {
    _setConfigurator(address(new Token721Configurator()));
  }


  /*

  ERC721

  */


  function name() public view override returns (string memory) {
    return getMeta(0, 'collectionName')._string;
  }

  function symbol() public view override returns (string memory) {
    return getMeta(0, 'collectionSymbol')._string;
  }

  function exists(uint id_) public view returns (bool) {
    return _exists(id_);
  }

  function totalSupply() public view returns (uint) {
    return _minted;
  }


  /*

  TOKENS

  */

  /// @dev create a new token
  function createToken(PollyToken.MetaEntry[] memory meta_, address mint_) public returns (uint) {

    _requireRole('manager', msg.sender);

    uint id_ = _createToken(meta_);

    if(mint_ != address(0))
      _mintFor(mint_, id_, true, PollyAux.Msg(msg.sender, 0, msg.data, msg.sig));

    return id_;

  }



  /// @dev mint a token
  /// @param id_ the id of the token
  function _mintFor(address for_, uint id_, bool pre_, PollyAux.Msg memory msg_) private {

    address hook_ = getHookAddress('action_BeforeMint721');
    if(hook_ != address(0))
      _call(hook_, abi.encodeWithSignature('action_BeforeMint721(address,uint256,bool,(address,uint256,bytes,bytes4))', for_, id_, pre_, msg_));

    _mint(for_, id_);
    _minted++;

    hook_ = getHookAddress('action_AfterMint721');
    if(hook_ != address(0))
      _call(hook_, abi.encodeWithSignature('action_AfterMint721(address,uint256,bool,(address,uint256,bytes,bytes4))', for_, id_, pre_, msg_));

  }




  /// @dev mint a token
  /// @param id_ the id of the token
  function mint(uint id_) public payable nonReentrant {
    _mintFor(msg.sender, id_, false, PollyAux.Msg(msg.sender, msg.value, msg.data, msg.sig));
    _postMintTransfer(id_, msg.value);
  }


  /// @dev get the token uri
  /// @param id_ the id of the token
  function tokenURI(uint id_) public view override returns(string memory) {
    require(exists(id_), 'TOKEN_DOES_NOT_EXIST');
    return _tokenUri(id_);
  }


  /// Override
  function supportsInterface(bytes4 interfaceId) public view virtual override(PollyToken, ERC721) returns (bool){
      return super.supportsInterface(interfaceId);
  }


}







contract Token721Configurator is PollyConfigurator, ReentrancyGuard {

  function inputs() public pure override virtual returns (string[] memory) {

    string[] memory inputs_ = new string[](1);
    inputs_[0] = '...address || Aux addresses || addresses of the aux contracts to attach';
    return inputs_;
  }

  function outputs() public pure override virtual returns (string[] memory) {

    string[] memory outputs_ = new string[](2);

    outputs_[0] = 'module || Token721 || the main Token721 module address';
    outputs_[1] = 'module || Meta || the meta handler address';

    return outputs_;

  }

  function run(Polly polly_, address for_, Polly.Param[] memory inputs_) public override payable nonReentrant returns(Polly.Param[] memory) {

    Polly.Param[] memory rparams_ = new Polly.Param[](3);

    // Clone the Token721 module
    Token721 token_ = Token721(polly_.cloneModule('Token721', 1));
    rparams_[0]._string = 'Token721';
    rparams_[0]._address = address(token_);
    rparams_[0]._uint = 1;

    // Configure a Meta module
    Polly.Param[] memory meta_params_ = polly_.configureModule(
      'Meta', // module name
      1, // version
      new Polly.Param[](0), // No inputs
      false, // Don't store
      '' // No config name
    );

    token_.setMetaHandler(meta_params_[0]._address);
    token_.grantRole('manager', meta_params_[0]._address);

    Meta meta_ = Meta(meta_params_[0]._address);
    meta_.grantRole('manager', address(token_));

    rparams_[1] = meta_params_[0];


    /// Configure all the Token721Aux modules passed to the configurator
    if(inputs_.length > 0){
      for(uint i = 0; i < inputs_.length; i++){
        token_.registerAux(inputs_[i]._address);
      }
    }


    // Transfer to sender
    _transfer(address(token_), for_);
    _transfer(meta_params_[0]._address, for_);

    return rparams_;

  }


}