// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./TokenEvent.sol";

/**
 * @title dForce's lending Token admin Contract
 * @author dForce
 */
abstract contract TokenAdmin is TokenEvent {
    //----------------------------------
    //********* Owner Actions **********
    //----------------------------------

    modifier settleInterest() {
        // Accrues interest.
        _updateInterest();
        require(
            accrualBlockNumber == block.number,
            "settleInterest: Fail to accrue interest!"
        );
        _;
    }

    /**
     * @dev Sets a new controller.
     */
    function _setController(IControllerInterface _newController)
        external
        virtual
        onlyOwner
    {
        IControllerInterface _oldController = controller;
        // Ensures the input address is a controller contract.
        require(
            _newController.isController(),
            "_setController: This is not the controller contract!"
        );

        // Sets to new controller.
        controller = _newController;

        emit NewController(_oldController, _newController);
    }

    /**
     * @dev Sets a new interest rate model.
     * @param _newInterestRateModel The new interest rate model.
     */
    function _setInterestRateModel(
        IInterestRateModelInterface _newInterestRateModel
    ) external virtual onlyOwner {
        // Gets current interest rate model.
        IInterestRateModelInterface _oldInterestRateModel = interestRateModel;

        // Ensures the input address is the interest model contract.
        require(
            _newInterestRateModel.isInterestRateModel(),
            "_setInterestRateModel: This is not the rate model contract!"
        );

        // Set to the new interest rate model.
        interestRateModel = _newInterestRateModel;

        emit NewInterestRateModel(_oldInterestRateModel, _newInterestRateModel);
    }

    /**
     * @dev Sets a new reserve ratio.
     */
    function _setNewReserveRatio(uint256 _newReserveRatio)
        external
        virtual
        onlyOwner
        settleInterest
    {
        require(
            _newReserveRatio <= maxReserveRatio,
            "_setNewReserveRatio: New reserve ratio too large!"
        );

        // Gets current reserve ratio.
        uint256 _oldReserveRatio = reserveRatio;

        // Sets new reserve ratio.
        reserveRatio = _newReserveRatio;

        emit NewReserveRatio(_oldReserveRatio, _newReserveRatio);
    }

    /**
     * @dev Sets a new flashloan fee ratio.
     */
    function _setNewFlashloanFeeRatio(uint256 _newFlashloanFeeRatio)
        external
        virtual
        onlyOwner
        settleInterest
    {
        require(
            _newFlashloanFeeRatio <= BASE,
            "setNewFlashloanFeeRatio: New flashloan ratio too large!"
        );

        // Gets current reserve ratio.
        uint256 _oldFlashloanFeeRatio = flashloanFeeRatio;

        // Sets new reserve ratio.
        flashloanFeeRatio = _newFlashloanFeeRatio;

        emit NewFlashloanFeeRatio(_oldFlashloanFeeRatio, _newFlashloanFeeRatio);
    }

    /**
     * @dev Sets a new protocol fee ratio.
     */
    function _setNewProtocolFeeRatio(uint256 _newProtocolFeeRatio)
        external
        virtual
        onlyOwner
        settleInterest
    // nonReentrant
    {
        require(
            _newProtocolFeeRatio <= BASE,
            "_setNewProtocolFeeRatio: New protocol ratio too large!"
        );

        // Gets current reserve ratio.
        uint256 _oldProtocolFeeRatio = protocolFeeRatio;

        // Sets new reserve ratio.
        protocolFeeRatio = _newProtocolFeeRatio;

        emit NewProtocolFeeRatio(_oldProtocolFeeRatio, _newProtocolFeeRatio);
    }

    /**
     * @dev Admin withdraws `_withdrawAmount` of the iToken.
     * @param _withdrawAmount Amount of reserves to withdraw.
     */
    function _withdrawReserves(uint256 _withdrawAmount)
        external
        virtual
        onlyOwner
        settleInterest
    // nonReentrant
    {
        require(
            _withdrawAmount <= totalReserves &&
                _withdrawAmount <= _getCurrentCash(),
            "_withdrawReserves: Invalid withdraw amount and do not have enough cash!"
        );

        uint256 _oldTotalReserves = totalReserves;
        // Updates total amount of the reserves.
        totalReserves = totalReserves.sub(_withdrawAmount);

        // Transfers reserve to the owner.
        _doTransferOut(owner, _withdrawAmount);

        emit ReservesWithdrawn(
            owner,
            _withdrawAmount,
            totalReserves,
            _oldTotalReserves
        );
    }

    /**
     * @notice Calculates interest and update total borrows and reserves.
     * @dev Updates total borrows and reserves with any accumulated interest.
     */
    function _updateInterest() internal virtual;

    /**
     * @dev Transfers underlying token out.
     */
    function _doTransferOut(address payable _recipient, uint256 _amount)
        internal
        virtual;

    /**
     * @dev Total amount of reserves owned by this contract.
     */
    function _getCurrentCash() internal view virtual returns (uint256);
}