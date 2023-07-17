// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./extensions/ERC721OSafeRemote.sol";

import "./game/IGameStatus.sol";
import "./game/IDNAManager.sol";
import "./game/IFriendship.sol";

import "./IMinted.sol";

error TokenLocked();
error InvalidMinter();

contract Catddle is IMinted, ERC721OSafeRemote {

    string public _baseTokenURI;

    address public minter;

    // Token will be locked when transfer to other chains, then transfer, approve, burn and moveFrom actions will be frozen
    mapping(uint256 => bool) public isLocked;
    
    // Catddle game parts

    // encode attributes, status and friendship into 256 bits
    IGameStatus public gameStatus;
    // encode catddle's DNA and rarity into 256 bits;
    IDNAManager public dnaManager;
    // helper of Catddle friendship
    IFriendship public friendshipManager;


    constructor(string memory baseURI, address endpoint) ERC721O("Catddle", "CAT", endpoint) {
        _baseTokenURI = baseURI;
    }
  
   /**
    * Authorized functions
    */

    function authorizedMint(address user, uint256 tokenId) public override {
        if (msg.sender != minter) revert InvalidMinter();
        _safeMint(user, tokenId);
    }

    /**
     * @dev Invoked by internal transcation to handle lzReceive logic
     */
    function onLzReceive(
        uint16 srcChainId,
        uint64 nonce,
        bytes memory payload
    ) public override {
        
        // only allow internal transaction
        require(
            msg.sender == address(this),
            "ERC721-O: only internal transcation allowed"
        );

        // decode the payload
        (bytes memory to, uint256 tokenId, uint256 dna, uint256 encode) = abi.decode(
            payload,
            (bytes, uint256, uint256, uint256)
        );

        // distributed gameStatus to game managers on local chain
        gameStatus.resolveEncodes(tokenId, encode);

        // write dna to local chain
        dnaManager.setDNA(tokenId, dna);

        address toAddress = _bytes2address(to);

        _afterMoveIn(srcChainId, toAddress, tokenId);

        emit MoveIn(srcChainId, toAddress, tokenId, nonce);
    }


    /**
        OnlyOwner functions
     */

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setMinter(address minter_) public onlyOwner {
        minter = minter_;
    }

    function setDnaManager(address dnaManager_) public onlyOwner {
        dnaManager = IDNAManager(dnaManager_);
    }

    function setFriendshipManager(address friendshipManager_) public onlyOwner {
        friendshipManager = IFriendship(friendshipManager_);
    }

    function setGameStatus(address gameStatus_) public onlyOwner {
        gameStatus = IGameStatus(gameStatus_);
    }

    /**
     * Private pure functions
     */

    function _bytes2address(bytes memory to) private pure returns(address) {
        address toAddress;
        // get toAddress from bytes
        assembly {
            toAddress := mload(add(to, 20))
        }
        return toAddress;
    }

    /**
     * Internal functions   
    */

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev  Move `tokenId` token from `from` address on the current chain to `to` address on the `dstChainId` chain.
     * Internal function of {moveFrom}
     * See {IERC721_O-moveFrom}
     */
    function _move(
        address from,
        uint16 dstChainId,
        bytes calldata to,
        uint256 tokenId,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes calldata adapterParams
    ) internal override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721-O: move caller is not owner or approved"
        );
        // only send message to exist remote contract`
        require(
            _remotes[dstChainId].length > 0,
            "ERC721-O: no remote contract on destination chain"
        );

        // revert if the destination gas limit is lower than `_minDestinationGasLimit`
        _gasGuard(adapterParams);

        _beforeMoveOut(from, dstChainId, to, tokenId);

        // send tokenId, dna, and game status
        bytes memory payload = abi.encode(
            to,
            tokenId,
            dnaManager.dnas(tokenId),
            gameStatus.generateEncodes(tokenId));


        // send message via LayerZero
        _endpoint.send{value: msg.value}(
            dstChainId,
            _remotes[dstChainId],
            payload,
            refundAddress,
            zroPaymentAddress,
            adapterParams
        );

        // track the LayerZero nonce
        uint64 nonce = _endpoint.getOutboundNonce(dstChainId, address(this));

        emit MoveOut(dstChainId, from, to, tokenId, nonce);
    }

    /**
     * @dev See {ERC721O-_beforeMoveOut}.
     */
    function _beforeMoveOut(
        address from,
        uint16 dstChainId,
        bytes memory to,
        uint256 tokenId
    ) internal virtual override {
        require(
            !_pauses[dstChainId],
            "ERC721OSafeRemote: cannot move token to a paused chain"
        );

        if(isLocked[tokenId]) revert TokenLocked();

        // Clear approvals even send to self
        _approve(address(0), tokenId);

        // reset friendship when transfer to other address
        if (from != _bytes2address(to)) {
            friendshipManager.resetFriendship(tokenId);
        }

        // lock token when move out
        isLocked[tokenId] = true;
    }

    /**
     * @dev See {ERC721O-_afterMoveIn}.
     */
    function _afterMoveIn(
        uint16, // srcChainId
        address to,
        uint256 tokenId
    ) internal virtual override {
        if (_exists(tokenId)) {
            // clear all approvals
            _approve(address(0), tokenId);
            // if the token came current chain before, unlock token
            isLocked[tokenId] = false;
            // then transfer token to address(to)
            address owner = ownerOf(tokenId);
            if (owner != to) {
                _transfer(owner, to, tokenId);
            }
        } else {
            // erc721 cannot mint to zero address
            if (to == address(0x0)) {
                to = address(0xdEaD);
            }
            // mint if the token never come to current chain
            _safeMint(to, tokenId);
        }
    }

    // override function in ERC721
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (isLocked[tokenId]) {
            revert TokenLocked();
        }
        // include transfer and burn, exlucde mint (when token from other chain move in the friendship should keep)
        if (from != to && from != address(0) && address(friendshipManager) != address(0)) {
            // reset friendship to zero
            friendshipManager.resetFriendship(tokenId);
        }
    }
}