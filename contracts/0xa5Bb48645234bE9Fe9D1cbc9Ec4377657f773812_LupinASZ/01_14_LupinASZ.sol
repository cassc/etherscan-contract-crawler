// ██╗     ██╗   ██╗██████╗ ██╗███╗   ██╗    ████████╗██╗  ██╗███████╗        ██╗██╗██╗██████╗ ██████╗
// ██║     ██║   ██║██╔══██╗██║████╗  ██║    ╚══██╔══╝██║  ██║██╔════╝        ██║██║██║██╔══██╗██╔══██╗
// ██║     ██║   ██║██████╔╝██║██╔██╗ ██║       ██║   ███████║█████╗          ██║██║██║██████╔╝██║  ██║
// ██║     ██║   ██║██╔═══╝ ██║██║╚██╗██║       ██║   ██╔══██║██╔══╝          ██║██║██║██╔══██╗██║  ██║
// ███████╗╚██████╔╝██║     ██║██║ ╚████║       ██║   ██║  ██║███████╗        ██║██║██║██║  ██║██████╔╝
// ╚══════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═══╝       ╚═╝   ╚═╝  ╚═╝╚══════╝        ╚═╝╚═╝╚═╝╚═╝  ╚═╝╚═════╝
//
//                                             ██╗  ██╗
//                                             ╚██╗██╔╝
//                                              ╚███╔╝
//                                              ██╔██╗
//                                             ██╔╝ ██╗
//                                             ╚═╝  ╚═╝
//
//                                      █████╗ ███████╗███████╗
//                                     ██╔══██╗██╔════╝╚══███╔╝
//                                     ███████║███████╗  ███╔╝
//                                     ██╔══██║╚════██║ ███╔╝
//                                     ██║  ██║███████║███████╗
//                                     ╚═╝  ╚═╝╚══════╝╚══════╝

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @dev Implementation of the ASZ tokens which are ERC721 tokens.
 */
