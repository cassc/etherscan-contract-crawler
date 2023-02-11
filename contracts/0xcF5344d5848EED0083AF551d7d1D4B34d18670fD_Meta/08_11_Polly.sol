/*

       -*%%+++*#+:              .+     --
        [email protected]*     *@*           -#@-  .=#%
        %@.      @@:          [email protected]*    :@:
       [email protected]*       @@.          [email protected]    #*  :=     --
       #@.      [email protected]#  +*+#:    @=    [email protected]: *=%*    *@
      [email protected]*      :@#.-%-  [email protected]   +%    [email protected]*.+  [email protected]    =#
      *@.    .+%= =%.   [email protected] :@-    *@     [email protected]:   *-
     :@#---===-  [email protected]    #@  %%    :@-     [email protected]  .#
     #@:        [email protected]*    [email protected]+ [email protected]:    ##      [email protected]  #.
    :@%         *@.    *% [email protected]+    :@.      [email protected] =:
    #@-         @*    [email protected] +%  =. %+ .=    [email protected]::=
   :@#          @=   [email protected] [email protected]==  [email protected]+-     [email protected]*
   *@-          #*  *#.  #@*.  :@@+       [email protected]+
.:=++=:.         ===:    +:    :=.        +=
                                         +-
                                       =+.
                                  +*-=+.

v1

*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PollyModule.sol";
import "./PollyConfigurator.sol";
import "./PollyFeeHandler.sol";

/// @title Polly main contract
/// @author polly.tools

/**
 *
 * Polly is a modular smart contract framework that allows anyone to deploy registered modules as proxy contracts onchain.
 * The framework is built and designed by continuousengagement.xyz and is open source.
 */

