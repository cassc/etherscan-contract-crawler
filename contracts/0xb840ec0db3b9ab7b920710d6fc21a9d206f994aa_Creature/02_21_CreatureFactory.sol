// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";
import "./IFactoryERC721.sol";
import "./Creature.sol";


contract CreatureFactory is FactoryERC721, Ownable {
    using Strings for string;

    address public proxyRegistryAddress;
    address public nftAddress;
     string public baseURI = "https://api.cyber-hunter.com/factory/";

    // temporary control creature sale round
    uint256 public creatureOpened = 6666;


    /*
     * Set the corresponding option (x1,x3,x6...)
     */
    uint256[] OPTIONS=[1,1,3,3,6,6,9,9,18,18,27,27];


    constructor(address _proxyRegistryAddress, address _nftAddress) {
        proxyRegistryAddress = _proxyRegistryAddress;
        nftAddress = _nftAddress;
        fireTransferEvents(address(0), owner());
    }

    function name() override external pure returns (string memory) {
        return "CyberHunter Box";
    }

    function symbol() override external pure returns (string memory) {
        return "CBHB";
    }

    function supportsFactoryInterface() override public pure returns (bool) {
        return true;
    }

    function numOptions() override public view returns (uint256) {
        return OPTIONS.length;
    }

    function setOptions(uint256 id, uint256 option) public onlyOwner {
        require(id == OPTIONS.length, "Id must be consecutive");
        require(option < 100, "Option must lt 100");
        OPTIONS[id]=option;
        emit Transfer(address(0), owner(), id);
    }

    function transferOwnership(address newOwner) override public onlyOwner {
        address _prevOwner = owner();
        super.transferOwnership(newOwner);
        fireTransferEvents(_prevOwner, newOwner);
    }

    function setCreatureOpened(uint256 openNum) public onlyOwner {
        creatureOpened = openNum;
    }

    function fireTransferEvents(address _from, address _to) private {
        for (uint256 i = 0; i < OPTIONS.length; i++) {
            emit Transfer(_from, _to, i);
        }
    }

    function batchMint(uint256 _mintNum, address _toAddress)  private returns (uint256){
        Creature elementCreature = Creature(nftAddress);
        uint256 tokenIdStart = elementCreature.totalSupply() + 1;
        for (uint256 i = 0; i < _mintNum; i++) {
            elementCreature.mintTo(_toAddress);
        }
        return tokenIdStart;
    }

    function mint(uint256 _optionId, address _toAddress) override public {
        // Must be sent from the owner proxy or owner.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        require(address(proxyRegistry.proxies(owner())) == _msgSender() || owner() == _msgSender(), "not owner or proxy");
        require(canMint(_optionId), "sale end or stop");
        uint256 mintNum = OPTIONS[_optionId];
        if (mintNum > 0) {
            uint256 tokenIdStart = batchMint(mintNum,_toAddress);
            emit FactoryMint(tx.origin, _toAddress, _optionId, tokenIdStart, mintNum);
        }
    }

    function canMint(uint256 _optionId) override public view returns (bool) {
        if (_optionId >= OPTIONS.length) {
            return false;
        }

        Creature elementCreature = Creature(nftAddress);
        uint256 creatureSupply = elementCreature.totalSupply();

        uint256 numItemsAllocated = OPTIONS[_optionId];
        // open creature check
        if (creatureSupply > (creatureOpened - numItemsAllocated)) {
            return false;
        }
        return creatureSupply <= creatureOpened;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _optionId) override external view returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(_optionId)));
    }

    /**
     * Get things work automatically on Element.
     * It's a hack, Use transferFrom so the frontend doesn't have to worry about different method names.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        mint(_tokenId, _to);
    }

    /**
     * Get things work automatically on Element.
     * It's a hack, Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        returns (bool)
    {
        if (owner() == _owner && _owner == _operator) {
            return true;
        }

        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (
            owner() == _owner &&
            address(proxyRegistry.proxies(_owner)) == _operator
        ) {
            return true;
        }

        return false;
    }

    /**
     * Get things to work automatically on Element.
     */
    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        return owner();
    }

}