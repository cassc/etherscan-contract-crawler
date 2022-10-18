// SPDX-License-Identifier: MIT

/// @title The Mojos ERC-721 token

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░███████████████████████░░░ *
 * ░░░░░░█████████████████░░░░░░ *
 * ░░░░░░█████████████████░░░░░░ *
 * ░░░░░░█████████████████░░░░░░ *
 * ░░░░░░█████████████████░░░░░░ *
 * ░░░░░░█████████████████░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { ERC721Checkpointable } from './base/ERC721Checkpointable.sol';
import { IMojosDescriptor } from './interfaces/IMojosDescriptor.sol';
import { IMojosSeeder } from './interfaces/IMojosSeeder.sol';
import { IMojosToken } from './interfaces/IMojosToken.sol';
import { ERC721 } from './base/ERC721.sol';
import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './NonBlockingLzApp.sol';

import './base/ERC721Enumerable.sol';

contract MojosToken is IMojosToken, NonblockingLzApp, ERC721Checkpointable {
    // used for Cross Chain and emergency minting
    // bytes32 public constant EXT_MINTER_ROLE = keccak256('EXT_MINTER_ROLE');

    // The mojos DAO address (creators org)
    address public mojosDAO;

    // An address who has permissions to mint Mojos
    address public minter;

    // The Mojos token URI descriptor
    IMojosDescriptor public descriptor;

    // The Mojos token seeder
    IMojosSeeder public seeder;

    // Whether the minter can be updated
    bool public isMinterLocked;

    // Whether the descriptor can be updated
    bool public isDescriptorLocked;

    // Whether the seeder can be updated
    bool public isSeederLocked;

    // The mojo seeds
    mapping(uint256 => IMojosSeeder.Seed) public seeds;

    // The internal mojo ID tracker
    uint256 public _currentMojoId;

    uint256 public _maxMintId;

    // IPFS content hash of contract-level metadata
    string private _contractURIHash = 'QmZi1n79FqWt2tTLwCqiy6nLM6xLGRsEPQ5JmReJQKNNzX';

    mapping(address => bool) externalMinters;

    /**
     * @notice Require that the minter has not been locked.
     */
    modifier whenMinterNotLocked() {
        require(!isMinterLocked, 'Minter is locked');
        _;
    }

    /**
     * @notice Require that the descriptor has not been locked.
     */
    modifier whenDescriptorNotLocked() {
        require(!isDescriptorLocked, 'Descriptor is locked');
        _;
    }

    /**
     * @notice Require that the seeder has not been locked.
     */
    modifier whenSeederNotLocked() {
        require(!isSeederLocked, 'Seeder is locked');
        _;
    }

    /**
     * @notice Require that the sender is the mojos DAO.
     */
    modifier onlyMojosDAO() {
        require(msg.sender == mojosDAO, 'Sender is not the mojos DAO');
        _;
    }

    /**
     * @notice Require that the sender is the minter.
     */
    modifier onlyMinter() {
        require(msg.sender == minter, 'Sender is not the minter');
        _;
    }

    constructor(
        address _mojosDAO,
        address _minter,
        IMojosDescriptor _descriptor,
        IMojosSeeder _seeder,
        address _lzEndpoint,
        uint256 _startMintId,
        uint256 _endMintId
    ) ERC721('Mojos', 'MOJO') NonblockingLzApp(_lzEndpoint) {
        mojosDAO = _mojosDAO;
        minter = _minter;
        descriptor = _descriptor;
        seeder = _seeder;
        _currentMojoId = _startMintId;
        _maxMintId = _endMintId;
        addExternalMinter(msg.sender);
        addExternalMinter(_lzEndpoint);
    }

    string public baseTokenURI;

    /**
     * @notice The IPFS URI of contract-level metadata.
     */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked('ipfs://', _contractURIHash));
    }

    /**
     * @notice Set the _contractURIHash.
     * @dev Only callable by the owner.
     */
    function setContractURIHash(string memory newContractURIHash) external onlyOwner {
        _contractURIHash = newContractURIHash;
    }

    /**
     * @notice Mint a Mojo to the minter, along with a possible mojos reward
     * Mojo. Mojos reward Mojos are minted every 10 Mojos, starting at 0,
     * until 183 founder Mojos have been minted (5 years w/ 24 hour auctions).
     * @dev Call _mintTo with the to address(es).
     */
    function mint() public override onlyMinter returns (uint256) {
        if (_currentMojoId <= 3640 && _currentMojoId % 10 == 0) {
            _mintTo(mojosDAO, _currentMojoId++);
        }
        return _mintTo(minter, _currentMojoId++);
    }

    /**
     * @notice Mint a Mojo to a specific address, along with a possible mojos reward
     * Mojo. Mojos reward Mojos are minted every 10 Mojos, starting at 0,
     * this is only used for Cross-Chain functionality and emergency minting
     * @dev Call _mintTo with the to address(es).
     */
    function externalMint(
        address _to,
        uint48 _background,
        uint48 _body,
        uint48 _bodyAccessory,
        uint48 _face,
        uint48 _headAccessory
    ) public returns (uint256) {
        require(isExternalMinter(msg.sender),"Not External Minter");
        uint256 mojoId = _currentMojoId++;
        IMojosSeeder.Seed memory seed = seeds[mojoId] = IMojosSeeder.Seed({
            background: _background,
            body: _body,
            bodyAccessory: _bodyAccessory,
            face: _face,
            headAccessory: _headAccessory
        });

        _mint(owner(), _to, mojoId);
        emit MojoCreated(mojoId, seed);

        return mojoId;
    }

    /**
     * @notice Burn a mojo.
     */
    function burn(uint256 mojoId) public override onlyMinter {
        _burn(mojoId);
        emit MojoBurned(mojoId);
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'MojosToken: URI query for nonexistent token');
        return descriptor.tokenURI(tokenId, seeds[tokenId]);
    }

    /**
     * @notice Similar to `tokenURI`, but always serves a base64 encoded data URI
     * with the JSON contents directly inlined.
     */
    function dataURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'MojosToken: URI query for nonexistent token');
        return descriptor.dataURI(tokenId, seeds[tokenId]);
    }

    /**
     * @notice Set the mojos DAO.
     * @dev Only callable by the mojos DAO when not locked.
     */
    function setMojosDAO(address _mojosDAO) external override onlyMojosDAO {
        mojosDAO = _mojosDAO;

        emit MojosDAOUpdated(_mojosDAO);
    }

    /**
     * @notice Set the token minter.
     * @dev Only callable by the owner when not locked.
     */
    function setMinter(address _minter) external override onlyOwner whenMinterNotLocked {
        minter = _minter;

        emit MinterUpdated(_minter);
    }

    /**
     * @notice Lock the minter.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockMinter() external override onlyOwner whenMinterNotLocked {
        isMinterLocked = true;

        emit MinterLocked();
    }

    /**
     * @notice Set the token URI descriptor.
     * @dev Only callable by the owner when not locked.
     */
    function setDescriptor(IMojosDescriptor _descriptor) external override onlyOwner whenDescriptorNotLocked {
        descriptor = _descriptor;

        emit DescriptorUpdated(_descriptor);
    }

    /**
     * @notice Lock the descriptor.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockDescriptor() external override onlyOwner whenDescriptorNotLocked {
        isDescriptorLocked = true;

        emit DescriptorLocked();
    }

    /**
     * @notice Set the token seeder.
     * @dev Only callable by the owner when not locked.
     */
    function setSeeder(IMojosSeeder _seeder) external override onlyOwner whenSeederNotLocked {
        seeder = _seeder;

        emit SeederUpdated(_seeder);
    }

    /**
     * @notice Lock the seeder.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockSeeder() external override onlyOwner whenSeederNotLocked {
        isSeederLocked = true;

        emit SeederLocked();
    }

    /**
     * @notice Mint a Mojo with `mojoId` to the provided `to` address.
     */
    function _mintTo(address to, uint256 mojoId) internal returns (uint256) {
        IMojosSeeder.Seed memory seed = seeds[mojoId] = seeder.generateSeed(mojoId, descriptor);

        _mint(owner(), to, mojoId);
        emit MojoCreated(mojoId, seed);

        return mojoId;
    }

    /// LayerZero Implementation
    function estimateSendFee(
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256 _tokenId,
        bool _useZro,
        bytes calldata _adapterParams
    ) external view virtual override returns (uint256 nativeFee, uint256 zroFee) {
        // mock the payload for send()
        bytes memory payload = abi.encode(_toAddress, _tokenId, seeds[_tokenId]);
        return lzEndpoint.estimateFees(_dstChainId, address(this), payload, _useZro, _adapterParams);
    }

    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256 _tokenId,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParam
    ) external payable virtual override {
        _send(_from, _dstChainId, _toAddress, _tokenId, _refundAddress, _zroPaymentAddress, _adapterParam);
    }

    function send(
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256 _tokenId,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParam
    ) external payable virtual override {
        _send(_msgSender(), _dstChainId, _toAddress, _tokenId, _refundAddress, _zroPaymentAddress, _adapterParam);
    }

    function _send(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint256 _tokenId,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParam
    ) internal virtual {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), 'ONFT721: send caller is not owner nor approved');
        require(ERC721.ownerOf(_tokenId) == _from, 'ONFT721: send from incorrect owner');
        _beforeSend(_from, _dstChainId, _toAddress, _tokenId);

        bytes memory payload = abi.encode(_toAddress, _tokenId, seeds[_tokenId]);
        _lzSend(_dstChainId, payload, _refundAddress, _zroPaymentAddress, _adapterParam);

        uint64 nonce = lzEndpoint.getOutboundNonce(_dstChainId, address(this));
        emit SendToChain(_from, _dstChainId, _toAddress, _tokenId, nonce);
        _afterSend(_from, _dstChainId, _toAddress, _tokenId);
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual override {
        _beforeReceive(_srcChainId, _srcAddress, _payload);

        // decode and load the toAddress
        (bytes memory toAddress, uint256 tokenId, IMojosSeeder.Seed memory seed) = abi.decode(
            _payload,
            (bytes, uint256, IMojosSeeder.Seed)
        );
        address localToAddress;
        assembly {
            localToAddress := mload(add(toAddress, 20))
        }

        // if the toAddress is 0x0, convert to dead address, or it will get cached
        if (localToAddress == address(0x0)) localToAddress == address(0xdEaD);

        _afterReceive(_srcChainId, localToAddress, seed);

        emit ReceiveFromChain(_srcChainId, localToAddress, tokenId, _nonce);
    }

    function _beforeSend(
        address, /* _from */
        uint16, /* _dstChainId */
        bytes memory, /* _toAddress */
        uint256 _tokenId
    ) internal virtual {
        _burn(_tokenId);
    }

    function _afterSend(
        address, /* _from */
        uint16, /* _dstChainId */
        bytes memory, /* _toAddress */
        uint256 /* _tokenId */
    ) internal virtual {}

    function _beforeReceive(
        uint16, /* _srcChainId */
        bytes memory, /* _srcAddress */
        bytes memory /* _payload */
    ) internal virtual {}

    function _afterReceive(
        uint16, /* _srcChainId */
        address _toAddress,
IMojosSeeder.Seed memory _seed
    ) internal virtual {
        uint256 mojoId = _currentMojoId++;
        seeds[mojoId] = _seed;

        _mint(owner(), _toAddress, mojoId);
        emit MojoCreated(mojoId, _seed);
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function addExternalMinter(address _member) public onlyOwner {
        externalMinters[_member] = true;
    }

    function removeExternalMinter(address _member) public onlyOwner {
        externalMinters[_member] = false;
    }

    function isExternalMinter(address _account) public view virtual returns (bool) {
        return externalMinters[_account];
    }
}