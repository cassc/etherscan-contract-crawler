// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interface/IMintValidator.sol";
import "../interface/IERC721BalanceOf.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract CryptNinjaChildren1stSaleMintValidator is IMintValidator, Ownable, AccessControl {
    bytes32 public constant ADMIN = "ADMIN";

    address public collectionAddr = 0x828AD2904341f6026b4607A278349F5C840c4A2E;
    address public validContractAddr;
    uint256 public cost = 0.01 ether;
    uint256 public constant maxAmount = 1;
    mapping(address => uint256) public mintedCount;

    constructor() {
        _grantRole(ADMIN, msg.sender);
    }

    function validate(uint256 _amount, uint256, uint256 _value, bytes32[] calldata) external {
        address origSender = tx.origin;

        require(_amount >= 1, "amount specify 1 or more");
        require(msg.sender == validContractAddr, "invalid sender");
        require(_value >= cost, "not enouth eth");
        require(hasNFT(origSender), "you don't have NFT");
        require(mintedCount[origSender] + _amount <= maxAmount, "max over");

        mintedCount[origSender] += _amount;
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN, msg.sender), "You are not authorized.");
        _;
    }

    function setCost(uint256 _cost) external onlyAdmin {
        cost = _cost;
    }

    function setCollectionAddr(address _collectionAddr) external onlyAdmin {
        collectionAddr = _collectionAddr;
    }

    function setValidContractAddr(address _validContractAddr) external onlyAdmin {
        validContractAddr = _validContractAddr;
    }

    function hasNFT(address _addr) public view returns(bool) {
        IERC721BalanceOf erc721 = IERC721BalanceOf(collectionAddr);
        return erc721.balanceOf(_addr) >= 1;
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(AccessControl)
        returns(bool)
    {
        return AccessControl.supportsInterface(_interfaceId);
    }

    // ==================================================================
    // Override Ownerble for fail safe
    // ==================================================================
    function renounceOwnership() public view override onlyOwner {
        revert("Can not renounceOwnership. In the absence of the Owner, the system will not be operational.");
    }

    // ==================================================================
    // operations
    // ==================================================================
    function grantRole(bytes32 _role, address _account)
        public
        override
        onlyOwner
    {
        _grantRole(_role, _account);
    }

    function revokeRole(bytes32 _role, address _account)
        public
        override
        onlyOwner
    {
        _revokeRole(_role, _account);
    }
}