///SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import "./multisig.sol";
import "./DaoToken.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

contract LockingDAO is Ownable {
    MultiSigWallet public multisig;
    DaoToken public daoToken;
    address public excludedAddress;

    address[] private initialOwners;

    bool public voting;

    mapping(address => uint256) public lockedTokens;
    mapping(uint256 => uint256) public votesForProposal;
    uint256 public currentProposal;
    uint256 public maxExcludedAddressChanges;
    uint256 public currentExcludedAddressChanges;


    constructor(
        address[] memory _initialOwners,
        address _excludedAddress
    ) {
        initialOwners = _initialOwners;
        initialOwners.push(address(this));
        excludedAddress = _excludedAddress;

        maxExcludedAddressChanges = 10;

        uint size = initialOwners.length;
        bool [] memory initialOwnersRequired = new bool[](size);
        initialOwnersRequired[initialOwnersRequired.length - 1] = true; // the last one


        multisig = new MultiSigWallet(initialOwners, initialOwnersRequired, initialOwners.length - 1);
    }

    function setDaoToken (address _daoToken) public onlyOwner {
      require(address(daoToken) == address(0), "Token already configured");
      daoToken = DaoToken(_daoToken);
      multisig.initialise(address(daoToken.stablecoin()), address(daoToken));
    }

    function setExcludedAddress (address _excludedAddress) public onlyOwner {
      require(maxExcludedAddressChanges > currentExcludedAddressChanges, "excluded address max changes performed");
      excludedAddress = _excludedAddress;
      currentExcludedAddressChanges++;
    }

    function createProposal(
        address _tokenAddress,
        uint256 _amount,
        address _user
    ) public onlyOwner {
        require(!voting, "There is a vote already happening");
        voting = true;

        currentProposal = multisig.submitTransaction(
            _tokenAddress,
            _user,
            _amount
        );
    }

    function voteCurrent(uint256 _amount) public {
        require(voting, "No voting taking place");
        require(excludedAddress != msg.sender, "No voting for this address");
        lockedTokens[msg.sender] += _amount;
        votesForProposal[currentProposal] += _amount;
        daoToken.lockToVote(msg.sender, _amount);
    }

    function claimTokens(uint256 _amount) public {
        require(!voting, "Can't claim during vote");
        require(
            lockedTokens[msg.sender] >= _amount,
            "Not enough locked tokens"
        );

        lockedTokens[msg.sender] -= _amount;
        bool success = daoToken.transfer(msg.sender, _amount);
        require (success, "Could not complete transfer");
    }

    function confirmToMultisig() public onlyOwner{
        require(voting, "No voting taking place");
        require(
            currentProposalOverThreshold(),
            "Not enough votes to confirm transaction"
        );

        voting = false;

        multisig.confirmTransaction(currentProposal);

    }

    function stopVoting() public onlyOwner {
        voting = false;
    }

    function votingThreshold() public view returns (uint256) {
        return daoToken.totalSupply() / 2; // 50%
    }

    function currentProposalOverThreshold() public view returns (bool) {
        return votesForProposal[currentProposal] > votingThreshold();
    }
}