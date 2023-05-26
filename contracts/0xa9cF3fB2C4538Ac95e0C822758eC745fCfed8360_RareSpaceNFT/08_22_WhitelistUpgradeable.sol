// contracts/token/ERC721/Whitelist.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "@openzeppelin/contracts-upgradeable-0.7.2/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable-0.7.2/math/SafeMathUpgradeable.sol";

contract WhitelistUpgradeable is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    uint256 constant MAX_UINT256 = type(uint256).max;

    mapping(address => uint256) public mintingAllowance;

    bool public whitelistEnabled = true;

    event MintingAllowanceUpdated(
        address indexed _address,
        uint256 _allowedAmount
    );

    function __Whitelist_init() internal initializer {
        __Ownable_init();
    }

    modifier canMint(address _address, uint256 _numMints) {
        require(getMintingAllowance(_address) >= _numMints);
        _;
    }

    function toggleWhitelist(bool _enabled) public onlyOwner {
        whitelistEnabled = _enabled;
    }

    function addToWhitelist(address _newAddress) public onlyOwner {
        _changeMintingAllowance(_newAddress, MAX_UINT256);
        emit MintingAllowanceUpdated(_newAddress, MAX_UINT256);
    }

    function removeFromWhitelist(address _newAddress) public onlyOwner {
        _changeMintingAllowance(_newAddress, 0);
        emit MintingAllowanceUpdated(_newAddress, 0);
    }

    function updateMintingAllowance(address _newAddress, uint256 _newAllowance)
        public
        onlyOwner
    {
        _changeMintingAllowance(_newAddress, _newAllowance);
        emit MintingAllowanceUpdated(_newAddress, _newAllowance);
    }

    function getMintingAllowance(address _address)
        public
        view
        returns (uint256)
    {
        if (whitelistEnabled) {
            return mintingAllowance[_address];
        } else {
            return MAX_UINT256;
        }
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return getMintingAllowance(_address) != 0 ? true : false;
    }

    function _decrementMintingAllowance(address _minter) internal {
        if (whitelistEnabled) {
            uint256 allowance = mintingAllowance[_minter];
            mintingAllowance[_minter] = allowance.sub(1);
        }
    }

    function _changeMintingAllowance(address _address, uint256 _allowance)
        internal
    {
        mintingAllowance[_address] = _allowance;
    }
}