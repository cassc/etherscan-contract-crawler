// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC165Checker} from "@openzeppelin/contracts/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract VipPrivatePublicSaleInfo is Ownable {

    using ERC165Checker for address;

    enum WhitelistType{ VIP, PRIVATE }

    struct SaleInfo {
        uint256 vipSaleDate;
        mapping(address => bool) vipWhitelist;
        uint256 privateSaleDate;
        mapping(address => bool) privateWhitelist;
        uint256 publicSaleDate;
        address creator;
    }

    /// @dev address -> token id -> sale info
    mapping(bytes32 => SaleInfo) public saleInfo;

    event Whitelisted(WhitelistType whitelistType, address indexed account, bool isWhitelisted);

    modifier onlyCreator(bytes32 _saleId) {
        require(saleInfo[_saleId].creator == msg.sender, "Whitelist: Not Sale creator");
        _;
    }

    function setSaleInfo(        
        address _token,
        uint256 _tokenId,
        uint256 _vipSaleDate,
        uint256 _privateSaleDate,
        uint256 _publicSaleDate
    ) external {

        if(_token.supportsInterface(type(IERC1155).interfaceId)) {
            require(
                IERC1155(_token).balanceOf(msg.sender, _tokenId) > 0,
                "ERC1155Sale: Caller doesn't have any tokens"
            );
        } else if(_token.supportsInterface(type(IERC721).interfaceId)) {
            require(
                IERC721(_token).ownerOf(_tokenId) == msg.sender,
                "ERC721Sale: Caller doesn't this tokenId"
            );
        } else {
            require(false, "not ERC1155 or ERC721 token");
        }

        bytes32 saleId = getID(msg.sender, _token, _tokenId);

        saleInfo[saleId] = SaleInfo({
            vipSaleDate: _vipSaleDate,
            privateSaleDate: _privateSaleDate,
            publicSaleDate: _publicSaleDate,
            creator: msg.sender
        });
    }

    function batchSetSaleInfo(
        address[] memory _tokens,
        uint256[] memory _tokenIds,
        uint256 _vipSaleDate,
        uint256 _privateSaleDate,
        uint256 _publicSaleDate
    ) external {         

        require(_tokens.length == _tokenIds.length, "tokens and token ids length doesnt match");

        for(uint i = 0; i < _tokenIds.length; i++) {

            if(_tokens[i].supportsInterface(type(IERC1155).interfaceId)) {
                require(
                    IERC1155(_tokens[i]).balanceOf(msg.sender, _tokenIds[i]) > 0,
                    "ERC1155Sale: Caller doesn't have any tokens"
                );
            } else if(_tokens[i].supportsInterface(type(IERC721).interfaceId)) {
                require(
                    IERC721(_tokens[i]).ownerOf(_tokenIds[i]) == msg.sender,
                    "ERC721Sale: Caller doesn't this tokenId"
                );
            } else {
                require(false, "not ERC1155 or ERC721 token");
            }


            bytes32 saleId = getID(msg.sender, _tokens[i], _tokenIds[i]);
            saleInfo[saleId] = SaleInfo({
                vipSaleDate: _vipSaleDate,
                privateSaleDate: _privateSaleDate,
                publicSaleDate: _publicSaleDate,
                creator: msg.sender
            });
        }
    }

    function whitelisted(bytes32 saleId, address _address)
    public
    view
    returns (bool)
    {

        // if it doesn't exist, we just allow sale to go through
        if(saleInfo[saleId].creator == address(0)) {
            return true;
        }

        // should be whitelisted if we're in the VIP sale
        if(
            saleInfo[saleId].vipSaleDate <= _getNow() &&
            saleInfo[saleId].privateSaleDate > _getNow() 
        ) {
            return saleInfo[saleId].vipWhitelist[_address];
        }
        

        // should be whitelisted if we're in the Private sale
        if(
            saleInfo[saleId].privateSaleDate <= _getNow() && 
            saleInfo[saleId].publicSaleDate > _getNow() 
        ) {
            return 
                saleInfo[saleId].vipWhitelist[_address] || 
                saleInfo[saleId].privateWhitelist[_address];
        }

        return false;
    }

    function whitelistNeeded(bytes32 saleId)
    public
    view
    returns (bool)
    {
        // whitelist has passed when now is > vip and private sale date
        if(
            saleInfo[saleId].vipSaleDate < _getNow() &&
            saleInfo[saleId].privateSaleDate < _getNow() &&
            saleInfo[saleId].publicSaleDate < _getNow()

        ) {
            return false;
        }


        return true;
    }

    function toggleAddressByBatch(bytes32[] memory _saleIds, WhitelistType[][] memory _whitelistTypes, address[][][] memory _addresses, bool enable)
    public
    {
        // for many sale ids
        for(uint i = 0; i < _saleIds.length; i++) {       

            require(saleInfo[_saleIds[i]].creator == msg.sender, "Whitelist: Not Sale creator");

            // 1 sale can have many whitelist types
            for (uint256 j = 0; j < _whitelistTypes[i].length; j++) {

                // 1 whitelist type can have many addresses
                for(uint k = 0; k < _addresses[i][j].length; k++) {
                    if(_whitelistTypes[i][j] == WhitelistType.VIP) {
                        require(saleInfo[_saleIds[i]].vipWhitelist[_addresses[i][j][k]] == !enable);
                        saleInfo[_saleIds[i]].vipWhitelist[_addresses[i][j][k]] = enable;
                        emit Whitelisted(WhitelistType.VIP, _addresses[i][j][k], enable);
                    }
                    if(_whitelistTypes[i][j] == WhitelistType.PRIVATE) {
                        require(saleInfo[_saleIds[i]].privateWhitelist[_addresses[i][j][k]] == !enable);
                        saleInfo[_saleIds[i]].privateWhitelist[_addresses[i][j][k]] = enable;
                        emit Whitelisted(WhitelistType.PRIVATE, _addresses[i][j][k], enable);
                    }
                }
            }
        }
    }

    function _getNow() internal virtual view returns (uint256) {
        return block.timestamp;
    }

    /*
     * @notice Get Sale info with owner address and token id
     * @param _owner address of token Owner
     * @param _tokenId Id of token
     */
    function getSaleInfo(
        address _owner,
        address _token,
        uint256 _tokenId
    ) public view returns (bytes32 saleId, uint256 vipSaleDate, uint256 privateSaleDate, uint256 publicSaleDate, address creator) {

        bytes32 _saleId = getID(_owner, _token, _tokenId);

        require(saleInfo[_saleId].vipSaleDate >= 0, "VipPrivatePublicSale: Sale has no dates set");

        return (_saleId, saleInfo[_saleId].vipSaleDate, saleInfo[_saleId].privateSaleDate, saleInfo[_saleId].publicSaleDate, saleInfo[_saleId].creator);
    }



    
    function getID(address _owner, address _token, uint256 _tokenId) public pure returns (bytes32) {
        return sha256(abi.encodePacked(_owner, ":", _token, ":",Strings.toString(_tokenId)));
    }

    function getIDBatch(address[] memory _owners, address[] memory _tokens, uint256[] memory _tokenIds) public pure returns (bytes32[] memory) {
        
        require(_tokenIds.length <= 100, "You are requesting too many ids, max 100");
        require(_tokenIds.length == _owners.length, "tokenIds length != owners length");
        require(_tokenIds.length == _tokens.length, "tokenIds length != tokens length");
        
        bytes32[] memory ids = new bytes32[](_tokenIds.length);
        
        for(uint i = 0; i < _tokenIds.length; i++) {
            ids[i] = getID(_owners[i], _tokens[i], _tokenIds[i]);
        }

        return ids;
    }
}