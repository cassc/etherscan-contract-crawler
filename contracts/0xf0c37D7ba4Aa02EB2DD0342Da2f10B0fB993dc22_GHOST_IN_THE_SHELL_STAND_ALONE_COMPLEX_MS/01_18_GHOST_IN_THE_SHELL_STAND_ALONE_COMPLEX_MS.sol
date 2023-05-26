// SPDX-License-Identifier: MIT

//      ██████╗ ██╗  ██╗ ██████╗ ███████╗████████╗    ██╗███╗   ██╗    ████████╗██╗  ██╗███████╗    ███████╗██╗  ██╗███████╗██╗     ██╗
//     ██╔════╝ ██║  ██║██╔═══██╗██╔════╝╚══██╔══╝    ██║████╗  ██║    ╚══██╔══╝██║  ██║██╔════╝    ██╔════╝██║  ██║██╔════╝██║     ██║
//     ██║  ███╗███████║██║   ██║███████╗   ██║       ██║██╔██╗ ██║       ██║   ███████║█████╗      ███████╗███████║█████╗  ██║     ██║
//     ██║   ██║██╔══██║██║   ██║╚════██║   ██║       ██║██║╚██╗██║       ██║   ██╔══██║██╔══╝      ╚════██║██╔══██║██╔══╝  ██║     ██║
//     ╚██████╔╝██║  ██║╚██████╔╝███████║   ██║       ██║██║ ╚████║       ██║   ██║  ██║███████╗    ███████║██║  ██║███████╗███████╗███████╗
//      ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝       ╚═╝╚═╝  ╚═══╝       ╚═╝   ╚═╝  ╚═╝╚══════╝    ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝
//
//                                                  ███████╗     █████╗      ██████╗
//                                                  ██╔════╝    ██╔══██╗    ██╔════╝
//                                                  ███████╗    ███████║    ██║
//                                                  ╚════██║    ██╔══██║    ██║
//                                                  ███████║██╗ ██║  ██║██╗ ╚██████╗██╗
//                                                  ╚══════╝╚═╝ ╚═╝  ╚═╝╚═╝  ╚═════╝╚═╝
//
//                                                               ██╗  ██╗
//                                                               ╚██╗██╔╝
//                                                                ╚███╔╝
//                                                                ██╔██╗
//                                                               ██╔╝ ██╗
//                                                               ╚═╝  ╚═╝
//
//                         ███╗   ███╗███████╗████████╗ █████╗ ███████╗ █████╗ ███╗   ███╗██╗   ██╗██████╗  █████╗ ██╗
//                         ████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██╔════╝██╔══██╗████╗ ████║██║   ██║██╔══██╗██╔══██╗██║
//                         ██╔████╔██║█████╗     ██║   ███████║███████╗███████║██╔████╔██║██║   ██║██████╔╝███████║██║
//                         ██║╚██╔╝██║██╔══╝     ██║   ██╔══██║╚════██║██╔══██║██║╚██╔╝██║██║   ██║██╔══██╗██╔══██║██║
//                         ██║ ╚═╝ ██║███████╗   ██║   ██║  ██║███████║██║  ██║██║ ╚═╝ ██║╚██████╔╝██║  ██║██║  ██║██║
//                         ╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {UpdatableOperatorFilterer} from "./operatorFilterer/UpdatableOperatorFilterer.sol";
import {RevokableDefaultOperatorFilterer} from "./operatorFilterer/RevokableDefaultOperatorFilterer.sol";

/**
 * @dev Implementation of the MS tokens which are ERC721 tokens.
 */
