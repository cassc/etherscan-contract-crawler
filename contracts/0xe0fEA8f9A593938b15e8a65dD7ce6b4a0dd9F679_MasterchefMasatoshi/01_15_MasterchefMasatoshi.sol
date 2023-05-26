// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ERC721.sol";

/**
 * @title MasterchefMasatoshi
 * NFT + DAO = NEW META
 * Vitalik, remove contract size limit pls
 */
contract MasterchefMasatoshi is ERC721, Ownable {
    string public PROVENANCE;
    bool provenanceSet;

    uint256 public mintPrice;
    uint256 public maxPossibleSupply;

    bool public saleIsActive;

    address public immutable currency;
    address immutable wrappedNativeCoinAddress;

    uint256 public percentToVote = 60;
    uint256 public votingDuration = 86400;

    bool public isDao;
    bool public percentToVoteFrozen;
    bool public votingDurationFrozen;

    event VotingCreated(
        address contractAddress,
        bytes data,
        uint256 value,
        string comment,
        uint256 indexed index,
        uint256 timestamp
    );
    event VotingSigned(uint256 indexed index, address indexed signer, uint256 timestamp);
    event VotingActivated(uint256 indexed index, uint256 timestamp, bytes result);
    event Received(address, uint256);

    struct Voting {
        address contractAddress;
        bytes data;
        uint256 value;
        string comment;
        uint256 index;
        uint256 timestamp;
        bool isActivated;
        address[] signers;
    }

    Voting[] public votings;

    receive() external payable {
        emit Received(_msgSender(), msg.value);
    }

    modifier onlyHoldersOrOwner {
        require((isDao && balanceOf(_msgSender()) > 0) || _msgSender() == owner());
        _;
    }

    modifier onlyContractOrOwner {
        require(_msgSender() == address(this) || _msgSender() == owner());
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxPossibleSupply,
        uint256 _mintPrice,
        address _currency,
        address _wrappedNativeCoinAddress
    ) ERC721(_name, _symbol) {
        maxPossibleSupply = _maxPossibleSupply;
        mintPrice = _mintPrice;
        currency = _currency;
        wrappedNativeCoinAddress = _wrappedNativeCoinAddress;
    }

    function preMint(uint amount) public onlyContractOrOwner {        
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < amount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        require(!provenanceSet);
        PROVENANCE = provenanceHash;
        provenanceSet = true;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function flipSaleState() public onlyContractOrOwner {
        saleIsActive = !saleIsActive;
    }

    function permanentlyConvertToDao() external onlyOwner {
        isDao = true;
    }

    function createVoting(
        address _contractAddress,
        bytes calldata _data,
        uint256 _value,
        string memory _comment
    ) external onlyHoldersOrOwner returns (bool success) {
        address[] memory _signers;

        votings.push(
            Voting({
                contractAddress: _contractAddress,
                data: _data,
                value: _value,
                comment: _comment,
                index: votings.length,
                timestamp: block.timestamp,
                isActivated: false,
                signers: _signers
            })
        );

        emit VotingCreated(_contractAddress, _data, _value, _comment, votings.length - 1, block.timestamp);

        return true;
    }

    function signVoting(uint256 _index) external onlyHoldersOrOwner returns (bool success) {
        for (uint256 i = 0; i < votings[_index].signers.length; i++) {
            require(_msgSender() != votings[_index].signers[i], "v");
        }

        require(block.timestamp <= votings[_index].timestamp + votingDuration, "t");

        votings[_index].signers.push(_msgSender());
        emit VotingSigned(_index, _msgSender(), block.timestamp);
        return true;
    }

    function activateVoting(uint256 _index) external {
        uint256 sumOfSigners = 0;

        for (uint256 i = 0; i < votings[_index].signers.length; i++) {
            sumOfSigners += balanceOf(votings[_index].signers[i]);
        }

        require(sumOfSigners >= totalSupply() * percentToVote / 100, "s");
        require(!votings[_index].isActivated, "a");

        address _contractToCall = votings[_index].contractAddress;
        bytes storage _data = votings[_index].data;
        uint256 _value = votings[_index].value;
        (bool b, bytes memory result) = _contractToCall.call{value: _value}(_data);

        require(b);

        votings[_index].isActivated = true;

        emit VotingActivated(_index, block.timestamp, result);
    }

    function changePercentToVote(uint256 _percentToVote) public onlyContractOrOwner returns (bool success) {
        require(_percentToVote >= 1 && _percentToVote <= 100 && !percentToVoteFrozen, "f");
        percentToVote = _percentToVote;
        return true;
    }

    function freezePercentToVoteFrozen() public onlyContractOrOwner returns (bool success) {
        percentToVoteFrozen = true;
        return true;
    }

    function changeVotingDuration(uint256 _votingDuration) public onlyContractOrOwner returns (bool success) {
        require(!votingDurationFrozen, "f");
        require(
            _votingDuration == 2 hours || _votingDuration == 24 hours || _votingDuration == 72 hours, "t"
        );
        votingDuration = _votingDuration;
        return true;
    }

    function freezeVotingDuration() public onlyContractOrOwner returns (bool success) {
        votingDurationFrozen = true;
        return true;
    }

    function mintTokens(uint _amount) public payable {
        require(saleIsActive, "s");
        require(totalSupply() + _amount <= maxPossibleSupply, "m");

        if (currency == wrappedNativeCoinAddress) {
            require(mintPrice * _amount <= msg.value, "a");            
        } else {
            IERC20 _currency = IERC20(currency);
            _currency.transferFrom(_msgSender(), address(this), _amount * mintPrice);    
        }

        for(uint i = 0; i < _amount; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < maxPossibleSupply) {
                _safeMint(_msgSender(), mintIndex);
            }
        }
    }

    function getAllVotings() external view returns (Voting[] memory) {
        return votings;
    }

    function withdraw() public onlyContractOrOwner() {
        uint balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }

    function withdrawTokens(address tokenAddress) external onlyContractOrOwner() {
        IERC20(tokenAddress).transfer(_msgSender(), IERC20(tokenAddress).balanceOf(address(this)));
    }
}

// The High Table