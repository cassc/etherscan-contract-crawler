pragma solidity ^0.8.8;

import "./ERC20.sol";
import "./Owned.sol";

contract DNM is ERC20, Owned {

    bool public CONTACT_FINALIZED = false;
    mapping(address => bool) public operators;
    uint256 public MAX_SUPPLY = 9999999 ether;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) ERC20(name, symbol, decimals) Owned(msg.sender) {}

    function mintByOperator(address send_to, uint256 amount) public onlyOperator{
        require((totalSupply + amount) <= MAX_SUPPLY, 'can not mint more than max supply');
        _mint(send_to, amount);
    }

    function setFinalizeContract() public onlyOwner{
        CONTACT_FINALIZED = true;
        emit FinalizeContract(block.timestamp);
    }

    function createOperator(address _wallet) external onlyOwner {
        require(CONTACT_FINALIZED == false, 'contract finalized');
        operators[_wallet] = true;
        emit EnableOperator(_wallet);
    }

    function removeOperator(address _wallet) external onlyOwner {
        require(CONTACT_FINALIZED == false, 'contract finalized');
        operators[_wallet] = false;
        emit DisableOperator(_wallet);
    }

    modifier onlyOperator() {
        require(operators[msg.sender] == true, "caller is not the operator");
        _;
    }

    event FinalizeContract(uint256 time);
    event EnableOperator(address indexed operator);
    event DisableOperator(address indexed operator);
}