contract GHOST_IN_THE_SHELL_STAND_ALONE_COMPLEX_MS is
    ERC721,
    RevokableDefaultOperatorFilterer,
    Ownable,
    ERC2981
{
    using Strings for uint256;

    /**
     * @dev The base URI of metadata
     */
    string private _baseTokenURI;

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    /**
     * @dev The max number of tokens can be minted.
     */
    uint256 public maxSupply;

    /**
     * @dev Price per mint
     */
    uint256 private constant _price = 0.2 ether;

    /**
     * @dev Merkle root hash to check who can mint
     */
    bytes32 private _merkleRoot;

    /**
     * @dev Pre sale status. Pre-minters can't mint if 'isPreActive' is false.
     */
    bool public isPreActive;

    /**
     * @dev `isBurnable` is a public boolean variable that determines the burnability of a token or asset.
     * When `isBurnable` is set to true, `burn` can be executed.
     * The `toggleBurnable` function can be used to change the value of `isBurnable` between true and false, controlling the burn functionality accordingly.
     */
    bool public isBurnable;

    /**
     * @dev The amount of minted tokens by address.
     */
    mapping(address => uint256) private _amountMinted;

    /**
     * @dev Emitted when '_minter' mints. '_mintAmountLeft' is
     * how many pre mints '_minter' can mint. '_totalMinted' is
     * total supply after '_minter' minted.
     */
    event MintAmount(
        uint256 _mintAmountLeft,
        uint256 _totalMinted,
        address _minter
    );

    /**
     * @dev Constractor of this contract. Setting the base token URI,
     * max supply, royalty info and merkle proof.
     * @param _uri The base URI of metadata
     * @param _maxSupply The amount of max supply
     * @param merkleRoot_ Merkle root hash to check who can mint
     */
    constructor(
        string memory _uri,
        uint256 _maxSupply,
        bytes32 merkleRoot_
    ) ERC721("MetaSamurai", "MS") {
        _currentIndex = _startTokenId();
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
            totalMinted() + _mintAmount <= maxSupply,
            "Must mint within max supply"
        );
        require(_mintAmount > 0, "Must mint at least 1");
        _;
    }

    modifier saleCompliance(uint256 _mintAmount, uint256 _maxMintableAmount) {
        require(isPreActive, "The sale is not Active yet");
        address _sender = _msgSender();
        require(
            _mintAmount <= _maxMintableAmount - _amountMinted[_sender],
            "Insufficient mints left"
        );
        require(
            msg.value == _price * _mintAmount,
            "The mint price is not right"
        );
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
     * @dev Mint the specified MS tokens and transfer them to the owner address.
     * @param _mintAmount The amount of minting
     */
    function ownerMint(
        uint256 _mintAmount
    ) external onlyOwner mintCompliance(_mintAmount) {
        mint_(_mintAmount, owner());
    }

    /**
     * @notice Only those who are qualified to preMint can mint the number of '_mintAmount'.
     * @dev Mint the specified MS tokens and transfer them to the minter's address.
     * @param _mintAmount The amount of minting
     * @param _merkleProof `_merkleProof` is valid with minter's address and '_merkleRoot'
     * if and only if the rebuilt hash matches the root of the tree.
     *
     * Emits a {MintAmount} event.
     */
    function preMint(
        uint256 _mintAmount,
        uint256 _maxMintableAmount,
        bytes32[] calldata _merkleProof
    )
        external
        payable
        mintCompliance(_mintAmount)
        saleCompliance(_mintAmount, _maxMintableAmount)
    {
        address to = _msgSender();
        require(
            _verify(to, _maxMintableAmount, _merkleProof),
            "Invalid Merkle Proof"
        );

        unchecked {
            _amountMinted[to] += _mintAmount;
        }
        mint_(_mintAmount, to);

        uint256 mintAmountLeft;
        unchecked {
            mintAmountLeft = _maxMintableAmount - _amountMinted[to];
        }
        emit MintAmount(mintAmountLeft, totalMinted(), to);
    }

    function burn(uint256 _tokenId) external virtual {
        require(isBurnable, "burn is not ready yet");
        require(
            ownerOf(_tokenId) == msg.sender,
            "Only tokens you have can be burned"
        );
        unchecked {
            ++_burnCounter;
        }
        _burn(_tokenId);
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
     * @notice Only the owner can toggle 'isBurnable'.
     * @dev If 'isBurnable' is false, then true. And vice versa.
     * Check the status before toggling.
     */
    function toggleBurnable() external onlyOwner {
        isBurnable = !isBurnable;
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
    function mintableAmount(
        address _address,
        uint256 _maxMintableAmount,
        bytes32[] calldata _merkleProof
    ) external view returns (uint256) {
        if (
            _verify(_address, _maxMintableAmount, _merkleProof) &&
            _amountMinted[_address] < _maxMintableAmount
        ) return _maxMintableAmount - _amountMinted[_address];
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
     * @dev Burned tokens are calculated here, use totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function totalMinted() public view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function owner()
        public
        view
        virtual
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }

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
    function setRoyaltyInfo(
        address _receiver,
        uint96 _royaltyFee
    ) public onlyOwner {
        _setDefaultRoyalty(_receiver, _royaltyFee);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC2981) returns (bool) {
        return
            ERC721.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
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
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 1;
    }

    /**
     * private
     * -----------------------------------------------------------------------------------
     */

    /**
     * @dev This is the common minting function of ownerMint and preMint.
     * Mint the specified MS tokens and transfer them to '_to'.
     * @param _mintAmount The amount of minting
     * @param _to The address where MS tokens are transferred.
     */
    function mint_(uint256 _mintAmount, address _to) private {
        uint256 currentIndex = _currentIndex;
        uint256 maxIndex = currentIndex + _mintAmount;

        _currentIndex = maxIndex;
        for (; currentIndex < maxIndex; ) {
            _safeMint(_to, currentIndex);
            unchecked {
                ++currentIndex;
            }
        }
    }

    function _verify(
        address _address,
        uint256 _maxMintableAmount,
        bytes32[] calldata _merkleProof
    ) private view returns (bool) {
        bytes32 leaf = keccak256(
            abi.encodePacked(_address, _maxMintableAmount.toString())
        );

        return MerkleProof.verify(_merkleProof, _merkleRoot, leaf);
    }
}