// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./core/Base.sol";

contract ERC721EP is ERC721EBase {
    using Strings for uint256;

    bool private _final = false;
    mapping(uint256 => bool) private _freez;

    uint256 private _supporterFee = 0;
    uint256 private _mintFee = 0.03 ether;

    bool private _autoFreeze = false;

    event URIfreezing(address indexed sender, uint256 tokenId);
    event ContractFinalize(address indexed sender);
    
    constructor(string memory name_, string memory symbol_, address ownerAddress)
    ERC721EBase(name_, symbol_, ownerAddress)
    {}

    function getSupporterFee()
        public
        view
        returns(uint256)
    {
        return _supporterFee;
    }

    function getOwnerFee()
        public
        view
        returns(uint256)
    {
        return address(this).balance - _supporterFee;
    }

    function withdrawETH()
        external
        virtual
        onlyAdmin
        emergencyMode
        override
    {
        uint256 royalty = address(this).balance - _supporterFee;

        Address.sendValue(payable(owner()), royalty);
        Address.sendValue(payable(supporter()), _supporterFee);
        _supporterFee = 0;
    }

    function putTokenURI(uint256 tokenId, string memory uri)
        external
        onlySupporter
    {
       require(!_final, "Already Finalized");
        require(tokenOwnerIsCreator(tokenId), "Can not write");
        _setTokenURI(tokenId, uri);
    }

    function enableAutoFreez()
        public
        virtual
        onlySupporter
    {
        _autoFreeze = true;
    }

    function disableAutoFreez()
        public
        virtual
        onlySupporter
    {
        _autoFreeze = false;
    }

    function setMintFee(uint256 fee)
        public
        onlySupporter
    {
        _mintFee = fee;
    }

    function getMintFee()
        external
        view
        returns(uint256)
    {
        return _mintFee;
    }

    function mint(string memory uri)
        public
        payable
        onlyOwner
        emergencyMode
    {
        require(msg.value >= _mintFee, "Need to send ETH");
        require(!_final, "Already Finalized");
        uint256 currentNumber = totalSupply() + 1;

        _safeMint(_msgSender(), currentNumber);
        _setTokenURI(currentNumber, uri);

        _supporterFee = _supporterFee + msg.value;

        if(_autoFreeze){
            freezing(currentNumber);
        }
    }

    function finalize()
        external
        onlySupporter
    {
        _final = true;
        emit ContractFinalize(_msgSender());
    }

    function freezing(uint256 tokenId)
        public
        onlyAdmin
        emergencyMode
    {
        _freez[tokenId] = true;
        emit URIfreezing(_msgSender(), tokenId);
    }

    function isFinalize()
        external
        view
        returns( bool )
    {
        return _final;
    }

    function isFreezing(uint256 tokenId)
        external
        view
        returns( bool )
    {
        return _freez[tokenId];
    }

}