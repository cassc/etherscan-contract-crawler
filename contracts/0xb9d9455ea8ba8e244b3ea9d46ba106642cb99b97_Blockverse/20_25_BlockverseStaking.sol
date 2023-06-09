// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./interfaces/IBlockverseStaking.sol";
import "./interfaces/IBlockverseDiamonds.sol";
import "./interfaces/IBlockverse.sol";

contract BlockverseStaking is IBlockverseStaking, IERC721Receiver, Ownable, ReentrancyGuard {
    IBlockverse blockverse;
    IBlockverseDiamonds diamonds;
    address signer;

    mapping(address => uint256) public userStake;
    mapping(address => uint256) public userUnstakeTime;
    mapping(address => IBlockverse.BlockverseFaction) public userUnstakeFaction;
    mapping(uint256 => address) public tokenStakedBy;
    mapping(uint256 => bool) public nonceUsed;

    uint256 unstakeFactionChangeTime = 3 days;

    function stake(address from, uint256 tokenId) external override requireContractsSet nonReentrant {
        require(tx.origin == _msgSender() || _msgSender() == address(blockverse), "Only EOA");
        require(userStake[from] == 0, "Must not be staking already");
        require(userUnstakeFaction[from] == blockverse.getTokenFaction(tokenId) || block.timestamp - userUnstakeTime[from] > unstakeFactionChangeTime, "Can't switch faction yet");
        if (_msgSender() != address(blockverse)) {
            require(blockverse.ownerOf(tokenId) == _msgSender(), "Must own this token");
            require(_msgSender() == from, "Must stake from yourself");
            blockverse.transferFrom(_msgSender(), address(this), tokenId);
        }

        userStake[from] = tokenId;
        tokenStakedBy[tokenId] = from;
    }

    bytes32 constant public MINT_CALL_HASH_TYPE = keccak256("mint(address to,uint256 amount)");

    function claim(uint256 tokenId, bool unstake, uint256 nonce, uint256 amountV, bytes32 r, bytes32 s) external override requireContractsSet nonReentrant {
        require(tx.origin == _msgSender(), "Only EOA");
        require(userStake[_msgSender()] == tokenId, "Must own this token");
        require(tokenStakedBy[tokenId] == _msgSender(), "Must own this token");
        require(!nonceUsed[nonce], "Claim already used");

        nonceUsed[nonce] = true;
        uint256 amount = uint248(amountV >> 8);
        uint8 v = uint8(amountV);

        bytes32 digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",
            keccak256(abi.encode(MINT_CALL_HASH_TYPE, nonce, _msgSender(), amount))
        ));

        address signedBy = ecrecover(digest, v, r, s);
        require(signedBy == signer, "Invalid signer");

        if (unstake) {
            userStake[_msgSender()] = 0;
            tokenStakedBy[tokenId] = address(0);
            userUnstakeFaction[_msgSender()] = blockverse.getTokenFaction(tokenId);
            userUnstakeTime[_msgSender()] = block.timestamp;

            blockverse.safeTransferFrom(address(this), _msgSender(), tokenId, "");
        }

        diamonds.mint(_msgSender(), amount);

        emit Claim(tokenId, amount, unstake);
    }

    function stakedByUser(address user) external view override returns (uint256) {
        return userStake[user];
    }

    // SETUP
    modifier requireContractsSet() {
        require(address(blockverse) != address(0) && address(diamonds) != address(0) &&
            address(signer) != address(0),
            "Contracts not set");
        _;
    }

    function setContracts(address _blockverse, address _diamonds, address _signer) external onlyOwner {
        blockverse = IBlockverse(_blockverse);
        diamonds = IBlockverseDiamonds(_diamonds);
        signer = _signer;
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send to BlockverseStaking directly");
      return IERC721Receiver.onERC721Received.selector;
    }
}