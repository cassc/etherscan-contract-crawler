// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.6.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./IMintableERC20.sol";

contract MintableERC20 is ERC20, Ownable {

    using SafeMath for uint256;

    event MaintainerAdded(address maintainer);
    event MaintainerRemoved(address maintainer);

    address[] private _maintainers;
    uint256 private immutable _maxMintedSupply;

    constructor (
        string memory name, 
        string memory symbol, 
        uint256 totalSupply,
        uint8 decimals,
        uint256 maxMintedSupply
    ) public ERC20(name, symbol) {
        _setupDecimals(decimals);
        _mint(msg.sender, totalSupply);
        require(totalSupply <= maxMintedSupply, "MintableERC20: totalSupply must be less of equal to maxMintedSupply");
        _maxMintedSupply = maxMintedSupply;
    }

    function mintAmount(address[] calldata accounts, uint256 amount) external onlyMaintainers {
        for (uint i = 0; i < accounts.length; ++i) {
            _mint(accounts[i], amount);
        }
        require(totalSupply() <= _maxMintedSupply, "MintableERC20: total amount exceeds maximum minted amount");
    }

    function mintAmounts(address[] calldata accounts, uint256[] calldata amounts) external onlyMaintainers {
        require(accounts.length == amounts.length, "MintableERC20: invalid length");
        for (uint i = 0; i < accounts.length; ++i) {
            _mint(accounts[i], amounts[i]);
        }
        require(totalSupply() <= _maxMintedSupply, "MintableERC20: total amount exceeds maximum minted amount");
    }

    function addMaintainer(address maintainer) external onlyOwner {
        if (_isMaintainer(maintainer)) {
            revert("MintableERC20: maintainer exists");
        }
        _maintainers.push(maintainer);
        emit MaintainerAdded(maintainer);
    }

    function removeMaintainer(address maintainer) external onlyOwner {
        for (uint i = 0; i < _maintainers.length; ++i) {
            if (_maintainers[i] == maintainer) {
                _maintainers[i] = _maintainers[_maintainers.length - 1];
                _maintainers.pop();
                emit MaintainerRemoved(maintainer);
                return;
            }
        }
        revert("MintableERC20: maintainer not found");
    }

    function maintainers() external view returns (address[] memory) {
        return _maintainers;
    }

    function maxMintedSupply() external view returns (uint256) {
        return _maxMintedSupply;
    }

    function _isMaintainer(address maintaner) private view returns (bool) {
        if (maintaner == owner()) {
            return true;
        }
        for (uint i = 0; i < _maintainers.length; ++i) {
            if (_maintainers[i] == maintaner) {
                return true;
            }
        }
        return false;
    }

    modifier onlyMaintainers() {
        require(_isMaintainer(msg.sender), "MintableERC20: permission denied");
        _;
    }
}