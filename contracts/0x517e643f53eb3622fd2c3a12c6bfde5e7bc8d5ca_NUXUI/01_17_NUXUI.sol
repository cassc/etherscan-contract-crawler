//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*

███╗   ██╗██╗ ██████╗
████╗  ██║██║██╔════╝
██╔██╗ ██║██║██║
██║╚██╗██║██║██║
██║ ╚████║██║╚██████╗
╚═╝  ╚═══╝╚═╝ ╚═════╝

██╗  ██╗ █████╗ ███╗   ███╗██╗██╗  ████████╗ ██████╗ ███╗   ██╗
██║  ██║██╔══██╗████╗ ████║██║██║  ╚══██╔══╝██╔═══██╗████╗  ██║
███████║███████║██╔████╔██║██║██║     ██║   ██║   ██║██╔██╗ ██║
██╔══██║██╔══██║██║╚██╔╝██║██║██║     ██║   ██║   ██║██║╚██╗██║
██║  ██║██║  ██║██║ ╚═╝ ██║██║███████╗██║   ╚██████╔╝██║ ╚████║

*/


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract NUXUI is
    ERC721,
    IERC2981,
    Pausable,
    AccessControl
{
    using Strings for uint256;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    uint256 public constant MAX_MINT_COUNT = 8;       // +1 to save on gas cost of <= vs <
    uint256 public constant ARTIST_PROOF_COUNT = 11;  // +1 to save on gas cost of <= vs <
    uint256 public constant MAX_SUPPLY = 334;       // +1 to save on gas cost of <= vs <
    uint256 public constant ETH_PRICE = 0.22 ether;
    string public provenanceHash = '8d08f9bd916abfa9cbc965cabb8fd7bdbcc34deb599c48fafe4b4e283c5ba24f';
    string private _baseURIextended = "https://nuxui.art/api/metadata/";
    string private _tombURI = "https://tombseri.es/metadata/20.json";
    address payable private _withdrawalWallet = payable(0x24a1891178b0f4700A6F7D6b4e030Da0054683BA);

    constructor() ERC721("NUXUI", "NUXUI") {
        _pause(); // start paused
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, 0xcb77c9A73E969D0d19CcaE16545eF635702baA85); // k ledger
        grantRole(MANAGER_ROLE, msg.sender);
        _mint(0x518201899E316bf98c957C73e1326b77672Fe52b, 0); // Tomb mint
    }

    function setWithdrawalWallet(address payable withdrawalWallet_) external onlyRole(MANAGER_ROLE) {
        _withdrawalWallet = (withdrawalWallet_);
    }
    function withdraw() external onlyRole(MANAGER_ROLE) {
        payable(_withdrawalWallet).transfer(address(this).balance);
    }

    function pause() public onlyRole(MANAGER_ROLE) {
        _pause();
    }
    function unpause() public onlyRole(MANAGER_ROLE) {
        _unpause();
    }

    function setProvenanceHash(string memory provenanceHash_) external onlyRole(MANAGER_ROLE) {
        provenanceHash = provenanceHash_;
    }
    function setBaseURI(string memory baseURI_) external onlyRole(MANAGER_ROLE) {
        _baseURIextended = baseURI_;
    }
    function setTombURI(string memory tombURI_) external onlyRole(MANAGER_ROLE) {
        _tombURI = tombURI_;
    }

    function contractURI() external view returns (string memory) {
        return string(abi.encodePacked(_baseURIextended, "metadata.json"));
    }

    function getLastTokenId() external view returns (uint256) {
        return _tokenIds.current();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(tokenId <= _tokenIds.current(), "Nonexistent token");
        if (tokenId == 0) {
            return _tombURI;
        }
        return string(abi.encodePacked(_baseURIextended, tokenId.toString(), ".json"));
    }

    function mint(uint256 count)
    external
    payable
    whenNotPaused
    returns (uint256)
    {
        require((ETH_PRICE * count) == msg.value, "Incorrect ETH sent; check price!");
        require(count < MAX_MINT_COUNT, "Tried to mint too many NFTs at once");
        require(_tokenIds.current() + count < MAX_SUPPLY, "SOLD OUT");
        for (uint256 i=0; i<count; i++) {
            _tokenIds.increment();
            _mint(msg.sender, _tokenIds.current());
        }
        return _tokenIds.current();
    }

    // Allows an admin to mint the artist proofs, and send it to an address
    // This can be run while the contract is paused
    function artistMint(uint256 count, address recipient)
    external
    onlyRole(MANAGER_ROLE)
    returns (uint256)
    {
        require(_tokenIds.current() + count < ARTIST_PROOF_COUNT, "Exceeded max proofs");
        require(_tokenIds.current() + count < MAX_SUPPLY, "SOLD OUT");
        for (uint256 i=0; i<count; i++) {
            _tokenIds.increment();
            _mint(recipient, _tokenIds.current());
        }
        return _tokenIds.current();
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");
        return (address(this), SafeMath.div(SafeMath.mul(salePrice, 10), 100));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165, AccessControl) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}