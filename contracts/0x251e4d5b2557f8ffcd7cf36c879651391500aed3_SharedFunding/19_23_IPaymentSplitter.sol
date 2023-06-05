// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./IFundingAllocations.sol";

/**
 * @title IPaymentSplitter
 * @author ChangeDao
 */
interface IPaymentSplitter {
    /* ============== Events ============== */

    /**
     * @notice Emitted when a payee is added to the _payees array
     */
    event PayeeAdded(address indexed account, uint256 indexed shares);

    /**
     * @notice Emitted when ETH is released to an address
     */
    event ETHPaymentReleased(address indexed to, uint256 indexed amount);

    /**
     * @notice Emitted when DAI or USDC is released to an address
     */
    event StablecoinPaymentReleased(
        IERC20 indexed token,
        address indexed to,
        uint256 indexed amount
    );

    /**
     * @notice Emitted when the contract directly receives ETH
     */
    event ETHPaymentReceived(address indexed from, uint256 indexed amount);

    /**
     * @notice Emitted when a paymentSplitter clone is initialized
     */
    event PaymentSplitterInitialized(
        address indexed changeMaker,
        bytes32 indexed contractType,
        IPaymentSplitter indexed paymentSplitterCloneAddress,
        uint256 changeDaoShares,
        address changeDaoWallet,
        IFundingAllocations allocations
    );

    /* ============== Receive ============== */

    receive() external payable;

    /* ============== Initialize ============== */

    function initialize(
        address _changeMaker,
        bytes32 _contractType,
        IFundingAllocations _allocations,
        address[] memory payees_,
        uint256[] memory shares_
    ) external payable;

    /* ============== Getter Functions ============== */

    function changeDaoShares() external view returns (uint256);

    function changeDaoWallet() external view returns (address payable);

    function DAI_ADDRESS() external view returns (IERC20);

    function USDC_ADDRESS() external view returns (IERC20);

    function payeesLength() external view returns (uint256);

    function getPayee(uint256 _index) external view returns (address);

    function totalShares() external view returns (uint256);

    function totalReleasedETH() external view returns (uint256);

    function totalReleasedERC20(IERC20 _token) external view returns (uint256);

    function shares(address _account) external view returns (uint256);

    function recipientReleasedETH(address _account)
        external
        view
        returns (uint256);

    function recipientReleasedERC20(IERC20 _token, address _account)
        external
        view
        returns (uint256);

    function pendingETHPayment(address _account)
        external
        view
        returns (uint256);

    function pendingERC20Payment(IERC20 _token, address _account)
        external
        view
        returns (uint256);

    /* ============== Release Functions ============== */

    function releaseETH(address payable _account) external;

    function releaseERC20(IERC20 _token, address _account) external;

    function releaseAll(address payable _account) external;

    function releaseAllFundingTypes(
        address[] memory _fundingTokens,
        address payable _account
    ) external;

    function ownerReleaseAll() external;
}