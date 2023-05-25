// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


contract Flokitar is ERC721, Ownable {
    string private _baseTokenURI;
    uint256 public nextTokenId = 1;

    uint256 public constant GENESIS_MINT_COST = 0.03 ether;
    uint256 public constant REGULAR_MINT_COST = 0.05 ether;

    IERC721 public immutable bronze;
    IERC721 public immutable silver;
    IERC721 public immutable diamond;
    IERC721 public immutable ruby;

    uint8[] private Backgrounds = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
    uint8[] private Eyes = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    uint8[] private Hat = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    uint8[] private Mouth = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    uint8[] private Shirt = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    uint8[] private Ear = [0, 1, 2, 3, 4, 5];

    struct PFP {
        uint8 background;
        uint8 eyes;
        uint8 hat;
        uint8 mouth;
        uint8 shirt;
        uint8 ear;
    }

    mapping (uint256 => uint256) public superMapping;
    mapping (uint256 => uint256) public reverseSuperMapping;
    mapping (bytes32 => bool) private _hashMinted;
    mapping (uint256 => bool) private _superMinted;
    mapping (uint256 => PFP) private _pfpData;

    uint256 public immutable genesisStartDate;
    uint256 public immutable regularStartDate;
    uint256 public constant MINT_CAP_PER_TX = 10;
    uint256 public constant MINT_CAP = 10000;
    uint256 public constant GENESIS_MINT_CAP = 2000;
    uint256 public constant RARE_NFT_RANGE = 1000;
    uint256 public genesisMinted;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _tokenURI,
        address _bronze,
        address _silver,
        address _diamond,
        address _ruby,
        uint256 _genesisStartDate,
        uint256 _regularStartDate
    )
        ERC721(_name, _symbol)
    {
        _baseTokenURI = _tokenURI;

        bronze = IERC721(_bronze);
        silver = IERC721(_silver);
        diamond = IERC721(_diamond);
        ruby = IERC721(_ruby);

        genesisStartDate = _genesisStartDate;
        regularStartDate = _regularStartDate;
    }

    function setBaseURI(string memory _tokenURI) external onlyOwner {
        _baseTokenURI = _tokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function mint(uint256 _number) external payable {
        require(
            1 <= _number && _number <= MINT_CAP_PER_TX,
            "Flokivatar: Invalid number provided."
        );
        require(
            nextTokenId + _number - 1 <= MINT_CAP,
            "Flokivatar: Mint cap reached."
        );

        bool _isGenesisHolder = hasGenesisNFT(msg.sender);

        require(
            _canMint(_isGenesisHolder),
            "Flokivatar: Minting hasn't started yet."
        );

        if (_isGenesisMintPeriod()) {
            require(
                genesisMinted + _number <= GENESIS_MINT_CAP,
                "Flokivatar: Genesis mint cap reached."
            );
            genesisMinted += _number;
        }

        if (_isGenesisHolder) {
            require(
                msg.value == _number * GENESIS_MINT_COST,
                "Flokivatar: Invalid mint value provided."
            );
        } else {
            require(
                msg.value == _number * REGULAR_MINT_COST,
                "Flokivatar: Invalid mint value provided."
            );
        }

        while (_number > 0) {
            _mintFlokivatar();
            _number--;
        }
    }

    function _mintFlokivatar() private {
        uint256 _potentialSuperId = _getSuperRange(nextTokenId);

        // Check for potential super Floki.
        if (!_superMinted[_potentialSuperId]) {
            uint256 _superOdds = _getSuperOdds(nextTokenId);
            uint256 _rng = uint256(
                keccak256(
                    abi.encodePacked(
                        _potentialSuperId,
                        msg.sender,
                        block.timestamp,
                        nextTokenId
                    )
                )
            );

            if (_superOdds == 0 || _rng % _superOdds == 0) {
                superMapping[nextTokenId] = _potentialSuperId;
                reverseSuperMapping[_potentialSuperId] = nextTokenId;
                _superMinted[_potentialSuperId] = true;

                _safeMint(msg.sender, nextTokenId++);

                // Exit the function early, because the super has already been
                // minted.
                return;
            }
        }

        // Calculate seed for regular mint.
        bytes32 _seed = keccak256(
            abi.encodePacked(
                msg.sender,
                block.timestamp,
                nextTokenId
            )
        );
        PFP memory _pfp = _generate(_seed);
        bytes32 _hash = _generateHash(_pfp);

        while (_hashMinted[_hash]) {
            _seed = keccak256(abi.encodePacked(msg.sender, _seed));
            _pfp = _generate(_seed);
            _hash = _generateHash(_pfp);
        }

        _hashMinted[_hash] = true;
        _pfpData[nextTokenId] = _pfp;

        _safeMint(msg.sender, nextTokenId++);
    }

    function hasGenesisNFT(address _account) public view returns (bool) {
        return bronze.balanceOf(_account) > 0
            || silver.balanceOf(_account) > 0
            || diamond.balanceOf(_account) > 0
            || ruby.balanceOf(_account) > 0;
    }

    function getData(
        uint256 _tokenId
    )
        external
        view
        returns (uint8, uint8, uint8, uint8, uint8, uint8)
    {
        require(_exists(_tokenId), "Flokivatar: Nonexistent token.");

        PFP memory _pfp = _pfpData[_tokenId];

        return (
            _pfp.background,
            _pfp.eyes,
            _pfp.hat,
            _pfp.shirt,
            _pfp.mouth,
            _pfp.ear
        );
    }

    function _isGenesisMintPeriod() private view returns (bool) {
        return genesisStartDate <= block.timestamp && block.timestamp <= regularStartDate;
    }

    function _canMint(bool _hasGenesisNFT) private view returns (bool) {
        if (_hasGenesisNFT) {
            return block.timestamp >= genesisStartDate;
        } else {
            return block.timestamp >= regularStartDate;
        }
    }

    function _generate(bytes32 _seed) private view returns (PFP memory _pfp) {
        _pfp.background = Backgrounds[_getAttributeHash(_seed, "Background") % Backgrounds.length];
        _pfp.eyes = Eyes[_getAttributeHash(_seed, "Eyes") % Eyes.length];
        _pfp.hat = Hat[_getAttributeHash(_seed, "Hat") % Hat.length];
        _pfp.mouth = Mouth[_getAttributeHash(_seed, "Mouth") % Mouth.length];
        _pfp.shirt = Shirt[_getAttributeHash(_seed, "Shirt") % Shirt.length];
        _pfp.ear = Ear[_getAttributeHash(_seed, "Ear") % Ear.length];
    }

    function _getAttributeHash(
        bytes32 _seed,
        string memory _attribute
    )
        private
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(_seed, _attribute)));
    }

    function _generateHash(PFP memory _pfp) private pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                _pfp.background,
                _pfp.eyes,
                _pfp.hat,
                _pfp.mouth,
                _pfp.shirt,
                _pfp.ear
            )
        );
    }

    function _getSuperRange(uint256 _tokenId) private pure returns (uint256) {
        return 1 + (_tokenId - 1) / RARE_NFT_RANGE;
    }

    function _getSuperOdds(uint256 _tokenId) private pure returns (uint256) {
        return RARE_NFT_RANGE * _getSuperRange(_tokenId) - _tokenId;
    }

    function withdraw() external onlyOwner {
        payable(owner()).call{value: address(this).balance}("");
    }
}