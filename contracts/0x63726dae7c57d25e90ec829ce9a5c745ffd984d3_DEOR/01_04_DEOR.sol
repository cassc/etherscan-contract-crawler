pragma solidity >=0.6.6;

import "./library/SafeMathDEOR.sol";
import "./library/Ownable.sol";
import "./interfaces/IDEOR.sol";

contract DEOR is IDEOR, Ownable {

    using SafeMathDEOR for uint256;

    mapping(address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowed;

    string private _name = "DEOR";
    string private _symbol = "DEOR";
    uint256 private _decimals = 10;
    uint256 private _totalSupply;
    uint256 private _maxSupply = 100000000 * (10**_decimals);
    bool public mintingFinished = false;
	uint256 public startTime = 1488294000;

    constructor() public {}

    receive () external payable {
        revert();
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view virtual override(IDEOR) returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) external view override(IDEOR) returns (uint256) {
        return _balances[_owner];
    }

    function transfer(address _to, uint256 _value) external override(IDEOR) returns (bool) {
        _balances[msg.sender] = _balances[msg.sender].sub(_value);
        _balances[_to] = _balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external override(IDEOR) returns (bool) {
        uint256 _allowance = _allowed[_from][msg.sender];

        _allowed[_from][msg.sender] = _allowance.sub(_value);
        _balances[_to] = _balances[_to].add(_value);
        _balances[_from] = _balances[_from].sub(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external override(IDEOR) returns (bool) {
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external view override(IDEOR) returns (uint256) {
        return _allowed[_owner][_spender];
    }


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    /**
    * Function to mint tokens
    * @param _to The address that will recieve the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
        uint256 amount = _maxSupply.sub(_totalSupply);
        if (amount > _amount) {
            amount = _amount;
        }
        else {
            mintingFinished = true;
            emit MintFinished();
        }
        _totalSupply = _totalSupply.add(amount);
        _balances[_to] = _balances[_to].add(amount);
        emit Mint(_to, _amount);
        return true;
    }

    /**
    * Function to stop minting new tokens.
    * @return True if the operation was successful.
    */
    function finishMinting() public onlyOwner returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}