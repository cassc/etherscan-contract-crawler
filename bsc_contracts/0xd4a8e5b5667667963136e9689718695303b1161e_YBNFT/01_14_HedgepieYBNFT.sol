// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IAdapterManager.sol";
import "./interfaces/IYBNFT.sol";
import "./libraries/Ownable.sol";
import "./type/BEP721.sol";

contract YBNFT is BEP721, Ownable {
    using Counters for Counters.Counter;

    struct Adapter {
        uint256 allocation;
        address token;
        address addr;
    }

    struct AdapterDate {
        uint128 created;
        uint128 modified;
    }

    // current max tokenId
    Counters.Counter private _tokenIdPointer;
    // tokenId => token uri
    mapping(uint256 => string) private _tokenURIs;
    // tokenId => Adapter[]
    mapping(uint256 => Adapter[]) public adapterInfo;
    // tokenId => AdapterDate
    mapping(uint256 => AdapterDate) public adapterDate;
    // tokenId => performanceFee
    mapping(uint256 => uint256) public performanceFee;

    // AdapterManager handler
    IAdapterManager public adapterManager;

    event Mint(address indexed minter, uint256 indexed tokenId);

    /**
     * @notice Construct
     */
    constructor() BEP721("Hedgepie YBNFT", "YBNFT") {}

    /**
     * @notice Get current nft token id
     */
    function getCurrentTokenId() public view returns (uint256) {
        return _tokenIdPointer._value;
    }

    /**
     * @notice Get adapter info from nft tokenId
     * @param _tokenId  YBNft token id
     */
    function getAdapterInfo(uint256 _tokenId)
        public
        view
        returns (Adapter[] memory)
    {
        return adapterInfo[_tokenId];
    }

    /**
     * @notice Get tokenURI from token id
     * @param _tokenId token id
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return _tokenURIs[_tokenId];
    }

    /**
     * @notice Check if nft id is existed
     * @param _tokenId  YBNft token id
     */
    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * @notice Mint nft with adapter infos
     * @param _adapterAllocations  allocation of adapters
     * @param _adapterTokens  token of adapters
     * @param _adapterAddrs  address of adapters
     */
    /// #if_succeeds {:msg "Mint failed"} adapterInfo[_tokenIdPointer._value].length == _adapterAllocations.length;
    function mint(
        uint256[] calldata _adapterAllocations,
        address[] calldata _adapterTokens,
        address[] calldata _adapterAddrs,
        uint256 _performanceFee,
        string memory _tokenURI
    ) external {
        require(
            _performanceFee < 1000,
            "Performance fee should be less than 10%"
        );
        require(
            _adapterTokens.length > 0 &&
                _adapterTokens.length == _adapterAllocations.length &&
                _adapterTokens.length == _adapterAddrs.length,
            "Mismatched adapters"
        );
        require(
            _checkPercent(_adapterAllocations),
            "Incorrect adapter allocation"
        );
        require(address(adapterManager) != address(0), "AdapterManger not set");

        for (uint256 i = 0; i < _adapterAddrs.length; i++) {
            (
                address adapterAddr,
                ,
                address stakingToken,
                bool status
            ) = IAdapterManager(adapterManager).getAdapterInfo(
                    _adapterAddrs[i]
                );
            require(
                _adapterAddrs[i] == adapterAddr,
                "Adapter address mismatch"
            );
            require(
                _adapterTokens[i] == stakingToken,
                "Staking token address mismatch"
            );
            require(status, "Adapter is inactive");
        }

        _tokenIdPointer.increment();
        performanceFee[_tokenIdPointer._value] = _performanceFee;

        _safeMint(msg.sender, _tokenIdPointer._value);
        _setTokenURI(_tokenIdPointer._value, _tokenURI);
        _setAdapterInfo(
            _tokenIdPointer._value,
            _adapterAllocations,
            _adapterTokens,
            _adapterAddrs
        );

        emit Mint(msg.sender, _tokenIdPointer._value);
    }

    /**
     * @notice Update performance fee of adapters
     * @param _tokenId  tokenId of NFT
     * @param _performanceFee  address of adapters
     */
    function updatePerformanceFee(uint256 _tokenId, uint256 _performanceFee)
        external
    {
        require(
            _performanceFee < 1000,
            "Performance fee should be less than 10%"
        );
        require(msg.sender == ownerOf(_tokenId), "Invalid NFT Owner");

        performanceFee[_tokenId] = _performanceFee;
        adapterDate[_tokenId].modified = uint128(block.timestamp);
    }

    /**
     * @notice Update allocation of adapters
     * @param _tokenId  tokenId of NFT
     * @param _adapterAllocations  array of adapter allocation
     */
    function updateAllocations(
        uint256 _tokenId,
        uint256[] calldata _adapterAllocations
    ) external {
        require(
            _adapterAllocations.length == adapterInfo[_tokenId].length,
            "Invalid allocation length"
        );
        require(msg.sender == ownerOf(_tokenId), "Invalid NFT Owner");
        require(
            _checkPercent(_adapterAllocations),
            "Incorrect adapter allocation"
        );

        for (uint256 i; i < adapterInfo[_tokenId].length; i++) {
            adapterInfo[_tokenId][i].allocation = _adapterAllocations[i];
        }

        adapterDate[_tokenId].modified = uint128(block.timestamp);
    }

    /**
     * @notice Update token URI of NFT
     * @param _tokenId  tokenId of NFT
     * @param _tokenURI  URI of NFT
     */
    function updateTokenURI(uint256 _tokenId, string memory _tokenURI)
        external
    {
        require(msg.sender == ownerOf(_tokenId), "Invalid NFT Owner");

        _setTokenURI(_tokenId, _tokenURI);
        adapterDate[_tokenId].modified = uint128(block.timestamp);
    }

    /**
     * @notice Set token uri
     * @param _tokenId  token id
     * @param _tokenURI  token uri
     */
    function _setTokenURI(uint256 _tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[_tokenId] = _tokenURI;
    }

    /**
     * @notice Set adapter infos of nft from token id
     * @param _adapterAllocations  allocation of adapters
     * @param _adapterTokens  adapter token
     * @param _adapterAddrs  address of adapters
     */
    function _setAdapterInfo(
        uint256 _tokenId,
        uint256[] calldata _adapterAllocations,
        address[] calldata _adapterTokens,
        address[] calldata _adapterAddrs
    ) internal {
        for (uint256 i = 0; i < _adapterTokens.length; i++) {
            adapterInfo[_tokenId].push(
                Adapter({
                    allocation: _adapterAllocations[i],
                    token: _adapterTokens[i],
                    addr: _adapterAddrs[i]
                })
            );
        }
        adapterDate[_tokenId] = AdapterDate({
            created: uint128(block.timestamp),
            modified: uint128(block.timestamp)
        });
    }

    /**
     * @notice Check if total percent of adapters is valid
     * @param _adapterAllocations  allocation of adapters
     */
    function _checkPercent(uint256[] calldata _adapterAllocations)
        internal
        pure
        returns (bool)
    {
        uint256 totalAlloc;
        for (uint256 i; i < _adapterAllocations.length; i++) {
            totalAlloc = totalAlloc + _adapterAllocations[i];
        }

        return totalAlloc <= 1e4;
    }

    /**
     * @notice Set adapter manager address
     * @param _adapterManager adapter manager address
     */
    function setAdapterManager(address _adapterManager) external onlyOwner {
        adapterManager = IAdapterManager(_adapterManager);
    }
}