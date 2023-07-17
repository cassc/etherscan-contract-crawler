/**
 *Submitted for verification at Etherscan.io on 2023-06-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract AllFather {
    string public name = "AllFather";
    string public symbol = "ALFTH";
    uint256 public totalSupply = 9 * (10 ** 9) * (10 ** 18);

    uint8 public decimals = 18;
    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public isExcludedFromAntiWhale;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Burn(address indexed from, uint256 value);
    event ChangeOwner(address _new_owner);
    event ChangeWarChest(address _new_warChest);

    // Variables
    uint8 public taxPercent = 4;
    uint8 public burnPercent = 50;
    uint8 public treasuryPercent = 50;
    uint8 public runeSmithPercent = 5;
    uint8 public whaleLimit = 4;
    uint public maxWalletToken = (totalSupply * whaleLimit) / 100; // Maximum limit of tokens that a holder can hold
    address public burnAddress;
    address public warChest;
    address public runeSmith;

    // Constructor
    constructor(address _warChest, address _runeSmith) {
        owner = address(msg.sender);
        warChest = _warChest;
        runeSmith = _runeSmith;
        balanceOf[runeSmith] = (totalSupply * runeSmithPercent) / 100;
        balanceOf[msg.sender] = totalSupply - balanceOf[runeSmith];
        burnAddress = address(0);

        isExcludedFromAntiWhale[address(this)] = true;
        isExcludedFromAntiWhale[owner] = true;
        isExcludedFromAntiWhale[warChest] = true;
        isExcludedFromAntiWhale[runeSmith] = true;
    }

    modifier antiWhale(address recipient, uint amount) {
        if (
            ( maxWalletToken > 0 &&
            recipient != address(0) )
            || isExcludedFromAntiWhale[recipient]
        ) {
            uint newBalance = balanceOf[recipient] + amount;
            require(
                newBalance <= maxWalletToken ||  isExcludedFromAntiWhale[recipient]  == true,
                "Exceeds maximum wallet token amount"
            );
        }
        _;
    }

    // Transfer function
    function transfer(
        address _to,
        uint256 _value
    ) public antiWhale(_to, _value) returns (bool success) {
        require(
            _to != address(0),
            "Transfers to the realm of emptiness, the zero address, are forbidden."
        );

        // Calculate tax
        uint256 tax = getTax(_value);
        uint256 taxedValue = _value - tax;

        // Update balances
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += taxedValue;

        // Burn and transfer tax
        if (tax > 0) {
            balanceOf[burnAddress] += (tax * burnPercent) / 100;
            balanceOf[warChest] += (tax * treasuryPercent) / 100;
            emit Transfer(msg.sender, burnAddress, (tax * burnPercent) / 100);
            emit Transfer(msg.sender, warChest, (tax * treasuryPercent) / 100);
            emit Burn(msg.sender, tax);
        }

        emit Transfer(msg.sender, _to, taxedValue);
        return true;
    }

    // Approval function
    function approve(
        address _spender,
        uint256 _value
    ) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // Transfer from function
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public antiWhale(_to, _value) returns (bool success) {
        require(
            _to != address(0),
            "Transfers to the realm of emptiness, the zero address, are forbidden."
        );
        require(
            _value <= balanceOf[_from],
            "Your coffers lack the necessary wealth."
        );
        require(
            _value <= allowance[_from][msg.sender],
            "Your granted privilege falls short of the required amount."
        );

        // Calculate tax
        uint256 tax = getTax(_value);
        uint256 taxedValue = _value - tax;

        // Update balances and allowances
        balanceOf[_from] -= _value;
        balanceOf[_to] += taxedValue;
        allowance[_from][msg.sender] -= _value;

        // Burn and transfer tax
        if (tax > 0) {
            balanceOf[burnAddress] += (tax * burnPercent) / 100;
            balanceOf[warChest] += (tax * treasuryPercent) / 100;
            emit Transfer(_from, burnAddress, (tax * burnPercent) / 100);
            emit Transfer(_from, warChest, (tax * treasuryPercent) / 100);
            emit Burn(_from, tax);
        }

        emit Transfer(_from, _to, taxedValue);
        return true;
    }

    function burn(uint256 _value) public {
        require(
            _value <= balanceOf[msg.sender],
            "Your coffers lack the necessary wealth."
        );
        require(
            _value <= totalSupply,
            "Beyond the total supply, flames shalt not consume."
        );

        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;

        emit Burn(msg.sender, _value);
    }

    // Get tax function
    function getTax(uint256 _value) public view returns (uint256) {
        return (_value * taxPercent) / 100;
    }

    // Renounce contract ownership
    function renounceOwnership() public {
        require(
            msg.sender == owner,
            "Only the Allfather himself may forsake his dominion."
        );
        owner = address(0);
    }

    function changeOwner(address _new_owner) public {
        require(
            msg.sender == owner,
            "Only the Allfather himself may bestow his realm upon another."
        );
        owner = _new_owner;
    }

    function changeWarchestAddress(address _new_warChest) public {
        require(
            msg.sender == owner,
            "Only the Allfather himself may change the location of the war chest."
        );
        require(_new_warChest != address(0));

        warChest = _new_warChest;
        emit ChangeWarChest(_new_warChest);
    }

    function excludeFromAntiWhale(address _address) public {
        require(
            msg.sender == owner,
            "Only the Allfather himself may exclude from reaping the spoils of war."
        );
        require(_address != address(0));

        isExcludedFromAntiWhale[_address] = true;
    }

    function includeInAntiWhale(address _address) public {
        require(
            msg.sender == owner,
            "Only the Allfather himself may include in reaping the spoils of war."
        );
        require(_address != address(0));

        isExcludedFromAntiWhale[_address] = false;
    }

    function updateWhaleLimit(uint8 _new_whaleLimit) public {
        require(
            msg.sender == owner,
            "Only the Allfather himself may change the whale limit."
        );
        require(_new_whaleLimit > 0);

        whaleLimit = _new_whaleLimit;
    }
}