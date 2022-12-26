// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./nft-tokenion.sol";

contract TokenionDeposit {
    using SafeERC20 for IERC20;

    address public token;
    IERC20 public _depositToken;
    uint256 public tokenID;
    uint256 public totalSupply;

    address public payer;
    uint256 price = 5700000000000000;
    address payable caller;
    address payable f;

    mapping(bytes32=>address) public validIds;
    mapping(address => bool) wait;

    address public owner;
    address public _bonusContract;
    uint256 public priceToken;
    mapping(uint256 => uint256) bonus;

    mapping(uint256 => uint256) public distribution;
    uint256 public distributionNum;

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not Owner");
        _;
    }

    modifier onlyToken() {
        require(msg.sender == token || msg.sender == owner, "caller is not Token");
        _;
    }

    modifier onlyLegalCaller() {
        require(msg.sender == _bonusContract || msg.sender == owner, "caller is not Legal Caller");
        _;
    }

    modifier onlyCaller() {
        require(msg.sender == caller || msg.sender == owner, "caller is not Contract Caller");
        _;
    }

    event UserQueryId(bytes32 queryId);
    event WithdrawnFromDeposit(address user, uint256 amount);
    event ReceivedTokens(address indexed user, uint256 indexed tokenID, uint256 indexed amount);
    event DividendsEstablished(uint256 indexed num, uint256 indexed amount);

    constructor(uint256 id, address bonusContract, IERC20 depositToken, address payable _f, address payable _caller, address _payer){
        tokenID = id;
        owner = msg.sender;
        f = _f;
        caller = _caller;
        _depositToken = depositToken;
        payer = _payer;
        _bonusContract = bonusContract;
    }

    function changeF(address payable _f, address payable _caller) public onlyLegalCaller{
        f = _f;
        caller = _caller;
    }

    function setNextDividends(uint256 amount) public onlyOwner{
        distributionNum++;
        distribution[distributionNum] = amount;
    }

    function setPayer(address _payer) public onlyOwner{
        payer = _payer;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function setBonus(uint256 _amount, uint256 _bonus) public onlyOwner{
        bonus[_amount] = _bonus;
    }

    function setToken(address t) public onlyOwner{
        token = t;
    }

    function setTotalSupply(uint256 _totalSupply) public onlyToken{
        totalSupply += _totalSupply;
    }

    function setPriceToken(uint256 pt) public onlyOwner{
        priceToken = pt;
    }

    function newOwner(address o) public onlyOwner{
        owner = o;
    }

    function setBonusContract(address bonusContract) public onlyOwner{
        _bonusContract = bonusContract;
    }

    function delivery(
		address user,
		uint256 packetType,
		uint256 quantity,
		uint256 packageId,
		uint256 amount
	) external onlyLegalCaller {
        TokenionToken(token).safeTransferFrom(address(this), user, tokenID, (amount / priceToken) + bonus[amount], "");
        emit ReceivedTokens(user, tokenID, amount);
	}

    function __callback(bytes32 myid, uint256 result) public onlyCaller{
        if (validIds[myid] == address(0)) revert();
        if(result > 0){
            _depositToken.safeTransferFrom(payer, validIds[myid], result);
        }
        emit WithdrawnFromDeposit(validIds[myid], result);
        wait[validIds[myid]] = false;
        delete validIds[myid];
    }

    function widthdrawIncome() public payable{
        require(!wait[msg.sender], "The request is already being processed!");
        require(msg.value >= price, "Provable query was NOT sent, please add some ETH to cover for the query fee!");
        bytes32 queryId = keccak256(abi.encodePacked(msg.sender, block.timestamp));
        (bool sent, ) = caller.call{value: 1000000000000000}("");
        (bool sent2, ) = f.call{value: 4700000000000000}("");
        emit UserQueryId(queryId);
        validIds[queryId] = msg.sender;
        wait[msg.sender] = true;
    }
}