// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

abstract contract HavahMitter is OwnableUpgradeable, UUPSUpgradeable {

    struct TokenInfo {
        address wrappedToken;
        uint16 originChainId;
        string originToken;
    }

    struct OriginInfo {
        uint16 chainId;
        string token;
    }

    uint16 private _chainId;
    mapping(string => bool) private _completed;
    bool private _active;
    address private _validator;
    address private _treasury;
    address private _admin;
    mapping(address => TokenInfo) private _deployedToken;
    mapping(uint16 => mapping(string => TokenInfo)) private _originToToken;

    modifier onlyAdmin() {
        require(admin() == _msgSender(), "caller is not the admin");
        _;
    }

    function __HavahMitter_init(uint16 chainId_) internal onlyInitializing {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __HavahMitter_init_unchained(chainId_);
    }

    function __HavahMitter_init_unchained(uint16 chainId_) internal onlyInitializing {
        _chainId = chainId_;
        _active = false;        
        _admin = _msgSender();
    }

    function chainId() public view returns (uint16) {
        return _chainId;
    }

    function setActive(bool active_) external onlyAdmin {
        _active = active_;
    }

    function active() public view returns (bool) {
        return _active;
    }

    function setValidator(address validator_) external onlyAdmin {
        require(validator_ != address(0), "validator should not be zero address");
        _validator = validator_;
    }

    function validator() public view returns (address) {
        return _validator;
    }

    function setTreasury(address treasury_) external onlyAdmin {
        require(treasury_ != address(0), "treasury should not be zero address");
        _treasury = treasury_;
    }

    function treasury() public view returns (address) {
        return _treasury;
    }

    function setAdmin(address admin_) external {
        require(admin() == _msgSender() || owner() == _msgSender(), "caller does not have permission");
        require(admin_ != address(0), "admin should not be zero address");
        _admin = admin_;
    }

    function admin() public view returns (address) {
        return _admin;
    }

    function _authorizeUpgrade(address) internal override(UUPSUpgradeable) onlyOwner {}

    function _setCompleted(string memory messageId) internal {
        _completed[messageId] = true;
    }

    function _registerTokenInfo(uint16 originChain, string memory originToken, address wrappedToken) internal {
        require(AddressUpgradeable.isContract(wrappedToken), "address is not contract");
        require(_originToToken[originChain][originToken].wrappedToken == address(0), "already registered");
        require(_deployedToken[wrappedToken].wrappedToken == address(0), "already registered");

        TokenInfo memory tokenInfo = TokenInfo(wrappedToken, originChain, originToken);
        _originToToken[originChain][originToken] = tokenInfo;
        _deployedToken[wrappedToken] = tokenInfo;
    }

    function _upgradeTokenInfo(uint16 originChain, string memory originToken, address oldFT, address newFT) internal {
        require(AddressUpgradeable.isContract(newFT), "address is not contract");
        require(_originToToken[originChain][originToken].wrappedToken == oldFT, "had not been registered");
        require(_deployedToken[oldFT].wrappedToken != address(0), "had not been registered");

        delete _deployedToken[oldFT];

        TokenInfo memory tokenInfo = TokenInfo(newFT, originChain, originToken);
        _originToToken[originChain][originToken] = tokenInfo;
        _deployedToken[newFT] = tokenInfo;
    }

    function _getTokenInfo(address wrappedToken) internal view returns (TokenInfo memory) {        
        return _deployedToken[wrappedToken];
    }

    function _getTokenInfo(uint16 originChain, string memory originToken) internal view returns (TokenInfo memory) {
        return _originToToken[originChain][originToken];
    }

    function _checkBaseRequirement(string memory messageId, uint256 expires, uint16 chainId_) internal view {
        require(_active, "smart contract is not activated");
        require(_validator != address(0), "validator has not been set");
        require(_treasury != address(0), "treasury has not been set");
        require(block.number <= expires, "expired request");
        require(_chainId == chainId_, "invalid chain id");
        require(!_completed[messageId], "already completed");
    }

    function _verify(bytes memory data, bytes memory signature) internal view {
        require(ECDSA.recover(keccak256(data), signature) == _validator, "failed to verify data"); 
    }

    uint256[42] private __gap;
}