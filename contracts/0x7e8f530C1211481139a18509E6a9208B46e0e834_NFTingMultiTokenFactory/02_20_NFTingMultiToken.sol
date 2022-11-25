// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "../utilities/PreAuthorization.sol";
import "../interface/INFTingConfig.sol";

contract NFTingMultiToken is
    ERC1155Burnable,
    ERC1155Supply,
    ERC2981,
    PreAuthorization
{
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private currentTokenId;

    INFTingConfig public config;

    string public name;
    string public symbol;

    mapping(uint256 => address) private tokenCreator;
    mapping(bytes32 => uint256) public URI2ID;
    mapping(uint256 => bytes32) public ID2URI;

    event URIUpdated(string _uri);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initURI,
        address _nftingConfig
    ) ERC1155(_initURI) {
        if (_nftingConfig == address(0)) revert ZeroAddress();
        name = _name;
        symbol = _symbol;
        config = INFTingConfig(_nftingConfig);
    }

    function publicMint(
        bytes32 _metadataId,
        uint256 _amount,
        uint96 _royaltyFraction
    ) external {
        if (_royaltyFraction > config.maxRoyaltyFee()) {
            revert InvalidArgumentsProvided();
        }

        currentTokenId.increment();
        uint256 curTokenId = currentTokenId.current();

        _setTokenRoyalty(
            curTokenId,
            _msgSender(),
            (_feeDenominator() * _royaltyFraction) / 100
        );

        tokenCreator[curTokenId] = _msgSender();

        URI2ID[_metadataId] = curTokenId;
        ID2URI[curTokenId] = _metadataId;

        _mint(_msgSender(), curTokenId, _amount, "");
    }

    function additionalMint(uint256 _tokenId, uint256 _amount) external {
        if (tokenCreator[_tokenId] == address(0)) {
            revert InvalidTokenId(_tokenId);
        } else if (tokenCreator[_tokenId] != _msgSender()) {
            revert PermissionDenied();
        }

        _mint(_msgSender(), _tokenId, _amount, "");
    }

    function publicBatchMint(
        bytes32[] calldata _metadataIds,
        uint256[] calldata _amounts,
        uint96[] calldata _royaltyFractions
    ) external {
        if (
            _metadataIds.length == 0 ||
            _metadataIds.length != _amounts.length ||
            _metadataIds.length != _royaltyFractions.length
        ) {
            revert InvalidArgumentsProvided();
        }

        uint256[] memory tokenIds = new uint256[](_metadataIds.length);

        for (uint256 i; i < _metadataIds.length; i++) {
            if (_royaltyFractions[i] > config.maxRoyaltyFee()) {
                revert InvalidArgumentsProvided();
            }

            currentTokenId.increment();
            uint256 curTokenId = currentTokenId.current();

            tokenIds[i] = curTokenId;

            tokenCreator[curTokenId] = _msgSender();

            URI2ID[_metadataIds[i]] = curTokenId;
            ID2URI[curTokenId] = _metadataIds[i];

            _setTokenRoyalty(
                curTokenId,
                _msgSender(),
                (_feeDenominator() * _royaltyFractions[i]) / 100
            );
        }

        _mintBatch(_msgSender(), tokenIds, _amounts, "");
    }

    function withdraw() public onlyOwner {
        if (!payable(_msgSender()).send(address(this).balance)) {
            revert WithdrawalFailed();
        }
    }

    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    ERC1155.uri(_tokenId),
                    "token/",
                    ID2URI[_tokenId]
                )
            );
    }

    function setURI(string memory _newURI) public onlyOwner {
        if (bytes(_newURI)[bytes(_newURI).length - 1] != bytes1("/"))
            revert NoTrailingSlash(_newURI);

        _setURI(_newURI);

        emit URIUpdated(_newURI);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Supply, ERC1155) {
        ERC1155Supply._beforeTokenTransfer(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * Override isApprovedForAll to whitelist the trusted accounts to enable gas-free listings.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool)
    {
        if (_isAuthorizedOperator(_operator)) {
            return true;
        }
        return super.isApprovedForAll(_owner, _operator);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return
            _interfaceId == type(IERC2981).interfaceId ||
            ERC1155.supportsInterface(_interfaceId);
    }
}