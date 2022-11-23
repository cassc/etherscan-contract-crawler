// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC1271Upgradeable.sol";
import "./Errors.sol";
import "./Utils.sol";

//
contract UpstreamCollectiveToken is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    OwnableUpgradeable,
    ERC20PermitUpgradeable,
    ERC721HolderUpgradeable,
    ERC1155HolderUpgradeable,
    IERC1271Upgradeable
{
    bytes4 private constant ERC1271_IS_VALID_SIGNATURE = 0x1626ba7e; // bytes4(keccak256("isValidSignature(bytes32,bytes)"));

    bool public enableDeposits;
    bool public gateDeposits;
    uint256 public exchangeRate;
    mapping(address => bool) public members;

    uint256 public depositFee;
    address public upstreamWalletAddress;
    bool public enableWithdraws;
    uint256 public minEthContribution;

    bool private _paused;
    bool public disableTokenTransfers;

    address private _pendingOwner;

    event EnableDepositsChanged(bool indexed enableDeposits);
    event EnableWithdrawsChanged(bool indexed enableWithdraws);
    event GateDepositsChanged(bool indexed gateDeposits);
    event ExchangeRateChanged(
        uint256 indexed previousRate,
        uint256 indexed newRate
    );
    event MemberAdded(address indexed targetMember);
    event MemberRemoved(address indexed targetMember);
    event FeesChanged(uint256 depositFee);
    event FeePaid(uint256 feeAmount);
    event MemberDepositedFunds(
        address member,
        uint256 etherAmount,
        uint256 tokenAmount
    );
    event MemberWithdrewFunds(address member, uint256 etherAmount);
    event NonDepositEtherReceived(address sender, uint256 etherAmount);
    event TokensSent(address recipient, uint256 tokenAmount);
    event MinEthContributionChanged(uint256 contributionAmount);
    event DisableTokenTransfersChanged(bool disableTokenTransfers);
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
        string memory _tokenName,
        string memory _tokenSymbol,
        address _multisigAddress,
        address _upstreamWalletAddress,
        uint256 _depositFee,
        uint256 _premintAmount,
        uint256 _minEthContribution,
        bool _disableTokenTransfers,
        bool _gateDeposits
    ) public initializer {
        if (
            _multisigAddress == address(0) ||
            _upstreamWalletAddress == address(0)
        ) {
            revert ZeroAddress();
        }

        __ERC20_init(_tokenName, _tokenSymbol);
        __ERC20Burnable_init();
        __ERC20Permit_init(_tokenName);

        enableDeposits = true;
        enableWithdraws = true;
        gateDeposits = _gateDeposits;
        exchangeRate = 1000;
        depositFee = _depositFee;
        upstreamWalletAddress = _upstreamWalletAddress;
        minEthContribution = _minEthContribution;
        _paused = false;
        disableTokenTransfers = _disableTokenTransfers;
        if (_premintAmount > 0) {
            _mint(address(this), _premintAmount * 10**decimals());
        }

        _transferOwnership(_multisigAddress);
    }

    function mint(address to, uint256 amount) public onlyOwner whenNotPaused {
        _mint(to, amount);
    }

    function changeExchangeRate(uint256 newRate)
        public
        onlyOwner
        whenNotPaused
        returns (bool success)
    {
        emit ExchangeRateChanged(exchangeRate, newRate);
        exchangeRate = newRate;
        return true;
    }

    function toggleGateDeposits(bool newValue)
        public
        onlyOwner
        whenNotPaused
        returns (bool success)
    {
        emit GateDepositsChanged(newValue);
        gateDeposits = newValue;
        return true;
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

    function toggleEnableWithdraws(bool newValue)
        public
        onlyOwner
        whenNotPaused
        returns (bool success)
    {
        emit EnableWithdrawsChanged(newValue);
        enableWithdraws = newValue;
        return true;
    }

    function addMember(address targetMember)
        public
        onlyOwner
        whenNotPaused
        returns (bool success)
    {
        emit MemberAdded(targetMember);
        members[targetMember] = true;
        return true;
    }

    function removeMember(address targetMember)
        public
        onlyOwner
        whenNotPaused
        returns (bool success)
    {
        emit MemberRemoved(targetMember);
        delete members[targetMember];
        return true;
    }

    function setDepositFee(uint256 _depositFee) public onlyUpstream {
        depositFee = _depositFee;
        emit FeesChanged(depositFee);
    }

    receive() external payable {
        emit NonDepositEtherReceived(_msgSender(), msg.value);
    }

    function deposit() public payable whenNotPaused {
        // gate deposits from members only (or ungated)
        if (!members[_msgSender()] && gateDeposits) {
            revert NotAMember();
        }

        // gate toggle deposits
        if (!enableDeposits) {
            revert DepositsDisabled();
        }

        // deposit amount must be a positive number
        if (msg.value <= 0) {
            revert AmountTooLow();
        }

        // deposit amout must be equal to or greater than minEthContribution
        if (msg.value < minEthContribution) {
            revert AmountLowerThanMinEthContribution();
        }

        // if the depositer isn't a member yet, make them one (open enrollment)
        if (!members[_msgSender()]) {
            members[_msgSender()] = true;
            emit MemberAdded(_msgSender());
        }

        // calculate deposit fee
        uint256 feeAmount = (depositFee > 0)
            ? ((msg.value / 100) * depositFee)
            : 0;
        uint256 creditAmount = msg.value - feeAmount;
        uint256 tokenAmount = creditAmount * exchangeRate;

        // charge the upstream fee; this can be 0 when the tokenAmount is under 100 wei
        if (feeAmount > 0) {
            (bool feeSent, ) = upstreamWalletAddress.call{value: feeAmount}("");
            if (!feeSent) {
                revert FailedToSendFee();
            }

            emit FeePaid(feeAmount);
        }

        // mint new tokens & send to the member
        _mint(_msgSender(), tokenAmount);

        emit MemberDepositedFunds(_msgSender(), msg.value, tokenAmount);
    }

    function withdraw(uint256 tokenAmount)
        public
        whenNotPaused
        returns (bool success)
    {
        // gate toggle deposits
        if (!enableWithdraws) {
            revert WithdrawsDisabled();
        }

        if (tokenAmount <= 0) {
            revert AmountTooLow();
        }

        uint256 totalMemberTokens = this.balanceOf(_msgSender());
        if (tokenAmount > totalMemberTokens) {
            revert AmountTooHigh();
        }

        // translate relative token share to available treasury balance
        uint256 totalSupply = this.totalSupply();
        uint256 treasuryBalance = address(this).balance;
        uint256 withdrawableEtherAmount = (tokenAmount * treasuryBalance) /
            totalSupply;

        // burn DAO tokens from member
        _burn(_msgSender(), tokenAmount);

        // send the member their ether back
        (bool etherSent, ) = _msgSender().call{value: withdrawableEtherAmount}(
            ""
        );
        if (!etherSent) {
            revert FailedToSendEther();
        }

        emit MemberWithdrewFunds(_msgSender(), withdrawableEtherAmount);

        return true;
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

    function sendTokens(address to, uint256 tokenAmount)
        public
        onlyOwner
        whenNotPaused
        returns (bool success)
    {
        _mint(to, tokenAmount);
        emit TokensSent(to, tokenAmount);

        return true;
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

    function isValidSignature(bytes32 _msgHash, bytes memory _signature)
        external
        view
        override
        returns (bytes4)
    {
        require(_signature.length == 65, "Invalid signature length");
        address recoveredAddress = Utils.recoverSigner(_msgHash, _signature, 0);
        require(members[recoveredAddress], "Invalid signer");
        return ERC1271_IS_VALID_SIGNATURE;
    }

    function changeMinEthContribution(uint256 _contributionAmount)
        public
        onlyOwner
        whenNotPaused
        returns (bool success)
    {
        minEthContribution = _contributionAmount;
        emit MinEthContributionChanged(_contributionAmount);
        return true;
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(
            !disableTokenTransfers,
            "ERC20Pausable: token transfer while paused"
        );
    }

    function changeDisableTokenTransfers(bool _disableTokenTransfers)
        public
        onlyOwner
        whenNotPaused
        returns (bool success)
    {
        disableTokenTransfers = _disableTokenTransfers;
        emit DisableTokenTransfersChanged(_disableTokenTransfers);
        return true;
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