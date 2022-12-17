// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./common/ERC2981.sol";

contract ICONIQ1155 is
    Context,
    ERC1155Burnable,
    ERC1155Supply,
    ERC2981,
    AccessControl
{
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIdTracker;
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => bool) private usedNonce;

    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 nonce;
    }

    string private baseTokenURI;
    string private _name;
    string private _symbol;
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event BaseURIChanged(string indexed uri, string indexed newuri);

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _baseTokenURI
    ) ERC1155(_baseTokenURI) {
        baseTokenURI = _baseTokenURI;
        owner = _msgSender();
        _setupRole("ADMIN_ROLE", msg.sender);
        _name = _tokenName;
        _symbol = _tokenSymbol;
        _tokenIdTracker.increment();
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /** @dev change the Ownership from current owner to newOwner address
        @param newOwner : newOwner address */

    function transferOwnership(address newOwner)
        external
        onlyRole("ADMIN_ROLE")
        returns (bool)
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _revokeRole("ADMIN_ROLE", owner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        _setupRole("ADMIN_ROLE", newOwner);
        return true;
    }

    function setBaseURI(string memory uri_) external onlyRole("ADMIN_ROLE") returns (bool) {
        emit BaseURIChanged(baseTokenURI, uri_);
        baseTokenURI = uri_;
        return true;
    }

    function mint(
        string memory _tokenURI,
        uint96 _royaltyFee,
        uint256 supply,
        Sign calldata sign
    ) external virtual returns (uint256 _tokenId) {
        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        verifySign(_tokenURI, msg.sender, sign);
        _tokenId = _tokenIdTracker.current();
        _mint(_msgSender(), _tokenId, supply, "");
        _tokenURIs[_tokenId] = _tokenURI;
        _setTokenRoyalty(_tokenId, _msgSender(), _royaltyFee);
        _tokenIdTracker.increment();
        return _tokenId;
    }

    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            exists(tokenId),
            "ERC1155URIStorage: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];
        // If there is no base URI, return the token URI.
        if (bytes(baseTokenURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(baseTokenURI, _tokenURI));
        }
        return
            bytes(baseTokenURI).length > 0
                ? string(abi.encodePacked(baseTokenURI, tokenId.toString()))
                : "";
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

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address _operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Supply, ERC1155) {
        super._beforeTokenTransfer(_operator, from, to, ids, amounts, data);
    }
}