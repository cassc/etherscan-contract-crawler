// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IVault.sol";

contract Vault is IVault, AccessControlEnumerable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint256 public constant DIVIDER = 10000;

    EnumerableSet.AddressSet private _paymentTokens;
    EnumerableSet.UintSet private _depositIds;

    IMediator public mediator;
    Beneficiary[] public beneficiaries;

    mapping(uint256 => Deposit) public depositIdToRecipient;

    function beneficiariesList(uint256 offset, uint256 limit) external view returns (Beneficiary[] memory output) {
        uint256 beneficiariesLength_ = beneficiaries.length;
        if (offset >= beneficiariesLength_) return new Beneficiary[](0);
        uint256 to = offset + limit;
        if (beneficiariesLength_ < to) to = beneficiariesLength_;
        output = new Beneficiary[](to - offset);
        for (uint256 i = 0; i < output.length; i++) output[i] = beneficiaries[offset + i];
    }

    function beneficiariesLength() external view returns (uint256) {
        return beneficiaries.length;
    }

    function depositIds(uint256 index) external view returns (uint256) {
        return _depositIds.at(index);
    }

    function depositIdsLength() external view returns (uint256) {
        return _depositIds.length();
    }

    function depositIdsContains(uint256 id) external view returns (bool) {
        return _depositIds.contains(id);
    }

    function depositIdsList(uint256 offset, uint256 limit) external view returns (uint256[] memory output) {
        uint256 depositIdsLength_ = _depositIds.length();
        if (offset >= depositIdsLength_) return new uint256[](0);
        uint256 to = offset + limit;
        if (depositIdsLength_ < to) to = depositIdsLength_;
        output = new uint256[](to - offset);
        for (uint256 i = 0; i < output.length; i++) output[i] = _depositIds.at(offset + i);
    }

    function paymentTokens(uint256 index) external view returns (address) {
        return _paymentTokens.at(index);
    }

    function paymentTokensLength() external view returns (uint256) {
        return _paymentTokens.length();
    }

    function paymentTokensContains(address token) external view returns (bool) {
        return _paymentTokens.contains(token);
    }

    function paymentTokensList(uint256 offset, uint256 limit) external view returns (address[] memory output) {
        uint256 paymentTokensLength_ = _paymentTokens.length();
        if (offset >= paymentTokensLength_) return new address[](0);
        uint256 to = offset + limit;
        if (paymentTokensLength_ < to) to = paymentTokensLength_;
        output = new address[](to - offset);
        for (uint256 i = 0; i < output.length; i++) output[i] = _paymentTokens.at(offset + i);
    }

    constructor(address mediator_) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _updateMediator(mediator_);
    }

    receive() external payable {}

    function addPaymentToken(address token) external onlyRole(ADMIN_ROLE) {
        _paymentTokens.add(token);
        emit PaymentTokenAdded(token);
    }

    function deposit(uint256 id, address token, uint256 amount) external payable {
        _deposit(id, token, amount);
    }

    function depositWithTokenize(IMediator.ERC721Data memory data) external payable {
        _deposit(data.id, data.token, data.price);
        mediator.tokenize(data);
    }

    function removePaymentToken(address token) external onlyRole(ADMIN_ROLE) {
        _paymentTokens.remove(token);
        emit PaymentTokenRemoved(token);
    }

    function updateBeneficiariesList(Beneficiary[] memory beneficiaries_) external onlyRole(ADMIN_ROLE) {
        require(beneficiaries_.length > 0, "Vault: Invalid params length");
        delete beneficiaries;
        uint256 rate = 0;
        for (uint256 i = 0; i < beneficiaries_.length; i++) {
            require(beneficiaries_[i].to != address(0), "Vault: Beneficiary is zero address");
            require(beneficiaries_[i].rate > 0, "Vault: Rate is not positive");
            rate += beneficiaries_[i].rate;
            beneficiaries.push(beneficiaries_[i]);
        }
        if (rate != DIVIDER) revert("Vault: Distribution ne TOTAL_RATE");
        emit BeneficiariesListUpdated(beneficiaries_);
    }

    function updateMediator(address mediator_) external onlyRole(ADMIN_ROLE) {
        _updateMediator(mediator_);
    }

    function withdraw(address token) external nonReentrant onlyRole(ADMIN_ROLE) {
        Beneficiary[] storage beneficiaries_ = beneficiaries;
        require(beneficiaries_.length > 0, "Vault: Beneficiaries not found");
        bool isNative = token == address(0);
        uint256 balance = isNative ? address(this).balance : IERC20(token).balanceOf(address(this));
        require(balance > 0, "Vault: Balance is not positive");
        uint256 paid = 0;
        for (uint256 i = 0; i < beneficiaries_.length; i++) {
            uint256 share = (balance * beneficiaries_[i].rate) / DIVIDER;
            paid += share;
            if (paid > balance) {
                share -= (paid - balance);
            } else if (i == beneficiaries_.length - 1) {
                share += (balance - paid);
            }
            if (isNative) {
                payable(beneficiaries_[i].to).transfer(share);
            } else {
                IERC20(token).transfer(beneficiaries_[i].to, share);
            }
            emit Withdrawal(token, beneficiaries_[i].to, share);
        }
    }

    function _deposit(uint256 id, address token, uint256 amount) private nonReentrant {
        require(!_depositIds.contains(id), "Vault: Deposit id contains");
        require(_paymentTokens.contains(token), "Vault: Token is not supported");
        if (token == address(0)) {
            require(msg.value >= amount, "Vault: Deposit value lt amount");
        } else {
            IERC20(token).transferFrom(msg.sender, address(this), amount);
        }
        _depositIds.add(id);
        depositIdToRecipient[id] = Deposit(msg.sender, token, amount);
        emit Deposited(id, depositIdToRecipient[id]);
    }

    function _updateMediator(address mediator_) private {
        require(mediator_ != address(0), "Vault: Mediator is zero address");
        mediator = IMediator(mediator_);
        emit MediatorUpdated(mediator_);
    }
}