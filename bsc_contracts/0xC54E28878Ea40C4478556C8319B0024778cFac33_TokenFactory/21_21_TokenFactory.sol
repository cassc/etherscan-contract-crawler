// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./DeployFee.sol";

contract TokenFactory is AccessControl, DeployFee {
    using SafeERC20 for IERC20;
    using Address for address;

    bytes32 public constant FACTORY_MANAGER = keccak256("FACTORY_MANAGER");
    bytes32 public constant WHITE_LIST = keccak256("WHITE_LIST");
    bytes32 internal constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 internal constant TX_FEE_WHITELISTED_MANAGER = keccak256("polkalokr.features.txFeeFeature._txFeeManagerRole");
    bytes32 internal constant UPGRADE_MANAGER_ROLE =
        keccak256("UPGRADE_MANAGER_ROLE");

    address public lokrFactory;

    mapping(address => bool) public feePaid;
    mapping (address => bool) public createdByMinted;

    event Deploy(address indexed owner, address tokenProxy);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(FACTORY_MANAGER, _msgSender());
    }

    function setupDeployFee(bytes calldata deployFeeOptions)
        external
        onlyRole(FACTORY_MANAGER)
    {
        (
            uint256 _deployFeeFixedAmount,
            uint256 _deployFeePercentageAmount,
            address _deployFeeBeneficiary,
            address[] memory _deployFeeTokens,
            address[] memory _tokenPriceFeeds,
            address _cryptoPriceFeed,
            bytes32 _deployFeePaymentOption
        ) = abi.decode(
                deployFeeOptions,
                (
                    uint256,
                    uint256,
                    address,
                    address[],
                    address[],
                    address,
                    bytes32
                )
            );
        setupDeployFeeInternal(
            _deployFeeFixedAmount,
            _deployFeePercentageAmount,
            _deployFeeBeneficiary,
            _deployFeeTokens,
            _tokenPriceFeeds,
            _cryptoPriceFeed,
            _deployFeePaymentOption
        );
    }

    function getPaymentTokens()
        external
        view
        returns (IERC20Metadata[] memory paymentTokens)
    {
        paymentTokens = deployFeeTokens;
    }

    function getCryptoPriceFeed() external view returns (address cryptoFeed) {
        cryptoFeed = address(cryptoPriceFeed);
    }

    function addFeedsAndPaymentTokens(
        address[] memory _deployFeeTokens,
        address[] memory _tokenPriceFeeds
    ) external onlyRole(FACTORY_MANAGER) {
        addNewFeedsAndTokens(_deployFeeTokens, _tokenPriceFeeds);
    }

    function updateFeesAndPaymentTokens(
        address[] memory _deployFeeTokens,
        address[] memory _tokenPriceFeeds,
        uint256[] memory _ids
    ) external onlyRole(FACTORY_MANAGER) {
        updateFeedsAndTokens(_deployFeeTokens, _tokenPriceFeeds, _ids);
    }

    function removeFeedAndPaymentToken(uint256 _id)
        external
        onlyRole(FACTORY_MANAGER)
    {
        removeFeedAndToken(_id);
    }

    function changeActivePaymentOption(bytes32 paymentOption)
        external
        onlyRole(FACTORY_MANAGER)
    {
        changeActivePaymentOptionInternal(paymentOption);
    }

    function addToWhiteList(address[] memory whiteListAddresses)
        external
        onlyRole(FACTORY_MANAGER)
    {
        for (uint256 i; i < whiteListAddresses.length; i++) {
            if (!hasRole(WHITE_LIST, whiteListAddresses[i])) {
                _grantRole(WHITE_LIST, whiteListAddresses[i]);
            }
        }
    }

    function removeFromWhiteList(address[] memory removedAddresses)
        external
        onlyRole(FACTORY_MANAGER)
    {
        for (uint256 i; i < removedAddresses.length; i++) {
            if (hasRole(WHITE_LIST, removedAddresses[i])) {
                _revokeRole(WHITE_LIST, removedAddresses[i]);
            }
        }
    }

    function changeActiveDeployFeeAmounts(
        uint256 newFixedAmount,
        uint256 newPercentageAmount
    ) external onlyRole(FACTORY_MANAGER) {
        changeActiveDeployFees(newFixedAmount, newPercentageAmount);
    }

    function getRequiredTokensToPayFee(IERC20Metadata paymentToken)
        external
        view
        returns (uint256 paymentTokenFixedAmount)
    {
        paymentTokenFixedAmount = calculateRequiredTokens(paymentToken);
    }

    function getRequiredMsgValue()
        external
        view
        returns (uint256 fixedRequiredCrypto)
    {
        fixedRequiredCrypto = calculateRequiredCrypto();
    }
    
    function setLokrFactory(address _lokrFactory) external onlyRole(FACTORY_MANAGER) {
        lokrFactory = _lokrFactory;
    }

    function deployToken(
        address tokenInstance,
        address governance,
        address paymentToken,
        bytes calldata tokenInitializerCall
    ) external payable {
        if (
            !hasRole(WHITE_LIST, _msgSender()) &&
            deployFeePaymentOption == FIXED_PAYMENT_OPTION
        ) {
            chargeDeployFee(paymentToken);
        }

        address tokenProxy = address(
            new ERC1967Proxy(tokenInstance, tokenInitializerCall)
        );
        uint256 balance;
        if (
            !hasRole(WHITE_LIST, _msgSender()) &&
            deployFeePaymentOption == PERCENTAGE_UPFRONT_PAYMENT_OPTION
        ) {
            AccessControl(tokenProxy).grantRole(TX_FEE_WHITELISTED_MANAGER, address(this));
            balance = IERC20(tokenProxy).balanceOf(address(this));
            IERC20(tokenProxy).safeTransfer(
                deployFeeBeneficiary,
                ((balance * deployFeePercentageAmount) / EXP_VALUE)
            );
            AccessControl(tokenProxy).renounceRole(TX_FEE_WHITELISTED_MANAGER, address(this));
        }
        balance = IERC20(tokenProxy).balanceOf(address(this));
        IERC20(tokenProxy).safeTransfer(_msgSender(), balance);
        manageRoles(tokenProxy, governance);
        createdByMinted[tokenProxy] = true;
        emit Deploy(_msgSender(), tokenProxy);
    }
    
    function manageRoles(address tokenProxy, address governance) internal {

        if(lokrFactory != address(0)) {
            AccessControl(tokenProxy).grantRole(DEFAULT_ADMIN_ROLE, lokrFactory);
            AccessControl(tokenProxy).grantRole(TX_FEE_WHITELISTED_MANAGER, lokrFactory);
        }

        AccessControl(tokenProxy).grantRole(UPGRADE_MANAGER_ROLE, _msgSender());
        AccessControl(tokenProxy).renounceRole(
            UPGRADE_MANAGER_ROLE,
            address(this)
        );
        AccessControl(tokenProxy).grantRole(GOVERNANCE_ROLE, governance);
        AccessControl(tokenProxy).renounceRole(GOVERNANCE_ROLE, address(this));
        AccessControl(tokenProxy).grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        AccessControl(tokenProxy).renounceRole(
            DEFAULT_ADMIN_ROLE,
            address(this)
        );
    }
}