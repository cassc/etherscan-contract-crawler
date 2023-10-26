// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./compliance/RegulatoryCompliant.sol";

/// @notice ERC-20 for working with forward commodity tokens
/// @author Solid World DAO
contract CollateralizedBasketToken is ERC20Burnable, Ownable, RegulatoryCompliant {
    bool private kycRequired;

    error NotRegulatoryCompliant(address subject);

    event KYCRequiredSet(bool indexed kycRequired);

    modifier regulatoryCompliant(address subject) {
        _checkValidCounterparty(subject);
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address _verificationRegistry
    ) ERC20(name, symbol) RegulatoryCompliant(_verificationRegistry) {}

    function setVerificationRegistry(address _verificationRegistry) public override onlyOwner {
        super.setVerificationRegistry(_verificationRegistry);
    }

    function setKYCRequired(bool _kycRequired) external onlyOwner {
        kycRequired = _kycRequired;

        emit KYCRequiredSet(_kycRequired);
    }

    function isKYCRequired() external view returns (bool) {
        return kycRequired;
    }

    function approve(address spender, uint256 amount)
        public
        override
        regulatoryCompliant(msg.sender)
        regulatoryCompliant(spender)
        returns (bool)
    {
        return super.approve(spender, amount);
    }

    function increaseAllowance(address spender, uint addedValue)
        public
        override
        regulatoryCompliant(msg.sender)
        regulatoryCompliant(spender)
        returns (bool)
    {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue)
        public
        override
        regulatoryCompliant(msg.sender)
        regulatoryCompliant(spender)
        returns (bool)
    {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    function transfer(address to, uint256 amount)
        public
        override
        regulatoryCompliant(msg.sender)
        regulatoryCompliant(to)
        returns (bool)
    {
        return super.transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    )
        public
        override
        regulatoryCompliant(msg.sender)
        regulatoryCompliant(from)
        regulatoryCompliant(to)
        returns (bool)
    {
        return super.transferFrom(from, to, amount);
    }

    function mint(address to, uint amount) public onlyOwner regulatoryCompliant(to) {
        _mint(to, amount);
    }

    function burnFrom(address from, uint amount)
        public
        override
        regulatoryCompliant(msg.sender)
        regulatoryCompliant(from)
    {
        super.burnFrom(from, amount);
    }

    function burn(uint amount) public override regulatoryCompliant(msg.sender) {
        super.burn(amount);
    }

    function _checkValidCounterparty(address subject) internal view {
        // owner is whitelisted
        if (subject == owner()) {
            return;
        }

        if (!isValidCounterparty(subject, kycRequired)) {
            revert NotRegulatoryCompliant(subject);
        }
    }
}