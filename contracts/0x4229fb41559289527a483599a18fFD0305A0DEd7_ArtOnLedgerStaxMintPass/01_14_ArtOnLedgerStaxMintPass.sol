// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import {ERC721} from "@rari-capital/solmate/src/tokens/ERC721.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./Errors.sol";
import "./IArtOfStaxMintPass.sol";
import "./ReentrancyGuard.sol";
import "../Helpers.sol";

contract ArtOnLedgerStaxMintPass is
    ERC721,
    IArtOfStaxMintPass,
    ReentrancyGuard,
    AccessControl,
    Ownable
{
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    string private _baseTokenURI;
    string private _baseContractURI;

    uint256 private _nextTokenCount = 1;

    address private _rootContract;

    constructor(
        string memory baseTokenURI_,
        string memory baseContractURI_,
        string memory _name,
        string memory _symbol,
        address rootContract_
    ) ERC721(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _rootContract = rootContract_;
        _baseTokenURI = baseTokenURI_;
        _baseContractURI = baseContractURI_;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    function mint(address to) external lock {
        if (_rootContract != msg.sender) revert Errors.OnlyRootContract();
        _safeMint(to, _nextTokenCount);

        unchecked {
            ++_nextTokenCount;
        }
    }

    function mint(address to, uint256 amount) external lock {
        if (_rootContract != msg.sender) revert Errors.OnlyRootContract();

        for (uint256 i; i < amount; ) {
            _safeMint(to, _nextTokenCount);

            unchecked {
                ++_nextTokenCount;
                ++i;
            }
        }
    }

    function burn(uint256 id, address tokenOwner)
        external
        onlyRole(BURNER_ROLE)
    {
        _burnLogic(id, tokenOwner);
    }

    function setContractURI(string calldata baseContractURI_)
        external
        onlyOwner
    {
        if (bytes(baseContractURI_).length == 0)
            revert Errors.InvalidBaseContractURL();

        _baseContractURI = baseContractURI_;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        if (bytes(baseURI_).length == 0) revert Errors.InvalidBaseURI();

        _baseTokenURI = baseURI_;
    }

    function totalSupply() external view returns (uint256) {
        return _nextTokenCount - 1;
    }

    function contractURI() external view returns (string memory) {
        return _baseContractURI;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (ownerOf(tokenId) == address(0)) revert Errors.TokenDoesNotExist();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, Helpers.uint2string(tokenId))
                )
                : "";
    }

    function _burnLogic(uint256 id, address tokenOwner) private {
        address owner_ = ownerOf(id);

        if (tokenOwner != owner_) revert Errors.InvalidOwner();

        _burn(id);
    }
}