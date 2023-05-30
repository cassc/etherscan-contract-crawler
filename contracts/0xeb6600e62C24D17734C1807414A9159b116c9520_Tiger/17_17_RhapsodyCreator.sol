// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./ERC721A.sol";

contract RhapsodyCreator is ERC721A, Ownable, ReentrancyGuard {
    /// ============ Libraries ============

    /// @notice safe math for arithmetic operations
    using SafeMath for uint256;

    /// ============ Immutable storage ============

    /// @notice promotional nfts count
    uint256 public immutable amountForPromotion;

    /// @notice max mintable tokens for each address in public
    uint256 public immutable maxPublicBatchPerAddress;

    /// @notice mint price of each nft; same for pre/public sale.
    uint256 public immutable mintPrice;

    /// ============ Mutable storage ============

    /// @notice metadata object used for tokenURI
    string private _baseTokenURI;

    /// @notice ERC721-presale inclusion root
    bytes32 public presaleMerkleRoot;

    /// @notice time the presale starts;
    uint256 public presaleTime;

    /// @notice time the public starts;
    uint256 public publicTime;

    /// ============ Constructor ============

    /// @notice Creates a new Creator contract
    /// @param _presaleMerkleRoot root of the merklelized whitelist
    /// @param _collectionSize the total size of the collection
    /// @param _maxPublicBatchPerAddress max mintable tokens in public sale
    /// @param _amountForPromotion promotional nfts count
    /// @param _mintPrice mint price of each nft
    constructor(
        string memory _name,
        string memory _symbol,
        bytes32 _presaleMerkleRoot,
        uint256 _collectionSize,
        uint256 _maxPublicBatchPerAddress,
        uint256 _amountForPromotion,
        uint256 _mintPrice
    ) ERC721A(_name, _symbol, _maxPublicBatchPerAddress, _collectionSize) {
        require(_amountForPromotion <= _collectionSize, "RhapsodyCreator/invalid-promotion-amount");
        require(_mintPrice > 0, "RhapsodyCreator/invalid-mint-price");

        maxPublicBatchPerAddress = _maxPublicBatchPerAddress;
        amountForPromotion = _amountForPromotion;
        mintPrice = _mintPrice;

        presaleMerkleRoot = _presaleMerkleRoot;
    }

    /// ============ Events ============

    event Created(address indexed to, uint256 amount);

    /// =========== Sale ===========

    /// @notice Allows presale minting of tokens if address is part of merkle tree
    /// @param invocations number of tokens to mint
    /// @param maxInvocation max number of invocations of the user
    /// @param proof merkle proof to prove address and token mint count are in tree
    function presaleMint(
        uint256 invocations,
        uint256 maxInvocation,
        bytes32[] calldata proof
    ) external payable isMintValid(invocations, maxInvocation) isMintLive(presaleTime) {
        require(_mintOf(msg.sender) == 0, "RhapsodyCreator/invalid-double-mint");
        require(
            MerkleProof.verify(proof, presaleMerkleRoot, keccak256(abi.encodePacked(msg.sender, maxInvocation))),
            "RhapsodyCreator/invalid-address-proof"
        );
        _safeMint(msg.sender, invocations);
        emit Created(msg.sender, invocations);
    }

    /// @notice Allows public minting of tokens
    /// @param invocations number of tokens to mint
    /// @dev user can only mint less than maxPublicBatchPerAddress of tokens
    function publicMint(uint256 invocations)
        external
        payable
        isMintValid(invocations, maxPublicBatchPerAddress)
        isMintLive(publicTime)
    {
        _safeMint(msg.sender, invocations);
        emit Created(msg.sender, invocations);
    }

    /// @notice Set the time for the mint
    /// @param _presaleTime time the presale starts
    /// @param _publicTime time the public sale starts
    /// @dev this function can serve as an "active" and "non-active" sale status
    /// @dev set the values to uint256(-1) for "non-active" sale status
    /// @dev also, pass contract ownership to address(0) to close sale forever
    function setMintTime(uint256 _presaleTime, uint256 _publicTime) public onlyOwner {
        require(_presaleTime > _currentTime(), "RhapsodyCreator/invalid-presale-time");
        require(_publicTime > _presaleTime, "RhapsodyCreator/invalid-public-time");
        presaleTime = _presaleTime;
        publicTime = _publicTime;
    }

    /// @notice force override the merkle root used in presale mint
    /// @param _presaleMerkleRoot root of the merklelized whitelist
    function setMintMerkleRoot(bytes32 _presaleMerkleRoot) public onlyOwner {
        presaleMerkleRoot = _presaleMerkleRoot;
    }

    /// @notice ensures that minters need valid invocations + value to mint
    modifier isMintValid(uint256 invocations, uint256 maxInvocation) {
        require(tx.origin == msg.sender, "RhapsodyCreator/invalid-mint-caller");
        require(totalSupply().add(invocations) <= collectionSize, "RhapsodyCreator/invalid-total-supply");
        require(msg.value == mintPrice.mul(invocations), "RhapsodyCreator/invalid-mint-value");
        require(msg.value > 0 && invocations > 0, "RhapsodyCreator/invalid-invocation-lower-boundary");
        require(
            _mintOf(msg.sender).add(invocations) <= maxInvocation,
            "RhapsodyCreator/invalid-invocation-upper-boundary"
        );
        _;
    }

    /// @notice used to check the time of mint of presale and public
    /// @dev only publicTime/presaleTime variable is used here; see publicMint/presaleMint function
    /// @dev time > 0 is optimization when the sale is not live; r.e  mint "not-active" mode
    modifier isMintLive(uint256 time) {
        require(time > 0 && block.timestamp > time, "RhapsodyCreator/invalid-mint-time");
        _;
    }

    /// =========== Metadata ===========

    /// @notice set the new baseURI to change the tokens metadata
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /// @notice core metadata baseURI used for tokens metadata
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /// @notice core metadata baseURI used for tokens metadata
    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    /// =========== Dev ===========

    /// @notice used by owner to mint promotional nfts
    /// @param invocations the number of invocations to batch mint
    function promotionMint(uint256 invocations) external onlyOwner {
        require(totalSupply().add(invocations) <= amountForPromotion, "RhapsodyCreator/invalid-promotion-supply");
        require(invocations.mod(maxBatchSize) == 0, "RhapsodyCreator/invalid-batch-multiple");
        uint256 blocks = invocations.div(maxBatchSize);
        for (uint256 i = 0; i < blocks; i++) {
            _safeMint(msg.sender, maxBatchSize);
        }
        emit Created(msg.sender, invocations);
    }

    /// @notice withdraws the ether in the contract to owner
    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        require(success, "RhapsodyCreator/invalid-withdraw-money");
    }

    /// @notice returns the current block timestamp
    /// @dev this function is overriden in testing for time-dependent testing
    function _currentTime() internal virtual returns (uint256) {
        return block.timestamp;
    }

    /// @notice sets the owners quantity explicity
    /// @dev eliminate loops in future calls of ownerOf()
    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }
}