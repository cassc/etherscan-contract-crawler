// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721/ERC721Enumerable.sol";
import "./interfaces/IDobies.sol";

contract Dobies is ERC721Enumerable, Ownable, IDobies {
    string public baseURI;
    address public proxyRegistryAddress;
    uint256 public PUBLIC_SUPPLY = 7200;
    uint256 public minted = 0;
    uint256 public reserves = 800;
    bytes32 public whitelistMerkleRoot;

    mapping(address => bool) public projectProxy;
    mapping(address => uint256) public addressToMinted;

    constructor(
        string memory _baseURI,
        bytes32 _whitelistMerkleRoot,
        address _proxyRegistryAddress,
        uint256 _airdropCount
    ) ERC721("Dobies Collection", "Dobies") {
        baseURI = _baseURI;
        whitelistMerkleRoot = _whitelistMerkleRoot;
        proxyRegistryAddress = _proxyRegistryAddress;

        airdrop(0xb13Adc12aE39223A0A1Da6a531A8B0a946B26BcC, _airdropCount);
    }

    function setPublicSupply(uint256 _PUBLIC_SUPPLY) external onlyOwner {
        PUBLIC_SUPPLY = _PUBLIC_SUPPLY;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist.");
        return
            string(
                abi.encodePacked(
                    baseURI,
                    Strings.toString(_tokenId + 1),
                    ".json"
                )
            );
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress)
        external
        onlyOwner
    {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function flipProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function setMerkleRoot(bytes32 _whitelistMerkleRoot) external onlyOwner {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function _leaf(
        string memory allowance,
        string memory startTime,
        string memory payload
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(payload, startTime, allowance));
    }

    function _verifyWhitelist(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, whitelistMerkleRoot, leaf);
    }

    function mint(
        uint256 count,
        uint256 startTime,
        uint256 allowance,
        bytes32[] calldata proof
    ) public {
        string memory payload = string(abi.encodePacked(_msgSender()));
        require(
            _verifyWhitelist(
                _leaf(
                    Strings.toString(allowance),
                    Strings.toString(startTime),
                    payload
                ),
                proof
            ),
            "Invalid Merkle Tree proof supplied."
        );
        require(
            addressToMinted[_msgSender()] + count <= allowance,
            "Exceeds whitelist supply"
        );
        require(
            minted + count <= PUBLIC_SUPPLY,
            "No more dobies available"
        );

        minted += count;
        addressToMinted[_msgSender()] += count;
        for (uint256 i; i < count; i++) {
            _mint(_msgSender(), totalSupply() + i);
        }
    }

    function airdrop(address to, uint256 count) public onlyOwner {
        require(count <= reserves, "Cant go over reserves");

        reserves -= count;
        addressToMinted[to] += count;
        for(uint256 i; i < count; i++) {
            _mint(to, totalSupply() + i);
        }
    }

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Not approved to burn."
        );
        _burn(tokenId);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds
    ) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function batchSafeTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        bytes memory data_
    ) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }

    function isOwnerOf(address account, uint256[] calldata _tokenIds)
        external
        view
        returns (bool)
    {
        for (uint256 i; i < _tokenIds.length; ++i) {
            if (_owners[_tokenIds[i]] != account) return false;
        }

        return true;
    }

    function isApprovedForAll(address _owner, address operator)
        public
        view
        override(ERC721, IERC721)
        returns (bool)
    {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(
            proxyRegistryAddress
        );
        if (
            address(proxyRegistry.proxies(_owner)) == operator ||
            projectProxy[operator]
        ) return true;
        return super.isApprovedForAll(_owner, operator);
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }
}

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}