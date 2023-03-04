// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./interfaces/IStakedERC721.sol";

contract StakedERC721 is IStakedERC721, ERC721Enumerable, AccessControlEnumerable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    mapping(uint256 => StakedInfo) private _stakedInfos;

    bool private _transferrable;
    string private _baseTokenURI;

    event TransferrableUpdated(address updatedBy, bool transferrable);

    constructor(string memory name, string memory symbol, string memory baseTokenURI) 
        ERC721(
            string(abi.encodePacked("Staked", " ", name)), 
            string(abi.encodePacked("S", symbol))
        )
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _baseTokenURI = baseTokenURI;
        _transferrable = false; //default non-transferrable
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, _msgSender()), "StakedERC721.onlyAdmin: permission denied");
        _;
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "StakedERC721.onlyMinter: permission denied");
        _;
    }

    modifier onlyBurner() {
        require(hasRole(BURNER_ROLE, _msgSender()), "StakedERC721.onlyBurner: permission denied");
        _;
    }

    function disableTransfer() external override onlyAdmin() {
        _transferrable = false;
        emit TransferrableUpdated(msg.sender, false);
    }

    function enableTransfer() external override onlyAdmin() {
       _transferrable = true;
       emit TransferrableUpdated(msg.sender, true);
    }

    function transferrable() public view virtual returns (bool) {
        return _transferrable;
    }

    function safeMint(address to, uint256 tokenId, StakedInfo memory stakedInfo) 
        public 
        override 
        onlyMinter
    {
        require(
            stakedInfo.end >= stakedInfo.start, 
            "StakedERC721.safeMint: StakedInfo.end must be greater than StakedInfo.start"
        );
        require(
            stakedInfo.duration > 0, 
            "StakedERC721.safeMint: StakedInfo.duration must be greater than 0"
        );
        _stakedInfos[tokenId] = stakedInfo;
        _safeMint(to, tokenId);
    }

    function burn(uint256 tokenId) 
        public 
        override 
        onlyBurner
    {
        StakedInfo storage stakedInfo = _stakedInfos[tokenId];
        require(block.timestamp >= stakedInfo.end, "StakedERC721.burn: Too soon.");
        delete _stakedInfos[tokenId];
        _burn(tokenId);
    }

    function stakedInfoOf(uint256 _tokenId) public view override returns (StakedInfo memory) {
        require(_exists(_tokenId), "StakedERC721.stakedInfoOf: stakedInfo query for the nonexistent token");
        return _stakedInfos[_tokenId];
    }

    function _transfer(address from, address to, uint256 tokenId)
        internal
        override
    {
        require(transferrable(), "StakedERC721._transfer: not transferrable");
        super._transfer(from, to, tokenId);
    }

    function setBaseURI(string memory baseTokenURI) external onlyAdmin {
        _baseTokenURI = baseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, AccessControlEnumerable, IERC165)
        returns (bool)
    {
        return (interfaceId == type(IStakedERC721).interfaceId || super.supportsInterface(interfaceId));
    }
}