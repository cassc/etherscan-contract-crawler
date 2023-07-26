// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";

contract ERC721Base is
    ERC721,
    ERC721Enumerable,
    Pausable,
    AccessControlEnumerable,
    ERC721Burnable,
    ERC721Royalty
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    string public contractURI;
    string public baseTokenURI;

    mapping(uint256 => string) public _tokenURI;

    // Overrides paused()
    mapping(address => bool) public allowlisted;

    // Overrides when !paused()
    mapping(address => bool) public blocklisted;

    event Allowlisted(address, bool);
    event Blocklisted(address, bool);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        string memory _baseTokenURI
    ) ERC721(_name, _symbol) {
        contractURI = _contractURI;
        baseTokenURI = _baseTokenURI;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());

        _allowlist(msg.sender, true);
    }

    //////////
    // Pause
    //////////
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    //////////
    // Allow/block lists
    //////////

    function allowlist(
        address _address,
        bool _status
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _allowlist(_address, _status);
    }

    function allowlistMultiple(
        address[] calldata _addresses,
        bool[] calldata _statuses
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_addresses.length == _statuses.length, "Invalid lengths");

        for (uint256 i = 0; i < _addresses.length; ++i) {
            _allowlist(_addresses[i], _statuses[i]);
        }
    }

    function _allowlist(address _address, bool _status) internal {
        allowlisted[_address] = _status;
        emit Allowlisted(_address, _status);
    }

    function blocklist(
        address _address,
        bool _status
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _blocklist(_address, _status);
    }

    function blocklistMultiple(
        address[] calldata _addresses,
        bool[] calldata _statuses
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_addresses.length == _statuses.length, "Invalid lengths");

        for (uint256 i = 0; i < _addresses.length; ++i) {
            _blocklist(_addresses[i], _statuses[i]);
        }
    }

    function _blocklist(address _address, bool _status) internal {
        blocklisted[_address] = _status;
        emit Blocklisted(_address, _status);
    }

    //////////
    // Metadata URIs
    //////////
    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        return
            bytes(_tokenURI[_tokenId]).length == 0
                ? string(
                    abi.encodePacked(
                        baseTokenURI,
                        Strings.toString(_tokenId),
                        ".json"
                    )
                )
                : _tokenURI[_tokenId];
    }

    function setContractURI(
        string calldata uri_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        contractURI = uri_;
    }

    function setTokenURI(
        uint256 _tokenId,
        string calldata uri_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _tokenURI[_tokenId] = uri_;
    }

    function setBaseTokenURI(
        string calldata uri_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseTokenURI = uri_;
    }

    function removeTokenURI(
        uint256 _tokenId
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _removeTokenURI(_tokenId);
    }

    function _removeTokenURI(uint256 _tokenId) internal {
        delete _tokenURI[_tokenId];
    }

    //////////
    // Minting
    //////////

    function safeMint(
        address to,
        uint256 tokenId
    ) public onlyRole(MINTER_ROLE) {
        _safeMint(to, tokenId);
    }

    function mint(address to, uint256 id) external onlyRole(MINTER_ROLE) {
        _mint(to, id);
    }

    function mintMultiple(
        address[] calldata to,
        uint256[] calldata ids
    ) external onlyRole(MINTER_ROLE) {
        require(to.length == ids.length, "Length mismatch");
        for (uint256 i = 0; i < ids.length; i++) {
            _mint(to[i], ids[i]);
        }
    }

    //////////
    // Royalty
    //////////
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(
        uint256 tokenId
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _resetTokenRoyalty(tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
        _removeTokenURI(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        require(
            !paused() || allowlisted[msg.sender] || allowlisted[to],
            "Pausable: paused"
        );
        require(
            !blocklisted[msg.sender] && !blocklisted[from] && !blocklisted[to],
            "Blocklisted"
        );
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            ERC721,
            ERC721Enumerable,
            ERC721Royalty,
            AccessControlEnumerable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}