contract LupinASZ is ERC721, Ownable, ERC2981 {
    /**
     * @dev The base URI of metadata
     */
    string private _baseTokenURI;

    /**
     * @dev The max number of tokens can be minted.
     */
    uint256 public maxSupply;

    /**
     * @dev The total number of the MS tokens minted so far.
     */
    uint256 public totalSupply;

    /**
     * @dev Price per mint
     */
    uint256 private constant _price = 0.5 ether;

    /**
     * @dev Number of mint limits per address
     */
    uint256 private _mintLimitsPerAddress = 1;

    /**
     * @dev Merkle root hash to check who can mint
     */
    bytes32 private _merkleRoot;

    /**
     * @dev Pre sale status. Pre-minters can't mint if 'isPreActive' is false.
     */
    bool public isPreActive;

    /**
     * @dev The amount of minted tokens per address.
     */
    mapping(address => uint256) private _amountMinted;

    /**
     * @dev Emitted when '_minter' mints. '_mintAmountLeft' is
     * how many pre mints '_minter' can mint. '_totalSupply' is
     * total supply after '_minter' minted.
     */
    event MintAmount(
        uint256 _mintAmountLeft,
        uint256 _totalSupply,
        address _minter
    );

    /**
     * @dev Constractor of LupinASZ contract. Setting the base token URI,
     * max supply, royalty info and merkle proof.
     * @param _uri The base URI of metadata
     * @param _maxSupply The amount of max supply
     * @param merkleRoot_ Merkle root hash to check who can mint
     */
    constructor(
        string memory _uri,
        uint256 _maxSupply,
        bytes32 merkleRoot_
    ) ERC721("Air Smoke Zero", "ASZ") {
        setBaseTokenURI(_uri);
        setMaxSupply(_maxSupply);
        setRoyaltyInfo(_msgSender(), 750); // 750 == 7.5%
        setMerkleProof(merkleRoot_);
    }

    /**
     * @dev Throws if minting more than 'maxSupply' or
     * when '_mintAmount' is 0.
     * @param _mintAmount The amount of minting
     */
    modifier mintCompliance(uint256 _mintAmount) {
        require(
            totalSupply + _mintAmount <= maxSupply,
            "LUPINASZ: Must mint within max supply"
        );
        require(_mintAmount > 0, "LUPINASZ: Must mint at least 1");
        _;
    }

    /**
     * @dev Throws if pre sale is not active yet,
     * minting more than '_mintLimitsPerAddress' or
     * the mint price is not right.
     * @param _mintAmount The amount of minting
     */
    modifier saleCompliance(uint256 _mintAmount) {
        require(isPreActive, "LUPINASZ: The sale is not Active yet");
        require(
            _amountMinted[_msgSender()] + _mintAmount <= _mintLimitsPerAddress,
            "LUPINASZ: Already reached mint limit"
        );
        require(msg.value == _price, "LUPINASZ: The mint price is not right");
        _;
    }

    /**
     * external
     * -----------------------------------------------------------------------------------
     */

    /**
     * @dev For receiving ETH just in case someone tries to send it.
     */
    receive() external payable {}

    /**
     * @notice Only the owner can mint the number of '_mintAmount'.
     * @dev Mint the specified ASZ tokens and transfer them to the owner address.
     * @param _mintAmount The amount of minting
     */
    function ownerMint(uint256 _mintAmount)
        external
        onlyOwner
        mintCompliance(_mintAmount)
    {
        mint_(_mintAmount, owner());
    }

    /**
     * @notice Only those who are qualified to preMint can mint the number of '_mintAmount'.
     * @dev Mint the specified ASZ tokens and transfer them to the minter's address.
     * @param _mintAmount The amount of minting
     * @param _merkleProof `_merkleProof` is valid with minter's address and '_merkleRoot'
     * if and only if the rebuilt hash matches the root of the tree.
     *
     * Emits a {MintAmount} event.
     */
    function preMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        external
        payable
        mintCompliance(_mintAmount)
        saleCompliance(_mintAmount)
    {
        address to = _msgSender();
        require(_verify(to, _merkleProof), "LUPINASZ: Invalid Merkle Proof");

        unchecked {
            _amountMinted[to] += _mintAmount;
        }
        mint_(_mintAmount, to);

        uint256 mintAmountLeft;
        unchecked {
            mintAmountLeft = _mintLimitsPerAddress - _amountMinted[to];
        }
        emit MintAmount(mintAmountLeft, totalSupply, to);
    }

    /**
     * @notice Only the owner can toggle 'isPreActive'.
     * @dev If 'isPreActive' is false, then true. And vice versa.
     * Check the status before toggling.
     */
    function togglePreActive() external onlyOwner {
        isPreActive = !isPreActive;
    }

    /**
     * @notice Only the owner can set new mint limits.
     * @dev Pre-minters can mint a number of '_mintLimitsPerAddress'.
     */
    function setMintLimits(uint256 _newMintLimits) external onlyOwner {
        _mintLimitsPerAddress = _newMintLimits;
    }

    /**
     * @notice Only the owner can withdraw all of the contract balance.
     * @dev All the balance transfers to the owner's address.
     */
    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "withdraw is failed!!");
    }

    /**
     * @dev Verify if the '_address' can be pre-minted and return the mintable amount left.
     * @return uint256 The mintable amount of pre mint.
     */
    function mintableAmount(address _address, bytes32[] calldata _merkleProof)
        external
        view
        returns (uint256)
    {
        if (
            _verify(_address, _merkleProof) &&
            _amountMinted[_address] < _mintLimitsPerAddress
        ) return _mintLimitsPerAddress - _amountMinted[_address];
        else return 0;
    }

    /**
     * @dev Return the value of '_amountMinted' by the '_address'.
     * @return uint256 The amount minted of pre-mint.
     */
    function amountMinted(address _address) external view returns (uint256) {
        return _amountMinted[_address];
    }

    /**
     * public
     * -----------------------------------------------------------------------------------
     */

    /**
     * @dev Set the new token URI to '_baseTokenURI'.
     */
    function setBaseTokenURI(string memory _newTokenURI) public onlyOwner {
        _baseTokenURI = _newTokenURI;
    }

    /**
     * @dev Set the new max supply to 'maxSupply'.
     */
    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
    }

    /**
     * @dev Set the new merkle root to '_merkleRoot'.
     */
    function setMerkleProof(bytes32 _newMerkleRoot) public onlyOwner {
        _merkleRoot = _newMerkleRoot;
    }

    /**
     * @dev Set the new royalty fee and the new receiver.
     */
    function setRoyaltyInfo(address _receiver, uint96 _royaltyFee)
        public
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _royaltyFee);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * internal
     * -----------------------------------------------------------------------------------
     */

    /**
     * @dev See {ERC721-_baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * private
     * -----------------------------------------------------------------------------------
     */

    /**
     * @dev This is the common minting function of ownerMint and preMint.
     * Mint the specified ASZ tokens and transfer them to '_to'.
     * @param _mintAmount The amount of minting
     * @param _to The address where ASZ tokens are transferred.
     */
    function mint_(uint256 _mintAmount, address _to) private {
        uint256 currentTokenId = totalSupply;
        uint256 maxTokenId = currentTokenId + _mintAmount;

        totalSupply = maxTokenId;
        for (; currentTokenId < maxTokenId; ) {
            _safeMint(_to, currentTokenId);
            unchecked {
                ++currentTokenId;
            }
        }
    }

    /**
     * @dev Verify the '_address' by Merkle proof to check if it's
     * able to preMint.
     * @param _address The address to be verified.
     * @param _merkleProof `_merkleProof` is valid with minter's address and '_merkleRoot'
     * if and only if the rebuilt hash matches the root of the tree.
     */
    function _verify(address _address, bytes32[] calldata _merkleProof)
        private
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_address));

        return MerkleProof.verify(_merkleProof, _merkleRoot, leaf);
    }
}