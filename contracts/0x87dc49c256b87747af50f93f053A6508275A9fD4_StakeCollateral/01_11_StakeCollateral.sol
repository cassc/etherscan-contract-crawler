// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./IUniswapV2Router02.sol";

/// BIGCAP Staking Contract for ladder collateral. Any address can deposit
/// the collateral token, and they must provide the minimum collateral amount
/// and a signature from a signing authority.
/// Addresses can withdraw if they provide a signature from a signing
/// authority. The signing authority will only issue the signature if preconditions
/// are met.
/// ReentrancyGuard provided to eliminate risk of draining the collateral
/// during withdrawal.
/// Pausable implemented to provide emergency stopping the contract in the
/// event of a suspected compromise.
/// Emergency withdrawal functions also provided to pull Native or ERC20 tokens that
/// may have been deposited accidentally.
contract StakeCollateral is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    IUniswapV2Router02 public immutable uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IERC20 public immutable collateralToken;
    mapping(address => uint256) public collateralStaked;
    mapping(address => uint8) public signingNonces;
    uint256 public totalCollateral;
    address public signingAuthority;
    uint256 public minimumCollateral;
    bytes32 public constant WITHDRAW_DIGEST =
        0x9b364f015edab2a56fcadebbd609a6626a0612d05dd5d0b2203e1b1317d70ef7;
    bytes32 public constant LIQUIDATE_DIGEST =
        0x549326edee39fe5b5e5c4a5628b1f98a4f8b528b2fd817c04ed29af7eeb2bff0;
    bytes32 public constant PAYMENT_DIGEST =
        0xb4da9e5df91163d17121bfd299d4e800a475ae2b771bddb01f9d552ea9a3b391;

    event MinimumStakeUpdated(uint256 newMinimumStake);
    event SigningAuthorityUpdated(address newSigningAuthority);
    event Deposit(address depositor, uint256 depositAmount);
    event Withdraw(address withdrawer, uint256 withdrawnAmount);
    event Liquidate(address withdrawer, uint256 amount);
    event LiquidateWithPayment(address withdrawer, uint256 amount);
    event EmergencyWithdrawnNative(address destination);
    event EmergencyWithdrawnToken(address destination, IERC20 token);

    constructor(
        address _signingAuthority,
        IERC20 _collateralToken,
        uint256 _minimumCollateral
    ) {
        signingAuthority = _signingAuthority;
        collateralToken = _collateralToken;
        minimumCollateral = _minimumCollateral;
    }

    receive() external payable {}

    modifier hasCollateral() {
        require(collateralStaked[msg.sender] > 0, "no collateral staked");
        _;
    }

    function setMinimumStake(uint256 _minimumCollateral) external onlyOwner {
        require(
            _minimumCollateral != minimumCollateral,
            "setMinimumStake::minimum stake not changed"
        );
        minimumCollateral = _minimumCollateral;

        emit MinimumStakeUpdated(_minimumCollateral);
    }

    function setSigningAuthority(address _signingAuthority) external onlyOwner {
        require(
            _signingAuthority != signingAuthority,
            "setSigningAuthority::authority not changed"
        );
        signingAuthority = _signingAuthority;

        emit SigningAuthorityUpdated(_signingAuthority);
    }

    // Deposits collateral for the sender
    function deposit() external nonReentrant whenNotPaused {
        require(
            collateralStaked[msg.sender] < minimumCollateral,
            "deposit::already staked collateral"
        );

        collateralToken.safeTransferFrom(
            msg.sender,
            address(this),
            minimumCollateral
        );
        collateralStaked[msg.sender] += minimumCollateral;
        totalCollateral += minimumCollateral;

        emit Deposit(msg.sender, minimumCollateral);
    }

    /// Withdraws all collateral for the sender, if they have a valid signature from a signing authority
    function withdraw(
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS
    ) external hasCollateral nonReentrant whenNotPaused {
        // derive the digest from the current nonce of the account, ensuring signatures only work once
        bytes32 digest = keccak256(
            abi.encode(WITHDRAW_DIGEST, msg.sender, signingNonces[msg.sender])
        );

        address recoveredAddress = ecrecover(digest, sigV, sigR, sigS);
        require(
            signingAuthority == recoveredAddress,
            "withdraw::invalid approval signature"
        );

        uint256 amount = collateralStaked[msg.sender];

        collateralToken.safeTransferFrom(address(this), msg.sender, amount);

        collateralStaked[msg.sender] -= amount;
        totalCollateral -= amount;
        signingNonces[msg.sender] += 1;

        emit Withdraw(msg.sender, amount);
    }

    function liquidate(
        uint256 toLiquidate,
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS
    ) external hasCollateral nonReentrant whenNotPaused {
        // derive the digest from the current nonce of the account, ensuring signatures only work once
        // also only accept a signature of the specific amount to liquidate
        bytes32 digest = keccak256(
            abi.encode(
                LIQUIDATE_DIGEST,
                toLiquidate,
                msg.sender,
                signingNonces[msg.sender]
            )
        );

        address recoveredAddress = ecrecover(digest, sigV, sigR, sigS);
        require(
            signingAuthority == recoveredAddress,
            "liquidate::invalid approval signature"
        );

        uint256 amount = collateralStaked[msg.sender];

        // liquidate the amount
        swapTokensForNative(toLiquidate);

        // return the remainder that wasn't liquidated
        collateralToken.safeTransferFrom(
            address(this),
            msg.sender,
            amount - toLiquidate
        );

        collateralStaked[msg.sender] -= amount;
        totalCollateral -= amount;
        signingNonces[msg.sender] += 1;

        emit Liquidate(msg.sender, amount);
    }

    function liquidateWithPayment(
        uint256 payment,
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS
    ) external hasCollateral nonReentrant whenNotPaused {
        // derive the digest from the current nonce of the account, ensuring signatures only work once
        // also only accept a signature of the specific amount to liquidate
        bytes32 digest = keccak256(
            abi.encode(
                PAYMENT_DIGEST,
                payment,
                msg.sender,
                signingNonces[msg.sender]
            )
        );

        address recoveredAddress = ecrecover(digest, sigV, sigR, sigS);
        require(
            signingAuthority == recoveredAddress,
            "liquidateWithPayment::invalid approval signature"
        );

        // take the payment into the collateral contract
        (bool success, ) = payable(this).call{value: payment}("");
        require(success, "liquidateWithPayment::payment not successful");

        uint256 amount = collateralStaked[msg.sender];

        // return the collateral to the sender
        collateralToken.safeTransferFrom(address(this), msg.sender, amount);

        collateralStaked[msg.sender] -= amount;
        totalCollateral -= amount;
        signingNonces[msg.sender] += 1;

        emit LiquidateWithPayment(msg.sender, amount);
    }

    function swapTokensForNative(uint256 tokens) private {
        address[] memory path = new address[](2);
        path[0] = address(collateralToken);
        path[1] = uniswapV2Router.WETH();
        collateralToken.approve(address(uniswapV2Router), tokens);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokens,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function emergencyWithdrawNative(address destination)
        external
        onlyOwner
        whenPaused
    {
        require(
            address(this).balance > 0,
            "emergencyWithdrawNative::no native to withdraw"
        );
        (bool success, ) = payable(destination).call{
            value: address(this).balance
        }("");
        require(success, "emergencyWithdrawNative::withdrawal failed");

        emit EmergencyWithdrawnNative(destination);
    }

    function emergencyWithdrawToken(address destination, IERC20 token)
        external
        onlyOwner
        whenPaused
    {
        require(
            token.balanceOf(address(this)) > 0,
            "emergencyWithdrawToken::no tokens to withdraw"
        );
        collateralToken.safeTransferFrom(
            address(this),
            destination,
            token.balanceOf(address(this))
        );

        emit EmergencyWithdrawnToken(destination, token);
    }

    function pause() external onlyOwner {
        super._pause();
    }

    function unpause() external onlyOwner {
        super._unpause();
    }
}