// SPDX-License-Identifier: MIT AND BSD-3-Clause

pragma solidity ^0.8.15;

// █▀▀██▀▀█         ▀██                           ▀██▀▀█▄           ▀██              ▀██
//    ██      ▄▄▄    ██  ▄▄   ▄▄▄▄ ▄▄▄   ▄▄▄       ██   ██    ▄▄▄▄   ██ ▄▄▄    ▄▄▄▄   ██   ▄▄▄▄
//    ██    ▄█  ▀█▄  ██ ▄▀     ▀█▄  █  ▄█  ▀█▄     ██▀▀█▀   ▄█▄▄▄██  ██▀  ██ ▄█▄▄▄██  ██  ██▄ ▀
//    ██    ██   ██  ██▀█▄      ▀█▄█   ██   ██     ██   █▄  ██       ██    █ ██       ██  ▄ ▀█▄▄
//   ▄██▄    ▀█▄▄█▀ ▄██▄ ██▄     ▀█     ▀█▄▄█▀    ▄██▄  ▀█▀  ▀█▄▄▄▀  ▀█▄▄▄▀   ▀█▄▄▄▀ ▄██▄ █▀▄▄█▀
//                            ▄▄ █                                       contract by: primata 🐵
//                             ▀▀

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract TokyoRebels is ERC721AQueryable, Ownable, ERC2981 {
    uint256 public phase;
    uint256 public constant MAX_REBELS = 10000;
    uint256 public overrideCost = 0.01 ether;
    uint256 public maxOverride = 20;
    uint256 public discountDivisor = 100;
    bytes32 private rebelMerkleRoot;
    bytes32 private gcMerkleRoot;
    bytes32 private wlMerkleRoot;

    mapping(address => bool) public wlMinted;
    mapping(address => bool) public gcMinted;
    mapping(address => bool) public rebelMinted;
    mapping(address => bool) public publicMinted;

    string private _baseTokenURI;
    string private _prerevealURI;

    error WrongPhase();
    error WrongAmount();
    error ExceedsMaxRebels();
    error AlreadyMinted();
    error NotEnoughEth();
    error NotAllowed();

    /**
     * @dev Sets default royalty receiver and fee. 
     *
     * @param receiver The address that will receive the royalties.
     * @param feeNumerator The amount of royalties to be paid in bps.
     * @param prerevealURI_ The prereveal URI for the token metadata.
     */
    constructor(address receiver, uint96 feeNumerator, string memory prerevealURI_) ERC721A("Tokyo Rebels", "REBEL") {
        _setDefaultRoyalty(receiver, feeNumerator);
        _prerevealURI = prerevealURI_;
    }

    //           ██
    // ▄▄▄▄ ▄▄▄ ▄▄▄    ▄▄▄▄  ▄▄▄ ▄▄▄ ▄▄▄
    //  ▀█▄  █   ██  ▄█▄▄▄██  ██  ██  █
    //   ▀█▄█    ██  ██        ███ ███
    //    ▀█    ▄██▄  ▀█▄▄▄▀    █   █

    /**
    @dev Verifies if the address is whitelisted.
    @param _merkleProof Merkle Proof to verify with the caller address
     */
    function checkWhitelist(bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, wlMerkleRoot, leaf) && !wlMinted[msg.sender];
    }

    /**
    @dev Verifies if the address is GCListed.
    @param _merkleProof Merkle Proof to verify with the caller address
     */
    function checkGeneticChain(bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, gcMerkleRoot, leaf) && !gcMinted[msg.sender];
    }

    /**
    @dev Verifies if the address is RebelListed.
    @param _merkleProof Merkle Proof to verify with the caller address
     */
    function checkRebel(bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, rebelMerkleRoot, leaf) && !rebelMinted[msg.sender];
    }

    /**
    @dev Verifies if contract supports interface.
    @param interfaceId Id to verify
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981, IERC721A)
        returns (bool)
    {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    /**
    @dev Retrieves token URI.
    @param tokenId token Id to retrieve URI
     */
    function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : _prerevealURI;
    }

    //             ██             ▄
    // ▄▄ ▄▄ ▄▄   ▄▄▄  ▄▄ ▄▄▄   ▄██▄
    //  ██ ██ ██   ██   ██  ██   ██
    //  ██ ██ ██   ██   ██  ██   ██
    // ▄██ ██ ██▄ ▄██▄ ▄██▄ ██▄  ▀█▄▀

    /**
    @dev Mint a token to the caller during public phase (2).
     */
    function publicMint() external {
        if (phase != 2) revert WrongPhase();
        if (totalSupply() >= MAX_REBELS) revert ExceedsMaxRebels();
        if (publicMinted[msg.sender]) revert AlreadyMinted();

        _mint(msg.sender, 1);
        publicMinted[msg.sender] = true;
    }

    /**
    @dev Mints up to override limit to the caller during presale and public phase (1 and 2).
    @param _amount Amount of tokens to mint
     */
    function overrideMint(uint256 _amount) external payable {
        if (phase == 0) revert WrongPhase();
        if (_amount > maxOverride) revert WrongAmount();
        if (msg.value < _calculateTotalPrice(overrideCost, _amount)) revert NotEnoughEth();
        if (totalSupply() + _amount > MAX_REBELS) revert ExceedsMaxRebels();

        _mint(msg.sender, _amount);
    }

    /**
    @dev Mints one token the caller during presale and public phase (1 and 2).
    @param _merkleProof Merkle Proof to verify with the caller address
     */
    function whitelistMint(bytes32[] calldata _merkleProof) external {
        if (phase == 0) revert WrongPhase();
        if (totalSupply() >= MAX_REBELS) revert ExceedsMaxRebels();

        if (!checkWhitelist(_merkleProof)) revert NotAllowed();

        _mint(msg.sender, 1);
        wlMinted[msg.sender] = true;
    }

    /**
    @dev Mints up to two tokens to the caller during presale and public phase (1 and 2).
    @param _amount Amount of tokens to mint
    @param _merkleProof Merkle Proof to verify with the caller address
     */
    function geneticChainMint(uint256 _amount, bytes32[] calldata _merkleProof) external {
        if (phase == 0) revert WrongPhase();
        if (_amount > 2) revert WrongAmount();
        if (totalSupply() + _amount > MAX_REBELS) revert ExceedsMaxRebels();
        if (gcMinted[msg.sender]) revert AlreadyMinted();

        if (!checkGeneticChain(_merkleProof)) revert NotAllowed();

        _mint(msg.sender, _amount);
        gcMinted[msg.sender] = true;
    }

    /**
    @dev Mints up to three tokens to the caller during presale and public phase (1 and 2).
    @param _amount Amount of tokens to mint
    @param _merkleProof Merkle Proof to verify with the caller address
     */
    function rebelMint(uint256 _amount, bytes32[] calldata _merkleProof) external {
        if (phase == 0) revert WrongPhase();
        if (_amount > 3) revert WrongAmount();
        if (totalSupply() + _amount > MAX_REBELS) revert ExceedsMaxRebels();
        if (rebelMinted[msg.sender]) revert AlreadyMinted();

        if (!checkRebel(_merkleProof)) revert NotAllowed();

        _mint(msg.sender, _amount);
        rebelMinted[msg.sender] = true;
    }

    //                                                                                   ▄
    // ▄▄ ▄▄ ▄▄    ▄▄▄▄   ▄▄ ▄▄▄    ▄▄▄▄     ▄▄▄ ▄   ▄▄▄▄  ▄▄ ▄▄ ▄▄     ▄▄▄▄  ▄▄ ▄▄▄   ▄██▄
    //  ██ ██ ██  ▀▀ ▄██   ██  ██  ▀▀ ▄██   ██ ██  ▄█▄▄▄██  ██ ██ ██  ▄█▄▄▄██  ██  ██   ██
    //  ██ ██ ██  ▄█▀ ██   ██  ██  ▄█▀ ██    █▀▀   ██       ██ ██ ██  ██       ██  ██   ██
    // ▄██ ██ ██▄ ▀█▄▄▀█▀ ▄██▄ ██▄ ▀█▄▄▀█▀  ▀████▄  ▀█▄▄▄▀ ▄██ ██ ██▄  ▀█▄▄▄▀ ▄██▄ ██▄  ▀█▄▀
    //                                     ▄█▄▄▄▄▀

    function teamAllocation(uint256 _amount, address _receiver) external onlyOwner {
        if (totalSupply() + _amount > MAX_REBELS) revert ExceedsMaxRebels();
        _mint(_receiver, _amount);
    }

    function setPhase(uint256 _phase) public onlyOwner {
        phase = _phase;
    }

    function setDiscountDivisor(uint256 _discountDivisor) external onlyOwner {
        discountDivisor = _discountDivisor;
    }

    function setWLMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        wlMerkleRoot = _merkleRoot;
    }

    function setGCMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        gcMerkleRoot = _merkleRoot;
    }

    function setRebelMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        rebelMerkleRoot = _merkleRoot;
    }

    function setOverrideCost(uint256 _cost) external onlyOwner {
        overrideCost = _cost;
    }

    function setMaxOverride(uint256 _maxOverride) external onlyOwner {
        maxOverride = _maxOverride;
    }

    function setPrerevealURI(string memory prerevealURI_) external onlyOwner {
        _prerevealURI = prerevealURI_;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function withdraw() external onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }

    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        IERC20(_tokenAddress).transfer(address(msg.sender), _tokenAmount);
    }

    function recoverERC721(address _tokenAddress, uint256 _tokenId) external onlyOwner {
        IERC721A(_tokenAddress).transferFrom(address(this), address(msg.sender), _tokenId);
    }

    //  ██             ▄                                    ▀██
    // ▄▄▄  ▄▄ ▄▄▄   ▄██▄    ▄▄▄▄  ▄▄▄ ▄▄  ▄▄ ▄▄▄    ▄▄▄▄    ██
    //  ██   ██  ██   ██   ▄█▄▄▄██  ██▀ ▀▀  ██  ██  ▀▀ ▄██   ██
    //  ██   ██  ██   ██   ██       ██      ██  ██  ▄█▀ ██   ██
    // ▄██▄ ▄██▄ ██▄  ▀█▄▀  ▀█▄▄▄▀ ▄██▄    ▄██▄ ██▄ ▀█▄▄▀█▀ ▄██▄

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _calculateTotalPrice(uint256 _price, uint256 _num)
        internal
        view
        returns (uint256 totalPrice)
    {
        totalPrice = (_price * _num * (discountDivisor - _num)) / discountDivisor;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}