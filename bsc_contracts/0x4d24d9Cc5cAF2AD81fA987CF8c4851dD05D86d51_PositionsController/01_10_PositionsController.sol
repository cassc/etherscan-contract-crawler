pragma solidity ^0.8.17;
import '../lib/factories/HasFactories.sol';
//import '../lib/factories/ContractData.sol';
import 'contracts/interfaces/position_trading/IPositionAlgorithm.sol';
import 'contracts/interfaces/position_trading/IPositionsController.sol';
import 'contracts/fee/IFeeSettings.sol';

contract PositionsController is
    HasFactories,
    IPositionsController,
    IAssetListener
{
    IFeeSettings feeSettings;
    uint256 public totalPositions; // total positions created
    mapping(uint256 => address) public owners; // position owners
    mapping(uint256 => ContractData) public ownerAssets; // owner's asset (what is offered)
    mapping(uint256 => ContractData) public outputAssets; // output asset (what they want in return), may be absent, in case of locks
    mapping(uint256 => ContractData) public algorithms; // algorithm for processing the input and output asset
    mapping(uint256 => bool) public editingLocks; // locks on editing positions
    mapping(address => mapping(uint256 => uint256)) _ownedPositions; // indexed from position 0 for each account
    mapping(uint256 => uint256) _ownedPositionsIndex; // mapping from position ID to index in owner list
    mapping(address => uint256) _positionCountsByAccounts; // counts of positions by account
    mapping(address => uint256) _positionsByAssets; // asset positions

    event NewPosition(address indexed account, uint256 indexed positionId);
    event SetPositionAlgorithm(uint256 indexed positionId, ContractData data);
    event TransferPositionOwnership(
        uint256 indexed positionId,
        address lastOwner,
        address newOwner
    );

    constructor(address feeSettings_) {
        feeSettings = IFeeSettings(feeSettings_);
    }

    modifier positionUnLocked(uint256 positionId) {
        require(!editingLocks[positionId], 'position editing is locked');
        ContractData memory data = algorithms[positionId];
        if (data.contractAddr != address(0)) {
            require(
                !IPositionAlgorithm(data.contractAddr).isPositionLocked(
                    positionId
                ),
                'position algogithm is not allowed to edit position'
            );
        }
        _;
    }

    modifier onlyPositionOwner(uint256 positionId) {
        require(owners[positionId] == msg.sender, 'only for position owner');
        _;
    }

    function getFeeSettings() external view returns (IFeeSettings) {
        return feeSettings;
    }

    function positionOfOwnerByIndex(address account, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < _positionCountsByAccounts[account],
            'account positions index out of bounds'
        );
        return _ownedPositions[account][index];
    }

    function _addPositionToOwnerEnumeration(address to, uint256 positionId)
        private
    {
        uint256 length = _positionCountsByAccounts[to];
        _ownedPositions[to][length] = positionId;
        _ownedPositionsIndex[positionId] = length;
    }

    function _removePositionFromOwnerEnumeration(
        address from,
        uint256 positionId
    ) private {
        uint256 lastPositionIndex = _positionCountsByAccounts[from] - 1;
        uint256 positionIndex = _ownedPositionsIndex[positionId];

        // When the position to delete is the last posiiton, the swap operation is unnecessary
        if (positionIndex != lastPositionIndex) {
            uint256 lastPositionId = _ownedPositions[from][lastPositionIndex];

            _ownedPositions[from][positionIndex] = lastPositionId; // Move the last position to the slot of the to-delete token
            _ownedPositionsIndex[lastPositionId] = positionIndex; // Update the moved position's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedPositionsIndex[positionId];
        delete _ownedPositions[from][lastPositionIndex];
    }

    function transferPositionOwnership(uint256 positionId, address newOwner)
        external
        onlyPositionOwner(positionId)
    {
        _removePositionFromOwnerEnumeration(msg.sender, positionId);
        _addPositionToOwnerEnumeration(newOwner, positionId);
        --_positionCountsByAccounts[msg.sender];
        ++_positionCountsByAccounts[newOwner];
        owners[positionId] = newOwner;
        emit TransferPositionOwnership(positionId, msg.sender, newOwner);
    }

    function ownedPositionsCount(address account)
        external
        view
        override
        returns (uint256)
    {
        return _positionCountsByAccounts[account];
    }

    function getAssetPositionId(address assetAddress)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _positionsByAssets[assetAddress];
    }

    function ownerOf(uint256 positionId)
        external
        view
        override
        returns (address)
    {
        return owners[positionId];
    }

    function getAsset(uint256 positionId, uint256 assetCode)
        external
        view
        returns (ContractData memory)
    {
        if (assetCode == 1) return ownerAssets[positionId];
        else if (assetCode == 2) return outputAssets[positionId];
        else revert('unknown asset code');
    }

    function createPosition() external override {
        ++totalPositions;
        owners[totalPositions] = msg.sender;
        _addPositionToOwnerEnumeration(msg.sender, totalPositions);
        _positionCountsByAccounts[msg.sender]++;
        emit NewPosition(msg.sender, totalPositions);
    }

    function setAsset(
        uint256 positionId,
        uint256 assetCode,
        ContractData calldata data
    ) external override onlyFactory positionUnLocked(positionId) {
        if (assetCode == 1) {
            delete _positionsByAssets[ownerAssets[positionId].contractAddr];
            ownerAssets[positionId] = data;
        } else if (assetCode == 2) {
            delete _positionsByAssets[outputAssets[positionId].contractAddr];
            outputAssets[positionId] = data;
        } else revert('unknown asset code');
        _positionsByAssets[data.contractAddr] = positionId;
        trySetAssetOwnershipToAlgorithm(positionId, data);
    }

    function trySetAssetOwnershipToAlgorithm(
        uint256 positionId,
        ContractData calldata assetData
    ) internal {
        if (algorithms[positionId].contractAddr != address(0))
            IOwnable(assetData.contractAddr).transferOwnership(
                algorithms[positionId].contractAddr
            );
    }

    function setAlgorithm(uint256 positionId, ContractData calldata algData)
        external
        override
        onlyFactory
        positionUnLocked(positionId)
    {
        // if there is already an algorithm, then transfer the asset ownership to the current controller or to a new algorithm
        // owner's asset
        if (ownerAssets[positionId].contractAddr != address(0)) {
            if (algorithms[positionId].contractAddr != address(0)) {
                IPositionAlgorithm(algorithms[positionId].contractAddr)
                    .transferAssetOwnerShipTo(
                        ownerAssets[positionId].contractAddr,
                        algData.contractAddr != address(0)
                            ? algData.contractAddr
                            : address(this)
                    );
            } else {
                IOwnable(ownerAssets[positionId].contractAddr)
                    .transferOwnership(algData.contractAddr);
            }
        }
        // output asset
        if (outputAssets[positionId].contractAddr != address(0)) {
            if (algorithms[positionId].contractAddr != address(0)) {
                IPositionAlgorithm(algorithms[positionId].contractAddr)
                    .transferAssetOwnerShipTo(
                        outputAssets[positionId].contractAddr,
                        algData.contractAddr != address(0)
                            ? algData.contractAddr
                            : address(this)
                    );
            } else {
                IOwnable(outputAssets[positionId].contractAddr)
                    .transferOwnership(algData.contractAddr);
            }
        }

        // set a new algorithm
        algorithms[positionId] = algData;

        emit SetPositionAlgorithm(positionId, algData);
    }

    function getAlgorithm(uint256 positionId)
        external
        view
        override
        returns (ContractData memory data)
    {
        return algorithms[positionId];
    }

    function disableEdit(uint256 positionId)
        external
        override
        onlyPositionOwner(positionId)
        positionUnLocked(positionId)
    {
        editingLocks[positionId] = false;
    }

    function beforeAssetTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256[] memory data
    ) external pure override {
        revert('has no algorithm');
    }

    function afterAssetTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256[] memory data
    ) external pure override {
        revert('has no algorithm');
    }
}