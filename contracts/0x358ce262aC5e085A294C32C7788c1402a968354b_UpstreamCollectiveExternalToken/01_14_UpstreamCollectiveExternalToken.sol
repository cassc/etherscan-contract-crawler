// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./Errors.sol";

contract UpstreamCollectiveExternalToken is
    Initializable,
    OwnableUpgradeable,
    ERC721HolderUpgradeable,
    ERC1155HolderUpgradeable
{
    bool public enableDeposits;

    uint256 public depositFee;
    address public upstreamWalletAddress;
    bool private _paused;

    address private _pendingOwner;

    event EnableDepositsChanged(bool indexed enableDeposits);
    event FeesChanged(uint256 depositFee);
    event FeePaid(uint256 feeAmount);
    event FundsDeposited(address from, uint256 etherAmount);
    event Paused(address account);
    event Unpaused(address account);
    event OwnershipTransferStarted(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyUpstream() {
        if (_msgSender() != upstreamWalletAddress) {
            revert NotUpstream();
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _multisigAddress,
        address _upstreamWalletAddress,
        uint256 _depositFee
    ) public initializer {
        if (
            _multisigAddress == address(0) ||
            _upstreamWalletAddress == address(0)
        ) {
            revert ZeroAddress();
        }

        enableDeposits = true;
        depositFee = _depositFee;
        upstreamWalletAddress = _upstreamWalletAddress;
        _paused = false;
        _transferOwnership(_multisigAddress);
    }

    function toggleEnableDeposits(bool newValue)
        public
        onlyOwner
        whenNotPaused
        returns (bool success)
    {
        emit EnableDepositsChanged(newValue);
        enableDeposits = newValue;
        return true;
    }

    function setDepositFee(uint256 _depositFee) public onlyUpstream {
        depositFee = _depositFee;
        emit FeesChanged(depositFee);
    }

    receive() external payable {
        // gate toggle deposits
        if (!enableDeposits) {
            revert DepositsDisabled();
        }

        // deposit amount must be a positive number
        if (msg.value <= 0) {
            revert AmountTooLow();
        }

        // calculate deposit fee
        uint256 feeAmount = (depositFee > 0)
            ? ((msg.value / 100) * depositFee)
            : 0;

        // charge the upstream fee; this can be 0 when the tokenAmount is under 100 wei
        if (feeAmount > 0) {
            (bool feeSent, ) = upstreamWalletAddress.call{value: feeAmount}("");
            if (!feeSent) {
                revert FailedToSendFee();
            }

            emit FeePaid(feeAmount);
        }

        emit FundsDeposited(_msgSender(), msg.value);
    }

    function deposit() public payable whenNotPaused {
        // gate toggle deposits
        if (!enableDeposits) {
            revert DepositsDisabled();
        }

        // deposit amount must be a positive number
        if (msg.value <= 0) {
            revert AmountTooLow();
        }

        // calculate deposit fee
        uint256 feeAmount = (depositFee > 0)
            ? ((msg.value / 100) * depositFee)
            : 0;

        // charge the upstream fee; this can be 0 when the tokenAmount is under 100 wei
        if (feeAmount > 0) {
            (bool feeSent, ) = upstreamWalletAddress.call{value: feeAmount}("");
            if (!feeSent) {
                revert FailedToSendFee();
            }

            emit FeePaid(feeAmount);
        }

        emit FundsDeposited(_msgSender(), msg.value);
    }

    function sendEther(address to, uint256 amount)
        public
        onlyOwner
        whenNotPaused
        returns (bool success)
    {
        if (amount <= 0) {
            revert AmountTooLow();
        } else if (amount > address(this).balance) {
            revert AmountTooHigh();
        }

        (success, ) = to.call{value: amount}("");
        if (!success) {
            revert FailedToSendEther();
        }
    }

    function callRemote(address to, bytes calldata data)
        public
        onlyOwner
        whenNotPaused
        returns (bool success)
    {
        (success, ) = to.call(data);
        if (!success) {
            revert FailedToCallRemote();
        }
    }

    function callRemoteWithValue(
        address to,
        bytes calldata data,
        uint256 amount
    ) public onlyOwner whenNotPaused returns (bool success) {
        (success, ) = to.call{value: amount}(data);
        if (!success) {
            revert FailedToCallRemoteWithValue();
        }
    }

    function transferTokens(
        address callAddress,
        address recipient,
        uint256 tokens
    ) public onlyOwner whenNotPaused returns (bool success) {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (success, ) = callAddress.call(
            abi.encodeWithSelector(0xa9059cbb, recipient, tokens)
        );
        if (!success) {
            revert FailedToTransferTokens();
        }
    }

    function transferERC721(
        address callAddress,
        address recipient,
        uint256 tokenId
    ) public onlyOwner whenNotPaused returns (bool success) {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (success, ) = callAddress.call(
            abi.encodeWithSelector(0x23b872dd, this, recipient, tokenId)
        );
        if (!success) {
            revert FailedToTransferERC721();
        }
    }

    function transferERC1155(
        address callAddress,
        address recipient,
        uint256 tokenId,
        uint256 amount
    ) public onlyOwner whenNotPaused returns (bool success) {
        // bytes4(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)"))
        (success, ) = callAddress.call(
            abi.encodeWithSelector(
                0xf242432a,
                this,
                recipient,
                tokenId,
                amount,
                ""
            )
        );
        if (!success) {
            revert FailedToTransferERC1155();
        }
    }

    function setUpstreamWalletAddress(address _upstreamWalletAddress)
        public
        onlyUpstream
    {
        upstreamWalletAddress = _upstreamWalletAddress;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function pause() public onlyUpstream whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function unpause() public onlyUpstream whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    function acceptOwnership() external {
        address sender = _msgSender();
        require(
            pendingOwner() == sender,
            "Ownable2Step: caller is not the new owner"
        );
        _transferOwnership(sender);
    }

    function _transferOwnership(address newOwner) internal override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }
}