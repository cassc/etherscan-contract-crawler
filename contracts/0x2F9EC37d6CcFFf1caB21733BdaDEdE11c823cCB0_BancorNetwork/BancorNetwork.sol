/**
 *Submitted for verification at Etherscan.io on 2020-06-18
*/

// File: contracts/token/interfaces/IERC20Token.sol

pragma solidity 0.4.26;

/*
    ERC20 Standard Token interface
*/
contract IERC20Token {
    // these functions aren't abstract since the compiler emits automatically generated getter functions as external
    function name() public view returns (string) {this;}
    function symbol() public view returns (string) {this;}
    function decimals() public view returns (uint8) {this;}
    function totalSupply() public view returns (uint256) {this;}
    function balanceOf(address _owner) public view returns (uint256) {_owner; this;}
    function allowance(address _owner, address _spender) public view returns (uint256) {_owner; _spender; this;}

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

// File: contracts/IBancorNetwork.sol

pragma solidity 0.4.26;


/*
    Bancor Network interface
*/
contract IBancorNetwork {
    function convert2(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _affiliateAccount,
        uint256 _affiliateFee
    ) public payable returns (uint256);

    function claimAndConvert2(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _affiliateAccount,
        uint256 _affiliateFee
    ) public returns (uint256);

    function convertFor2(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for,
        address _affiliateAccount,
        uint256 _affiliateFee
    ) public payable returns (uint256);

    function claimAndConvertFor2(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for,
        address _affiliateAccount,
        uint256 _affiliateFee
    ) public returns (uint256);

    // deprecated, backward compatibility
    function convert(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn
    ) public payable returns (uint256);

    // deprecated, backward compatibility
    function claimAndConvert(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn
    ) public returns (uint256);

    // deprecated, backward compatibility
    function convertFor(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for
    ) public payable returns (uint256);

    // deprecated, backward compatibility
    function claimAndConvertFor(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for
    ) public returns (uint256);
}

// File: contracts/IConversionPathFinder.sol

pragma solidity 0.4.26;


/*
    Conversion Path Finder interface
*/
contract IConversionPathFinder {
    function findPath(address _sourceToken, address _targetToken) public view returns (address[] memory);
}

// File: contracts/utility/interfaces/IOwned.sol

pragma solidity 0.4.26;

/*
    Owned contract interface
*/
contract IOwned {
    // this function isn't abstract since the compiler emits automatically generated getter functions as external
    function owner() public view returns (address) {this;}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

// File: contracts/utility/interfaces/ITokenHolder.sol

pragma solidity 0.4.26;



/*
    Token Holder interface
*/
contract ITokenHolder is IOwned {
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) public;
}

// File: contracts/converter/interfaces/IConverterAnchor.sol

pragma solidity 0.4.26;



/*
    Converter Anchor interface
*/
contract IConverterAnchor is IOwned, ITokenHolder {
}

// File: contracts/utility/interfaces/IWhitelist.sol

pragma solidity 0.4.26;

/*
    Whitelist interface
*/
contract IWhitelist {
    function isWhitelisted(address _address) public view returns (bool);
}

// File: contracts/converter/interfaces/IConverter.sol

pragma solidity 0.4.26;





/*
    Converter interface
*/
contract IConverter is IOwned {
    function converterType() public pure returns (uint16);
    function anchor() public view returns (IConverterAnchor) {this;}
    function isActive() public view returns (bool);

    function rateAndFee(IERC20Token _sourceToken, IERC20Token _targetToken, uint256 _amount) public view returns (uint256, uint256);
    function convert(IERC20Token _sourceToken,
                     IERC20Token _targetToken,
                     uint256 _amount,
                     address _trader,
                     address _beneficiary) public payable returns (uint256);

    function conversionWhitelist() public view returns (IWhitelist) {this;}
    function conversionFee() public view returns (uint32) {this;}
    function maxConversionFee() public view returns (uint32) {this;}
    function reserveBalance(IERC20Token _reserveToken) public view returns (uint256);
    function() external payable;

    function transferAnchorOwnership(address _newOwner) public;
    function acceptAnchorOwnership() public;
    function setConversionFee(uint32 _conversionFee) public;
    function setConversionWhitelist(IWhitelist _whitelist) public;
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) public;
    function withdrawETH(address _to) public;
    function addReserve(IERC20Token _token, uint32 _ratio) public;

    // deprecated, backward compatibility
    function token() public view returns (IConverterAnchor);
    function transferTokenOwnership(address _newOwner) public;
    function acceptTokenOwnership() public;
    function connectors(address _address) public view returns (uint256, uint32, bool, bool, bool);
    function getConnectorBalance(IERC20Token _connectorToken) public view returns (uint256);
    function connectorTokens(uint256 _index) public view returns (IERC20Token);
    function connectorTokenCount() public view returns (uint16);
}

// File: contracts/converter/interfaces/IBancorFormula.sol

pragma solidity 0.4.26;

/*
    Bancor Formula interface
*/
contract IBancorFormula {
    function purchaseRate(uint256 _supply,
                          uint256 _reserveBalance,
                          uint32 _reserveWeight,
                          uint256 _amount)
                          public view returns (uint256);

    function saleRate(uint256 _supply,
                      uint256 _reserveBalance,
                      uint32 _reserveWeight,
                      uint256 _amount)
                      public view returns (uint256);

    function crossReserveRate(uint256 _sourceReserveBalance,
                              uint32 _sourceReserveWeight,
                              uint256 _targetReserveBalance,
                              uint32 _targetReserveWeight,
                              uint256 _amount)
                              public view returns (uint256);

    function fundCost(uint256 _supply,
                      uint256 _reserveBalance,
                      uint32 _reserveRatio,
                      uint256 _amount)
                      public view returns (uint256);

    function liquidateRate(uint256 _supply,
                           uint256 _reserveBalance,
                           uint32 _reserveRatio,
                           uint256 _amount)
                           public view returns (uint256);
}

