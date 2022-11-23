// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "ERC721A/extensions/ERC721AQueryable.sol";
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/token/ERC1155/ERC1155.sol";
import "closedsea/OperatorFilterer.sol";
import "./lib/ECDSA.sol";

contract B3LB3asts is ERC721AQueryable, OperatorFilterer, Ownable {
    /* -------------------------------------------------------------------------- */
    /*                                   errors                                   */
    /* -------------------------------------------------------------------------- */
    error ErrExceedsWLAmount();
    error ErrInactive();
    error ErrInvalidSignature();
    error NonSufficientFunds();
    error ErrExceedsSupplyCap();
    error TransferFailed();
    error ErrInvalidValue();

    /* -------------------------------------------------------------------------- */
    /*                                  constants                                 */
    /* -------------------------------------------------------------------------- */
    ERC1155 private immutable OLD_PASS;
    address private immutable _signer;
    uint256 private constant _maxSupply = 1000;
    uint256 private constant _maxWLMint = 5;

    /* -------------------------------------------------------------------------- */
    /*                                   states                                   */
    /* -------------------------------------------------------------------------- */
    uint256 private _price = 0.1 ether;
    bool private _burnActive;
    bool private _mintActive;

    string private _unrevealedURI = "ipfs://QmWZdmG7RELQXP6T6CA4DsFBWG5AiUG9zXeXN9H5nmfHmV";
    string private _baseTokenURI;

    mapping(address => uint256) private _minted;
    bool public operatorFilterEnabled;

    /* -------------------------------------------------------------------------- */
    /*                                 constructor                                */
    /* -------------------------------------------------------------------------- */
    constructor(address signer_, address oldPass_) ERC721A("B3L B3asts", "B3ASTS") {
        _signer = signer_;
        OLD_PASS = ERC1155(oldPass_);
        _registerForOperatorFiltering();
        operatorFilterEnabled = true;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  external                                  */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev Burns erc1155 passes and mint new 721 passes
     */
    function burnAndBreed() external {
        if (!_burnActive) revert ErrInactive();
        uint256 _quantity = OLD_PASS.balanceOf(_msgSender(), 1);
        uint256 totalSupply = totalSupply();
        assembly {
            // if not enough supply, set quantity to remaining supply.
            if lt(_maxSupply, add(totalSupply, _quantity)) {
                _quantity := sub(_maxSupply, totalSupply)
            }
        }
        OLD_PASS.safeTransferFrom(
            _msgSender(),
            0x000000000000000000000000000000000000dEaD,
            1,
            _quantity,
            "0x0"
        );

        // modified to not update number minted.
        _mint(_msgSender(), _quantity);
    }

    /**
     * @dev Mint for approved applicants
     */
    function mint(uint256 amount, bytes calldata signature) external payable {

        if (!_mintActive) revert ErrInactive();
        if (amount + totalSupply() > _maxSupply) revert ErrExceedsSupplyCap();
        if (msg.value != amount * _price) revert ErrInvalidValue();
        bytes32 data;

        assembly {
            // prepare signature data
            mstore(0x00, shl(0x60, caller()))
            mstore(0x20, keccak256(0x00, 0x14))
            mstore(0x00, "\x00\x00\x00\x00\x19Ethereum Signed Message:\n32")
            data := keccak256(0x04, 0x3c)

            mstore(0x00, caller())
            mstore(0x20, _minted.slot)
            let location := keccak256(0x00, 0x40)
            let newMintedBal := add(amount, sload(location))

            // revert ErrExceedsWLAmount() if exceeds max mint
            if gt(newMintedBal, _maxWLMint) {
                mstore(0x00, 0x7b64f7b9)
                revert(0x1c, 0x04)
            }

            // update minted mapping
            sstore(location, newMintedBal)
        }

        if (_signer != ECDSA.recover(data, signature))
            revert ErrInvalidSignature();

        // modified to not update number minted.
        _mint(_msgSender(), amount);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   Owners                                   */
    /* -------------------------------------------------------------------------- */
    function teamMint(uint256 quantity_, address to_) external onlyOwner {
        if (totalSupply() + quantity_ > _maxSupply) revert ErrExceedsSupplyCap();
        _mint(to_, quantity_);
    }

    function toggleBurn() external onlyOwner {
        _burnActive = !_burnActive;
    }

    function toggleMint() external onlyOwner {
        _mintActive = !_mintActive;
    }

    function changePrice(uint256 price_) external onlyOwner {
        _price = price_;
    }

    function toggleOperatorFilter() external onlyOwner {
        operatorFilterEnabled = !operatorFilterEnabled;
    }

    function setUnrevealedURI(string calldata unrevealedURI_) external onlyOwner {
        _unrevealedURI = unrevealedURI_;
    }

    function setBaseURI(string calldata baseTokenURI_) external onlyOwner {
        _baseTokenURI = baseTokenURI_;
    }

    function withdrawFunds(address to_, uint256 amount_) external onlyOwner {
        (bool success, ) = payable(to_).call{value: amount_}("");
        if (!success) revert TransferFailed();
    }

    /* -------------------------------------------------------------------------- */
    /*                                  overrides                                 */
    /* -------------------------------------------------------------------------- */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) 
        public view virtual override(IERC721A, ERC721A) 
        returns (string memory) {
        if (bytes(_baseTokenURI).length == 0) {
            return _unrevealedURI;
        } else {
            return super.tokenURI(tokenId);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                          ClosedSea Implementation                          */
    /* -------------------------------------------------------------------------- */
    function repeatRegistration() public {
        _registerForOperatorFiltering();
    }

    function setApprovalForAll(address operator, bool approved)
        public override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator, operatorFilterEnabled) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) 
        public payable override(IERC721A, ERC721A) 
        onlyAllowedOperatorApproval(operator, operatorFilterEnabled) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) 
        public payable override(IERC721A, ERC721A) 
        onlyAllowedOperator(from, operatorFilterEnabled) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) 
        public payable override(IERC721A, ERC721A)  
        onlyAllowedOperator(from, operatorFilterEnabled) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) 
        public payable override(IERC721A, ERC721A) 
        onlyAllowedOperator(from, operatorFilterEnabled) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  internal                                  */
    /* -------------------------------------------------------------------------- */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /* -------------------------------------------------------------------------- */
    /*                                    views                                   */
    /* -------------------------------------------------------------------------- */
    function maxWLMint() external pure returns (uint256) {
        return _maxWLMint;
    }

    function maxSupply() external pure returns (uint256) {
        return _maxSupply;
    }

    function mintedWL(address account) external view returns (uint256) {
        return _minted[account];
    }

    function burnAndBreedActive() external view returns (bool) {
        return _burnActive;
    }

    function mintActive() external view returns (bool) {
        return _mintActive;
    }

    function price() external view returns (uint256) {
        return _price;
    }
}