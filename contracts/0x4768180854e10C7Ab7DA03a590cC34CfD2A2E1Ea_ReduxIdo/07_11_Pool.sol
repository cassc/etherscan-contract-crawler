// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IPool.sol";
import "./Validations.sol";

contract Pool is IPool, Ownable {
    using SafeERC20 for IERC20;
    PoolModel private poolInformation;
    IDOInfo private idoInfo;

    address[] private participantsAddress;
    mapping(address => uint256) private collaborations;
    uint256 private _amountRaised = 0;

    event LogPoolContractAddress(address);
    event LogPoolStatusChanged(uint256 currentStatus, uint256 newStatus);
    event LogDeposit(address indexed participant, uint256 amount);

    constructor(PoolModel memory _pool) {
        _preValidatePoolCreation(_pool);
        poolInformation = IPool.PoolModel({
            hardCap: _pool.hardCap, // 100k
            startDateTime: _pool.startDateTime,
            endDateTime: _pool.endDateTime,
            status: _pool.status
        });

        emit LogPoolContractAddress(address(this));
    }

    modifier _addIDOInfoOnlyOnce() {
        require(
            address(idoInfo.investmentTokenAddress) == address(0),
            "already added IDO info"
        );
        _;
    }

    function addIDOInfo(IDOInfo memory _pdi)
        external
        override
        onlyOwner
        _addIDOInfoOnlyOnce
    {
        _preIDOInfoUpdate(_pdi);

        idoInfo.investmentTokenAddress = _pdi.investmentTokenAddress;
        idoInfo.minAllocationPerUser = _pdi.minAllocationPerUser;
        idoInfo.maxAllocationPerUser = _pdi.maxAllocationPerUser;
    }

    receive() external payable {
    }

    function deposit(address _sender, uint256 _amount)
        external
        override
        onlyOwner
        _pooIsOngoing(poolInformation)
        _hardCapNotPassed(poolInformation.hardCap, _amount)
        _isAmountStaisfyAllocationRange(_amount)
    {
        IERC20(idoInfo.investmentTokenAddress).safeTransferFrom( _sender,
            msg.sender,
            _amount);

        _increaseRaisedAmount(_amount);
        _addToParticipants(_sender, _amount);
        emit LogDeposit(_sender, _amount);
    }

    function updatePoolStatus(uint256 _newStatus) external override onlyOwner {
        require(_newStatus < 5 && _newStatus >= 0, "wrong Status;");
        uint256 currentStatus = uint256(poolInformation.status);
        poolInformation.status = PoolStatus(_newStatus);
        emit LogPoolStatusChanged(currentStatus, _newStatus);
    }

    function getCompletePoolDetails()
        external
        view
        override
        returns (CompletePoolDetails memory poolDetails)
    {
        poolDetails = CompletePoolDetails({
            participationDetails: _getParticipantsInfo(),
            totalRaised: _getTotalRaised(),
            pool: poolInformation,
            poolDetails: idoInfo
        });
    }

    function getInvestmentTokenAddress()
        external
        view
        override
        returns (address investmentTokenAddress)
    {
        return idoInfo.investmentTokenAddress;
    }

    // remove

    function _getParticipantsInfo()
        private
        view
        returns (Participations memory participants)
    {
        uint256 count = participantsAddress.length;

        ParticipantDetails[] memory parts = new ParticipantDetails[](count);

        for (uint256 i = 0; i < count; i++) {
            address userAddress = participantsAddress[i];
            parts[i] = ParticipantDetails(
                userAddress,
                collaborations[userAddress]
            );
        }
        participants.count = count;
        participants.investorsDetails = parts;
    }

    function _getTotalRaised() private view returns (uint256 amount) {
        amount = _amountRaised;
    }

    function _increaseRaisedAmount(uint256 _amount) private {
        require(_amount > 0, "No amount found!");
        _amountRaised += _amount;
    }

    function _addToParticipants(address _address, uint256 amount) private {
        require(!_didAlreadyParticipated(_address), "Already participated");
        _addToListOfParticipants(_address);
        _keepRecordOfAmountRaised(_address, amount);
    }

    function _didAlreadyParticipated(address _address)
        private
        view
        returns (bool isIt)
    {
        isIt = collaborations[_address] > 0;
    }

    function _addToListOfParticipants(address _address) private {
        participantsAddress.push(_address);
    }

    function _keepRecordOfAmountRaised(address _address, uint256 amount)
        private
    {
        collaborations[_address] += amount;
    }

    function _preValidatePoolCreation(IPool.PoolModel memory _pool)
        private
        view
    {
        require(_pool.hardCap > 0, "hardCap must be > 0");
        require(
            _pool.startDateTime > block.timestamp,
            "startDateTime must be > now"
        );
    }

    function _preIDOInfoUpdate(IDOInfo memory _idoInfo) private pure {
        require(
            address(_idoInfo.investmentTokenAddress) != address(0),
            "investmentTokenAddress is a zero address!"
        );
        require(
            _idoInfo.minAllocationPerUser > 0,
            "minAllocation must be > 0!"
        );
        require(
            _idoInfo.minAllocationPerUser < _idoInfo.maxAllocationPerUser,
            "minAllocation must be < max!"
        );
    }

    modifier _pooIsOngoing(IPool.PoolModel storage _pool) {
        require(_pool.status == IPool.PoolStatus.Ongoing, "Pool not open!");
        require(
            _pool.startDateTime <= block.timestamp,
            "Pool not started yet!"
        );
        require(_pool.endDateTime >= block.timestamp, "pool endDate passed!");

        _;
    }

    modifier _isPoolFinished(IPool.PoolModel storage _pool) {
        require(
            _pool.status == IPool.PoolStatus.Finished,
            "Pool status not Finished!"
        );
        _;
    }

    modifier _isAmountStaisfyAllocationRange(uint256 amount) {
        require(
            amount >= idoInfo.minAllocationPerUser &&
                amount <= idoInfo.maxAllocationPerUser,
            "Amount out of allocation range"
        ); // deposit between 500 USDT and 1000 USDT */
        _;
    }

    modifier _hardCapNotPassed(uint256 _hardCap, uint256 amount) {
        uint256 _beforeBalance = _getTotalRaised();

        uint256 sum = _getTotalRaised() + amount;
        require(sum <= _hardCap, "hardCap reached!");
        assert(sum > _beforeBalance);
        _;
    }
}