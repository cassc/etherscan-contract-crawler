pragma solidity =0.6.6;

import 'SafeMath.sol';

contract Eterna {
    using SafeMath for uint;

    string public constant name = 'Eterna Token';
    string public constant symbol = '$ERN';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces; 

    uint16[] public taxes;
    address[] public taxRecipients;
    uint16 public totalTax;
    address public taxChanger;
    mapping(address => bool) public taxWhitelist;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    event TaxesChanged(uint16[], address[]);
    event TaxesSent(address indexed to, uint value);

    constructor(uint _totalSupply, address _rewardsAddress, address _airDropAddress) public {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
        taxChanger = msg.sender;
        totalTax = 0;
        taxWhitelist[msg.sender] = true;
        taxWhitelist[_rewardsAddress] = true;
        taxWhitelist[_airDropAddress] = true;
        _mint(msg.sender, _totalSupply);
    }

    function getTaxes() external view returns (uint16[] memory _taxes){
        _taxes = taxes;
    }

    function getTaxRecipients() external view returns (address[] memory _taxRecipients){
        _taxRecipients = taxRecipients;
    }

    function getTotalTax() external view returns (uint16 _total){
        _total = totalTax;
    }

    function whitelist(address[] calldata _addresses, bool _value) external{
        require(msg.sender == taxChanger, 'ERN20: FORBIDDEN');
        for(uint i = 0; i < _addresses.length; i++){
            taxWhitelist[_addresses[i]] = _value;
        }
    }

    function changeTaxes(uint16[] calldata _taxes, address[] calldata _taxRecipients) external{
        require(msg.sender == taxChanger, 'ERN20: FORBIDDEN');
        require(_taxes.length == _taxRecipients.length, 'ERN20: TAX LENGTH DOES NOT MATCH');
        taxes = _taxes;
        taxRecipients = _taxRecipients;
        emit TaxesChanged(_taxes, _taxRecipients);
        totalTax = 0;
        for(uint i = 0; i < taxes.length; i++){
            totalTax += taxes[i];
        }
        require(totalTax <= 100, "Can't set taxes over 10%");
    }


    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _tax(address from, address to, uint v) private returns (uint){

        if(taxWhitelist[to] || taxWhitelist[from]){
            require(false, "taxfree");
            return v;
        }
        uint totalTaxedAmount = v.mul(totalTax)/1000;
        uint totalSent = 0;
        for(uint i = 0; i < taxes.length; i++){
            uint value = totalTaxedAmount.mul(taxes[i])/totalTax;
            if(value >0){
                balanceOf[from] = balanceOf[from].sub(value);
                totalSent += value;
                balanceOf[taxRecipients[i]] = balanceOf[taxRecipients[i]].add(value);
                emit Transfer(from, taxRecipients[i], value);
                emit TaxesSent(taxRecipients[i], value);
            }
        }
        return v - totalSent;
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        value = _tax(from, to, value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}
