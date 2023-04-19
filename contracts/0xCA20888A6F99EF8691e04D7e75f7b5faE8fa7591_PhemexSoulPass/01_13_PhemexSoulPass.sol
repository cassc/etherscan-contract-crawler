// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract PhemexSoulPass is ERC721, Pausable, ERC721Burnable {
    address private _minter;
    address private _admin;
    string private _baseUri = "https://ipfs-gateway.phemex.com/ipns/phexsbtmd.com/";

    event MinterTransferred(address indexed previousMinter, address indexed newMinter);
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
    event BaseUriUpdated(string previousUri, string newUri);
    event TokenLocked(uint256 indexed tokenId, address indexed approvedContract);

    constructor() ERC721("Phemex Soul Pass", "PSP") {
        _transferMinter(_msgSender());
        _transferAdmin(_msgSender());
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function getBaseUri()
    public
    view
    returns (string memory)
    {
        return _baseUri;
    }

    function setBaseUri(string memory value)
    public
    onlyAdmin
    {
        string memory oldUri = _baseUri;
        _baseUri = value;

        emit BaseUriUpdated(oldUri, _baseUri);
    }

    function pause() public onlyAdmin {
        _pause();
    }

    function unpause() public onlyAdmin {
        _unpause();
    }

    function mint(address to, uint256 tokenId)
    public
    onlyMinter
    {
        _safeMint(to, tokenId);
        emit TokenLocked(tokenId, address(0));
    }

    function batchMint(address[] memory tos, uint256[] memory ids)
    public
    onlyMinter
    {
        require(tos.length == ids.length, "batch mint input invalid");

        for (uint256 i = 0;i < tos.length;i++) {
            mint(tos[i], ids[i]);
        }
    }

    function revoke(uint256 tokenId)
    public
    onlyMinter
    {
        _burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
    internal
    whenNotPaused
    override
    {
        require(
            from == address(0) || to == address(0),
            "ERC721: transfer is not supported yet."
        );

        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    //
    modifier onlyMinter() {
        _checkMinter();
        _;
    }

    function minter() public view virtual returns (address) {
        return _minter;
    }

    function _checkMinter() internal view virtual {
        require(minter() == _msgSender(), "caller is not the minter");
    }

    function transferMinter(address newMinter) public virtual onlyMinter {
        require(newMinter != address(0), "new minter is the zero address");
        _transferMinter(newMinter);
    }

    function _transferMinter(address newMinter) internal virtual {
        address oldMinter = _minter;
        _minter = newMinter;
        emit MinterTransferred(oldMinter, newMinter);
    }

    //
    modifier onlyAdmin() {
        _checkAdmin();
        _;
    }

    function admin() public view virtual returns (address) {
        return _admin;
    }

    function _checkAdmin() internal view virtual {
        require(admin() == _msgSender(), "caller is not the admin");
    }

    function transferAdmin(address newAdmin) public virtual onlyAdmin {
        require(newAdmin != address(0), "new admin is the zero address");
        _transferAdmin(newAdmin);
    }

    function _transferAdmin(address newAdmin) internal virtual {
        address oldAdmin = _admin;
        _admin = newAdmin;
        emit AdminTransferred(oldAdmin, newAdmin);
    }
}