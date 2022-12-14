// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

import "./FnbswapExchange20.sol";

contract Ownable {
  address internal owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the specied address
   * @param _firstOwner Address of the first owner
   */
  constructor (address _firstOwner) {
    owner = _firstOwner;
    emit OwnershipTransferred(address(0), _firstOwner);
  }

  /**
   * @dev Throws if called by any account other than the master owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "Ownable#onlyOwner: SENDER_IS_NOT_OWNER");
    _;
  }

  /**
   * @notice Transfers the ownership of the contract to new address
   * @param _newOwner Address of the new owner
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0), "Ownable#transferOwnership: INVALID_ADDRESS");
    owner = _newOwner;
    emit OwnershipTransferred(owner, _newOwner);
  }

  /**
   * @notice Returns the address of the owner.
   */
  function getOwner() public view returns (address) {
    return owner;
  }
}

interface IFnbswapFactory20 {

  /***********************************|
  |               Events              |
  |__________________________________*/

  event NewExchange(address indexed token, address indexed currency, uint256 indexed salt, uint256 lpFee, address exchange);

  event MetadataContractChanged(address indexed metadataContract);

  /***********************************|
  |         Public  Functions         |
  |__________________________________*/

  /**
   * @notice Creates a FnbSwap Exchange for given token contract
   * @param _token      The address of the ERC-1155 token contract
   * @param _currency   The address of the currency token contract
   * @param _lpFee      Fee that will go to LPs
   *                    Number between 0 and 1000, where 10 is 1.0% and 100 is 10%.
   */
  function createExchange(address _token, address _currency, uint256 _lpFee) external;

  /**
   * @notice Return address of exchange for corresponding ERC-1155 token contract
   * @param _token      The address of the ERC-1155 token contract
   * @param _currency   The address of the currency token contract
   * @param _lpFee      Fee that will go to LPs.
   * @param _instance   Instance # that allows to deploy new instances of an exchange.
   *                    This is mainly meant to be used for tokens that change their ERC-2981 support.
   */
  function tokensToExchange(address _token, address _currency, uint256 _lpFee, uint256 _instance) external view returns (address);

  /**
   * @notice Returns array of exchange instances for a given pair
   * @param _token    The address of the ERC-1155 token contract
   * @param _currency The address of the ERC-20 token contract
   */
  function getPairExchanges(address _token, address _currency) external view returns (address[] memory);
}

contract FnbswapFactory20 is IFnbswapFactory20, Ownable, IDelegatedERC1155Metadata {

  /***********************************|
  |       Events And Variables        |
  |__________________________________*/

  // tokensToExchange[erc1155_token_address][currency_address][lp_fee][instance]
  mapping(address => mapping(address => mapping(uint256 => mapping(uint256 => address)))) public override tokensToExchange;
  mapping(address => mapping(address => address[])) internal pairExchanges;
  mapping(address => mapping(address => mapping(uint256 => uint256))) public tokenTolastIntance;

  // Metadata implementation
  IERC1155Metadata internal metadataContract; // address of the ERC-1155 Metadata contract

  /**
   * @notice Will set the initial Fnbswap admin
   * @param _admin Address of the initial niftyswap admin to set as Owner
   */
  constructor(address _admin) Ownable(_admin) {}

  /***********************************|
  |             Functions             |
  |__________________________________*/
  /**
   * @notice Creates a FnbSwap Exchange for given token contract
   * @param _token    The address of the ERC-1155 token contract
   * @param _currency The address of the ERC-20 token contract
   * @param _lpFee    Fee that will go to LPs.
   *                  Number between 0 and 1000, where 10 is 1.0% and 100 is 10%.
   */
  function createExchange(address _token, address _currency, uint256 _lpFee) public override {
    //define instance id
    uint256 _newInstance = tokenTolastIntance[_token][_currency][_lpFee];

    if(_newInstance > 0) {
      require(tokensToExchange[_token][_currency][_lpFee][_newInstance - 1] == address(0x0), "NF20#1"); // FnbswapFactory20#createExchange: EXCHANGE_ALREADY_CREATED
    }

    // Create new exchange contract
    FnbswapExchange20 exchange = new FnbswapExchange20(_token, _currency, _lpFee);

    // Store exchange and token addresses
    tokensToExchange[_token][_currency][_lpFee][_newInstance] = address(exchange);
    tokenTolastIntance[_token][_currency][_lpFee] = _newInstance + 1;
    pairExchanges[_token][_currency].push(address(exchange));

    // Emit event
    emit NewExchange(_token, _currency, _newInstance, _lpFee, address(exchange));
  }

  /**
   * @notice Returns array of exchange instances for a given pair
   * @param _token    The address of the ERC-1155 token contract
   * @param _currency The address of the ERC-20 token contract
   */
  function getPairExchanges(address _token, address _currency) public override view returns (address[] memory) {
    return pairExchanges[_token][_currency];
  }

  /***********************************|
  |        Metadata Functions         |
  |__________________________________*/

  /**
   * @notice Changes the implementation of the ERC-1155 Metadata contract
   * @dev This function changes the implementation for all child exchanges of the factory
   * @param _contract The address of the ERC-1155 Metadata contract
   */
  function setMetadataContract(IERC1155Metadata _contract) onlyOwner external {
    emit MetadataContractChanged(address(_contract));
    metadataContract = _contract;
  }

  /**
   * @notice Returns the address of the ERC-1155 Metadata contract
   */
  function metadataProvider() external override view returns (IERC1155Metadata) {
    return metadataContract;
  }
}