// File: contracts/utility/Owned.sol

pragma solidity 0.4.26;


/**
  * @dev Provides support and utilities for contract ownership
*/
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    /**
      * @dev triggered when the owner is updated
      *
      * @param _prevOwner previous owner
      * @param _newOwner  new owner
    */
    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

    /**
      * @dev initializes a new Owned instance
    */
    constructor() public {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        _ownerOnly();
        _;
    }

    // error message binary size optimization
    function _ownerOnly() internal view {
        require(msg.sender == owner, "ERR_ACCESS_DENIED");
    }

    /**
      * @dev allows transferring the contract ownership
      * the new owner still needs to accept the transfer
      * can only be called by the contract owner
      *
      * @param _newOwner    new contract owner
    */
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner, "ERR_SAME_OWNER");
        newOwner = _newOwner;
    }

    /**
      * @dev used by a new owner to accept an ownership transfer
    */
    function acceptOwnership() public {
        require(msg.sender == newOwner, "ERR_ACCESS_DENIED");
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// File: contracts/utility/Utils.sol

pragma solidity 0.4.26;

/**
  * @dev Utilities & Common Modifiers
*/
contract Utils {
    // verifies that a value is greater than zero
    modifier greaterThanZero(uint256 _value) {
        _greaterThanZero(_value);
        _;
    }

    // error message binary size optimization
    function _greaterThanZero(uint256 _value) internal pure {
        require(_value > 0, "ERR_ZERO_VALUE");
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        _validAddress(_address);
        _;
    }

    // error message binary size optimization
    function _validAddress(address _address) internal pure {
        require(_address != address(0), "ERR_INVALID_ADDRESS");
    }

    // verifies that the address is different than this contract address
    modifier notThis(address _address) {
        _notThis(_address);
        _;
    }

    // error message binary size optimization
    function _notThis(address _address) internal view {
        require(_address != address(this), "ERR_ADDRESS_IS_SELF");
    }
}

// File: contracts/utility/interfaces/IContractRegistry.sol

pragma solidity 0.4.26;

/*
    Contract Registry interface
*/
contract IContractRegistry {
    function addressOf(bytes32 _contractName) public view returns (address);

    // deprecated, backward compatibility
    function getAddress(bytes32 _contractName) public view returns (address);
}

// File: contracts/utility/ContractRegistryClient.sol

pragma solidity 0.4.26;




/**
  * @dev Base contract for ContractRegistry clients
*/
contract ContractRegistryClient is Owned, Utils {
    bytes32 internal constant CONTRACT_REGISTRY = "ContractRegistry";
    bytes32 internal constant BANCOR_NETWORK = "BancorNetwork";
    bytes32 internal constant BANCOR_FORMULA = "BancorFormula";
    bytes32 internal constant CONVERTER_FACTORY = "ConverterFactory";
    bytes32 internal constant CONVERSION_PATH_FINDER = "ConversionPathFinder";
    bytes32 internal constant CONVERTER_UPGRADER = "BancorConverterUpgrader";
    bytes32 internal constant CONVERTER_REGISTRY = "BancorConverterRegistry";
    bytes32 internal constant CONVERTER_REGISTRY_DATA = "BancorConverterRegistryData";
    bytes32 internal constant BNT_TOKEN = "BNTToken";
    bytes32 internal constant BANCOR_X = "BancorX";
    bytes32 internal constant BANCOR_X_UPGRADER = "BancorXUpgrader";

    IContractRegistry public registry;      // address of the current contract-registry
    IContractRegistry public prevRegistry;  // address of the previous contract-registry
    bool public onlyOwnerCanUpdateRegistry; // only an owner can update the contract-registry

    /**
      * @dev verifies that the caller is mapped to the given contract name
      *
      * @param _contractName    contract name
    */
    modifier only(bytes32 _contractName) {
        _only(_contractName);
        _;
    }

    // error message binary size optimization
    function _only(bytes32 _contractName) internal view {
        require(msg.sender == addressOf(_contractName), "ERR_ACCESS_DENIED");
    }

    /**
      * @dev initializes a new ContractRegistryClient instance
      *
      * @param  _registry   address of a contract-registry contract
    */
    constructor(IContractRegistry _registry) internal validAddress(_registry) {
        registry = IContractRegistry(_registry);
        prevRegistry = IContractRegistry(_registry);
    }

    /**
      * @dev updates to the new contract-registry
     */
    function updateRegistry() public {
        // verify that this function is permitted
        require(msg.sender == owner || !onlyOwnerCanUpdateRegistry, "ERR_ACCESS_DENIED");

        // get the new contract-registry
        IContractRegistry newRegistry = IContractRegistry(addressOf(CONTRACT_REGISTRY));

        // verify that the new contract-registry is different and not zero
        require(newRegistry != address(registry) && newRegistry != address(0), "ERR_INVALID_REGISTRY");

        // verify that the new contract-registry is pointing to a non-zero contract-registry
        require(newRegistry.addressOf(CONTRACT_REGISTRY) != address(0), "ERR_INVALID_REGISTRY");

        // save a backup of the current contract-registry before replacing it
        prevRegistry = registry;

        // replace the current contract-registry with the new contract-registry
        registry = newRegistry;
    }

    /**
      * @dev restores the previous contract-registry
    */
    function restoreRegistry() public ownerOnly {
        // restore the previous contract-registry
        registry = prevRegistry;
    }

    /**
      * @dev restricts the permission to update the contract-registry
      *
      * @param _onlyOwnerCanUpdateRegistry  indicates whether or not permission is restricted to owner only
    */
    function restrictRegistryUpdate(bool _onlyOwnerCanUpdateRegistry) public ownerOnly {
        // change the permission to update the contract-registry
        onlyOwnerCanUpdateRegistry = _onlyOwnerCanUpdateRegistry;
    }

    /**
      * @dev returns the address associated with the given contract name
      *
      * @param _contractName    contract name
      *
      * @return contract address
    */
    function addressOf(bytes32 _contractName) internal view returns (address) {
        return registry.addressOf(_contractName);
    }
}

// File: contracts/utility/ReentrancyGuard.sol

pragma solidity 0.4.26;

/**
  * @dev ReentrancyGuard
  *
  * The contract provides protection against re-entrancy - calling a function (directly or
  * indirectly) from within itself.
*/
contract ReentrancyGuard {
    // true while protected code is being executed, false otherwise
    bool private locked = false;

    /**
      * @dev ensures instantiation only by sub-contracts
    */
    constructor() internal {}

    // protects a function against reentrancy attacks
    modifier protected() {
        _protected();
        locked = true;
        _;
        locked = false;
    }

    // error message binary size optimization
    function _protected() internal view {
        require(!locked, "ERR_REENTRANCY");
    }
}

// File: contracts/utility/TokenHandler.sol

pragma solidity 0.4.26;


contract TokenHandler {
    bytes4 private constant APPROVE_FUNC_SELECTOR = bytes4(keccak256("approve(address,uint256)"));
    bytes4 private constant TRANSFER_FUNC_SELECTOR = bytes4(keccak256("transfer(address,uint256)"));
    bytes4 private constant TRANSFER_FROM_FUNC_SELECTOR = bytes4(keccak256("transferFrom(address,address,uint256)"));

    /**
      * @dev executes the ERC20 token's `approve` function and reverts upon failure
      * the main purpose of this function is to prevent a non standard ERC20 token
      * from failing silently
      *
      * @param _token   ERC20 token address
      * @param _spender approved address
      * @param _value   allowance amount
    */
    function safeApprove(IERC20Token _token, address _spender, uint256 _value) internal {
       execute(_token, abi.encodeWithSelector(APPROVE_FUNC_SELECTOR, _spender, _value));
    }

    /**
      * @dev executes the ERC20 token's `transfer` function and reverts upon failure
      * the main purpose of this function is to prevent a non standard ERC20 token
      * from failing silently
      *
      * @param _token   ERC20 token address
      * @param _to      target address
      * @param _value   transfer amount
    */
    function safeTransfer(IERC20Token _token, address _to, uint256 _value) internal {
       execute(_token, abi.encodeWithSelector(TRANSFER_FUNC_SELECTOR, _to, _value));
    }

    /**
      * @dev executes the ERC20 token's `transferFrom` function and reverts upon failure
      * the main purpose of this function is to prevent a non standard ERC20 token
      * from failing silently
      *
      * @param _token   ERC20 token address
      * @param _from    source address
      * @param _to      target address
      * @param _value   transfer amount
    */
    function safeTransferFrom(IERC20Token _token, address _from, address _to, uint256 _value) internal {
       execute(_token, abi.encodeWithSelector(TRANSFER_FROM_FUNC_SELECTOR, _from, _to, _value));
    }

    /**
      * @dev executes a function on the ERC20 token and reverts upon failure
      * the main purpose of this function is to prevent a non standard ERC20 token
      * from failing silently
      *
      * @param _token   ERC20 token address
      * @param _data    data to pass in to the token's contract for execution
    */
    function execute(IERC20Token _token, bytes memory _data) private {
        uint256[1] memory ret = [uint256(1)];

        assembly {
            let success := call(
                gas,            // gas remaining
                _token,         // destination address
                0,              // no ether
                add(_data, 32), // input buffer (starts after the first 32 bytes in the `data` array)
                mload(_data),   // input length (loaded from the first 32 bytes in the `data` array)
                ret,            // output buffer
                32              // output length
            )
            if iszero(success) {
                revert(0, 0)
            }
        }

        require(ret[0] != 0, "ERR_TRANSFER_FAILED");
    }
}

// File: contracts/utility/TokenHolder.sol

pragma solidity 0.4.26;






/**
  * @dev We consider every contract to be a 'token holder' since it's currently not possible
  * for a contract to deny receiving tokens.
  *
  * The TokenHolder's contract sole purpose is to provide a safety mechanism that allows
  * the owner to send tokens that were sent to the contract by mistake back to their sender.
  *
  * Note that we use the non standard ERC-20 interface which has no return value for transfer
  * in order to support both non standard as well as standard token contracts.
  * see https://github.com/ethereum/solidity/issues/4116
*/
contract TokenHolder is ITokenHolder, TokenHandler, Owned, Utils {
    /**
      * @dev withdraws tokens held by the contract and sends them to an account
      * can only be called by the owner
      *
      * @param _token   ERC20 token contract address
      * @param _to      account to receive the new amount
      * @param _amount  amount to withdraw
    */
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount)
        public
        ownerOnly
        validAddress(_token)
        validAddress(_to)
        notThis(_to)
    {
        safeTransfer(_token, _to, _amount);
    }
}

