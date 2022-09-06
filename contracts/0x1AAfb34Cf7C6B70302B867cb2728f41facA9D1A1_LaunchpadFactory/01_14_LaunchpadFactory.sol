// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./Crowdsale.sol";
import "../library/CloneBase.sol";
import "../Interface/ICrowdSaleMinimalProxy.sol";
import "../Interface/IMinimalProxy.sol";
import "../Interface/IReferralManager.sol";
import "../Interface/IFeeManager.sol";
import "../library/TransferHelper.sol";

contract LaunchpadFactory is Ownable, CloneBase {
    using SafeMath for uint256;
    using SafeMath for uint128;

    /// @notice all the information for this crowdsale in one struct
    struct CrowdsaleInfo {
        address crowdsaleAddress;
        IERC20 tokenAddress;
        address owner;
    }

    struct LaunchCrowdsaleVars {
        uint128 crowdsaleStart;
        uint128 crowdsaleEnd;
        uint128 vestingStart;
        uint128 vestingEnd;
        uint128 cliffDuration;
        uint256 feeAmount;
        address feeToken;
    }

    LaunchCrowdsaleVars private _launchVars;

    //creating a variable requests of type array which will hold value in format that of Request
    CrowdsaleInfo[] public crowdsales;

    uint256 public crowdsaleIndex;

    IFeeManager public feeManager;

    //Trigger for ReferralManager mode
    bool public isReferralManagerEnabled;

    IReferralManager public referralManager;

    event CrowdsaleLaunched(
        uint256 _id,
        address indexed crowdsaleAddress,
        IERC20 token,
        uint256 indexed crowdsaleStartTime
    );

    event ImplementationLaunched(uint256 _id, address _implementation);
    event ImplementationUpdated(uint256 _id, address _implementation);

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
        require(address(feeManager) != address(0), "Add FeeManager");
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

    /**
     * @notice Creates a new Crowdsale contract and registers it in the LaunchpadFactory
     * All invested amount would be accumulated in the Crowdsale Contract
     */
    function launchCrowdsale(uint256 _id, bytes memory _encodedData)
        external
        payable
        returns (address)
    {
        address crowdSaleAddress = _launchCrowdsale(_id, _encodedData);
        _handleFeeManager();

        return crowdSaleAddress;
    }

    function launchCrowdsaleWithReferral(
        uint256 _id,
        address referrer,
        bytes memory _encodedData
    ) external payable returns (address) {
        address crowdSaleAddress = _launchCrowdsale(_id, _encodedData);
        (uint256 feeAmount, ) = _handleFeeManager();
        _handleReferral(referrer, feeAmount);

        return crowdSaleAddress;
    }

    function _launchCrowdsale(uint256 _id, bytes memory _encodedData)
        internal
        returns (address)
    {
        address crowdSaleLibrary = implementationIdVsImplementation[_id];
        require(crowdSaleLibrary != address(0), "Incorrect Id");

        IERC20 tokenAddress;
        uint256 amountAllocation;
        bytes memory crowdsaleTimings;
        IERC20[] memory _inputToken;
        uint256[] memory _rate;

        (
            tokenAddress,
            amountAllocation,
            _inputToken,
            _rate,
            crowdsaleTimings
        ) = abi.decode(
            _encodedData,
            (IERC20, uint256, IERC20[], uint256[], bytes)
        );

        require(address(tokenAddress) != address(0), "Cant be Zero address");
        (
            _launchVars.crowdsaleStart,
            _launchVars.crowdsaleEnd,
            _launchVars.vestingStart,
            _launchVars.vestingEnd,
            _launchVars.cliffDuration
        ) = abi.decode(
            crowdsaleTimings,
            (uint128, uint128, uint128, uint128, uint128)
        );
        require(
            _launchVars.crowdsaleStart >= block.timestamp,
            "Start time should be greater than current"
        ); // ideally at least 24 hours more to give investors time
        require(
            _launchVars.crowdsaleEnd > _launchVars.crowdsaleStart ||
                _launchVars.crowdsaleEnd == 0,
            "End Time could be 0 or > crowdsale StartTime"
        ); //_launchVars.crowdsaleEnd = 0 means crowdsale would be concluded manually by owner
        require(
            amountAllocation > 0,
            "Allocate some amount to start Crowdsale"
        );

        require(_inputToken.length > 0, "Invalid input tokens length");
        require(
            _rate.length == _inputToken.length,
            "Rate & token array length doesnt match"
        );

        if (_launchVars.crowdsaleEnd == 0) {
            // vesting Data would be 0 & can be set when crowdsale is ended manually by owner to avoid confusion
            _launchVars.vestingStart = 0;
            _launchVars.vestingEnd = 0;
            _launchVars.cliffDuration = 0;
        } else if (_launchVars.crowdsaleEnd > _launchVars.crowdsaleStart) {
            require(
                _launchVars.vestingStart >= _launchVars.crowdsaleEnd,
                "Vesting Start time should >= Crowdsale EndTime"
            );
            require(
                _launchVars.vestingEnd >
                    _launchVars.vestingStart.add(_launchVars.cliffDuration),
                "Vesting End Time should be after the cliffPeriod"
            );
        }

        TransferHelper.safeTransferFrom(
            address(tokenAddress),
            msg.sender,
            address(this),
            amountAllocation
        );

        address crowdSaleClone = createClone(crowdSaleLibrary);
        TransferHelper.safeApprove(
            address(tokenAddress),
            address(crowdSaleClone),
            amountAllocation
        );
        IMinimalProxy(crowdSaleClone).init(_encodedData);

        Ownable(crowdSaleClone).transferOwnership(msg.sender);

        crowdsales.push(
            CrowdsaleInfo({ //creating a variable newCrowdsaleInfo which will hold value in format that of CrowdsaleInfo
                crowdsaleAddress: address(crowdSaleClone), //setting the value of keys as being passed by crowdsale deployer during the function call
                tokenAddress: tokenAddress,
                owner: msg.sender
            })
        ); //stacking up every crowdsale info ever made to crowdsales variable

        emit CrowdsaleLaunched(
            _id,
            address(crowdSaleClone),
            tokenAddress,
            _launchVars.crowdsaleStart
        );
        crowdsaleIndex++;

        return address(crowdSaleClone);
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