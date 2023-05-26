//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.6;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControlMixin} from "@maticnetwork/pos-portal/contracts/common/AccessControlMixin.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

contract GoldFeverNativeGoldRoot is ERC20, AccessControlMixin {

    uint256 private immutable _creationTimestamp;
    uint256 private _totalMinted;
    mapping(uint256 => uint256) private _yearTotalSupply;
    mapping(uint256 => uint256) private _yearMinted;

    constructor(
        address admin,
        uint256 totalSupply
    ) public ERC20("Gold Fever Native Gold", "NGL") {
        _setupContractId("GoldFeverNativeGoldRoot ");
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _creationTimestamp = block.timestamp;

        _mint(admin, totalSupply);
        _totalMinted = totalSupply;
    }

    /**
     * @param user user for whom tokens are being minted
     * @param amount amount of token to mint
     */
    function mint(address user, uint256 amount)
        public
        only(DEFAULT_ADMIN_ROLE)
    {
        require(block.timestamp - _creationTimestamp >= 2 * 365 days);
        uint256 year = ((block.timestamp - _creationTimestamp) - 2 * 365 days) /
            365 days;

        if (_yearTotalSupply[year] == 0) {
            _yearTotalSupply[year] = _totalMinted;
        }

        require(
            amount <= ((_yearTotalSupply[year] * 30) / 100) - _yearMinted[year]
        );
        _yearMinted[year] += amount;
        _totalMinted += amount;

        _mint(user, amount);
    }
}