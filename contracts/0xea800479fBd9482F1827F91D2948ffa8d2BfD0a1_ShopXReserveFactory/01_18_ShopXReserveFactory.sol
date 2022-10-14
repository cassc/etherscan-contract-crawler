// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ShopXReserveNFT.sol";

/**
 * @title ShopXReserveNFT Factory
 * @dev Create smart contract that will create ShopxReserveNFT contract for a given (name, symbol, brand).
 * https://eips.ethereum.org/EIPS/eip-1014
 * https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Factory.sol#L32

 */
contract ShopXReserveFactory is Pausable {

  // platform configurations
  struct Config {
    bool    isValid;
    uint256 shopxFee;
    address shopxAddress;
    uint256 platformFee;
    address platformAddress;
    uint256 agencyFee;
    address agencyAddress;
    uint256 shopxRequired;
  }
  mapping (uint256 => Config) public Configs;
  uint256 public configIndex;

  address[] public allReserveX;
  address[] public shopxAdmins;
  address public shopxTokenAddress=0x7BEF710a5759d197EC0Bf621c3Df802C2D60D848;//SHOPX Token Address

  mapping(address => bool) public isShopxAdmin;
  mapping(address => bool) public isReserveX;

  event ConfigCreated(uint256 indexed configId, uint256 shopxFee, address shopxAddress, uint256 platformFee, address platformAddress, uint256 agencyFee, address agencyAddress, uint256 shopxRequired);
  event FactoryCreated(address indexed ShopXReserveFactory);
  event ContractCreated(uint256 indexed configId, string name, string symbol, string brand, address indexed ReserveX, uint256 index);
  event ShopxAddressUpdated(uint256 indexed configId, address indexed _shopxAddress);
  event PlatformAddressUpdated(uint256 indexed configId, address indexed _platformAddress);
  event AgencyAddressUpdated(uint256 indexed configId, address indexed _platformAddress);
  event ContractDestroyed(string name, string symbol, string brand, address indexed ReserveX);

  constructor (
    address[] memory _shopxAdmins
  ) public {
    require(_shopxAdmins.length > 0);

    for (uint i = 0; i < _shopxAdmins.length; i++) {
      require(_shopxAdmins[i] != address(0));
      shopxAdmins.push(_shopxAdmins[i]);
      isShopxAdmin[_shopxAdmins[i]] = true;
    }
    configIndex=0;
    emit FactoryCreated(address(this));
  }

  /*
  arguments for createReserveNFT()

  _stringArgs[0]: _name
  _stringArgs[1]: _symbol
  _stringArgs[2]: _brand
  _stringArgs[3]: _baseURI

  _uintArgs[0]: _configId
  _uintArgs[1]: _maxSupply
  _uintArgs[2]: _mintPrice
  _uintArgs[3]: _mintLimitPerWallet
  _uintArgs[4]: _royaltyValue

  _addressArgs: _royaltyRecipient

  _beneficiaryFees[]: beneficiary1, beneficiary2, ...
  _beneficiaryAddresses[]: beneficiary1, beneficiary2, ...
  _brandAdmins[]: brandAdmin1, brandAdmin2, ...
  _saleAdmins[]: saleAdmin1, saleAdmin2, ...
  */
  function createReserveNFT(
    string[4] memory _stringArgs,
    uint256[5] memory _uintArgs,
    address _addressArgs,
    uint256[] memory _beneficiaryFees,
    address[] memory _beneficiaryAddresses,
    address[] memory _brandAdmins,
    address[] memory _saleAdmins
  ) external whenNotPaused returns (address) {
    require(IERC20(shopxTokenAddress).balanceOf(msg.sender) >= Configs[_uintArgs[0]].shopxRequired);
    require(isReserveX[computeAddress(_stringArgs[0],_stringArgs[1],_stringArgs[2])] == false);
    require(_beneficiaryFees.length == _beneficiaryAddresses.length);

    // {} to avoid stack too deep error
    {
      uint256 totalFee = Configs[_uintArgs[0]].shopxFee + Configs[_uintArgs[0]].platformFee + Configs[_uintArgs[0]].agencyFee;
      for (uint i=0; i<_beneficiaryFees.length; i++) {
        totalFee = totalFee + _beneficiaryFees[i];
      }
      require(totalFee == 10000);
    }

    bytes memory bytecode = abi.encodePacked(type(ShopXReserveNFT).creationCode, abi.encode(
        _stringArgs[0],
        _stringArgs[1],
        _stringArgs[2]
      ));

    require(bytecode.length != 0);

    address payable reserveX;
    uint256 codeSize;

    assembly {
      reserveX := create2(0, add(bytecode, 0x20), mload(bytecode), 0)
      codeSize := extcodesize(reserveX)
    }
    require(codeSize > 0);
    require(reserveX != address(0));

    // {} to avoid stack too deep error
    {
      // _uintArgsX: uint arguments for ReserveX initialize()
      uint256[8] memory _uintArgsX;
      _uintArgsX[0] = _uintArgs[0];
      _uintArgsX[1] = _uintArgs[1];
      _uintArgsX[2] = _uintArgs[2];
      _uintArgsX[3] = _uintArgs[3];
      _uintArgsX[4] = _uintArgs[4];
      _uintArgsX[5] = Configs[_uintArgs[0]].shopxFee;
      _uintArgsX[6] = Configs[_uintArgs[0]].platformFee;
      _uintArgsX[7] = Configs[_uintArgs[0]].agencyFee;

      // _addressArgsX: address arguments for ReserveX initialize()
      address[5] memory _addressArgsX;
      _addressArgsX[0] = msg.sender;
      _addressArgsX[1] = _addressArgs;
      _addressArgsX[2] = Configs[_uintArgs[0]].shopxAddress;
      _addressArgsX[3] = Configs[_uintArgs[0]].platformAddress;
      _addressArgsX[4] = Configs[_uintArgs[0]].agencyAddress;

      IShopXReserveNFT(reserveX).initialize(
        _stringArgs[3],
        _uintArgsX,
        _addressArgsX,
        _beneficiaryFees,
        _beneficiaryAddresses,
        _brandAdmins,
        _saleAdmins,
        shopxAdmins
      );
    }

    allReserveX.push(reserveX);
    isReserveX[reserveX] = true;
    emit ContractCreated(_uintArgs[0], _stringArgs[0], _stringArgs[1], _stringArgs[2], address(reserveX), allReserveX.length);

    return reserveX;
  }

  /**
  * @dev Returns the address where a contract will be stored if deployed via {createReserveNFT}. Any change in the
  * `bytecodeHash` or `salt` will result in a new destination address.
  */
  function computeAddress(string memory _name, string memory _symbol, string memory _brand) public view returns (address) {
    bytes memory bytecode = abi.encodePacked(type(ShopXReserveNFT).creationCode, abi.encode(
        _name,
        _symbol,
        _brand
      ));
    bytes32 bytecodeHash = keccak256(abi.encodePacked(bytecode));
    bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), address(this), bytes32(0), bytecodeHash));
    return address(uint160(uint256(_data)));
  }

  /**
 * @dev Throws if called by any account other than a shopxAdmin
     */
  modifier onlyShopxAdmin() {
    require(isShopxAdmin[msg.sender]);
    _;
  }

  function addConfig (uint256 _shopxFee, address _shopxAddress, uint256 _platformFee, address _platformAddress, uint256 _agencyFee, address _agencyAddress, uint256 _shopxRequired) onlyShopxAdmin external {
    require(_shopxAddress != address(0));
    Configs[configIndex] = Config(true, _shopxFee, _shopxAddress, _platformFee, _platformAddress, _agencyFee, _agencyAddress, _shopxRequired);
    emit ConfigCreated(configIndex, _shopxFee, _shopxAddress, _platformFee, _platformAddress, _agencyFee, _agencyAddress, _shopxRequired);
    configIndex = configIndex + 1;
  }

  /*
  function setShopxFee (uint256 _configId, uint256 _shopxFee) onlyShopxAdmin external {
    require(Configs[_configId].isValid);
    Configs[_configId].shopxFee = _shopxFee;
  }
  */

  function setShopxAddress (uint256 _configId, address _shopxAddress) onlyShopxAdmin external {
    require(Configs[_configId].isValid);
    require(_shopxAddress != address(0));
    Configs[_configId].shopxAddress = _shopxAddress;
    emit ShopxAddressUpdated(_configId, _shopxAddress);
  }

  /*
  function setPlatformFee (uint256 _configId, uint256 _platformFee) onlyShopxAdmin external {
    require(Configs[_configId].isValid);
    Configs[_configId].platformFee = _platformFee;
  }
  */

  function setPlatformAddress (uint256 _configId, address _platformAddress) onlyShopxAdmin external {
    require(Configs[_configId].isValid);
    require(_platformAddress != address(0));
    Configs[_configId].platformAddress = _platformAddress;
    emit PlatformAddressUpdated(_configId, Configs[_configId].platformAddress);
  }

  /*
  function setAgencyFee (uint256 _configId, uint256 _agencyFee) onlyShopxAdmin external {
    require(Configs[_configId].isValid);
    Configs[_configId].agencyFee = _agencyFee;
  }
  */

  function setAgencyAddress (uint256 _configId, address _agencyAddress) onlyShopxAdmin external {
    require(Configs[_configId].isValid);
    require(_agencyAddress != address(0));
    Configs[_configId].agencyAddress = _agencyAddress;
    emit AgencyAddressUpdated(_configId, Configs[_configId].agencyAddress);
  }

  /*
  function setShopxRequired (uint256 _configId, uint256 _shopxRequired) onlyShopxAdmin external {
    Configs[_configId].shopxRequired = _shopxRequired;
  }
  */

  function setShopxTokenAddress (address _shopxTokenAddress) onlyShopxAdmin external {
    require(_shopxTokenAddress != address(0));
    shopxTokenAddress = _shopxTokenAddress;
  }

  function addShopxAdmin (address _shopxAdmin) onlyShopxAdmin external {
    require(_shopxAdmin != address(0));
    require( !isShopxAdmin[_shopxAdmin]);
    shopxAdmins.push(_shopxAdmin);
    isShopxAdmin[_shopxAdmin]=true;
  }

  function removeShopxAdmin(address _shopxAdmin) onlyShopxAdmin external {
    require( shopxAdmins.length > 1);
    require( isShopxAdmin[_shopxAdmin]);

    for (uint i=0; i<shopxAdmins.length; i++) {
      if (shopxAdmins[i] == _shopxAdmin) {
        shopxAdmins[i] = shopxAdmins[shopxAdmins.length - 1];
        shopxAdmins.pop();
        isShopxAdmin[_shopxAdmin]=false;
        break;
      }
    }
  }

  function destroyReserveNFT(address payable _reserveX, address payable _to) onlyShopxAdmin external {
    emit ContractDestroyed(IShopXReserveNFT(_reserveX).name(), IShopXReserveNFT(_reserveX).symbol(), IShopXReserveNFT(_reserveX).getBrand(), address(_reserveX));
    IShopXReserveNFT(_reserveX).destroySmartContract(msg.sender, _to);
    isReserveX[_reserveX] = false;
  }

  function pause() onlyShopxAdmin external {
    _pause();
  }

  function unpause() onlyShopxAdmin external {
    _unpause();
  }
}