// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";

contract Factory is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply, ContextMixin, NativeMetaTransaction {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    address public _router;

    address public _proxyRegistryAddress;
    bool public _secAllowMsgSenderOverride = true;
    bool public _secAllowIsApprovedForAll = true;
    constructor(address router) ERC1155("https://fisport.org/option/{id}.json") {
        _router = router;
    }

    modifier onlyRouter {
        require(msg.sender == _router, "Caller is not the router");
        _;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 amount, bytes memory data)
        public
        onlyRouter
    {
        uint256 id = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(account, id, amount, data);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyRouter
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyRouter
    {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function setProxyRegistryAddress(address _newProxyRegistryAddress) public onlyOwner {
        _proxyRegistryAddress = _newProxyRegistryAddress;
    }

    function setSecAllowIsApprovedForAll(bool isAllowed) external onlyOwner {
        _secAllowIsApprovedForAll = isAllowed;
    }

    function isApprovedForAll(address account, address operator) public view override returns (bool isOperator) {
        if ((operator == address(_proxyRegistryAddress) && _secAllowIsApprovedForAll) || operator == address(_router)) {
            return true;
        }

        return super.isApprovedForAll(account, operator);
    }

    function setSecAllowMsgSenderOverride(bool isAllowed) external onlyOwner {
        _secAllowMsgSenderOverride = isAllowed;
    }

    function _msgSender() internal view override returns (address sender) {
        if (_secAllowMsgSenderOverride) {
            return ContextMixin.msgSender();
        }
        return super._msgSender();
    }

    function getIdCounter() public view returns(uint256) {
        return _tokenIdCounter.current();
    }
}