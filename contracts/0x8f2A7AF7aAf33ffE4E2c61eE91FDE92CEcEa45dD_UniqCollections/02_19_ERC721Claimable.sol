// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../common/meta-transactions/ContentMixin.sol";
import "../common/meta-transactions/NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

abstract contract ERC721Claimable is
    ContextMixin,
    ERC721Enumerable,
    NativeMetaTransaction,
    Ownable
{
    // ----- VARIABLES ----- //
    address proxyRegistryAddress;
    string internal _token_uri;
    address internal _claimingAddress;
    string public METADATA_PROVENANCE_HASH;
    uint256 public ROYALTY_FEE;

    // ----- EVENTS ----- //
    event ReceivedRoyalties(
        address indexed _royaltyRecipient,
        address indexed _buyer,
        uint256 indexed _tokenId,
        address _tokenPaid,
        uint256 _amount
    );

    // ----- CONSTRUCTOR ----- //
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address _proxyRegistryAddress,
        address _claimingContractAddress,
        uint256 _royaltyFee
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        _token_uri = _uri;
        _initializeEIP712(_name);
        _claimingAddress = _claimingContractAddress;
        ROYALTY_FEE = _royaltyFee;
    }

    // ----- VIEWS ----- //
    function baseTokenURI() public view virtual returns (string memory){
        return _token_uri;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId))
            );
    }

    function getClaimerAddress() external view returns (address) {
        return _claimingAddress;
    }

    function royaltyInfo(uint256)
        external
        view
        returns (address receiver, uint256 amount)
    {
        return (owner(), ROYALTY_FEE);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    // ----- PUBLIC METHODS ----- //
    function burn(uint256 _tokenId) external {
        if (msg.sender != _claimingAddress) {
            require(
                _isApprovedOrOwner(msg.sender, _tokenId),
                "Ownership or approval required"
            );
        }
        _burn(_tokenId);
    }

    function receivedRoyalties(
        address,
        address _buyer,
        uint256 _tokenId,
        address _tokenPaid,
        uint256 _amount
    ) external {
        emit ReceivedRoyalties(owner(), _buyer, _tokenId, _tokenPaid, _amount);
    }

    // ----- OWNERS METHODS ----- //
    function editClaimingAdress(address _newAddress) external onlyOwner {
        _claimingAddress = _newAddress;
    }

    function setProvenanceHash(string memory _hash) external onlyOwner {
        METADATA_PROVENANCE_HASH = _hash;
    }
}