// File: contracts/utility/SafeMath.sol

pragma solidity 0.4.26;

/**
  * @dev Library for basic math operations with overflow/underflow protection
*/
library SafeMath {
    /**
      * @dev returns the sum of _x and _y, reverts if the calculation overflows
      *
      * @param _x   value 1
      * @param _y   value 2
      *
      * @return sum
    */
    function add(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        require(z >= _x, "ERR_OVERFLOW");
        return z;
    }

    /**
      * @dev returns the difference of _x minus _y, reverts if the calculation underflows
      *
      * @param _x   minuend
      * @param _y   subtrahend
      *
      * @return difference
    */
    function sub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        require(_x >= _y, "ERR_UNDERFLOW");
        return _x - _y;
    }

    /**
      * @dev returns the product of multiplying _x by _y, reverts if the calculation overflows
      *
      * @param _x   factor 1
      * @param _y   factor 2
      *
      * @return product
    */
    function mul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        // gas optimization
        if (_x == 0)
            return 0;

        uint256 z = _x * _y;
        require(z / _x == _y, "ERR_OVERFLOW");
        return z;
    }

    /**
      * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
      *
      * @param _x   dividend
      * @param _y   divisor
      *
      * @return quotient
    */
    function div(uint256 _x, uint256 _y) internal pure returns (uint256) {
        require(_y > 0, "ERR_DIVIDE_BY_ZERO");
        uint256 c = _x / _y;
        return c;
    }
}

