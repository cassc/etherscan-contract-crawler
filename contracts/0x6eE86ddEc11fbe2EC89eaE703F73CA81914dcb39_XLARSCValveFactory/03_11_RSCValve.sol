// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IFeeFactory.sol";


contract XLARSCValve is Initializable, OwnableUpgradeable {
    address public distributor;
    address public controller;
    bool public immutableController;
    bool public autoEthDistribution;
    uint256 public minAutoDistributionAmount;
    uint256 public platformFee;
    IFeeFactory public factory;

    address payable [] public recipients;
    mapping(address => uint256) public recipientsPercentage;
    uint256 public numberOfRecipients = 0;

    event SetRecipients(address payable [] recipients, uint256[] percentages, string[] names);
    event DistributeToken(address token, uint256 amount);
    event DistributorChanged(address oldDistributor, address newDistributor);
    event ControllerChanged(address oldController, address newController);

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

    // Throw when RSC doesnt have any ERC20 balance for given token
    error Erc20ZeroBalanceError();

    // Throw when distributor address is same as submit one
    error DistributorAlreadyConfiguredError();

    // Throw when distributor address is same as submit one
    error ControllerAlreadyConfiguredError();

    // Throw when change is triggered for immutable controller
    error ImmutableControllerError();


    /**
     * @dev Checks whether sender is distributor
     */
    modifier onlyDistributor {
        if (msg.sender != distributor) {
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
     * @param _distributor address which can distribute ERC20 tokens or ETH
     * @param _immutableController flag indicating whether controller could be changed
     * @param _autoEthDistribution flag indicating whether ETH will be automatically distributed or manually
     * @param _minAutoDistributionAmount Minimum ETH amount to trigger auto ETH distribution
     * @param _platformFee Percentage defining fee for distribution services
     * @param _factoryAddress Address of the factory used for creating this RSC
     * @param _initialRecipients Initial recipient addresses
     * @param _percentages initial percentages for recipients
     * @param _names names for recipients
     */
    function initialize(
        address _owner,
        address _controller,
        address _distributor,
        bool _immutableController,
        bool _autoEthDistribution,
        uint256 _minAutoDistributionAmount,
        uint256 _platformFee,
        address _factoryAddress,
        address payable [] memory _initialRecipients,
        uint256[] memory _percentages,
        string[] memory _names
    ) public initializer {

        distributor = _distributor;
        controller = _controller;
        immutableController = _immutableController;
        autoEthDistribution = _autoEthDistribution;
        minAutoDistributionAmount = _minAutoDistributionAmount;
        factory = IFeeFactory(_factoryAddress);
        platformFee = _platformFee;

        _setRecipients(_initialRecipients, _percentages, _names);
        _transferOwnership(_owner);
    }

    fallback() external payable {
        if (autoEthDistribution && msg.value >= minAutoDistributionAmount) {
            _redistributeEth(msg.value);
        }
    }

    receive() external payable {
        if (autoEthDistribution && msg.value >= minAutoDistributionAmount) {
            _redistributeEth(msg.value);
        }
    }

    /**
     * @notice Internal function to redistribute ETH based on percentages assign to the recipients
     * @param _valueToDistribute ETH amount to be distribute
     */
    function _redistributeEth(uint256 _valueToDistribute) internal {
        if (platformFee > 0) {
            uint256 fee = _valueToDistribute / 10000 * platformFee;
            _valueToDistribute -= fee;
            address payable platformWallet = factory.platformWallet();
            (bool success,) = platformWallet.call{value: fee}("");
            if (success == false) {
                revert TransferFailedError();
            }
        }

        uint256 recipientsLength = recipients.length;
        for (uint256 i = 0; i < recipientsLength;) {
            address payable recipient = recipients[i];
            uint256 percentage = recipientsPercentage[recipient];
            uint256 amountToReceive = _valueToDistribute / 10000 * percentage;
            (bool success,) = payable(recipient).call{value: amountToReceive}("");
            if (success == false) {
                revert TransferFailedError();
            }
            unchecked{i++;}
        }
    }

    /**
     * @notice External function to redistribute ETH based on percentages assign to the recipients
     */
    function redistributeEth() external onlyDistributor {
        _redistributeEth(address(this).balance);
    }


    /**
     * @notice Internal function to check whether percentages are equal to 100%
     * @return valid boolean indicating whether sum of percentage == 100%
     */
    function _percentageIsValid() internal view returns (bool valid){
        uint256 recipientsLength = recipients.length;
        uint256 percentageSum;

        for (uint256 i = 0; i < recipientsLength;) {
            address recipient = recipients[i];
            percentageSum += recipientsPercentage[recipient];
            unchecked {i++;}
        }

        return percentageSum == 10000;
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
        if (numberOfRecipients == 0) {
            return;
        }

        for (uint256 i = 0; i < numberOfRecipients;) {
            address recipient = recipients[i];
            recipientsPercentage[recipient] = 0;
            unchecked{i++;}
        }
        delete recipients;
        numberOfRecipients = 0;
    }

    /**
     * @notice Internal function for setting recipients
     * @param _newRecipients Addresses to be added
     * @param _percentages new percentages for recipients
     * @param _names names for recipients
     */
    function _setRecipients(
        address payable [] memory _newRecipients,
        uint256[] memory _percentages,
        string[] memory _names
    ) internal {
        uint256 newRecipientsLength = _newRecipients.length;

        if (
            newRecipientsLength != _percentages.length &&
            newRecipientsLength != _names.length
        ) {
            revert InconsistentDataLengthError();
        }

        _removeAll();

        for (uint256 i = 0; i < newRecipientsLength;) {
            _addRecipient(_newRecipients[i], _percentages[i]);
            unchecked{i++;}
        }

        numberOfRecipients = newRecipientsLength;
        if (_percentageIsValid() == false) {
            revert InvalidPercentageError();
        }

        emit SetRecipients(_newRecipients, _percentages, _names);
    }

    /**
     * @notice External function for setting recipients
     * @param _newRecipients Addresses to be added
     * @param _percentages new percentages for recipients
     * @param _names names for recipients
     */
    function setRecipients(
        address payable [] memory _newRecipients,
        uint256[] memory _percentages,
        string[] memory _names
    ) public onlyController {
        _setRecipients(_newRecipients, _percentages, _names);
    }


    /**
     * @notice External function to redistribute ERC20 token based on percentages assign to the recipients
     * @param _token Address of the ERC20 token to be distribute
     */
    function redistributeToken(address _token) external onlyDistributor {
        uint256 recipientsLength = recipients.length;

        IERC20 erc20Token = IERC20(_token);
        uint256 contractBalance = erc20Token.balanceOf(address(this));
        if (contractBalance == 0) {
            revert Erc20ZeroBalanceError();
        }

         if (platformFee > 0) {
            uint256 fee = contractBalance / 10000 * platformFee;
            contractBalance -= fee;
            address payable platformWallet = factory.platformWallet();
             erc20Token.transfer(platformWallet, fee);
        }

        for (uint256 i = 0; i < recipientsLength;) {
            address payable recipient = recipients[i];
            uint256 percentage = recipientsPercentage[recipient];
            uint256 amountToReceive = contractBalance / 10000 * percentage;
            erc20Token.transfer(recipient, amountToReceive);
            unchecked{i++;}
        }
        emit DistributeToken(_token, contractBalance);
    }

    /**
     * @notice External function to set distributor address
     * @param _distributor address of new distributor
     */
    function setDistributor(address _distributor) external onlyOwner {
        if (_distributor == distributor) {
            revert DistributorAlreadyConfiguredError();
        }
        emit DistributorChanged(distributor, _distributor);
        distributor = _distributor;
    }

    /**
     * @notice External function to set controller address, if set to address(0), unable to change it
     * @param _controller address of new controller
     */
    function setController(address _controller) external onlyOwner {
        if (controller == address(0) || immutableController) {
            revert ImmutableControllerError();
        }
        emit ControllerChanged(controller, _controller);
        controller = _controller;
    }
}