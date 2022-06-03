// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../library/Ownable.sol";
import "./LiquidityLocker.sol";
import "../library/CloneBase.sol";
import "../Interface/IFeeManager.sol";
import "../Interface/ILiquidityLockerMinimalProxy.sol";
import "../Interface/IMinimalProxy.sol";
import "../Interface/IReferralManager.sol";
import "../library/TransferHelper.sol";

contract LiquidityLockerFactory is Ownable, CloneBase {
    using SafeMath for uint256;

    event LiquidityLockerLaunched(uint256 _id, address _vestingContract);
    event ImplementationLaunched(uint256 _id, address _implementation);
    event ImplementationUpdated(uint256 _id, address _implementation);

    address[] public liquidityLockerVestings;

    IFeeManager public feeManager;

    //Trigger for ReferralManager mode
    bool public isReferralManagerEnabled;

    IReferralManager public referralManager;

    mapping(uint256 => address) public implementationIdVsImplementation;
    uint256 public nextId;

    function addImplementation(address _newImplementation) external onlyOwner {
        require(_newImplementation != address(0), "Invalid implementation");
        implementationIdVsImplementation[nextId] = _newImplementation;

        emit ImplementationLaunched(nextId, _newImplementation);

        nextId = nextId.add(1);
    }

    function updateImplementation(uint256 _id, address _newImplementation)
        external
        onlyOwner
    {
        address currentImplementation = implementationIdVsImplementation[_id];
        require(currentImplementation != address(0), "Incorrect Id");

        implementationIdVsImplementation[_id] = _newImplementation;
        emit ImplementationUpdated(_id, _newImplementation);
    }

    function _handleFeeManager()
        private
        returns (uint256 feeAmount_, address feeToken_)
    {
        require(address(feeManager) != address(0), "Fee manager must be added");
        (feeAmount_, feeToken_) = getFeeInfo();
        if (feeToken_ != address(0)) {
            TransferHelper.safeTransferFrom(
                feeToken_,
                msg.sender,
                address(this),
                feeAmount_
            );

            TransferHelper.safeApprove(
                feeToken_,
                address(feeManager),
                feeAmount_
            );

            feeManager.fetchFees();
        } else {
            require(msg.value == feeAmount_, "Invalid value sent for fee");
            feeManager.fetchFees{value: msg.value}();
        }

        return (feeAmount_, feeToken_);
    }

    function getFeeInfo() public view returns (uint256, address) {
        return feeManager.getFactoryFeeInfo(address(this));
    }

    function _handleReferral(address referrer, uint256 feeAmount) private {
        if (isReferralManagerEnabled && referrer != address(0)) {
            referralManager.handleReferralForUser(
                referrer,
                msg.sender,
                feeAmount
            );
        }
    }

    function _launchVesting(
        uint256 _id,
        uint256 _amount,
        address _beneficiary,
        bytes memory _encodedData
    ) internal returns (address) {
        IERC20 _erc20Token;
        address liquidityLockerOwner;
        (_erc20Token, liquidityLockerOwner) = abi.decode(
            _encodedData,
            (IERC20, address)
        );
        require(address(_erc20Token) != address(0), "Incorrect token address");

        address liquidityLockerLibrary = implementationIdVsImplementation[_id];
        require(liquidityLockerLibrary != address(0), "Incorrect Id");

        address liquidityLocker = createClone(liquidityLockerLibrary);

        IMinimalProxy(liquidityLocker).init(_encodedData);

        TransferHelper.safeTransferFrom(
            address(_erc20Token),
            msg.sender,
            address(this),
            _amount
        );

        TransferHelper.safeApprove(
            address(_erc20Token),
            address(liquidityLocker),
            _amount
        );

        ILiquidityLockerMinimalProxy(liquidityLocker).createVestingSchedule(
            _beneficiary,
            _amount
        );

        Ownable(liquidityLocker).transferOwnership(liquidityLockerOwner);

        liquidityLockerVestings.push(liquidityLocker);

        emit LiquidityLockerLaunched(_id, liquidityLocker);
        return liquidityLocker;
    }

    function launchVesting(
        uint256 _id,
        uint256 _amount,
        address _beneficiary,
        bytes memory _encodedData
    ) external payable returns (address) {
        address vestingAddress = _launchVesting(
            _id,
            _amount,
            _beneficiary,
            _encodedData
        );
        _handleFeeManager();
        return vestingAddress;
    }

    function launchVestingWithReferral(
        uint256 _id,
        uint256 _amount,
        address referrer,
        address _beneficiary,
        bytes memory _encodedData
    ) external payable returns (address) {
        address vestingAddress = _launchVesting(
            _id,
            _amount,
            _beneficiary,
            _encodedData
        );
        (uint256 feeAmount, ) = _handleFeeManager();
        _handleReferral(referrer, feeAmount);

        return vestingAddress;
    }

    function updateFeeManager(address _feeManager) external onlyOwner {
        require(_feeManager != address(0), "Fee Manager address cant be zero");
        feeManager = IFeeManager(_feeManager);
    }

    function updateReferralManagerMode(
        bool _isReferralManagerEnabled,
        address _referralManager
    ) external onlyOwner {
        require(
            _referralManager != address(0),
            "Referral Manager address cant be zero"
        );
        isReferralManagerEnabled = _isReferralManagerEnabled;
        referralManager = IReferralManager(_referralManager);
    }

    function withdrawERC20(IERC20 _token) external onlyOwner {
        TransferHelper.safeTransfer(
            address(_token),
            msg.sender,
            _token.balanceOf(address(this))
        );
    }
}