// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

contract HCDT is
    UUPSUpgradeable,
    ContextUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable
{
    address public contractOwner;

    uint256 public totalSupply;
    uint256 public operationsCount;

    string public name;
    string public symbol;

    string internal invalidOperation ;
    string internal notAccepted ;
    string internal notEnoughBalance ;

    struct Operation {
        string operationSymbol; // operation symbol
        string operationName; // operation name
        string classType; // operation class type
        uint256 totalQuotes; // actual value of the operation of BRL
        string uri; // url for json attributes
    }

    mapping(string => Operation) public operations;
    mapping(string => mapping(address => uint256)) private _holders;

    bytes32 public BURNER_ROLE;
    bytes32 public MINTER_ROLE;

    event Mint(string indexed operationSymbol, string operationURI);
    event Burn(string indexed operationSymbol);

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    function initialize() public initializer {
        __Context_init();
        contractOwner = _msgSender();
        name = "Hurst Capital Digital Tokens";
        symbol = "HCDT";
        totalSupply = 0;
        operationsCount = 0;

        MINTER_ROLE = keccak256("MINTER_ROLE");
        BURNER_ROLE = keccak256("BURNER_ROLE");

        invalidOperation = "HCDT: Operation Invalid";
        notAccepted = "HCDT: Not Accepted";
        notEnoughBalance = "HCDT: Not enough balance";

        _setupRole(MINTER_ROLE, contractOwner);
        _setupRole(BURNER_ROLE, contractOwner);
        _setupRole(DEFAULT_ADMIN_ROLE, contractOwner);
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function decimals() public view virtual returns (uint8) {
        return 2;
    }

    function mint(Operation memory _operation, address _to)
        public
        virtual
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        require(!operationExist(_operation.operationSymbol), notAccepted);
        string memory operationSymbol = _operation.operationSymbol;

        _holders[operationSymbol][_to] = _operation.totalQuotes;
        operations[operationSymbol] = _operation;

        operationsCount += 1;

        emit Mint(operationSymbol, _operation.uri);

        return true;
    }

    function balanceOf(string memory _operationSymbol) public virtual view returns (uint256) {
        require(operationExist(_operationSymbol), invalidOperation);

        return _holders[_operationSymbol][_msgSender()];
    }

    function balanceOfFrom(string memory _operationSymbol, address _from) public virtual view onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
        return _holders[_operationSymbol][_from];
    }

    function transfer(string memory _operationSymbol, address _to, uint256 _amount) public {
        address _from = _msgSender();
        require(operationExist(_operationSymbol), invalidOperation);
        require(_holders[_operationSymbol][_from] >= _amount, notEnoughBalance);

        _holders[_operationSymbol][_from] -= _amount;
        _holders[_operationSymbol][_to] += _amount;
    }

    function transferFrom(string memory _operationSymbol, address _from, address _to, uint256 _amount) public onlyRole(DEFAULT_ADMIN_ROLE){
        require(operationExist(_operationSymbol), invalidOperation);
        require(_holders[_operationSymbol][_from] >= _amount, notEnoughBalance);

        _holders[_operationSymbol][_from] -= _amount;
        _holders[_operationSymbol][_to] += _amount;
    }

    function burn(string memory _operationSymbol) public onlyRole(DEFAULT_ADMIN_ROLE){
        require(operationExist(_operationSymbol), invalidOperation);

        operations[_operationSymbol].totalQuotes = 0;
        delete operations[_operationSymbol];

        operationsCount -= 1;

        emit Burn(_operationSymbol);
    }

    function burnFrom(string memory _operationSymbol, address _from, uint256 _amount) public onlyRole(DEFAULT_ADMIN_ROLE){
        require(operationExist(_operationSymbol), invalidOperation);
        require(_holders[_operationSymbol][_from] >= _amount, notEnoughBalance);

        _holders[_operationSymbol][_from] -= _amount;
        _holders[_operationSymbol][address(this)] += _amount;

        emit Burn(_operationSymbol);
    }

    function setOperationURI(string memory _operationSymbol, string memory _operationURI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _requireMinted(_operationSymbol);

        operations[_operationSymbol].uri = _operationURI;
    }

    function getOperationURI(string memory _operationSymbol)
        public
        view
        returns (string memory)
    {
        _requireMinted(_operationSymbol);

        return operations[_operationSymbol].uri;
    }

    function getOperation(string memory _operationSymbol)
        public
        view
        returns (Operation memory operation_)
    {
        require(operationExist(_operationSymbol), invalidOperation);

        return operations[_operationSymbol];
    }

    function operationExist(string memory _operationSymbol)
        public
        view
        returns (bool)
    {
        return operations[_operationSymbol].totalQuotes > 0;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // ####### INTERNAL FUNCTIONS #######
    function _requireMinted(string memory operationSymbol) internal view virtual {
        require(operationExist(operationSymbol), invalidOperation);
    }
}