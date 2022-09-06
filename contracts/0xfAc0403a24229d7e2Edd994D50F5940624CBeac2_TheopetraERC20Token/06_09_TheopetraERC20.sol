// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;

import "../Types/ERC20Permit.sol";
import "../Types/ERC20.sol";
import "../Types/TheopetraAccessControlled.sol";

import "../Libraries/SafeMath.sol";

contract TheopetraERC20Token is ERC20Permit, TheopetraAccessControlled {
    using SafeMath for uint256;

    event UpdateMintLimit(uint256 mintLimit);

    uint256 private _initialSupply;
    uint256 private _mintLimit;

    constructor(address _authority)
        ERC20("Theopetra", "THEO", 9)
        TheopetraAccessControlled(ITheopetraAuthority(_authority))
    {}

    function getInitialSupply() public view returns (uint256) {
        return _initialSupply;
    }

    function setMintLimit(uint256 limit) public onlyGuardian {
        _mintLimit = limit;
        emit UpdateMintLimit(limit);
    }

    /** @dev If `_initialSupply` is not zero, the amount to mint is
     * limited to at most 5% of `_initialSupply`.
     *
     * The first time mint is successfully called, it will update the `_initialSupply`
     * to equal the mint `amount_`
     *
     * Note _initialSupply is initialized to zero
     */
    function mint(address account_, uint256 amount_) external onlyVault {
        uint256 amount = amount_;
        if (_initialSupply == 0) {
            _initialSupply = amount_;
            _mintLimit = _initialSupply;
        } else if (_initialSupply != 0 && amount_ > _mintLimit) {
            amount = _mintLimit;
        }
        _mint(account_, amount);
    }

    function burn(uint256 amount) external virtual {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account_, uint256 amount_) external virtual {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) public virtual {
        uint256 decreasedAllowance_ = allowance(account_, msg.sender).sub(
            amount_,
            "ERC20: burn amount exceeds allowance"
        );

        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }
}