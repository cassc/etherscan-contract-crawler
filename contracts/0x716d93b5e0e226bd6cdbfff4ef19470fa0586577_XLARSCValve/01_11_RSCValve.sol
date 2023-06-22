// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IFeeFactory.sol";
import "../interfaces/IRecursiveRSC.sol";


contract XLARSCValve is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    mapping(address => bool) public distributors;
    address public controller;
    bool public isImmutableRecipients;
    bool public isAutoNativeCurrencyDistribution;
    uint256 public minAutoDistributionAmount;
    uint256 public platformFee;
    IFeeFactory public factory;

    address payable [] public recipients;
    mapping(address => uint256) public recipientsPercentage;

    event SetRecipients(address payable [] recipients, uint256[] percentages);
    event DistributeToken(address token, uint256 amount);
    event DistributorChanged(address distributor, bool isDistributor);
    event ControllerChanged(address oldController, address newController);
    event MinAutoDistributionAmountChanged(uint256 oldAmount, uint256 newAmount);
    event AutoNativeCurrencyDistributionChanged(bool oldValue, bool newValue);
    event ImmutableRecipients(bool isImmutableRecipients);

    // Throw when if sender is not distributor
    error OnlyDistributorError();

    // Throw when sender is not controller
    error OnlyControllerError();

    // Throw when transaction fails
    error TransferFailedError();

    // Throw when submitted recipient with address(0)
    error NullAddressRecipientError();

    // Throw if recipient is already in contract
    error RecipientAlreadyAddedError();

    // Throw when arrays are submit without same length
    error InconsistentDataLengthError();

    // Throw when sum of percentage is not 100%
    error InvalidPercentageError();

    // Throw when distributor address is same as submit one
    error DistributorAlreadyConfiguredError();

    // Throw when distributor address is same as submit one
    error ControllerAlreadyConfiguredError();

    // Throw when change is triggered for immutable recipients
    error ImmutableRecipientsError();

    // Throw when renounce ownership is called
    error RenounceOwnershipForbidden();


    /**
     * @dev Checks whether sender is distributor
     */
    modifier onlyDistributor {
        if (distributors[msg.sender] == false) {
            revert OnlyDistributorError();
        }
        _;
    }

    /**
     * @dev Checks whether sender is controller
     */
    modifier onlyController {
        if (msg.sender != controller) {
            revert OnlyControllerError();
        }
        _;
    }

     /**
     * @dev Constructor function, can be called only once
     * @param _owner Owner of the contract
     * @param _controller address which control setting / removing recipients
     * @param _distributors list of addresses which can distribute ERC20 tokens or native currency
     * @param _isImmutableRecipients flag indicating whether recipients could be changed
     * @param _isAutoNativeCurrencyDistribution flag indicating whether native currency will be automatically distributed or manually
     * @param _minAutoDistributionAmount Minimum native currency amount to trigger auto native currency distribution
     * @param _platformFee Percentage defining fee for distribution services
     * @param _factoryAddress Address of the factory used for creating this RSC
     * @param _initialRecipients Initial recipient addresses
     * @param _percentages initial percentages for recipients
     */
    function initialize(
        address _owner,
        address _controller,
        address[] memory _distributors,
        bool _isImmutableRecipients,
        bool _isAutoNativeCurrencyDistribution,
        uint256 _minAutoDistributionAmount,
        uint256 _platformFee,
        address _factoryAddress,
        address payable [] memory _initialRecipients,
        uint256[] memory _percentages
    ) public initializer {

        uint256 distributorsLength = _distributors.length;
        for (uint256 i = 0; i < distributorsLength;) {
            distributors[_distributors[i]] = true;
            unchecked{i++;}
        }

        controller = _controller;
        isAutoNativeCurrencyDistribution = _isAutoNativeCurrencyDistribution;
        minAutoDistributionAmount = _minAutoDistributionAmount;
        factory = IFeeFactory(_factoryAddress);
        platformFee = _platformFee;

        _setRecipients(_initialRecipients, _percentages);
        isImmutableRecipients = _isImmutableRecipients;
        _transferOwnership(_owner);
    }

    fallback() external payable {
        // Check whether automatic native currency distribution is enabled
        // and that contractBalance is more than automatic distribution threshold
        uint256 contractBalance = address(this).balance;
        if (isAutoNativeCurrencyDistribution && contractBalance >= minAutoDistributionAmount) {
            _redistributeNativeCurrency(contractBalance);
        }
    }

    receive() external payable {
        // Check whether automatic native currency distribution is enabled
        // and that contractBalance is more than automatic distribution threshold
        uint256 contractBalance = address(this).balance;
        if (isAutoNativeCurrencyDistribution && contractBalance >= minAutoDistributionAmount) {
            _redistributeNativeCurrency(contractBalance);
        }
    }

    /**
     * @notice External function to return number of recipients
     */
    function numberOfRecipients() external view returns(uint256) {
        return recipients.length;
    }

    /**
     * @notice Internal function to redistribute native currency based on percentages assign to the recipients
     * @param _valueToDistribute native currency amount to be distributed
     */
    function _redistributeNativeCurrency(uint256 _valueToDistribute) internal {
        uint256 fee = ((_valueToDistribute * platformFee) / 10000000);
        _valueToDistribute -= fee;

        if(_valueToDistribute < 10000000) {
            return;
        }

        address payable platformWallet = factory.platformWallet();
        if(fee != 0 && platformWallet != address(0)) {
            (bool success,) = platformWallet.call{value: fee}("");
            if (success == false) {
                revert TransferFailedError();
            }
        }

        uint256 recipientsLength = recipients.length;
        for (uint256 i = 0; i < recipientsLength;) {
            address payable recipient = recipients[i];
            uint256 percentage = recipientsPercentage[recipient];
            uint256 amountToReceive = ((_valueToDistribute * percentage) / 10000000);
            (bool success,) = payable(recipient).call{value: amountToReceive}("");
            if (success == false) {
                revert TransferFailedError();
            }
            _recursiveNativeCurrencyDistribution(recipient);
            unchecked{i++;}
        }
    }

    /**
     * @notice External function to redistribute native currency based on percentages assign to the recipients
     */
    function redistributeNativeCurrency() external onlyDistributor {
        _redistributeNativeCurrency(address(this).balance);
    }

    /**
     * @notice Internal function for adding recipient to revenue share
     * @param _recipient Fixed amount of token user want to buy
     * @param _percentage code of the affiliation partner
     */
    function _addRecipient(address payable _recipient, uint256 _percentage) internal {
        if (_recipient == address(0)) {
            revert NullAddressRecipientError();
        }
        if (recipientsPercentage[_recipient] != 0) {
            revert RecipientAlreadyAddedError();
        }
        recipients.push(_recipient);
        recipientsPercentage[_recipient] = _percentage;
    }

    /**
     * @notice Internal function for removing all recipients
     */
    function _removeAll() internal {
        uint256 recipientsLength = recipients.length;

        if (recipientsLength == 0) {
            return;
        }

        for (uint256 i = 0; i < recipientsLength;) {
            address recipient = recipients[i];
            recipientsPercentage[recipient] = 0;
            unchecked{i++;}
        }
        delete recipients;
    }

    /**
     * @notice Internal function for setting recipients
     * @param _newRecipients Addresses to be added
     * @param _percentages new percentages for recipients
     */
    function _setRecipients(
        address payable [] memory _newRecipients,
        uint256[] memory _percentages
    ) internal {
        if (isImmutableRecipients) {
            revert ImmutableRecipientsError();
        }

        uint256 newRecipientsLength = _newRecipients.length;

        if (newRecipientsLength != _percentages.length) {
            revert InconsistentDataLengthError();
        }

        _removeAll();

        uint256 percentageSum;
        for (uint256 i = 0; i < newRecipientsLength;) {
            uint256 percentage = _percentages[i];
            _addRecipient(_newRecipients[i], percentage);
            percentageSum += percentage;
            unchecked{i++;}
        }

        if (percentageSum != 10000000) {
            revert InvalidPercentageError();
        }

        emit SetRecipients(_newRecipients, _percentages);
    }

    /**
     * @notice External function for setting recipients
     * @param _newRecipients Addresses to be added
     * @param _percentages new percentages for recipients
     */
    function setRecipients(
        address payable [] memory _newRecipients,
        uint256[] memory _percentages
    ) public onlyController {
        _setRecipients(_newRecipients, _percentages);
    }

    /**
     * @notice External function for setting recipients and make recipients immutable
     * @param _newRecipients Addresses to be added
     * @param _percentages new percentages for recipients
     */
    function setRecipientsExt(
        address payable [] memory _newRecipients,
        uint256[] memory _percentages
    ) public onlyController {
        _setRecipients(_newRecipients, _percentages);
        _setImmutableRecipients();
    }

    /**
     * @notice External function to redistribute ERC20 token based on percentages assign to the recipients
     * @param _token Address of the ERC20 token to be distribute
     */
    function redistributeToken(address _token) external onlyDistributor {
        IERC20 erc20Token = IERC20(_token);
        uint256 contractBalance = erc20Token.balanceOf(address(this));

        uint256 fee = ((contractBalance * platformFee) / 10000000);
        contractBalance -= fee;

        if (contractBalance < 10000000) {
            // because of percentage
            return;
        }

        uint256 recipientsLength = recipients.length;

        address payable platformWallet = factory.platformWallet();
        if(fee != 0 && platformWallet != address(0)) {
            erc20Token.safeTransfer(platformWallet, fee);
        }

        for (uint256 i = 0; i < recipientsLength;) {
            address payable recipient = recipients[i];
            uint256 percentage = recipientsPercentage[recipient];
            uint256 amountToReceive = ((contractBalance * percentage) / 10000000);
            erc20Token.safeTransfer(recipient, amountToReceive);
            _recursiveERC20Distribution(recipient, _token);
            unchecked{i++;}
        }
        emit DistributeToken(_token, contractBalance);
    }

    /**
     * @notice External function to set distributor address
     * @param _distributor address of new distributor
     * @param _isDistributor bool indicating whether address is / isn't distributor
     */
    function setDistributor(address _distributor, bool _isDistributor) external onlyOwner {
        emit DistributorChanged(_distributor, _isDistributor);
        distributors[_distributor] = _isDistributor;
    }

    /**
     * @notice External function to set controller address, if set to address(0), unable to change it
     * @param _controller address of new controller
     */
    function setController(address _controller) external onlyOwner {
        emit ControllerChanged(controller, _controller);
        controller = _controller;
    }

    /**
     * @notice Internal function to check whether recipient should be recursively distributed
     * @param _recipient Address of recipient to recursively distribute
     * @param _token token to be distributed
     */
    function _recursiveERC20Distribution(address _recipient, address _token) internal {
        // Handle Recursive token distribution
        IRecursiveRSC recursiveRecipient = IRecursiveRSC(_recipient);

        // Wallets have size 0 and contracts > 0. This way we can distinguish them.
        uint256 recipientSize;
        assembly {recipientSize := extcodesize(_recipient)}
        if (recipientSize > 0) {
            // Validate this contract is distributor in child recipient
            try recursiveRecipient.distributors(address(this)) returns(bool isBranchDistributor) {
                if (isBranchDistributor) {
                    recursiveRecipient.redistributeToken(_token);
                }
            } catch {return;}  // unable to recursively distribute
        }
    }

    /**
     * @notice Internal function to check whether recipient should be recursively distributed
     * @param _recipient Address of recipient to recursively distribute
     */
    function _recursiveNativeCurrencyDistribution(address _recipient) internal {
        // Handle Recursive token distribution
        IRecursiveRSC recursiveRecipient = IRecursiveRSC(_recipient);

        // Wallets have size 0 and contracts > 0. This way we can distinguish them.
        uint256 recipientSize;
        assembly {recipientSize := extcodesize(_recipient)}
        if (recipientSize > 0) {

            // Check whether child recipient have autoNativeCurrencyDistribution set to true,
            // if yes tokens will be recursively distributed automatically
            try recursiveRecipient.isAutoNativeCurrencyDistribution() returns(bool childAutoNativeCurrencyDistribution) {
                if (childAutoNativeCurrencyDistribution == true) {
                    return;
                }
            } catch {return;}

            // Validate this contract is distributor in child recipient
            try recursiveRecipient.distributors(address(this)) returns(bool isBranchDistributor) {
                if (isBranchDistributor) {
                    recursiveRecipient.redistributeNativeCurrency();
                }
            } catch {return;}  // unable to recursively distribute
        }
    }

    /**
     * @notice Internal function for setting immutable recipients to true
     */
    function _setImmutableRecipients() internal {
        emit ImmutableRecipients(true);
        isImmutableRecipients = true;
    }

    /**
     * @notice external function for setting immutable recipients to true
    */
    function setImmutableRecipients() external onlyOwner {
        if (isImmutableRecipients) {
            revert ImmutableRecipientsError();
        }

        _setImmutableRecipients();
    }

    /**
     * @notice external function for setting auto native currency distribution
     * @param _isAutoNativeCurrencyDistribution Bool switching whether auto native currency distribution is enabled
     */
    function setAutoNativeCurrencyDistribution(bool _isAutoNativeCurrencyDistribution) external onlyOwner {
        emit AutoNativeCurrencyDistributionChanged(isAutoNativeCurrencyDistribution, _isAutoNativeCurrencyDistribution);
        isAutoNativeCurrencyDistribution = _isAutoNativeCurrencyDistribution;
    }

    /**
     * @notice external function for setting auto native currency distribution
     * @param _minAutoDistributionAmount New minimum distribution amount
     */
    function setMinAutoDistributionAmount(uint256 _minAutoDistributionAmount) external onlyOwner {
        emit MinAutoDistributionAmountChanged(minAutoDistributionAmount, _minAutoDistributionAmount);
        minAutoDistributionAmount = _minAutoDistributionAmount;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will is forbidden for RSC contract
     */
    function renounceOwnership() public view override onlyOwner {
        revert RenounceOwnershipForbidden();
    }
}