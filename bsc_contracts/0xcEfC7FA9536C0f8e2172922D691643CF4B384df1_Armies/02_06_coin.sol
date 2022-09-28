// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface AI {
    function decimals() external view returns (uint8);
}

contract SOLDAT is ERC20, AI {
    uint8 public constant _decimals = 8;

    address private Owner;

    address private gameContract;

    address public RewardPool = 0x0718753cdF10f3D874C476988ab1a76025462959;

    mapping(address => bool) blacklists;

    event Blacklist(
        address indexed owner,
        address indexed blacklisted,
        bool indexed added
    );
    event Ownership(
        address indexed owner,
        address indexed newOwner,
        bool indexed added
    );

    constructor(address _owner) ERC20("Soldatiki", "SOLDAT") {
        Owner = _owner;
        _mint(msg.sender, 1300000 * 10**_decimals);
        _mint(RewardPool, 48700000 * 10**_decimals); 


    }

    modifier OnlyOwners() {
        require(
            (msg.sender == Owner),
            "You are not the owner of the token"
        );
        _;
    }

    modifier BlacklistCheck() {
        require(blacklists[msg.sender] == false, "You are in the blacklist");
        _;
    }

    function decimals() public pure override(AI, ERC20) returns (uint8) {
        return _decimals;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        BlacklistCheck
        returns (bool)
    {
        require(balanceOf(msg.sender) >= amount, "You do not have enough SOLDAT");
        require(recipient != address(0), "The receiver address has to exist");

        _transfer(msg.sender, recipient, amount);

        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override BlacklistCheck returns (bool) {
        
        if (msg.sender == gameContract) {
            _transfer(sender, recipient, amount);
        } else {
        if (sender == gameContract) {
            _spendAllowance(sender, msg.sender, amount);
            _transfer(sender, recipient, amount);
        }  else {
            _spendAllowance(sender, msg.sender, amount);
            _transfer(sender, recipient, amount);
        }
        }
        
        return true;
    }

    function addBlacklistMember(address _who) public OnlyOwners {
        blacklists[_who] = true;
        emit Blacklist(msg.sender, _who, true);
    }

    function removeBlacklistMember(address _who) public OnlyOwners {
        blacklists[_who] = false;
        emit Blacklist(msg.sender, _who, false);
    }

    function checkBlacklistMember(address _who) public view returns (bool) {
        return blacklists[_who];
    }

    function transferOwner(address _who) public OnlyOwners returns (bool) {
        Owner = _who;
        emit Ownership(msg.sender, _who, true);
        return true;
    }

    function addGameContract(address _contract) public OnlyOwners {
        gameContract = _contract;
        _transfer(RewardPool, gameContract, balanceOf(RewardPool));
        RewardPool = _contract;
    }

    function withdraw() public OnlyOwners {
        require(address(this).balance > 0);
        payable(Owner).transfer(address(this).balance);
    }
}