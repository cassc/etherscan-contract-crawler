// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ClubPayment is Ownable {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    /// @notice new token to airdrop
    IERC20 public CLUBtoken;

    /// @notice payment wallet to transfer new tokens
    address public paymentWallet;

    /// migration event
    event Purchase(address indexed recepient, uint256 indexed paymentType, uint256 amount);

    error NotValidAddress(address checkedAddress);

    modifier onlyValidAddress(address addressToCheck) {
        if (addressToCheck == address(0)) {
            revert NotValidAddress(addressToCheck);
        }
        _;
    }

    constructor(
        IERC20 _CLUBtoken,
        address _paymentWallet
    )
        onlyValidAddress(address(_CLUBtoken))
        onlyValidAddress(_paymentWallet)
    {
        CLUBtoken = _CLUBtoken;
        paymentWallet = _paymentWallet;
    }

    /**
     * @dev Take Club tokens
     * @param _amount amount of club tokens paid
     * @param _paymentType paymentType
     */
    function payment(
        uint256 _amount,
        uint256 _paymentType
    ) external {
        require(
            msg.sender != address(0),
            "airdrop: Caller cannot be zero address!"
        );

        require(
            CLUBtoken.allowance(msg.sender, address(this)) >= _amount,
            "Payer didn't approve matching amount"
        );

        CLUBtoken.transferFrom( msg.sender, paymentWallet, _amount);

        emit Purchase(msg.sender, _paymentType, _amount);
    }


    /**
     * @dev update token contract we want to accept
     * @param _newTokenContract ERC20 contract
     */
    function updateTokenContract(IERC20 _newTokenContract)
        external
        onlyOwner
        onlyValidAddress(address(_newTokenContract))
    {
        CLUBtoken = _newTokenContract;
    }

    /**
     * @dev update payment wallet which will transfer tokens from
     * @param _newPaymentWallet new payment wallet address to update
     */
    function updatePaymentWallet(address _newPaymentWallet)
        external
        onlyOwner
        onlyValidAddress(_newPaymentWallet)
    {
        paymentWallet = _newPaymentWallet;
    }

    /**
     * @dev Recover ERC20 tokens
     * @param tokenAddress The token contract address
     */
    function recover(address tokenAddress) external onlyOwner {
        IERC20 tokenContract = IERC20(tokenAddress);

        if (tokenContract == IERC20(address(0))) {
            // allow to rescue ether
            payable(owner()).transfer(address(this).balance);
        } else {
            tokenContract.safeTransfer(
                owner(),
                tokenContract.balanceOf(address(this))
            );
        }
    }
}