contract Polly is Ownable {


    enum ModuleType {
        READONLY, CLONE
    }

    enum ParamType {
      UINT, INT, BOOL, STRING, ADDRESS
    }

    /// @dev struct for an uninstantiated module
    struct Module {
      string name;
      uint version;
      address implementation;
      bool clone;
    }

    /// @dev struct for an instantiated module
    struct ModuleInstance {
      string name;
      uint version;
      address location;
    }

    /// @dev struct for a module configuration
    struct Config {
      string name;
      string module;
      uint version;
      Param[] params;
    }

    /// @dev struct for a general type parameter
    struct Param {
      uint _uint;
      int _int;
      bool _bool;
      string _string;
      address _address;
    }


    /// PRIVATE PROPERTIES ///
    string[] private _module_names; // names of registered modules
    mapping(string => mapping(uint => address)) private _modules; // mapping of registered modules and their versions - name => (id => implementation)
    uint private _module_count; // the total number of registered modules
    mapping(string => uint) private _module_versions; // mapping of registered modules and their latest version - name => version
    mapping(address => mapping(uint => Config)) private _configs; // mapping of module configs - owner => (id => config)
    mapping(address => uint) private _configs_count; // mapping of owner config count - owner => count
    mapping(address => bool) private _configurators; // mapping of configurators - address => bool
    PollyFeeHandler private _fee_handler; // fee handler contract
    //////////////////



    /// EVENTS ///
    event moduleUpdated(
      string indexed indexedName, string name, uint version, address indexed implementation
    );

    event moduleCloned(
      string indexed indexedName, string name, uint version, address location
    );

    event moduleConfigured(
      string indexedName, string name, uint version, Polly.Param[] params
    );


    /// CONSTRUCTOR ///

    constructor() {
      _fee_handler = new PollyFeeHandler();
    }


    /// FEE ///
    function fee(address for_, uint value_) public view returns (uint) {
      return _fee_handler.get(for_, value_);
    }


    /// MODULES ///

    /// @dev adds or updates a given module implemenation
    /// @param implementation_ address of the module implementation
    function updateModule(address implementation_) public onlyOwner {

      string memory name_ = PollyModule(implementation_).PMNAME();
      uint version_ = PollyModule(implementation_).PMVERSION();

      require(_modules[name_][version_] == address(0), "MODULE_VERSION_EXISTS");
      require(version_ == _module_versions[name_]+1, "MODULE_VERSION_INVALID");

      _modules[name_][version_] = implementation_; // add module implementation address
      _module_versions[name_] = version_; // update module latest version

      if(version_ == 1)
        _module_names.push(name_); // This is a new module, add to module names mapping

      address configurator_ = getConfigurator(name_, version_); // get configurator address

      if(configurator_ != address(0))
        _configurators[configurator_] = true; // Store the configurator address for this module

      emit moduleUpdated(name_, name_, version_, implementation_); // emit event moduleUpated

    }


    /// @dev retrieves a specific module version base
    /// @param name_ string name of the module
    /// @param version_ uint version of the module
    /// @return address of the module implementation
    function getModule(string memory name_, uint version_) public view returns(Module memory){

      if(version_ < 1)
        version_ = getLatestModuleVersion(name_); // version_ is 0, get latest version

      require(moduleExists(name_, version_), string(abi.encodePacked('INVALID_MODULE_OR_VERSION: ', name_, '@', Strings.toString(version_))));

      Polly.ModuleType type_ = PollyModule(_modules[name_][version_]).PMTYPE(); // get module info from stored implementation
      bool clone_ = type_ == Polly.ModuleType.CLONE;

      return Module(name_, version_, _modules[name_][version_], clone_); // return module

    }


    /// @dev returns a list of modules available
    /// @param limit_ uint maximum number of modules to return
    /// @param page_ uint page of modules to return
    /// @param ascending_ bool sort modules ascending (true) or descending (false)
    /// @return Module[] array of modules
    function getModules(uint limit_, uint page_, bool ascending_) public view returns(Module[] memory){

      uint count_ = _module_names.length; // get total number of modules

      if(limit_ < 1 || limit_ > count_)
        limit_ = count_; // limit_ is 0, get all modules

      if(page_ < 1)
        page_ = 1; // page_ is 0, get first page

      uint i; // iterator
      uint index_; // index of module name in _module_names


      if(ascending_)
        index_ = page_ == 1 ? 0 : (page_-1)*limit_; // ascending, set index to last module result set
      else
        index_ = page_ == 1 ? count_ : count_ - (limit_*(page_-1)); // descending, set index to first module on result set


      if(
        (ascending_ && index_ >= count_) // ascending, index is greater than total number of modules
        || // or
        (!ascending_ && index_ == 0) // descending, index is 0
      )
        return new Module[](0); // no modules available - bail early


      Module[] memory modules_ = new Module[](limit_); // create array of modules

      if(ascending_){

        // ASCENDING
        while(index_ < limit_){
            modules_[i] = getModule(_module_names[index_], 0);
            ++i;
            ++index_;
        }

      }
      else {

        /// DESCENDING
        while(index_ > 0 && i < limit_){
            modules_[i] = getModule(_module_names[index_-1], 0);
            ++i;
            --index_;
        }

      }


      return modules_; // return modules

    }


    /// @dev retrieves the most recent version number for a module
    /// @param name_ string name of the module
    /// @return uint version number of the module
    function getLatestModuleVersion(string memory name_) public view returns(uint){
      return _module_versions[name_];
    }


    /// @dev check if a module version exists
    /// @param name_ string name of the module
    /// @param version_ uint version of the module
    /// @return exists_ bool true if module version exists
    function moduleExists(string memory name_, uint version_) public view returns(bool exists_){
      if(_modules[name_][version_] != address(0))
        exists_ = true;
      return exists_;
    }


    /// @dev get the configurator for a given module
    /// @param name_ string name of the module
    /// @param version_ uint version of the module
    /// @return address of the module configurator
    function getConfigurator(string memory name_, uint version_) public view returns(address){
      return PollyModule(_modules[name_][version_]).configurator();
    }

    /// @dev get the configurator fee for a given module
    /// @param name_ string name of the module
    /// @param version_ uint version of the module
    /// @return fee_ uint fee in points
    function getConfiguratorFee(address for_, string memory name_, uint version_, Polly.Param[] memory params_) public view returns(uint){

      address conf_address_ = getConfigurator(name_, version_);
      if(conf_address_ == address(0))
        return 0;
      return PollyConfigurator(conf_address_).fee(this, for_, params_);

    }


    /// @dev clone a given module
    /// @param name_ string name of the module
    /// @param version_ uint version of the module
    /// @return address of the cloned module implementation
    function cloneModule(string memory name_, uint version_) public returns(address) {

      if(version_ == 0)
        version_ = getLatestModuleVersion(name_); // version_ is 0, get latest version

      require(moduleExists(name_, version_), string(abi.encodePacked('INVALID_MODULE_OR_VERSION: ', name_, '@', Strings.toString(version_))));
      require(PollyModule(_modules[name_][version_]).PMTYPE() == Polly.ModuleType.CLONE, 'MODULE_NOT_CLONABLE'); // module is not clonable

      address implementation_ = _modules[name_][version_]; // get module implementation address

      PollyModule module_ = PollyModule(Clones.clone(implementation_)); // clone module implementation
      module_.init(msg.sender); // initialize module


      emit moduleCloned(name_, name_, version_, address(module_)); // emit module cloned event
      return address(module_); // return cloned module address

    }


    /// @dev if a module is configurable run the configurator
    /// @param name_ string name of the module
    /// @param version_ uint version of the module
    /// @param params_ array of configuration input parameters
    /// @return rparams_ array of configuration return parameters
    function configureModule(string memory name_, uint version_, Polly.Param[] memory params_, bool store_, string memory config_name_) public payable returns(Polly.Param[] memory rparams_) {

      if(version_ == 0)
        version_ = getLatestModuleVersion(name_); // version_ is 0, get latest version

      Module memory module_ = getModule(name_, version_); // get module
      address configurator_ = PollyModule(module_.implementation).configurator(); // get module configurator address
      require(configurator_ != address(0), 'NO_MODULE_CONFIGURATOR'); // module is not configurable - revert

      PollyConfigurator config_ = PollyConfigurator(configurator_); // get configurator instance

      // Fee
      uint fee_ = config_.fee(this, msg.sender, params_); // get configurator fee info
      if(!_configurators[msg.sender]){
        fee_ = fee_+_fee_handler.get(msg.sender, fee_);
      }

      require(fee_ == msg.value, 'INVALID_FEE');

      // Configure
      rparams_ = config_.run{value: fee_}(this, msg.sender, params_); // run configurator with params

      // Store
      if(store_){

        uint new_count_ = _configs_count[msg.sender] + 1; // get new config count for storing
        _configs[msg.sender][new_count_].name = config_name_; // store config name
        _configs[msg.sender][new_count_].module = name_; // store module name
        _configs[msg.sender][new_count_].version = version_; // store module name

        for (uint i = 0; i < rparams_.length; i++){ // store each config params
          _configs[msg.sender][new_count_].params.push(rparams_[i]);
        }

        _configs_count[msg.sender] = new_count_; // update config count

      }

      emit moduleConfigured(name_, name_, version_, rparams_); // emit module configured event
      return rparams_;  // return configuration params

    }

    /// @dev retrieves the stored configurations for a given address
    /// @param address_ address of the user
    /// @param limit_ maximum number of configurations to return
    /// @param page_ page of configurations to return
    /// @param ascending_ sort configurations ascending (true) or descending (false)
    /// @return PollyConfigurator.Config[] array of configurations
    function getConfigsForAddress(address address_, uint limit_, uint page_, bool ascending_) public view returns(Config[] memory){

      uint count_ = _configs_count[address_]; // get total number of configs for address

      if(limit_ < 1 || limit_ > count_)
        limit_ = count_;  // limit is 0 or greater than total number of configs, set limit to total number of configs

      if(page_ < 1)
        page_ = 1; // page is less than 1, set page to 1

      uint i; // counter
      uint id_; // config id

      if(ascending_)
        id_ = page_ == 1 ? 1 : ((page_-1)*limit_)+1; // calculate ascending start id
      else
        id_ = page_ == 1 ? count_ : count_ - (limit_*(page_-1)); // calculate descending start id


      if(
        (ascending_ && id_ > count_) // ascending and id is greater than total number of configs
        ||
        (!ascending_ && id_ == 0) // descending and id is 0
      )
        return new Config[](0); // no modules available - bail early


      Config[] memory configs_ = new Config[](limit_);  // create array of configs


      if(ascending_){

        // ASCENDING
        while(id_ <= count_ && i < limit_){
            configs_[i] = _configs[address_][id_];
            ++i;
            ++id_;
        }

      }
      else {

        /// DESCENDING
        while(id_ > 0 && i < limit_){
            configs_[i] = _configs[address_][id_];
            ++i;
            --id_;
        }

      }

      return configs_;

    }


    /// @dev retrieve a stored configuration for a given address and config index
    /// @param address_ address of the user
    /// @param index_ index of the configuration
    /// @return Polly.Config configuration
    function getConfigForAddress(address address_, uint index_) public view returns(Config memory){
      require(index_ > 0 && index_ <= _configs_count[address_], 'INVALID_CONFIG_INDEX'); // invalid config index
      return _configs[address_][index_]; // return config
    }


}