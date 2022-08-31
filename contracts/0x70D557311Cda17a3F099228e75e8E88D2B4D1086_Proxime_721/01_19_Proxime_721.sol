// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./common/ERC2981.sol";

contract Proxime_721 is
    Context,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721URIStorage,
    ERC2981,
    AccessControl
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    string private baseTokenURI;
    address public owner;
    mapping(uint256 => bool) private usedNonce;
    address public operator;

    // Create a new role identifier for the minter role
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 nonce;
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    constructor(
        string memory name,
        string memory symbol,
        string memory _baseTokenURI,
        address _operator
    ) ERC721(name, symbol) {
        baseTokenURI = _baseTokenURI;
        owner = _msgSender();
        operator = _operator;
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, operator);
        _tokenIdTracker.increment();
    }

    function transferOwnership(address newOwner)
        external
        onlyRole(ADMIN_ROLE)
        returns (bool)
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _revokeRole(ADMIN_ROLE, owner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        _setupRole(ADMIN_ROLE, newOwner);
        return true;
    }

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function setBaseURI(string memory _baseTokenURI) external onlyRole(ADMIN_ROLE) {
        baseTokenURI = _baseTokenURI;
    }

    function mint(
        string memory _tokenURI,
        uint96 _royaltyFee,
        Sign calldata sign
    ) external virtual returns (uint256 _tokenId) {
        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        verifySign(_tokenURI, msg.sender, sign);
        _tokenId = _tokenIdTracker.current();
        _mint(_msgSender(), _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
        _setTokenRoyalty(_tokenId, _msgSender(), _royaltyFee);
        _tokenIdTracker.increment();
        return _tokenId;
    }

    function mintAndTransfer(
        address from,
        address to,
        string memory _tokenURI,
        uint96 _royaltyFee
    ) external virtual onlyRole(OPERATOR_ROLE) returns(uint256 _tokenId) {
        if(!isApprovedForAll(from, operator)) {
            _setApprovalForAll(from, operator, true);
        }
        _tokenId = _tokenIdTracker.current();
        _mint(from, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
        _setTokenRoyalty(_tokenId, from, _royaltyFee);
        safeTransferFrom(from, to, _tokenId, "");
        _tokenIdTracker.increment();
        return _tokenId;  
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        _resetTokenRoyalty(tokenId);
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, ERC2981, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function verifySign(
        string memory _tokenURI,
        address caller,
        Sign memory sign
    ) internal view {
        bytes32 hash = keccak256(
            abi.encodePacked(this, caller, _tokenURI, sign.nonce)
        );
        require(
            owner ==
                ecrecover(
                    keccak256(
                        abi.encodePacked(
                            "\x19Ethereum Signed Message:\n32",
                            hash
                        )
                    ),
                    sign.v,
                    sign.r,
                    sign.s
                ),
            "Owner sign verification failed"
        );
    }
}