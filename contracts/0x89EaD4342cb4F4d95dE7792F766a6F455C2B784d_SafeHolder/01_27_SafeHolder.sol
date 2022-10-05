// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ISafe} from "./interfaces/ISafe.sol";
import {IBeSafe} from "./IBeSafe.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ISignatureValidator} from "./interfaces/ISignatureValidator.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IBeToken} from "./IBeToken.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

contract SafeHolder is ISignatureValidator, ReentrancyGuard, Ownable, Pausable {
    address internal constant SENTINEL = address(0x1); // for owners and modules

    IBeToken public iBeToken;
    IBeSafe public nft;
    uint256 public mintPrice;
    string public nftMetadata;

    mapping(uint256 => address) public tokenToSafe;
    mapping(address => uint256) public safeToToken;
    mapping(bytes32 => bool) internal validSignatures; // overkill

    event Minted(uint256 tokenId, address safe);
    event Redeemed(uint256 tokenId, address safe);

    constructor(
        uint256 _mintPrice,
        address _iBeToken,
        string memory _base64EncodedMetaData
    ) {
        nft = new IBeSafe();
        mintPrice = _mintPrice;
        iBeToken = IBeToken(_iBeToken);
        nftMetadata = _base64EncodedMetaData;
    }

    function mint(address safeAddress)
        external
        payable
        nonReentrant
        whenNotPaused
        returns (uint256 tokenId)
    {
        require(msg.value >= mintPrice, "Must pay the mint cost");
        assert(safeToToken[safeAddress] == 0);
        ISafe safe = ISafe(safeAddress);
        address[] memory safeOwners = safe.getOwners();

        require(safeOwners.length == 2, "Must be two owners");
        require(
            safeOwners[0] == msg.sender || safeOwners[1] == msg.sender,
            "the sender must be a owner"
        );
        require(
            safeOwners[0] == address(this) || safeOwners[1] == address(this),
            "this contract must be a owner"
        );
        require(safe.getThreshold() == 1, "the threshold must be 1");

        (address[] memory modules, ) = safe.getModulesPaginated(SENTINEL, 2);
        require(modules.length == 0, "cant have any enabled modules");

        tokenId = nft.numberOfMintedTokens() + 1;
        tokenToSafe[tokenId] = safeAddress;
        safeToToken[safeAddress] = tokenId;

        iBeToken.mint(msg.sender, iBeTokenReward(tokenId) * (1 ether));
        assert(nft.mint(msg.sender, safeAddress) == tokenId);

        bytes memory removeOwnerCall = abi.encodeWithSelector(
            ISafe.removeOwner.selector,
            address(this), // in theory this can fail
            msg.sender,
            1
        );
        executeOnSafe(safe, removeOwnerCall); // calling unsafe code

        emit Minted(tokenId, safeAddress);
    }

    function redeem(uint256 tokenId) external nonReentrant returns (address safeAddress) {
        require(nft.ownerOf(tokenId) == msg.sender, "only owner can redeem safe");

        safeAddress = tokenToSafe[tokenId];
        delete tokenToSafe[tokenId];
        delete safeToToken[safeAddress];
        ISafe safe = ISafe(safeAddress);

        nft.burn(tokenId);
        bytes memory swapOwnerCall = abi.encodeWithSelector(
            ISafe.swapOwner.selector,
            SENTINEL,
            address(this),
            msg.sender
        );
        executeOnSafe(safe, swapOwnerCall); // calling unsafe code

        emit Redeemed(tokenId, safeAddress);
    }

    function iBeTokenReward(uint256 tokenId) public pure returns (uint256) {
        return
            tokenId < 100 ? 100 : tokenId < 250 ? 75 : tokenId < 500 ? 50 : tokenId < 1000
                ? 25
                : 10;
    }

    function isValidSignature(bytes memory _data, bytes memory _signature)
        public
        view
        override
        returns (bytes4)
    {
        // overkill!
        if (
            validSignatures[
                keccak256(
                    abi.encodePacked(_signature, msg.sender, block.number, tx.origin)
                )
            ]
        ) {
            return EIP1271_MAGIC_VALUE;
        }
        return bytes4(0);
    }

    function executeOnSafe(ISafe safe, bytes memory data)
        internal
        returns (bool success)
    {
        bytes memory signature = createSignature(safe, data);

        success = safe.execTransaction(
            address(safe),
            0,
            data,
            ISafe.Operation.Call,
            0,
            0,
            0,
            address(0x0),
            payable(address(0x0)),
            signature
        );
    }

    function createSignature(ISafe safe, bytes memory data)
        internal
        returns (bytes memory signature)
    {
        bytes32 txHash = safe.getTransactionHash(
            address(safe),
            0,
            data,
            ISafe.Operation.Call,
            0,
            0,
            0,
            address(0x0),
            payable(address(0x0)),
            safe.nonce()
        );

        signature = abi.encodePacked(
            abi.encodePacked(""),
            abi.encode(address(this)),
            abi.encode(65),
            uint8(0),
            abi.encode(txHash.length),
            txHash
        );

        validSignatures[
            keccak256(abi.encodePacked(txHash, address(safe), block.number, tx.origin))
        ] = true;
    }

    function withdraw(address recipient) external onlyOwner {
        require(recipient != address(0));
        payable(recipient).transfer(address(this).balance);
    }

    function withdrawToken(
        address token,
        uint256 amount,
        address recipient
    ) external onlyOwner returns (bool) {
        require(recipient != address(0));
        IERC20(token).approve(recipient, amount);
        return IERC20(token).transferFrom(address(this), recipient, amount);
    }

    function setMintPrice(uint256 mintPriceInWei) external onlyOwner {
        mintPrice = mintPriceInWei;
    }

    function pauseMint() external onlyOwner {
        _pause();
    }

    function unPauseMint() external onlyOwner {
        _unpause();
    }

    //"data:application/json;base64,..."
    function setNftMetadata(string calldata base64EncodedMetaData) external onlyOwner {
        nftMetadata = base64EncodedMetaData;
    }
}