// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721psi/contracts/extension/ERC721PsiBurnable.sol";
import "./ERC721PsiRandomSeedReveal.sol";

contract OwnableDelegateProxy {}
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

interface ITrashCan {
    function emptyBurn(uint256 rarity) external;
    function redeemBurn(uint256 rarity, address redeemTo) external;
    function totalPoints() external view returns (uint256);
    function addPoints(uint256 amount) external;
}

abstract contract TrashBase is ERC721PsiRandomSeedReveal, ERC721PsiBurnable, Ownable {
    using Strings for uint256;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    string public baseURI = '';
    string public contractURI = '';
    address public feeVault;

    bytes32 public defaultKeyHash;
    uint64 public VRFSubId;

    uint256 public saleStartTime;
    uint256 public saleEndTime;

    address public proxyRegistryAddress; // For gasless listings

    mapping(address => bool) public isOperator; // Has approval to transfer contract NFTs; Universal operators for this contract
    mapping(address => bool) public hasOptedOutFromOperators; // Universal operators disabled for this account

    mapping(address => bool) public hasMinted; // If an account has minted

    bool public salePeriodLocked = false;

    constructor(
        string memory name_, string memory symbol_,
        address _proxyRegistryAddress,
        uint256 _saleStartTime,
        uint256 _saleEndTime,
        address coordinator,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        bytes32 _defaultKeyHash,
        uint64 _vrfsubid
        ) 
        ERC721Psi(name_, symbol_) 
        ERC721PsiRandomSeedReveal(
            coordinator,
            _callbackGasLimit,
            _requestConfirmations
        )
    {

        proxyRegistryAddress = _proxyRegistryAddress;
        saleStartTime = _saleStartTime;
        defaultKeyHash = _defaultKeyHash;
        VRFSubId = _vrfsubid;
        saleEndTime = _saleEndTime;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        return (address(feeVault), (_salePrice * 75) / 1000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Psi)
        returns (bool)
    {
        return
            interfaceId == _INTERFACE_ID_ERC2981 ||
            super.supportsInterface(interfaceId);
    }

    function accessByte(uint256 _number, uint8 _index) public pure returns (uint8) {
        return uint8(bytes32(_number)[_index]);
    }

    function setOperatorOptOut(bool _optOut) external {
        hasOptedOutFromOperators[msg.sender] = _optOut;
    }

    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        // If the owner has not opted out from operators
        if (!hasOptedOutFromOperators[_owner]) {
            // This is an operator, give them approval
            if (isOperator[operator]) return true;

            // Automatically consider opensea proxies approved, allows gasless listing
            OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
            if (address(proxyRegistry.proxies(_owner)) == operator) return true;
        }
        // Fallback to regular logic
        return super.isApprovedForAll(_owner, operator);
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(payable(address(this)).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setContractURI(string calldata _uri) external onlyOwner {
        contractURI = _uri;
    }

    function setSalePeriod(uint256 _startTime, uint256 _endTime) external onlyOwner {
        require(salePeriodLocked == false, "Sale period locked");
        saleStartTime = _startTime;
        saleEndTime = _endTime;
    }

    // Prevents further changes to the sale period
    function lockSalePeriod() external onlyOwner {
        salePeriodLocked = true;
    }

    function setOpenSeaProxyRegistry(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function setOperator(address _operator, bool _enabled) external onlyOwner {
        isOperator[_operator] = _enabled;
    }

    function setVault(address _vault) external onlyOwner {
        feeVault = _vault;
    }

    function setKeyHash(bytes32 _newkeyhash) external onlyOwner {
        defaultKeyHash = _newkeyhash;
    }

    function setSubId(uint64 _newSubId) external onlyOwner {
        VRFSubId = _newSubId;
    }

    function _keyHash() internal override returns (bytes32) {
        return defaultKeyHash;
    }

    function _subscriptionId() internal override returns (uint64) {
        return VRFSubId;
    }

    function requestReveal() external onlyOwner {
        _reveal();
    }

    function totalSupply() public view override(ERC721Psi, ERC721PsiBurnable) returns (uint256) {
        return super.totalSupply();
    }

    function _exists(uint256 tokenId) internal view override(ERC721Psi, ERC721PsiBurnable) returns (bool) {
        return super._exists(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Psi: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }
}