// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// @title:      Asura
// @url:        https://theasuraproject.com

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IAsuraToken.sol";

contract AsuraMinter is Ownable, ReentrancyGuard {
    using Address for address payable;

    // -=-=-=-=- Errors -=-=-=-=-

    error SaleInactive();
    error PaymentAmountInsufficient();
    error SoldOut();
    error MintAllowanceSurpassed();
    error SignatureIncorrect();
    error PayoutWalletLocked();
    error BalanceIsZero();
    error MinterNotPledgeContract();

    // -=-=-=-=- Signature -=-=-=-=-

    uint256 MINT_ID = 1;
    bytes32 PHASEONE_ID = keccak256("PHASEONE");
    bytes32 PHASETWO_ID = keccak256("PHASETWO");
    bytes32 PUBLIC_ID = keccak256("PUBLIC");
    address public signerAddress;

    // -=-=-=-=- Sale Supply -=-=-=-=-

    mapping(address => uint256) public addressToPhaseTwoMintCount;

    struct SaleSupply {
        uint256 phaseOneSupply;
        uint256 phaseTwoSupply;
        uint256 publicSupply;
    }
    SaleSupply public saleSupply;

    uint256 public teamSupply = 50;

    // -=-=-=-=- Sale Status -=-=-=-=-

    struct SaleStatus {
        uint256 phaseOneTimestampStart;
        uint256 phaseOneTimestampEnd;
        uint256 phaseTwoTimestampStart;
        uint256 phaseTwoTimestampEnd;
        uint256 publicTimestampStart;
        uint256 publicTimestampEnd;
    }
    SaleStatus public saleStatus;

    // -=-=-=-=- Sale Price ・-=-=-=-=-

    struct SalePrice {
        uint256 phaseOnePrice;
        uint256 phaseTwoPrice;
        uint256 publicPrice;
    }
    SalePrice public salePrice;

    // -=-=-=-=- Payout Wallet -=-=-=-=-

    address payoutWallet = 0xa3FF74eF802836dBd4d2C2c5AC950B88EAE237d5;
    bool public isPayoutWalletLocked = false;

    // -=-=-=-=- Token Address -=-=-=-=-
    /**
     * @dev This contract adopt the Minter <-> Token <-> Metadata pattern as inspired by Hapebeast's contract
     **/
    address public tokenAddress;

    // -=-=-=-=- Pledge Contract Address -=-=-=-=-

    address public pledgeContractAddress =
        0x61e8Fb506d1832a6214CfE1DC30862D58cdB9bA5;

    // -=-=-=-=- Constructor -=-=-=-=-

    constructor(
        address _tokenAddress,
        SaleStatus memory _saleStatus,
        SalePrice memory _salePrice,
        SaleSupply memory _saleSupply
    ) {
        tokenAddress = _tokenAddress;
        saleStatus = _saleStatus;
        salePrice = _salePrice;
        saleSupply = _saleSupply;
    }

    // -=-=-=-=- Token Information -=-=-=-=-
    function totalSupply() public view returns (uint256) {
        return IAsuraToken(tokenAddress).totalSupply();
    }

    function numberMinted(address _owner) public view returns (uint256) {
        return IAsuraToken(tokenAddress).numberMinted(_owner);
    }

    // -=-=-=-=- Mint -=-=-=-=-

    function mintPhaseOne(
        uint256 _amount,
        uint256 _maxAmount,
        bytes memory _sig
    ) external payable {
        if (
            block.timestamp < saleStatus.phaseOneTimestampStart ||
            block.timestamp > saleStatus.phaseOneTimestampEnd
        ) revert SaleInactive();
        if (totalSupply() + _amount > saleSupply.phaseOneSupply)
            revert SoldOut();
        if (msg.value < salePrice.phaseOnePrice * _amount)
            revert PaymentAmountInsufficient();
        if (numberMinted(msg.sender) + _amount > _maxAmount)
            revert MintAllowanceSurpassed();
        if (
            !validateSignature(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        _maxAmount,
                        MINT_ID,
                        PHASEONE_ID
                    )
                ),
                _sig
            )
        ) revert SignatureIncorrect();

        _mintPrivate(msg.sender, _amount);
    }

    function mintPhaseTwo(
        uint256 _amount,
        uint256 _maxAmount,
        bytes memory _sig
    ) external payable {
        if (
            block.timestamp < saleStatus.phaseTwoTimestampStart ||
            block.timestamp > saleStatus.phaseTwoTimestampEnd
        ) revert SaleInactive();
        if (totalSupply() + _amount > saleSupply.phaseTwoSupply)
            revert SoldOut();
        if (msg.value < salePrice.phaseTwoPrice * _amount)
            revert PaymentAmountInsufficient();
        if (addressToPhaseTwoMintCount[msg.sender] + _amount > _maxAmount)
            revert MintAllowanceSurpassed();
        if (
            !validateSignature(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        _maxAmount,
                        MINT_ID,
                        PHASETWO_ID
                    )
                ),
                _sig
            )
        ) revert SignatureIncorrect();

        addressToPhaseTwoMintCount[msg.sender] += _amount;
        _mintPrivate(msg.sender, _amount);
    }

    function mintPublic(
        uint256 _amount,
        uint256 _maxAmount,
        bytes memory _sig
    ) external payable nonReentrant {
        if (
            block.timestamp < saleStatus.publicTimestampStart ||
            block.timestamp > saleStatus.publicTimestampEnd
        ) revert SaleInactive();
        if (totalSupply() + _amount > saleSupply.publicSupply) revert SoldOut();
        if (msg.value < salePrice.publicPrice * _amount)
            revert PaymentAmountInsufficient();
        if (_amount > _maxAmount) revert MintAllowanceSurpassed();
        if (
            !validateSignature(
                keccak256(
                    abi.encodePacked(msg.sender, _maxAmount, MINT_ID, PUBLIC_ID)
                ),
                _sig
            )
        ) revert SignatureIncorrect();

        _mintPrivate(msg.sender, _amount);
    }

    function mintTeam(address _to, uint256 _amount) external onlyOwner {
        if (totalSupply() + _amount > teamSupply) revert SoldOut();

        teamSupply -= _amount;
        _mintPrivate(_to, _amount);
    }

    /**
     * @dev Pledge Mint Integration
     **/

    function pledgeMint(address _to, uint8 _amount) external payable {
        if (pledgeContractAddress != msg.sender)
            revert MinterNotPledgeContract();
        _mintPrivate(_to, uint256(_amount));
    }

    function setPledgeContractAddress(address _pledgeContractAddress)
        external
        onlyOwner
    {
        pledgeContractAddress = _pledgeContractAddress;
    }

    function _mintPrivate(address _to, uint256 _amount) internal {
        IAsuraToken(tokenAddress).mint(_to, _amount);
    }

    // -=-=-=-=- Setters -=-=-=-=-

    function setSaleStatus(SaleStatus memory _saleStatus) external onlyOwner {
        saleStatus = _saleStatus;
    }

    function setSalePrice(SalePrice memory _salePrice) external onlyOwner {
        salePrice = _salePrice;
    }

    function setSaleSupply(SaleSupply memory _saleSupply) external onlyOwner {
        saleSupply = _saleSupply;
    }

    function setTeamSupply(uint256 _teamSupply) external onlyOwner {
        teamSupply = _teamSupply;
    }

    function setMintId(uint256 _mintId) external onlyOwner {
        MINT_ID = _mintId;
    }

    // -=-=-=-=- Getters -=-=-=-=-

    function addressToPhaseOneMintCount(address _owner)
        external
        view
        returns (uint256)
    {
        return numberMinted(_owner);
    }

    function getSaleStatus() external view returns (uint8) {
        if (
            block.timestamp > saleStatus.phaseOneTimestampStart &&
            block.timestamp < saleStatus.phaseOneTimestampEnd
        ) {
            return 1;
        } else if (
            block.timestamp > saleStatus.phaseTwoTimestampStart &&
            block.timestamp < saleStatus.phaseTwoTimestampEnd
        ) {
            return 2;
        } else if (
            block.timestamp > saleStatus.publicTimestampStart &&
            block.timestamp < saleStatus.publicTimestampEnd
        ) {
            return 3;
        } else if (block.timestamp > saleStatus.publicTimestampEnd) {
            return 4;
        }
        return 0;
    }

    // -=-=-=-=- Withdraw -=-=-=-=-

    function withdraw() public onlyOwner {
        if (address(this).balance == 0) revert BalanceIsZero();

        payable(payoutWallet).sendValue(address(this).balance);
    }

    /**
     * @dev Retain ability to modify payout wallet in case of emergency
     * Ability to lock wallet to maintain the integrity of the contract
     **/
    function setPayoutWallet(address _payoutWallet) external onlyOwner {
        if (isPayoutWalletLocked) revert PayoutWalletLocked();
        payoutWallet = _payoutWallet;
    }

    function lockPayoutWallet() external onlyOwner {
        isPayoutWalletLocked = true;
    }

    // -=-=-=-=- Signature -=-=-=-=-

    function validateSignature(bytes32 _signedHash, bytes memory _sig)
        internal
        view
        returns (bool)
    {
        return ECDSA.recover(_signedHash, _sig) == signerAddress;
    }

    function setSignerAddress(address _signerAddress) external onlyOwner {
        signerAddress = _signerAddress;
    }
}

// @dev: marcelc63