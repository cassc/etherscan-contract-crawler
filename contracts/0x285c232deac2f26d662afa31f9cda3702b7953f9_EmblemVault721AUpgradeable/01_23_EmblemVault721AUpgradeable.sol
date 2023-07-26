// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import './ERC721AUpgradeable.sol';
import "./HasRegistration.sol";
import './extensions/ERC721ABurnableUpgradeable.sol';
import './extensions/ERC721AQueryableUpgradeable.sol';
import "./IHandlerCallback.sol";
import "./ERC2981Royalties.sol";
import "operator-filter-registry/src/upgradeable/OperatorFiltererUpgradeable.sol";

contract EmblemVault721AUpgradeable is ERC721AUpgradeable, ERC721ABurnableUpgradeable, ERC721AQueryableUpgradeable, HasRegistration, OperatorFiltererUpgradeable, ERC2981Royalties {  

    mapping(uint256 => uint256) internal _externalTokenIdMap; // tokenId >> externalTokenId
    bool initialized;
    
    function initialize(string memory name_, string memory symbol_) initializer external {
        if (!initialized) {
            initialized = true;
            ERC721AStorage.layout()._name = name_;
            ERC721AStorage.layout()._symbol = symbol_;
            ERC721AStorage.layout()._currentIndex = _startTokenId();
            _transferOwnership(_msgSender());
            toggleClaimable();
            __OperatorFilterer_init(0x9dC5EE2D52d014f8b81D662FA8f4CA525F27cD6b, true);
            BASE_URI = "https://v2.emblemvault.io/meta/";
        }
    }

    function mint(address to, uint256 externalTokenId) external onlyOwner {
        uint256 _tokenId = ERC721AStorage.layout()._currentIndex;
        _mint(to, 1);
        _externalTokenIdMap[externalTokenId] = _tokenId;
        if (registeredOfType[3].length > 0 && registeredOfType[3][0] == _msgSender()) { // Called by Handler
            IHandlerCallback(_msgSender()).executeCallbacks(address(0), to, _tokenId, IHandlerCallback.CallbackType.MINT);
        }
    }

    function burn(uint256 tokenId) public override isRegisteredContractOrOwner(_msgSender()) {        
        super.burn(tokenId);
        if (registeredOfType[3].length > 0 && registeredOfType[3][0] != address(0)) {
            IHandlerCallback(registeredOfType[3][0]).executeCallbacks(_msgSender(), address(0), tokenId, IHandlerCallback.CallbackType.BURN);
        }
    }

    function setDetails(string memory name_, string memory symbol_) public onlyOwner {
        ERC721AStorage.layout()._name = name_;
        ERC721AStorage.layout()._symbol = symbol_;
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        BASE_URI = baseURI;
    }
    

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 _interfaceId) public view override(ERC721AUpgradeable, IERC721AUpgradeable) returns (bool) {
        return 
        ERC721AUpgradeable.supportsInterface(_interfaceId) || 
        _interfaceId == bytes4(keccak256("ERC721A")) || 
        _interfaceId == 0x2a55205a;
    }

    function getInternalTokenId(uint256 tokenId) external view returns (uint256) {
        return _externalTokenIdMap[tokenId];
    }

    function version() external pure returns (string memory) {
        return "1.0.8";
    }

    function interfaceId() external pure returns (bytes4) {
        return bytes4(keccak256("ERC721A"));
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(_msgSender()) {
        super.transferFrom(from, to, tokenId);
        
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(_msgSender()) {
        super.safeTransferFrom(from, to, tokenId);
    }
    
    function approve(address to, uint256 tokenId) public payable override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperatorApproval(_msgSender()) {
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperatorApproval(_msgSender()) {
        super.setApprovalForAll(operator, approved);
    }

    uint256[50] private __gap;
    string BASE_URI;
}