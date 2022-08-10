/**
  ________       .__          __      __  .__           ________                       
 /  _____/_____  |  | _____  |  | ___/  |_|__| ____    /  _____/_____    ____    ____  
/   \  ___\__  \ |  | \__  \ |  |/ /\   __\  |/ ___\  /   \  ___\__  \  /    \  / ___\ 
\    \_\  \/ __ \|  |__/ __ \|    <  |  | |  \  \___  \    \_\  \/ __ \|   |  \/ /_/  >
 \______  (____  /____(____  /__|_ \ |__| |__|\___  >  \______  (____  /___|  /\___  / 
        \/     \/          \/     \/              \/          \/     \/     \//_____/  

Art By: Community Members and Prints by Chris Dyer
Contract By: Travis Delly
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Openzep
import '@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import './Helpers/Base.sol';

contract GalakticGifts is GalakticBase, ERC1155SupplyUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /** ===== STRUCTS ==== */
    struct Gift {
        // THIS IS ONE
        string ipfsMetadataHash;
        // THIS IS ALSO ONE
        uint152 id;
        bool mintable;
        bool snapshot;
        uint16 ggPer;
        uint64 mintableAt;
    }

    /** ===== VARIABLES ==== */
    string public name_;
    string public symbol_;
    uint256 counter;

    mapping(uint256 => Gift) public gifts;
    mapping(address => uint256) public usedCredits;
    mapping(bytes => bool) public usedSignature;
    mapping(address => uint256) public freeMints;

    IERC721Upgradeable galakticGangs;

    /** ===== INITIALIZE ==== */
    function initialize(
        string memory _name,
        string memory _symbol,
        address _galakticGangs
    ) public initializer {
        __ERC1155_init('ipfs://');
        __GalakticBase_init();
        name_ = _name;
        symbol_ = _symbol;

        galakticGangs = IERC721Upgradeable(_galakticGangs);
    }

    /** @dev contract name */
    function name() public view returns (string memory) {
        return name_;
    }

    /** @dev contract symbol */
    function symbol() public view returns (string memory) {
        return symbol_;
    }

    /**
     * @notice adds a new gift
     */
    function addGift(
        string memory _ipfsMetadataHash,
        bool _mintable,
        bool _snapshot,
        uint16 _ggPer,
        uint64 _mintableAt
    ) public onlyOwner {
        counter++;

        Gift storage util = gifts[counter];
        util.id = uint64(counter);
        util.ipfsMetadataHash = _ipfsMetadataHash;
        util.mintable = _mintable;
        util.snapshot = _snapshot;
        util.ggPer = _ggPer;
        util.mintableAt = _mintableAt;
    }

    /**
     * @notice edit an existing gift
     */
    function editGift(
        uint256 _idx,
        string memory _ipfsMetadataHash,
        bool _mintable,
        bool _snapshot,
        uint16 _ggPer,
        uint64 _mintableAt
    ) external onlyOwner {
        require(exists(_idx), 'EditGift: Gift does not exist');
        gifts[_idx].ipfsMetadataHash = _ipfsMetadataHash;
        gifts[_idx].mintable = _mintable;
        gifts[_idx].ggPer = _ggPer;
        gifts[_idx].snapshot = _snapshot;
        gifts[_idx].mintableAt = _mintableAt;
    }

    /**
     * @notice mint gift tokens
     *
     * @param giftIdx the gift id to mint
     * @param amount the amount of tokens to mint
     */
    function mint(
        uint256 giftIdx,
        uint256 amount,
        address to
    ) external onlyOwner {
        require(exists(giftIdx), 'Mint: Gift does not exist');
        _mint(to, giftIdx, amount, '');
    }

    /**
        @notice free mint

        @param giftIdx the gift id to mint (based on signature)
        @param amount amount to mint (based on signature)
        @param signature signature created by owner
     */
    function snapshotFreeMint(
        uint256 giftIdx,
        uint256 amount,
        bytes memory signature
    ) external whenNotPaused {
        bytes32 messageHash = sha256(abi.encode(msg.sender, giftIdx, amount));

        require(
            block.timestamp >= gifts[giftIdx].mintableAt,
            'Not mintable yet... Hold your horses!'
        );
        require(
            gifts[giftIdx].mintable,
            'This NFT is not mintable at the moment, ok just chill.'
        );
        require(
            ECDSAUpgradeable.recover(messageHash, signature) == owner,
            'Invalid Signature, BRO WHAT ARE YOU DOING?'
        );
        require(
            !usedSignature[signature],
            'Signature already used fren. You greedy bastard.'
        );

        usedSignature[signature] = true;
        _mint(msg.sender, giftIdx, amount, '');
    }

    /**
        @notice free mint

        @param giftIdx the gift id to mint (based on signature)
        @param amount amount to mint (based on signature),
     */
    function freeMint(uint256 giftIdx, uint256 amount) external whenNotPaused {
        uint256 balance = galakticGangs.balanceOf(msg.sender);
        uint256 mintableAmount = balance / gifts[giftIdx].ggPer;

        require(
            gifts[giftIdx].mintable,
            'This NFT is not mintable at the moment, ok just chill.'
        );
        require(!gifts[giftIdx].snapshot, 'Invalid request BUD.');
        require(
            block.timestamp >= gifts[giftIdx].mintableAt,
            'Not mintable yet... Hold your horses!'
        );
        require(amount <= mintableAmount, 'Amount is to much, Mr. Greed... ..');
        require(
            freeMints[msg.sender] < mintableAmount,
            "You've already minted your max... Greedy guy."
        );

        freeMints[msg.sender] += amount;

        _mint(msg.sender, giftIdx, amount, '');
    }

    /**
     * @notice mint gift tokens
     *
     * @param giftIdx the gift id to mint
     * @param amount the amount of tokens to mint
     */
    function bulkMint(
        uint256 giftIdx,
        uint256 amount,
        address[] calldata to
    ) external onlyOwner {
        require(exists(giftIdx), 'Mint: Gift does not exist');

        for (uint256 i = 0; i < to.length; i++) {
            require(gifts[giftIdx].mintable, 'Gift is not mintable');

            _mint(to[i], giftIdx, amount, '');
        }
    }

    /**
     * @notice Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address to) external onlyOwner {
        uint256 balance = address(this).balance;

        payable(to).transfer(balance);
    }

    function releaseTokenToOwner(address token) external onlyOwner {
        uint256 contractBalance =
            IERC20Upgradeable(token).balanceOf(address(this));
        IERC20Upgradeable(token).safeTransfer(owner, contractBalance);
    }

    /**
     * @notice return total supply for all existing gifts
     */
    function totalSupplyAll() external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](counter);

        for (uint256 i = 1; i <= counter; i++) {
            result[i - 1] = totalSupply(i);
        }

        return result;
    }

    /**
     *   @notice gets habitatgifts
     */
    function getGifts() external view returns (Gift[] memory) {
        Gift[] memory _utils = new Gift[](counter);

        for (uint256 i = 1; i <= counter; i++) {
            _utils[i - 1] = gifts[i];
        }

        return _utils;
    }

    /** @notice get current idx */
    function getCurrentCounter() external view returns (uint256) {
        return counter;
    }

    /**
     * @notice indicates weither any token exist with a given id, or not
     */
    function exists(uint256 id) public view override returns (bool) {
        return bytes(gifts[id].ipfsMetadataHash).length > 0;
    }

    /**
     * @notice returns the metadata uri for a given id
     *
     * @param _id the gift id to return metadata for
     */
    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), 'URI: nonexistent token');

        return
            string(
                abi.encodePacked(super.uri(_id), gifts[_id].ipfsMetadataHash)
            );
    }
}