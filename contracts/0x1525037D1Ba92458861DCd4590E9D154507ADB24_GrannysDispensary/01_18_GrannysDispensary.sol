// SPDX-License-Identifier: MIT
/*****************************************************************************************************************************************************
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@                &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@        @@        [email protected]@@@@@@@@@@@@@@         @         @@                       @@,        @@@@@@@@@,                  @@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@        @@@@         @@@@@@@@@@@@@@                   @@                       @@,        @@@@@@@                        @@@@@@@@@@@@
 @@@@@@@@@@@@@@@        @@@@@@         @@@@@@@@@@@@@                   @@                       @@,        @@@@@          (@@@@@@          @@@@@@@@@@@
 @@@@@@@@@@@@@(        @@@@@@@@         @@@@@@@@@@@@          @@@@@@@@@@@@@@@@@         @@@@@@@@@@,        @@@@         @@@@@@@@@@@         @@@@@@@@@@
 @@@@@@@@@@@@         @@@@@@@@@@         @@@@@@@@@@@         @@@@@@@@@@@@@@@@@@         @@@@@@@@@@,        @@@         @@@@@@@@@@@&%         @@@@@@@@@
 @@@@@@@@@@@                              @@@@@@@@@@         @@@@@@@@@@@@@@@@@@         @@@@@@@@@@,        @@@                               @@@@@@@@@
 @@@@@@@@@@                                @@@@@@@@@         @@@@@@@@@@@@@@@@@@         @@@@@@@@@@,        @@@                               @@@@@@@@@
 @@@@@@@@@                                  @@@@@@@@         @@@@@@@@@@@@@@@@@@         @@@@@@@@@@,        @@@         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@                                    @@@@@@@         @@@@@@@@@@@@@@@@@@          @@@@@@@@@.        @@@@         @@@@@@@@@@@@@@ @@@@@@@@@@@@@@@
 @@@@@@@         @@@@@@@@@@@@@@@@@@@@         @@@@@@         @@@@@@@@@@@@@@@@@@                 @@,        @@@@@            @@@@@         @@@@@@@@@@@@
 @@@@@@         @@@@@@@@@@@@@@@@@@@@@@         @@@@@         @@@@@@@@@@@@@@@@@@@                @@,        @@@@@@@                         @@@@@@@@@@@
 @@@@@         @@@@@@@@@@@@@@@@@@@@@@@@         @@@@         @@@@@@@@@@@@@@@@@@@@               @@,        @@@@@@@@@@                   @@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     (@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*****************************************************************************************************************************************************/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./ITokenURIRenderer.sol";


contract GrannysDispensary is ERC1155, ERC1155Burnable, IERC2981, Pausable, AccessControl, Ownable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(uint256 => mapping(address => bool)) public burnApprovals;

    uint24 public royaltyPercentBp;
    address payable public royaltyAddress;
    address payable public withdrawalAddress;
    ITokenURIRenderer public tokenURIRenderer;

    string public baseURI;
    string public contractURI;

    event Mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes data
    );
    event BatchMint(
        address to,
        uint256[] ids,
        uint256[] amounts,
        bytes data
    );

    modifier burnApproved(address burner, uint256 tokenId) {
        require(burnApprovals[tokenId][burner], "NOT APPROVED TO BURN TOKEN");
        _;
    }

    constructor(string memory _uri, string memory _contractURI, address _tokenURIRenderer, address payable _withdrawAddress, address payable _royaltyAddress, uint24 _royaltyPercentBp) ERC1155(_uri) Ownable(){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);

        tokenURIRenderer = ITokenURIRenderer(_tokenURIRenderer);
        withdrawalAddress = _withdrawAddress;
        royaltyPercentBp = _royaltyPercentBp;
        royaltyAddress = _royaltyAddress;
        baseURI = _uri;
        contractURI = _contractURI;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // ---- Burning Functions ----

    function approveBurner(address burner, uint256 tokenId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        burnApprovals[tokenId][burner] = true;
    }

    function revokeBurner(address burner, uint256 tokenId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        delete burnApprovals[tokenId][burner];
    }

    function safeBurn(address holder, uint256 tokenId, uint256 value) public whenNotPaused burnApproved(msg.sender, tokenId) {
        _burn(holder, tokenId, value);
    }

    // ---- Minting Functions ----

    function safeMint(address to, uint256 id, uint256 amount, bytes calldata data) public whenNotPaused onlyRole(MINTER_ROLE){
        _mint(to, id, amount, data);
        emit Mint(to, id, amount, data);
    }

    function safeBatchMint(address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) public whenNotPaused onlyRole(MINTER_ROLE){
        _mintBatch(to, ids, amounts, data);
        emit BatchMint(to, ids, amounts, data);
    }

    // --- Contract URI methods ----
    function setContractURI(string calldata _uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        contractURI = _uri;
    }

    // --- Token URI methods ----
    function setURI(string calldata _uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _uri;
        _setURI(_uri);
    }

    function setTokenURIRenderer(address _tokenURIRenderer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenURIRenderer = ITokenURIRenderer(_tokenURIRenderer);
    }

    function uri(uint256 id) public view virtual override returns (string memory){
        return tokenURIRenderer.tokenURI(id, baseURI);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155, AccessControl, IERC165)
    returns (bool)
    {
        return
        interfaceId == type(IERC2981).interfaceId ||
    super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 /* tokenId */, uint256 salePrice) external view override
    returns (address receiver, uint256 royaltyAmount) {
        return (royaltyAddress, (salePrice * royaltyPercentBp) / 10000);
    }

    function setRoyaltyAddress(address payable _royaltyAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        royaltyAddress = _royaltyAddress;
    }

    /// @dev Sets token royalties
    /// @param value percentage (using 2 decimals: 10000 = 100%, 0 = 0%)
    function setRoyalties(uint24 value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(value <= 10000, 'ERC2981Royalties: Too high');
        royaltyPercentBp = value;
    }

    function setWithdrawalAddress(address payable givenWithdrawalAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        withdrawalAddress = givenWithdrawalAddress;
    }

    function withdrawEth() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(withdrawalAddress != address(0), 'WITHDRAWAL_ADDRESS_ZERO');
        Address.sendValue(withdrawalAddress, address(this).balance);
    }


}