// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

error NotAdmin();
error LengthMismatch();

contract CG_Phygital is ERC721Enumerable, AccessControl {
    uint256 public startTokenId;
    uint256 public maxTokenId;

    string public _baseTokenURI = "https://api.nfc.chainguardians.io/metadata/";

    constructor() ERC721("CG_Phygital", "CG_Phygital") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            revert NotAdmin();
        }
        _;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI) external onlyAdmin {
        _baseTokenURI = baseURI;
    }

    function setTokenRange(uint256 _startTokenId, uint256 _maxTokenId)
        external
        onlyAdmin
    {
        startTokenId = _startTokenId;
        maxTokenId = _maxTokenId;
    }

    function mintBatch(address user, uint256 supply) external onlyAdmin {
        require(startTokenId + supply <= maxTokenId, "MAXSUPPLY_REACHED");

        for (uint256 i = 0; i < supply; i++) {
            startTokenId++;
            mint(user, startTokenId);
        }
    }

    function batchTransfer(address[] memory users, uint256[] memory tokenIds)
        external
    {
        if (users.length != tokenIds.length) {
            revert LengthMismatch();
        }

        for (uint256 i = 0; i < users.length; i++) {
            safeTransferFrom(_msgSender(), users[i], tokenIds[i]);
        }
    }

    function mint(address _user, uint256 _tokenId) internal {
        require(_user != address(0), "ZERO_ADDRESS");
        require(!_exists(_tokenId), "ALREADY_MINTED");

        _safeMint(_user, _tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}