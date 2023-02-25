// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import { ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { OwnableUpgradeable } from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import { PausableUpgradeable } from '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import { ReentrancyGuardUpgradeable } from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import { CountersUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { IRender3NUM } from "./interfaces/IRender3NUM.sol";
import { IContractRegistry } from "./interfaces/IContractRegistry.sol";

// for debugging
// import "hardhat/console.sol";

contract ENUM is ERC721Upgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error WithdrawError();
    error InvalidRenderContract(string name);
    error InvalidExternalNFTContract(IERC721Metadata addr);
    error InvalidOwner(address msg_sender, address externalOwner);
    error MintClosed();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event ReservationMade(address indexed reserver, uint256 indexed reservationId);

    event TokenMinted(address indexed minter, uint256 indexed tokenId, uint256 pfpId);

    event ContractURIUpdated(string newContractURI);

    event ReservationPriceUpdated(uint256 indexed newPrice);

    event MaxReservationsUpdated(uint256 indexed maxReservations);

    event DAOAddressUpdated(address indexed newAdress);

    event Render3NUMAdded(IRender3NUM _contractAddr, string _name);

    event ExternalNFTContractAdded(IERC721Metadata addr);

    event ExternalNFTContractRemoved(IERC721Metadata addr);

    event BalanceWithdrew(uint256 balance);

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

    // Reminder: you must always add new state variables to the end
    // of this list since this is an Upgradeable contract.

    // Variables added in V0

    string private _contractURI;
    uint256 public reservationPrice;
    address public daoAddress; // The DAO authorizes valid phone numbers (must be EOA)

    // When minting uses this to lookup which contract to use for originTokenURIContract
    IContractRegistry public pfpContractRegistry;

    // Every 3NUM has one and only one originTokenURI set at mint
    mapping(uint256 => IRender3NUM) public originTokenURIContract;

    // Used to render tokenURI from externally owned NFT
    mapping(uint256 => IERC721Metadata) public externalNFT;
    mapping(uint256 => uint256) public externalTokenId;
    mapping(IERC721Metadata => bool) public validExternalNFTContract;

    // Used to pay to reserve a number.
    CountersUpgradeable.Counter private reservationIds;
    mapping(address => uint256) private reservations;
    uint256 public maxReservations; // If set, don't allow reserving more than this number

    // Variables added in V1 (non yet, add them here and create Vn+1 comment)

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                      CONSTRUCTORS AND INITIALIZERS
    //////////////////////////////////////////////////////////////*/

    function initialize(
        IContractRegistry _pfpContractRegistry
    ) public initializer {
        __ERC721_init("3NUM Shield", "3NUM");
        __Ownable_init();

        _pause();

        pfpContractRegistry = _pfpContractRegistry;

        _contractURI = "ipfs://bafkreicu5dmv6bsaxt3nemw2ytfpdlib6h6bgzp5ksywipqwtce54vtfb4";
        reservationPrice = 0.08 ether;
        maxReservations = 1000;
    }

    /*//////////////////////////////////////////////////////////////
                            ERC-721 OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function contractURI() public view returns (string memory) {
        return string(_contractURI);
    }

    function setContractURI(string memory _newContractURI) external onlyOwner {
        _contractURI = _newContractURI;
        emit ContractURIUpdated(_contractURI);
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        address _owner = ownerOf(_tokenId);

        require(_owner != address(0), "3NUM: URI query for nonexistent token");

        // If the 3NUM set a different erc721, use it.
        IERC721Metadata _externalNFT = externalNFT[_tokenId];

        if (_externalNFT != IERC721Metadata(address(0))) {
            if (_externalNFT.ownerOf(externalTokenId[_tokenId]) == _owner) {
                // Invariant if externalNFT is set, externalTokenId is also set.
                return _externalNFT.tokenURI(externalTokenId[_tokenId]);
            }
        }

        IRender3NUM render3NUM = originTokenURIContract[_tokenId];

        // Ensure that the render3NUM,ownerOf matches _owner
        return render3NUM.tokenURI(_tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                        CONTRACT ADMINISTRATION
    //////////////////////////////////////////////////////////////*/

    // Send the eth balance in the contract to owner()
    function withdraw() external {
        uint256 _balance = address(this).balance;
        (bool success, ) = payable(owner()).call{value: _balance}('');
        if (!success) revert WithdrawError();

        emit BalanceWithdrew(_balance);
    }

    function addExternalNFTContract(IERC721Metadata _addr) external onlyOwner {
        validExternalNFTContract[_addr] = true;

        emit ExternalNFTContractAdded(_addr);
    }

    function removeExternalNFTContract(IERC721Metadata _addr) external onlyOwner {
        if (validExternalNFTContract[_addr] == false) revert InvalidExternalNFTContract(_addr);

        delete validExternalNFTContract[_addr];

        emit ExternalNFTContractRemoved(_addr);
    }

    function setReservationPrice(uint256 _newPrice) external onlyOwner {
        // ReservationPrice in wei
        reservationPrice = _newPrice;

        emit ReservationPriceUpdated(reservationPrice);
    }

    function setDAOAddress(address _address) external onlyOwner {
        daoAddress = _address;

        emit DAOAddressUpdated(daoAddress);
    }

    function setMaxReservations(uint256 _max) external onlyOwner {
        maxReservations =_max;

        emit MaxReservationsUpdated(maxReservations);
    }

    //
    // This function can only be called by the owner when the
    // contract is unpaused. It pauses mintItem.
    //
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function maxMintReached() private view returns (bool) {
        return( maxReservations != 0 && reservationIds.current() >= maxReservations );
    }

    function status() public view returns (string memory) {
        if ( maxMintReached() ) return "MintClosed";

        return paused() ? "MintPaused" : "MintOpen";
    }

    /*//////////////////////////////////////////////////////////////
                            CONTRACT LOGIC
    //////////////////////////////////////////////////////////////*/

    function mintItem(
        address _pendingTokenOwner,
        uint256 _tokenId,
        string calldata _mintPFPEdition,
        bytes calldata _signature
    ) external payable nonReentrant whenNotPaused returns (uint256) {
        require(reservationPrice <= msg.value, "Not enough funds sent");

        require(
            verifyNumberSignature(_tokenId, _pendingTokenOwner, _mintPFPEdition, _signature),
            "3NUM: Number signature does not match"
        );

        require(!_exists(_tokenId), "3NUM: tokenId already exists");

        if ( maxMintReached() ) revert MintClosed();

        IRender3NUM mintOriginTokenURIContract = IRender3NUM(pfpContractRegistry.getByName(_mintPFPEdition));

        if (IRender3NUM(address(0)) == mintOriginTokenURIContract) revert InvalidRenderContract(_mintPFPEdition);

        uint256 _pfpId = mintOriginTokenURIContract.mintPFP(_tokenId);

        originTokenURIContract[_tokenId] = mintOriginTokenURIContract;

        _safeMint(_pendingTokenOwner, _tokenId);

        reservationIds.increment(); // reservationIds is really mintCount

        emit TokenMinted(_pendingTokenOwner, _tokenId, _pfpId);

        return _tokenId;
    }

    //
    // You can always query the originTokenURI of a 3NUM (in case tokenURI was set to an external contract)
    //
    function originTokenURI(
        uint256 _tokenId
    ) public view returns (string memory) {
        address _owner = ownerOf(_tokenId);

        require(_owner != address(0), "3NUM: URI query for nonexistent token");

        IRender3NUM render3NUM = originTokenURIContract[_tokenId];

        // Ensure that the render3NUM,ownerOf matches _owner
        return render3NUM.tokenURI(_tokenId);

    }

    //
    // Add an ERC721 NFT as a pfp
    //
    function setExternalNftTokenURI(
        uint256 _tokenId,
        IERC721Metadata _externalNFT,
        uint256 _nftTokenId
    ) external {
        if ( validExternalNFTContract[_externalNFT] != true ) revert InvalidExternalNFTContract(_externalNFT);

        if (this.ownerOf(_tokenId) != msg.sender) revert InvalidOwner(msg.sender, this.ownerOf(_tokenId));

        // This ownership is also always checked to during the call to tokenURI
        if (_externalNFT.ownerOf(_nftTokenId) != msg.sender) revert InvalidOwner(msg.sender, _externalNFT.ownerOf(_nftTokenId));

        externalNFT[_tokenId]     = _externalNFT;
        externalTokenId[_tokenId] = _nftTokenId;
    }

    function e164uintToTokenId(
        uint56 _number
    ) public pure returns (uint256 tokenId) {
        return uint256(keccak256(abi.encodePacked(_number)));
    }

    function verifyNumberSignature(
        uint256 _tokenId,
        address _minter,
        string memory _edition,
        bytes memory _signature
    ) public view returns (bool) {
        bytes32 _messageHash = getMessageHash(_tokenId, _minter, _edition);
        bytes32 _ethSignedMessageHash = getEthSignedMessageHash(_messageHash);

        return (recoverSigner(_ethSignedMessageHash, _signature) == daoAddress);
    }

    function getMessageHash(
        uint256 _tokenId,
        address _minter,
        string memory _edition
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(abi.encodePacked(_tokenId, _minter, _edition))
            );
    }

    function getEthSignedMessageHash(
        bytes32 _messageHash
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(
        bytes memory _sig
    ) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(_sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }
    }
}