// File: contracts/token/interfaces/IEtherToken.sol

pragma solidity 0.4.26;


/*
    Ether Token interface
*/
contract IEtherToken is IERC20Token {
    function deposit() public payable;
    function withdraw(uint256 _amount) public;
    function depositTo(address _to) public payable;
    function withdrawTo(address _to, uint256 _amount) public;
}

// File: contracts/token/interfaces/ISmartToken.sol

pragma solidity 0.4.26;




/*
    Smart Token interface
*/
contract ISmartToken is IConverterAnchor, IERC20Token {
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}

// File: contracts/bancorx/interfaces/IBancorX.sol

pragma solidity 0.4.26;


contract IBancorX {
    function token() public view returns (IERC20Token) {this;}
    function xTransfer(bytes32 _toBlockchain, bytes32 _to, uint256 _amount, uint256 _id) public;
    function getXTransferAmount(uint256 _xTransferId, address _for) public view returns (uint256);
}

// File: contracts/BancorNetwork.sol

pragma solidity 0.4.26;













// interface of older converters for backward compatibility
contract ILegacyConverter {
    function change(IERC20Token _sourceToken, IERC20Token _targetToken, uint256 _amount, uint256 _minReturn) public returns (uint256);
}

/**
  * @dev The BancorNetwork contract is the main entry point for Bancor token conversions.
  * It also allows for the conversion of any token in the Bancor Network to any other token in a single
  * transaction by providing a conversion path.
  *
  * A note on Conversion Path: Conversion path is a data structure that is used when converting a token
  * to another token in the Bancor Network, when the conversion cannot necessarily be done by a single
  * converter and might require multiple 'hops'.
  * The path defines which converters should be used and what kind of conversion should be done in each step.
  *
  * The path format doesn't include complex structure; instead, it is represented by a single array
  * in which each 'hop' is represented by a 2-tuple - converter anchor & target token.
  * In addition, the first element is always the source token.
  * The converter anchor is only used as a pointer to a converter (since converter addresses are more
  * likely to change as opposed to anchor addresses).
  *
  * Format:
  * [source token, converter anchor, target token, converter anchor, target token...]
*/
contract BancorNetwork is IBancorNetwork, TokenHolder, ContractRegistryClient, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 private constant CONVERSION_FEE_RESOLUTION = 1000000;
    uint256 private constant AFFILIATE_FEE_RESOLUTION = 1000000;
    address private constant ETH_RESERVE_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    struct ConversionStep {
        IConverter converter;
        IConverterAnchor anchor;
        IERC20Token sourceToken;
        IERC20Token targetToken;
        address beneficiary;
        bool isV28OrHigherConverter;
        bool processAffiliateFee;
    }

    uint256 public maxAffiliateFee = 30000;     // maximum affiliate-fee

    mapping (address => bool) public etherTokens;       // list of all supported ether tokens

    /**
      * @dev triggered when a conversion between two tokens occurs
      *
      * @param _smartToken  anchor governed by the converter
      * @param _fromToken   source ERC20 token
      * @param _toToken     target ERC20 token
      * @param _fromAmount  amount converted, in the source token
      * @param _toAmount    amount returned, minus conversion fee
      * @param _trader      wallet that initiated the trade
    */
    event Conversion(
        address indexed _smartToken,
        address indexed _fromToken,
        address indexed _toToken,
        uint256 _fromAmount,
        uint256 _toAmount,
        address _trader
    );

    /**
      * @dev initializes a new BancorNetwork instance
      *
      * @param _registry    address of a contract registry contract
    */
    constructor(IContractRegistry _registry) ContractRegistryClient(_registry) public {
        etherTokens[ETH_RESERVE_ADDRESS] = true;
    }

    /**
      * @dev allows the owner to update the maximum affiliate-fee
      *
      * @param _maxAffiliateFee   maximum affiliate-fee
    */
    function setMaxAffiliateFee(uint256 _maxAffiliateFee)
        public
        ownerOnly
    {
        require(_maxAffiliateFee <= AFFILIATE_FEE_RESOLUTION, "ERR_INVALID_AFFILIATE_FEE");
        maxAffiliateFee = _maxAffiliateFee;
    }

    /**
      * @dev allows the owner to register/unregister ether tokens
      *
      * @param _token       ether token contract address
      * @param _register    true to register, false to unregister
    */
    function registerEtherToken(IEtherToken _token, bool _register)
        public
        ownerOnly
        validAddress(_token)
        notThis(_token)
    {
        etherTokens[_token] = _register;
    }

    /**
      * @dev returns the conversion path between two tokens in the network
      * note that this method is quite expensive in terms of gas and should generally be called off-chain
      *
      * @param _sourceToken source token address
      * @param _targetToken target token address
      *
      * @return conversion path between the two tokens
    */
    function conversionPath(IERC20Token _sourceToken, IERC20Token _targetToken) public view returns (address[]) {
        IConversionPathFinder pathFinder = IConversionPathFinder(addressOf(CONVERSION_PATH_FINDER));
        return pathFinder.findPath(_sourceToken, _targetToken);
    }

    /**
      * @dev returns the expected rate of converting a given amount on a given path
      * note that there is no support for circular paths
      *
      * @param _path        conversion path (see conversion path format above)
      * @param _amount      amount of _path[0] tokens received from the sender
      *
      * @return expected rate
    */
    function rateByPath(IERC20Token[] _path, uint256 _amount) public view returns (uint256) {
        uint256 amount;
        uint256 fee;
        uint256 supply;
        uint256 balance;
        uint32 weight;
        IConverter converter;
        IBancorFormula formula = IBancorFormula(addressOf(BANCOR_FORMULA));

        amount = _amount;

        // verify that the number of elements is larger than 2 and odd
        require(_path.length > 2 && _path.length % 2 == 1, "ERR_INVALID_PATH");

        // iterate over the conversion path
        for (uint256 i = 2; i < _path.length; i += 2) {
            IERC20Token sourceToken = _path[i - 2];
            IERC20Token anchor = _path[i - 1];
            IERC20Token targetToken = _path[i];

            converter = IConverter(IConverterAnchor(anchor).owner());

            // backward compatibility
            sourceToken = getConverterTokenAddress(converter, sourceToken);
            targetToken = getConverterTokenAddress(converter, targetToken);

            if (targetToken == anchor) { // buy the smart token
                // check if the current smart token has changed
                if (i < 3 || anchor != _path[i - 3])
                    supply = ISmartToken(anchor).totalSupply();

                // get the amount & the conversion fee
                balance = converter.getConnectorBalance(sourceToken);
                (, weight, , , ) = converter.connectors(sourceToken);
                amount = formula.purchaseRate(supply, balance, weight, amount);
                fee = amount.mul(converter.conversionFee()).div(CONVERSION_FEE_RESOLUTION);
                amount -= fee;

                // update the smart token supply for the next iteration
                supply = supply.add(amount);
            }
            else if (sourceToken == anchor) { // sell the smart token
                // check if the current smart token has changed
                if (i < 3 || anchor != _path[i - 3])
                    supply = ISmartToken(anchor).totalSupply();

                // get the amount & the conversion fee
                balance = converter.getConnectorBalance(targetToken);
                (, weight, , , ) = converter.connectors(targetToken);
                amount = formula.saleRate(supply, balance, weight, amount);
                fee = amount.mul(converter.conversionFee()).div(CONVERSION_FEE_RESOLUTION);
                amount -= fee;

                // update the smart token supply for the next iteration
                supply = supply.sub(amount);
            }
            else { // cross reserve conversion
                (amount, fee) = getReturn(converter, sourceToken, targetToken, amount);
            }
        }

        return amount;
    }

    /**
      * @dev converts the token to any other token in the bancor network by following
      * a predefined conversion path and transfers the result tokens to a target account
      * affiliate account/fee can also be passed in to receive a conversion fee (on top of the liquidity provider fees)
      * note that the network should already have been given allowance of the source token (if not ETH)
      *
      * @param _path                conversion path, see conversion path format above
      * @param _amount              amount to convert from, in the source token
      * @param _minReturn           if the conversion results in an amount smaller than the minimum return - it is cancelled, must be greater than zero
      * @param _beneficiary         account that will receive the conversion result or 0x0 to send the result to the sender account
      * @param _affiliateAccount    wallet address to receive the affiliate fee or 0x0 to disable affiliate fee
      * @param _affiliateFee        affiliate fee in PPM or 0 to disable affiliate fee
      *
      * @return amount of tokens received from the conversion
    */
    function convertByPath(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, address _beneficiary, address _affiliateAccount, uint256 _affiliateFee)
        public
        payable
        protected
        greaterThanZero(_minReturn)
        returns (uint256)
    {
        // verify that the path contrains at least a single 'hop' and that the number of elements is odd
        require(_path.length > 2 && _path.length % 2 == 1, "ERR_INVALID_PATH");

        // validate msg.value and prepare the source token for the conversion
        handleSourceToken(_path[0], IConverterAnchor(_path[1]), _amount);

        // check if affiliate fee is enabled
        bool affiliateFeeEnabled = false;
        if (address(_affiliateAccount) == 0) {
            require(_affiliateFee == 0, "ERR_INVALID_AFFILIATE_FEE");
        }
        else {
            require(0 < _affiliateFee && _affiliateFee <= maxAffiliateFee, "ERR_INVALID_AFFILIATE_FEE");
            affiliateFeeEnabled = true;
        }

        // check if beneficiary is set
        address beneficiary = msg.sender;
        if (_beneficiary != address(0))
            beneficiary = _beneficiary;

        // convert and get the resulting amount
        ConversionStep[] memory data = createConversionData(_path, beneficiary, affiliateFeeEnabled);
        uint256 amount = doConversion(data, _amount, _minReturn, _affiliateAccount, _affiliateFee);

        // handle the conversion target tokens
        handleTargetToken(data, amount, beneficiary);

        return amount;
    }

    /**
      * @dev converts any other token to BNT in the bancor network by following
      a predefined conversion path and transfers the result to an account on a different blockchain
      * note that the network should already have been given allowance of the source token (if not ETH)
      *
      * @param _path                conversion path, see conversion path format above
      * @param _amount              amount to convert from, in the source token
      * @param _minReturn           if the conversion results in an amount smaller than the minimum return - it is cancelled, must be greater than zero
      * @param _targetBlockchain    blockchain BNT will be issued on
      * @param _targetAccount       address/account on the target blockchain to send the BNT to
      * @param _conversionId        pre-determined unique (if non zero) id which refers to this transaction
      *
      * @return the amount of BNT received from this conversion
    */
    function xConvert(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        bytes32 _targetBlockchain,
        bytes32 _targetAccount,
        uint256 _conversionId
    )
        public
        payable
        returns (uint256)
    {
        return xConvert2(_path, _amount, _minReturn, _targetBlockchain, _targetAccount, _conversionId, address(0), 0);
    }

    /**
      * @dev converts any other token to BNT in the bancor network by following
      a predefined conversion path and transfers the result to an account on a different blockchain
      * note that the network should already have been given allowance of the source token (if not ETH)
      *
      * @param _path                conversion path, see conversion path format above
      * @param _amount              amount to convert from, in the source token
      * @param _minReturn           if the conversion results in an amount smaller than the minimum return - it is cancelled, must be greater than zero
      * @param _targetBlockchain    blockchain BNT will be issued on
      * @param _targetAccount       address/account on the target blockchain to send the BNT to
      * @param _conversionId        pre-determined unique (if non zero) id which refers to this transaction
      * @param _affiliateAccount    affiliate account
      * @param _affiliateFee        affiliate fee in PPM
      *
      * @return the amount of BNT received from this conversion
    */
    function xConvert2(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        bytes32 _targetBlockchain,
        bytes32 _targetAccount,
        uint256 _conversionId,
        address _affiliateAccount,
        uint256 _affiliateFee
    )
        public
        payable
        greaterThanZero(_minReturn)
        returns (uint256)
    {
        IERC20Token targetToken = _path[_path.length - 1];
        IBancorX bancorX = IBancorX(addressOf(BANCOR_X));

        // verify that the destination token is BNT
        require(targetToken == addressOf(BNT_TOKEN), "ERR_INVALID_TARGET_TOKEN");

        // convert and get the resulting amount
        uint256 amount = convertByPath(_path, _amount, _minReturn, this, _affiliateAccount, _affiliateFee);

        // grant BancorX allowance
        ensureAllowance(targetToken, bancorX, amount);

        // transfer the resulting amount to BancorX
        bancorX.xTransfer(_targetBlockchain, _targetAccount, amount, _conversionId);

        return amount;
    }

    /**
      * @dev allows a user to convert a token that was sent from another blockchain into any other
      * token on the BancorNetwork
      * ideally this transaction is created before the previous conversion is even complete, so
      * so the input amount isn't known at that point - the amount is actually take from the
      * BancorX contract directly by specifying the conversion id
      *
      * @param _path            conversion path
      * @param _bancorX         address of the BancorX contract for the source token
      * @param _conversionId    pre-determined unique (if non zero) id which refers to this conversion
      * @param _minReturn       if the conversion results in an amount smaller than the minimum return - it is cancelled, must be nonzero
      * @param _beneficiary     wallet to receive the conversion result
      *
      * @return amount of tokens received from the conversion
    */
    function completeXConversion(IERC20Token[] _path, IBancorX _bancorX, uint256 _conversionId, uint256 _minReturn, address _beneficiary)
        public returns (uint256)
    {
        // verify that the source token is the BancorX token
        require(_path[0] == _bancorX.token(), "ERR_INVALID_SOURCE_TOKEN");

        // get conversion amount from BancorX contract
        uint256 amount = _bancorX.getXTransferAmount(_conversionId, msg.sender);

        // perform the conversion
        return convertByPath(_path, amount, _minReturn, _beneficiary, address(0), 0);
    }

    /**
      * @dev executes the actual conversion by following the conversion path
      *
      * @param _data                conversion data, see ConversionStep struct above
      * @param _amount              amount to convert from, in the source token
      * @param _minReturn           if the conversion results in an amount smaller than the minimum return - it is cancelled, must be greater than zero
      * @param _affiliateAccount    affiliate account
      * @param _affiliateFee        affiliate fee in PPM
      *
      * @return amount of tokens received from the conversion
    */
    function doConversion(
        ConversionStep[] _data,
        uint256 _amount,
        uint256 _minReturn,
        address _affiliateAccount,
        uint256 _affiliateFee
    ) private returns (uint256) {
        uint256 toAmount;
        uint256 fromAmount = _amount;

        // iterate over the conversion data
        for (uint256 i = 0; i < _data.length; i++) {
            ConversionStep memory stepData = _data[i];

            // newer converter
            if (stepData.isV28OrHigherConverter) {
                // transfer the tokens to the converter only if the network contract currently holds the tokens
                // not needed with ETH or if it's the first conversion step
                if (i != 0 && _data[i - 1].beneficiary == address(this) && !etherTokens[stepData.sourceToken])
                    safeTransfer(stepData.sourceToken, stepData.converter, fromAmount);
            }
            // older converter
            // if the source token is the smart token, no need to do any transfers as the converter controls it
            else if (stepData.sourceToken != ISmartToken(stepData.anchor)) {
                // grant allowance for it to transfer the tokens from the network contract
                ensureAllowance(stepData.sourceToken, stepData.converter, fromAmount);
            }

            // do the conversion
            if (!stepData.isV28OrHigherConverter)
                toAmount = ILegacyConverter(stepData.converter).change(stepData.sourceToken, stepData.targetToken, fromAmount, 1);
            else if (etherTokens[stepData.sourceToken])
                toAmount = stepData.converter.convert.value(msg.value)(stepData.sourceToken, stepData.targetToken, fromAmount, msg.sender, stepData.beneficiary);
            else
                toAmount = stepData.converter.convert(stepData.sourceToken, stepData.targetToken, fromAmount, msg.sender, stepData.beneficiary);

            // pay affiliate-fee if needed
            if (stepData.processAffiliateFee) {
                uint256 affiliateAmount = toAmount.mul(_affiliateFee).div(AFFILIATE_FEE_RESOLUTION);
                require(stepData.targetToken.transfer(_affiliateAccount, affiliateAmount), "ERR_FEE_TRANSFER_FAILED");
                toAmount -= affiliateAmount;
            }

            emit Conversion(stepData.anchor, stepData.sourceToken, stepData.targetToken, fromAmount, toAmount, msg.sender);
            fromAmount = toAmount;
        }

        // ensure the trade meets the minimum requested amount
        require(toAmount >= _minReturn, "ERR_RETURN_TOO_LOW");

        return toAmount;
    }

    /**
      * @dev validates msg.value and prepares the conversion source token for the conversion
      *
      * @param _sourceToken source token of the first conversion step
      * @param _anchor      converter anchor of the first conversion step
      * @param _amount      amount to convert from, in the source token
    */
    function handleSourceToken(IERC20Token _sourceToken, IConverterAnchor _anchor, uint256 _amount) private {
        IConverter firstConverter = IConverter(_anchor.owner());
        bool isNewerConverter = isV28OrHigherConverter(firstConverter);

        // ETH
        if (msg.value > 0) {
            // validate msg.value
            require(msg.value == _amount, "ERR_ETH_AMOUNT_MISMATCH");

            // EtherToken converter - deposit the ETH into the EtherToken
            // note that it can still be a non ETH converter if the path is wrong
            // but such conversion will simply revert
            if (!isNewerConverter)
                IEtherToken(getConverterEtherTokenAddress(firstConverter)).deposit.value(msg.value)();
        }
        // EtherToken
        else if (etherTokens[_sourceToken]) {
            // claim the tokens - if the source token is ETH reserve, this call will fail
            // since in that case the transaction must be sent with msg.value
            safeTransferFrom(_sourceToken, msg.sender, this, _amount);

            // ETH converter - withdraw the ETH
            if (isNewerConverter)
                IEtherToken(_sourceToken).withdraw(_amount);
        }
        // other ERC20 token
        else {
            // newer converter - transfer the tokens from the sender directly to the converter
            // otherwise claim the tokens
            if (isNewerConverter)
                safeTransferFrom(_sourceToken, msg.sender, firstConverter, _amount);
            else
                safeTransferFrom(_sourceToken, msg.sender, this, _amount);
        }
    }

    /**
      * @dev handles the conversion target token if the network still holds it at the end of the conversion
      *
      * @param _data        conversion data, see ConversionStep struct above
      * @param _amount      conversion return amount, in the target token
      * @param _beneficiary wallet to receive the conversion result
    */
    function handleTargetToken(ConversionStep[] _data, uint256 _amount, address _beneficiary) private {
        ConversionStep memory stepData = _data[_data.length - 1];

        // network contract doesn't hold the tokens, do nothing
        if (stepData.beneficiary != address(this))
            return;

        IERC20Token targetToken = stepData.targetToken;

        // ETH / EtherToken
        if (etherTokens[targetToken]) {
            // newer converter should send ETH directly to the beneficiary
            assert(!stepData.isV28OrHigherConverter);

            // EtherToken converter - withdraw the ETH and transfer to the beneficiary
            IEtherToken(targetToken).withdrawTo(_beneficiary, _amount);
        }
        // other ERC20 token
        else {
            safeTransfer(targetToken, _beneficiary, _amount);
        }
    }

    /**
      * @dev creates a memory cache of all conversion steps data to minimize logic and external calls during conversions
      *
      * @param _conversionPath      conversion path, see conversion path format above
      * @param _beneficiary         wallet to receive the conversion result
      * @param _affiliateFeeEnabled true if affiliate fee was requested by the sender, false if not
      *
      * @return cached conversion data to be ingested later on by the conversion flow
    */
    function createConversionData(IERC20Token[] _conversionPath, address _beneficiary, bool _affiliateFeeEnabled) private view returns (ConversionStep[]) {
        ConversionStep[] memory data = new ConversionStep[](_conversionPath.length / 2);

        bool affiliateFeeProcessed = false;
        address bntToken = addressOf(BNT_TOKEN);
        // iterate the conversion path and create the conversion data for each step
        uint256 i;
        for (i = 0; i < _conversionPath.length - 1; i += 2) {
            IConverterAnchor anchor = IConverterAnchor(_conversionPath[i + 1]);
            IConverter converter = IConverter(anchor.owner());
            IERC20Token targetToken = _conversionPath[i + 2];

            // check if the affiliate fee should be processed in this step
            bool processAffiliateFee = _affiliateFeeEnabled && !affiliateFeeProcessed && targetToken == bntToken;
            if (processAffiliateFee)
                affiliateFeeProcessed = true;

            data[i / 2] = ConversionStep({
                // set the converter anchor
                anchor: anchor,

                // set the converter
                converter: converter,

                // set the source/target tokens
                sourceToken: _conversionPath[i],
                targetToken: targetToken,

                // requires knowledge about the next step, so initialize in the next phase
                beneficiary: address(0),

                // set flags
                isV28OrHigherConverter: isV28OrHigherConverter(converter),
                processAffiliateFee: processAffiliateFee
            });
        }

        // ETH support
        // source is ETH
        ConversionStep memory stepData = data[0];
        if (etherTokens[stepData.sourceToken]) {
            // newer converter - replace the source token address with ETH reserve address
            if (stepData.isV28OrHigherConverter)
                stepData.sourceToken = IERC20Token(ETH_RESERVE_ADDRESS);
            // older converter - replace the source token with the EtherToken address used by the converter
            else
                stepData.sourceToken = IERC20Token(getConverterEtherTokenAddress(stepData.converter));
        }

        // target is ETH
        stepData = data[data.length - 1];
        if (etherTokens[stepData.targetToken]) {
            // newer converter - replace the target token address with ETH reserve address
            if (stepData.isV28OrHigherConverter)
                stepData.targetToken = IERC20Token(ETH_RESERVE_ADDRESS);
            // older converter - replace the target token with the EtherToken address used by the converter
            else
                stepData.targetToken = IERC20Token(getConverterEtherTokenAddress(stepData.converter));
        }

        // set the beneficiary for each step
        for (i = 0; i < data.length; i++) {
            stepData = data[i];

            // first check if the converter in this step is newer as older converters don't even support the beneficiary argument
            if (stepData.isV28OrHigherConverter) {
                // if affiliate fee is processed in this step, beneficiary is the network contract
                if (stepData.processAffiliateFee)
                    stepData.beneficiary = this;
                // if it's the last step, beneficiary is the final beneficiary
                else if (i == data.length - 1)
                    stepData.beneficiary = _beneficiary;
                // if the converter in the next step is newer, beneficiary is the next converter
                else if (data[i + 1].isV28OrHigherConverter)
                    stepData.beneficiary = data[i + 1].converter;
                // the converter in the next step is older, beneficiary is the network contract
                else
                    stepData.beneficiary = this;
            }
            else {
                // converter in this step is older, beneficiary is the network contract
                stepData.beneficiary = this;
            }
        }

        return data;
    }

    /**
      * @dev utility, checks whether allowance for the given spender exists and approves one if it doesn't.
      * Note that we use the non standard erc-20 interface in which `approve` has no return value so that
      * this function will work for both standard and non standard tokens
      *
      * @param _token   token to check the allowance in
      * @param _spender approved address
      * @param _value   allowance amount
    */
    function ensureAllowance(IERC20Token _token, address _spender, uint256 _value) private {
        uint256 allowance = _token.allowance(this, _spender);
        if (allowance < _value) {
            if (allowance > 0)
                safeApprove(_token, _spender, 0);
            safeApprove(_token, _spender, _value);
        }
    }

    // legacy - returns the address of an EtherToken used by the converter
    function getConverterEtherTokenAddress(IConverter _converter) private view returns (address) {
        uint256 reserveCount = _converter.connectorTokenCount();
        for (uint256 i = 0; i < reserveCount; i++) {
            address reserveTokenAddress = _converter.connectorTokens(i);
            if (etherTokens[reserveTokenAddress])
                return reserveTokenAddress;
        }

        return ETH_RESERVE_ADDRESS;
    }

    // legacy - if the token is an ether token, returns the ETH reserve address
    // used by the converter, otherwise returns the input token address
    function getConverterTokenAddress(IConverter _converter, IERC20Token _token) private view returns (IERC20Token) {
        if (!etherTokens[_token])
            return _token;

        if (isV28OrHigherConverter(_converter))
            return IERC20Token(ETH_RESERVE_ADDRESS);

        return IERC20Token(getConverterEtherTokenAddress(_converter));
    }

    bytes4 private constant GET_RETURN_FUNC_SELECTOR = bytes4(keccak256("getReturn(address,address,uint256)"));

    // using assembly code since older converter versions have different return values
    function getReturn(address _dest, address _sourceToken, address _targetToken, uint256 _amount) internal view returns (uint256, uint256) {
        uint256[2] memory ret;
        bytes memory data = abi.encodeWithSelector(GET_RETURN_FUNC_SELECTOR, _sourceToken, _targetToken, _amount);

        assembly {
            let success := staticcall(
                gas,           // gas remaining
                _dest,         // destination address
                add(data, 32), // input buffer (starts after the first 32 bytes in the `data` array)
                mload(data),   // input length (loaded from the first 32 bytes in the `data` array)
                ret,           // output buffer
                64             // output length
            )
            if iszero(success) {
                revert(0, 0)
            }
        }

        return (ret[0], ret[1]);
    }

    bytes4 private constant IS_V28_OR_HIGHER_FUNC_SELECTOR = bytes4(keccak256("isV28OrHigher()"));

    // using assembly code to identify converter version
    // can't rely on the version number since the function had a different signature in older converters
    function isV28OrHigherConverter(IConverter _converter) internal view returns (bool) {
        bool success;
        uint256[1] memory ret;
        bytes memory data = abi.encodeWithSelector(IS_V28_OR_HIGHER_FUNC_SELECTOR);

        assembly {
            success := staticcall(
                5000,          // isV28OrHigher consumes 190 gas, but just for extra safety
                _converter,    // destination address
                add(data, 32), // input buffer (starts after the first 32 bytes in the `data` array)
                mload(data),   // input length (loaded from the first 32 bytes in the `data` array)
                ret,           // output buffer
                32             // output length
            )
        }

        return success && ret[0] != 0;
    }

    /**
      * @dev deprecated, backward compatibility
    */
    function getReturnByPath(IERC20Token[] _path, uint256 _amount) public view returns (uint256, uint256) {
        return (rateByPath(_path, _amount), 0);
    }

    /**
      * @dev deprecated, backward compatibility
    */
    function convert(IERC20Token[] _path, uint256 _amount, uint256 _minReturn) public payable returns (uint256) {
        return convertByPath(_path, _amount, _minReturn, address(0), address(0), 0);
    }

    /**
      * @dev deprecated, backward compatibility
    */
    function convert2(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _affiliateAccount,
        uint256 _affiliateFee
    )
        public
        payable
        returns (uint256)
    {
        return convertByPath(_path, _amount, _minReturn, address(0), _affiliateAccount, _affiliateFee);
    }

    /**
      * @dev deprecated, backward compatibility
    */
    function convertFor(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, address _beneficiary) public payable returns (uint256) {
        return convertByPath(_path, _amount, _minReturn, _beneficiary, address(0), 0);
    }

    /**
      * @dev deprecated, backward compatibility
    */
    function convertFor2(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _beneficiary,
        address _affiliateAccount,
        uint256 _affiliateFee
    )
        public
        payable
        greaterThanZero(_minReturn)
        returns (uint256)
    {
        return convertByPath(_path, _amount, _minReturn, _beneficiary, _affiliateAccount, _affiliateFee);
    }

    /**
      * @dev deprecated, backward compatibility
    */
    function claimAndConvert(IERC20Token[] _path, uint256 _amount, uint256 _minReturn) public returns (uint256) {
        return convertByPath(_path, _amount, _minReturn, address(0), address(0), 0);
    }

    /**
      * @dev deprecated, backward compatibility
    */
    function claimAndConvert2(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _affiliateAccount,
        uint256 _affiliateFee
    )
        public
        returns (uint256)
    {
        return convertByPath(_path, _amount, _minReturn, address(0), _affiliateAccount, _affiliateFee);
    }

    /**
      * @dev deprecated, backward compatibility
    */
    function claimAndConvertFor(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, address _beneficiary) public returns (uint256) {
        return convertByPath(_path, _amount, _minReturn, _beneficiary, address(0), 0);
    }

    /**
      * @dev deprecated, backward compatibility
    */
    function claimAndConvertFor2(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _beneficiary,
        address _affiliateAccount,
        uint256 _affiliateFee
    )
        public
        returns (uint256)
    {
        return convertByPath(_path, _amount, _minReturn, _beneficiary, _affiliateAccount, _affiliateFee);
    }
}