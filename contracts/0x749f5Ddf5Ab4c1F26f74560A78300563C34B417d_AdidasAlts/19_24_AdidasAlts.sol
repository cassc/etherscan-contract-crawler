// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TokenHierarchy.sol";

interface IERC1155Migration {
    function burn(address account, uint256 id, uint256 value) external;

    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);
}

contract AdidasAlts is TokenHierarchy {
    string public baseUri;
    string public uriSuffix;
    /// @dev Token name
    string private _name;
    /// @dev Token symbol
    string private _symbol;
    /// @dev Token reveal
    bool private _reveal;
    /// @dev max supply
    uint256 private _maxSupply;
    /// @dev 1155 contract
    IERC1155Migration private _src;
    bool public mintLocked = true;
    string private _contractURI;

    constructor(
        string memory __name,
        string memory __symbol,
        /// @dev AltsTokenOperatorFilter contract address
        address _filterAddress,
        /// @dev ERC1155 used for burnToMint function
        address _ERC1155address,
        string memory _baseUri,
        string memory _uriSuffix,
        string memory _uri,
        address _royaltyReceipient,
        uint96 _royaltyValue,
        uint256 _waitTimelapse,
        uint256 __maxSupply
    ) ERC721A(__name, __symbol) {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _setDefaultRoyalty(_royaltyReceipient, _royaltyValue);
        setAltsTokenOperatorFilter(_filterAddress);
        setWaitDuration(_waitTimelapse);
        _contractURI = _uri;
        _name = __name;
        _symbol = __symbol;
        baseUri = _baseUri;
        uriSuffix = _uriSuffix;
        _maxSupply = __maxSupply;
        _src = IERC1155Migration(_ERC1155address);
    }

    /// @dev Max Amount of Token that can ever be minted
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function setNameAndSymbol(
        string calldata __name,
        string calldata __symbol
    ) public onlyOwner {
        _name = __name;
        _symbol = __symbol;
    }

    /**
     * @param status sets minting state
     */
    function setMintLocked(bool status) public onlyOwner {
        mintLocked = status;
    }

    function setContractURI(string calldata _uri) public onlyOwner {
        _contractURI = _uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * @param reveal sets reveal state
     * @param _baseUri sets baseUri string
     */
    function setReveal(bool reveal, string calldata _baseUri) public onlyOwner {
        _reveal = reveal;
        baseUri = _baseUri;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        if (_reveal == true) {
            return
                string(
                    abi.encodePacked(
                        currentBaseURI,
                        _toString(_tokenId),
                        uriSuffix
                    )
                );
        } else {
            return currentBaseURI;
        }
    }

    /**
     * @param _tokenIds burns an array of tokens
     */
    function burn(uint256[] calldata _tokenIds) public {
        require(_tokenIds.length > 0, "Missing tokenIds");
        unchecked {
            for (uint256 i = 1; i < _tokenIds.length; i++) {
                require(
                    ownerOf(_tokenIds[i]) == msg.sender,
                    "Must own token to burn"
                );
                require(
                    !tokenHasChildren(_tokenIds[i]),
                    "Cannot burn token with children"
                );
                _burn(_tokenIds[i]);
            }
        }
    }

    /**
     * @param ids Token id contract has Id's = 0,1
     * @param values the amount of tokens to burn and minted
     */
    function burnAndMint(
        uint256[] calldata ids,
        uint256[] calldata values
    ) external {
        require(ids.length == values.length, "Bad data");
        require(!contractLocked, "Contract is locked");
        require(!mintLocked, "Mint is disabled");

        uint256 count = ids.length;
        for (uint256 i = 0; i < count; ) {
            uint256 newMax = _totalMinted() + values[i];
            require(_maxSupply >= newMax, "Max Supply limit reached");

            // 1155 Burn value of Token id
            _src.burn(msg.sender, ids[i], values[i]);

            // mint's to msg.sender 721 of value amount
            _mint(msg.sender, values[i]);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @param to array of destination addresses
     * @param value the amount of tokens to minted
     */
    function mintMany(
        address[] calldata to,
        uint256[] calldata value
    ) external onlyOwner {
        require(to.length == value.length, "Mismatched lengths");
        uint256 count = to.length;
        unchecked {
            for (uint256 i = 0; i < count; i++) {
                // mint value amount for to address
                uint256 newMax = _totalMinted() + value[i];
                require(_maxSupply >= newMax, "Max Supply limit reached");

                _mint(to[i], value[i]);
            }
        }
    }

    // URI methods
    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    /**
     * @param _baseUri new baseURI value to be used in tokenURI
     */
    function setBaseUri(string calldata _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    /**
     * @param _uriSuffix new suffix value to be used in tokenURI
     */
    function setUriSuffix(string calldata _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }
}