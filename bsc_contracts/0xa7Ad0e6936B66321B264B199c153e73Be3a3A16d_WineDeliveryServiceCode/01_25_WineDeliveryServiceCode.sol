// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./interfaces/IWineManager.sol";
import "./interfaces/IWineFactory.sol";
import "./interfaces/IWinePool.sol";
import "./interfaces/IWinePoolFull.sol";
import "./interfaces/IWineDeliveryService.sol";
import "./vendors/access/ManagerLikeOwner.sol";
import "./vendors/security/ReentrancyGuardInitializable.sol";
import "./vendors/utils/ERC721OnlySelfInitHolder.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./interfaces/IBordeauxCityBondIntegration.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract WineDeliveryServiceCode is
    ManagerLikeOwner,
    Initializable,
    ReentrancyGuardInitializable,
    ERC721OnlySelfInitHolder,
    IWineDeliveryService
{
    using SafeERC20 for IERC20;

    function initialize(
        address manager_
    )
        override
        public
        initializer
    {
        _initializeManager(manager_);
        _initializeReentrancyGuard();
    }

//////////////////////////////////////// fields definition

    // poolId => UnixTime(BeginOfDelivery)
    mapping(uint256 => uint256) public override getPoolDateBeginOfDelivery;

    uint256 private availableDeliveryTaskId = 1;
    // poolId => tokenId => deliveryTaskId`s
    mapping(uint256 => mapping(uint256 => uint256[])) private deliveryTasksHistory;
    // deliveryTaskId => deliveryTask
    mapping(uint256 => DeliveryTask) private deliveryTasks;
    uint256 bcbAmountSum = 0;

//////////////////////////////////////// DeliverySettings

    modifier allowedDelivery(uint256 poolId) {
        require(getPoolDateBeginOfDelivery[poolId] != 0, "allowedDelivery: DateBeginOfDelivery not set yet");
        require(getPoolDateBeginOfDelivery[poolId] < block.timestamp, "allowedDelivery: not allowed yet");
        _;
    }

    function _editPoolDateBeginOfDelivery(
        uint256 poolId,
        uint256 dateBegin
    )
        override
        public
        onlyManager
    {
        require(IWineManager(manager()).getPoolAddress(poolId) != address(0), "editPoolDateBeginOfDelivery - poolIdNotExists");
        getPoolDateBeginOfDelivery[poolId] = dateBegin;
    }

//////////////////////////////////////// DeliveryTasks inner methods
    function _getLastDeliveryTaskId(uint256 poolId, uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        uint256 deliveryTasksHistoryLength = deliveryTasksHistory[poolId][tokenId].length;
        if (deliveryTasksHistoryLength == 0) {
            return 0;
        }
        return deliveryTasksHistoryLength - 1;
    }

    function _createDeliveryTask(
        uint256 poolId,
        uint256 tokenId,
        address tokenOwner,
        bool isInternal,
        string memory deliveryData
    )
        internal
        returns (uint256 deliveryTaskId)
    {
        availableDeliveryTaskId++;
        deliveryTaskId = availableDeliveryTaskId - 1;

        deliveryTasks[deliveryTaskId] = DeliveryTask({
            tokenOwner: tokenOwner,
            isInternal: isInternal,
            deliveryData: deliveryData,
            supportResponse: "",
            status: DeliveryTaskStatus.New,
            amount: 0,
            bcbAmount: 0
        });
        deliveryTasksHistory[poolId][tokenId].push(deliveryTaskId);

        emit CreateDeliveryRequest(
            deliveryTaskId,
            poolId,
            tokenId,
            tokenOwner,
            isInternal
        );
    }

    function _getDeliveryTask(
        uint256 deliveryTaskId
    )
        internal
        view
        returns (DeliveryTask memory)
    {
        DeliveryTask memory deliveryTask = deliveryTasks[deliveryTaskId];
        require(deliveryTask.tokenOwner != address(0), "showSingleDelivery: deliveryTask not exists");
        require(
            _msgSender() == manager() || (deliveryTask.isInternal == false && _msgSender() == deliveryTask.tokenOwner),
            "showSingleDelivery: Permission denied"
        );
        return deliveryTask;
    }

//////////////////////////////////////// DeliveryTasks view methods

    function showSingleDeliveryTask(
        uint256 deliveryTaskId
    )
        override
        public
        view
        returns (DeliveryTask memory)
    {
        return _getDeliveryTask(deliveryTaskId);
    }

    function showLastDeliveryTask(
        uint256 poolId,
        uint256 tokenId
    )
        override
        public
        view
        returns (uint256, DeliveryTask memory)
    {
        uint256 deliveryTaskId = _getLastDeliveryTaskId(poolId, tokenId);
        return (deliveryTaskId, _getDeliveryTask(deliveryTaskId));
    }

    function showFullHistory(
        uint256 poolId,
        uint256 tokenId
    )
        override
        public
        view
        onlyManager
        returns (uint256, DeliveryTask[] memory)
    {
        uint256 historyLength = deliveryTasksHistory[poolId][tokenId].length;
        DeliveryTask[] memory history = new DeliveryTask[](historyLength);

        for (uint256 i = 0; i < historyLength; i++) {
            history[i] = _getDeliveryTask(deliveryTasksHistory[poolId][tokenId][i]);
        }

        return(historyLength, history);
    }

//////////////////////////////////////// BCB methods

    function getCurrency()
        public
        view
        returns (IERC20)
    {
        return __getIBordeauxCityBondIntegration().getCurrency();
    }

    function calculateStoragePrice(
        uint256 poolId,
        uint256 tokenId
    )
        public
        view
        returns (uint256)
    {
        return __getIBordeauxCityBondIntegration().calculateStoragePrice(poolId, tokenId, true);
    }

    function __getIBordeauxCityBondIntegration()
        private
        view
        returns (IBordeauxCityBondIntegration)
    {
        return IBordeauxCityBondIntegration(IWineManager(manager()).bordeauxCityBond());
    }

//////////////////////////////////////// DeliveryTasks edit methods

    function requestDelivery(
        uint256 poolId,
        uint256 tokenId,
        string memory deliveryData
    )
        override
        public
        returns (uint256 deliveryTaskId)
    {
        IWinePoolFull pool = IWineManager(manager()).getPoolAsContract(poolId);

        address tokenOwner = _msgSender();
        pool.safeTransferFrom(tokenOwner, address(this), tokenId);

        deliveryTaskId = _createDeliveryTask(
            poolId,
            tokenId,
            tokenOwner,
            false,
            deliveryData
        );
    }

    function requestDeliveryForInternal(
        uint256 poolId,
        uint256 tokenId,
        string memory deliveryData
    )
        override
        public
        onlyManager
        returns (uint256 deliveryTaskId)
    {
        IWinePoolFull pool = IWineManager(manager()).getPoolAsContract(poolId);

        address tokenOwner = pool.internalOwnedTokens(tokenId);
        pool.transferInternalToOuter(tokenOwner, address(this), tokenId);

        deliveryTaskId = _createDeliveryTask(
            poolId,
            tokenId,
            tokenOwner,
            true,
            deliveryData
        );
    }

    function setDeliveryTaskAmount(
        uint256 poolId,
        uint256 tokenId,
        uint256 amount
    )
        override
        public
        onlyManager nonReentrant
    {
        uint256 deliveryTaskId = _getLastDeliveryTaskId(poolId, tokenId);
        DeliveryTask storage deliveryTask = deliveryTasks[deliveryTaskId];
        require(deliveryTask.tokenOwner != address(0), "setSupportResponse: deliveryTask not exists");
        require(deliveryTask.status == DeliveryTaskStatus.New || deliveryTask.status == DeliveryTaskStatus.WaitingForPayment, "setSupportResponse: status not allowed");

        deliveryTask.amount = amount;
        deliveryTask.bcbAmount = calculateStoragePrice(poolId, tokenId);
        deliveryTask.status = DeliveryTaskStatus.WaitingForPayment;

        emit SetDeliveryTaskAmount(
            deliveryTaskId,
            poolId,
            tokenId,
            deliveryTask.amount,
            deliveryTask.bcbAmount
        );
    }

    function payDeliveryTaskAmount(
        uint256 poolId,
        uint256 tokenId
    )
        override
        public
        nonReentrant
    {
        uint256 deliveryTaskId = _getLastDeliveryTaskId(poolId, tokenId);
        DeliveryTask storage deliveryTask = deliveryTasks[deliveryTaskId];
        require(deliveryTask.tokenOwner != address(0), "setSupportResponse: deliveryTask not exists");
        require(deliveryTask.isInternal == false, "payDeliveryTaskAmountInternal: only for isInternal = false allowed");
        require(deliveryTask.status == DeliveryTaskStatus.WaitingForPayment, "payDeliveryTaskAmount: status not allowed");
        
        deliveryTask.status = DeliveryTaskStatus.DeliveryInProcess;

        emit PayDeliveryTaskAmount(
            deliveryTaskId,
            poolId,
            tokenId,
            deliveryTask.isInternal,
            deliveryTask.amount,
            deliveryTask.bcbAmount
        );

        IERC20 currency = getCurrency();
        currency.safeTransferFrom(_msgSender(), address(this), deliveryTask.amount + deliveryTask.bcbAmount);
        bcbAmountSum += deliveryTask.bcbAmount;
    }

    function payDeliveryTaskAmountInternal(
        uint256 poolId,
        uint256 tokenId
    )
        override
        public
        onlyManager nonReentrant
    {
        uint256 deliveryTaskId = _getLastDeliveryTaskId(poolId, tokenId);
        DeliveryTask storage deliveryTask = deliveryTasks[deliveryTaskId];
        require(deliveryTask.tokenOwner != address(0), "payDeliveryTaskAmountInternal: deliveryTask not exists");
        require(deliveryTask.isInternal == true, "payDeliveryTaskAmountInternal: only for isInternal = true allowed");
        require(deliveryTask.status == DeliveryTaskStatus.WaitingForPayment, "payDeliveryTaskAmountInternal: status not allowed");

        deliveryTask.status = DeliveryTaskStatus.DeliveryInProcess;

        emit PayDeliveryTaskAmount(
            deliveryTaskId,
            poolId,
            tokenId,
            deliveryTask.isInternal,
            deliveryTask.amount,
            deliveryTask.bcbAmount
        );
    }

    function cancelDeliveryTask(
        uint256 poolId,
        uint256 tokenId,
        string memory supportResponse
    )
        override
        public
        nonReentrant
    {
        uint256 deliveryTaskId = _getLastDeliveryTaskId(poolId, tokenId);
        DeliveryTask storage deliveryTask = deliveryTasks[deliveryTaskId];
        require(deliveryTask.tokenOwner != address(0), "cancelDeliveryTask: deliveryTask not exists");
        require(
            deliveryTask.status == DeliveryTaskStatus.New ||
            deliveryTask.status == DeliveryTaskStatus.WaitingForPayment ||
            deliveryTask.status == DeliveryTaskStatus.DeliveryInProcess
            ,
            "cancelDeliveryTask: status not allowed"
        );
        require(
            deliveryTask.status != DeliveryTaskStatus.DeliveryInProcess || _msgSender() == manager() 
            ,
            "cancelDeliveryTask: cancel of Task in status DeliveryInProcess allowed only to Manager"
        );

        IWinePoolFull pool = IWineManager(manager()).getPoolAsContract(poolId);
        if (deliveryTask.isInternal) {
            pool.transferOuterToInternal(address(this), deliveryTask.tokenOwner, tokenId);
        } else {
            pool.safeTransferFrom(address(this), deliveryTask.tokenOwner, tokenId);
            if (deliveryTask.status == DeliveryTaskStatus.DeliveryInProcess) {
                getCurrency().safeTransfer(deliveryTask.tokenOwner, deliveryTask.amount + deliveryTask.bcbAmount);
            }
        }
        
        deliveryTask.supportResponse = supportResponse;
        deliveryTask.status = DeliveryTaskStatus.Canceled;

        emit CancelDeliveryTask(
            deliveryTaskId,
            poolId,
            tokenId
        );
    }

    function finishDeliveryTask(
        uint256 poolId,
        uint256 tokenId,
        string memory supportResponse
    )
        override
        public
        onlyManager nonReentrant
    {
        uint256 deliveryTaskId = _getLastDeliveryTaskId(poolId, tokenId);
        DeliveryTask storage deliveryTask = deliveryTasks[deliveryTaskId];
        require(deliveryTask.tokenOwner != address(0), "showSingleDelivery: deliveryTask not exists");
        require(deliveryTask.status == DeliveryTaskStatus.DeliveryInProcess, "finishDeliveryTask: status not allowed");

        deliveryTask.supportResponse = supportResponse;
        deliveryTask.status = DeliveryTaskStatus.Executed;
        if (!deliveryTask.isInternal) {
            getCurrency().safeTransfer(address(__getIBordeauxCityBondIntegration()), deliveryTask.bcbAmount);
            bcbAmountSum -= deliveryTask.bcbAmount;
        }

        IWinePoolFull pool = IWineManager(manager()).getPoolAsContract(poolId);
        pool.burn(tokenId);

        emit FinishDeliveryTask(
            deliveryTaskId,
            poolId,
            tokenId
        );
    }

//////////////////////////////////////// DeliveryTasks withdraw payment amount

    function withdrawPaymentAmount(address to)
        override
        public
        onlyManager nonReentrant
    {
        IERC20 currency = getCurrency();
        uint256 balance = currency.balanceOf(address(this));
        currency.safeTransfer(to, balance - bcbAmountSum);
    }

}