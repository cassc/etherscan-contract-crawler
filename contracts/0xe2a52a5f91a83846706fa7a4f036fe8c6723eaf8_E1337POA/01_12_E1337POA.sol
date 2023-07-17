// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC721.sol";

contract E1337POA is ERC721 {
    event ConsecutiveTransfer(
        uint256 indexed fromTokenId,
        uint256 toTokenId,
        address indexed fromAddress,
        address indexed toAddress
    );

    struct Media {
        string uri;
        string mime;
    }

    struct Model {
        string name;
        uint256 from;
        uint256 to;
    }

    struct ModelData {
        string name;
    }

    struct Trait {
        string name;
        string value;
    }

    struct ModelView {
        string name;
        uint256 totalEditions;
        Media[] media;
        Trait[] traits;
    }

    struct TokenView {
        ModelView model;
        uint256 edition;
    }

    Model[] private models;
    mapping(uint256 => Media[]) private media;
    mapping(uint256 => Trait[]) private traits;
    mapping(uint256 => bool) private burnedTokens;

    string private baseURI;

    constructor() ERC721("E1337 Proof of Authenticity", "POA") {}

    function create(
        ModelData memory _model,
        Media[] memory _media,
        Trait[] memory _traits,
        uint256 quantity
    ) external onlyOwner {
        for (uint256 i; i < models.length; i++) {
            if (
                keccak256(abi.encodePacked(models[i].name)) ==
                keccak256(abi.encodePacked(_model.name))
            ) {
                revert();
            }
        }

        uint256 from;

        if (models.length == 0) {
            from = 0;
        } else {
            from = models[models.length - 1].to + 1;
        }

        uint256 to = from + quantity - 1;
        models.push(Model(_model.name, from, to));
        uint256 modelId = models.length - 1;

        for (uint256 i = 0; i < _media.length; i++) {
            media[modelId].push(Media(_media[i].uri, _media[i].mime));
        }

        for (uint256 i = 0; i < _traits.length; i++) {
            traits[modelId].push(Trait(_traits[i].name, _traits[i].value));
        }

        _increaseBalance(msg.sender, quantity);

        for (uint256 i = from; i <= to; i++) {
            emit Transfer(address(0), msg.sender, i);
        }
    }

    function addMediaForModel(uint256 _modelId, Media memory _media)
        external
        onlyOwner
    {
        media[_modelId].push(Media(_media.uri, _media.mime));
    }

    function updateMediaForModelByURI(
        uint256 _modelId,
        string memory _uri,
        string memory _newUri,
        string memory _mime
    ) external onlyOwner {
        for (uint256 i; i < media[_modelId].length; i++) {
            if (
                keccak256(abi.encodePacked(media[_modelId][i].uri)) !=
                keccak256(abi.encodePacked(_uri))
            ) {
                continue;
            }

            media[_modelId][i].uri = _newUri;
            media[_modelId][i].mime = _mime;
        }
    }

    function addTraitForModel(uint256 _modelId, Trait memory _traits)
        external
        onlyOwner
    {
        traits[_modelId].push(Trait(_traits.name, _traits.value));
    }

    function updateTraitForModelByName(
        uint256 _modelId,
        string memory _name,
        string memory _value
    ) external onlyOwner {
        for (uint256 i; i < traits[_modelId].length; i++) {
            if (
                keccak256(abi.encodePacked(traits[_modelId][i].name)) !=
                keccak256(abi.encodePacked(_name))
            ) {
                continue;
            }

            traits[_modelId][i].value = _value;
        }
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function baseTokenURI() external view returns (string memory) {
        return baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseTokenURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function retrieve(uint256 _id) external view returns (TokenView memory) {
        require(_exists(_id), "ERC721: retrieve for nonexistent token");

        for (uint256 i; i < models.length; i++) {
            if (_id < models[i].from || _id > models[i].to) {
                continue;
            }

            return
                TokenView(
                    ModelView(
                        models[i].name,
                        models[i].to - models[i].from + 1,
                        media[i],
                        traits[i]
                    ),
                    _id - models[i].from + 1
                );
        }

        revert();
    }

    function retrieveModelById(uint256 _id)
        external
        view
        returns (ModelView memory)
    {
        for (uint256 i; i < models.length; i++) {
            if (i != _id) {
                continue;
            }

            return
                ModelView(
                    models[i].name,
                    models[i].to - models[i].from + 1,
                    media[i],
                    traits[i]
                );
        }

        // No model found with the given name
        revert();
    }

    function _exists(uint256 tokenId)
        internal
        view
        virtual
        override
        returns (bool)
    {
        if (burnedTokens[tokenId]) {
            return false;
        }

        if (models.length == 0) {
            return false;
        }

        return tokenId <= models[models.length - 1].to;
    }

    function totalSupply() public view virtual returns (uint256) {
        if (models.length == 0) {
            return 0;
        }

        return models[models.length - 1].to + 1;
    }

    function burn(uint256 _tokenId) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), _tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(_tokenId);
        burnedTokens[_tokenId] = true;
    }
}