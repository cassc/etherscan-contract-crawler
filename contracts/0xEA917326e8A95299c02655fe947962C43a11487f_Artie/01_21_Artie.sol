// SPDX-License-Identifier: MIT
// To view Artie’s license agreement, please visit artie.com/general-terms
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

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./ITokenURIRenderer.sol";

contract Artie is ERC721, Pausable, AccessControl, ERC721Burnable, Ownable, IERC2981 {
    using SafeERC20 for IERC20;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string public baseURI;
    string public contractURI;
    
    uint24 public royaltyPercentBp;
    address payable public royaltyAddress;

    address payable public withdrawalAddress;

    ITokenURIRenderer public tokenURIRenderer;

    event Mint(
        address to,
        uint256 tokenId
    );

    constructor(string memory tokenName, string memory symbol, string memory baseURI_, string memory contractURI_, address tokenURIRenderer_, address payable withdrawAddress, address payable royaltyAddress_, uint24 royaltyPercentBp_) ERC721(tokenName, symbol) Ownable() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        baseURI = baseURI_;
        contractURI = contractURI_;
        withdrawalAddress = withdrawAddress;
        tokenURIRenderer = ITokenURIRenderer(tokenURIRenderer_);
        royaltyPercentBp = royaltyPercentBp_;
        royaltyAddress = royaltyAddress_;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // ----- minting functions -------

    function safeMint(address to, uint256 tokenId) public whenNotPaused onlyRole(MINTER_ROLE) {
        _safeMint(to, tokenId);
        emit Mint(to, tokenId);
    }

    // ---- Token URI methods ----

    function setTokenURIRenderer(address tokenURIRenderer_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenURIRenderer = ITokenURIRenderer(tokenURIRenderer_);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return tokenURIRenderer.tokenURI(tokenId, _baseURI());
    }

    function setBaseURI(string calldata baseURI_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = baseURI_;
    }

    function setContractURI(string calldata URI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        contractURI = URI;
    }

    // ----- Interface compliance methods -----

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl, IERC165)
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

    function setRoyaltyAddress(address payable royaltyAddress_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        royaltyAddress = royaltyAddress_;
    }

    /// @dev Sets token royalties
    /// @param value percentage (using 2 decimals: 10000 = 100%, 0 = 0%)
    function setRoyalties(uint24 value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(value <= 10000, 'ERC2981Royalties: Too high');
        royaltyPercentBp = uint24(value);
    }

    function setWithdrawalAddress(address payable givenWithdrawalAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        withdrawalAddress = givenWithdrawalAddress;
    }

    function withdrawEth() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(withdrawalAddress != address(0), 'WITHDRAWAL_ADDRESS_ZERO');
        Address.sendValue(withdrawalAddress, address(this).balance);
    }

    function transferERC1155(address contractAddress, address to, uint256 tokenTypeId, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC1155 erc1155Contract = IERC1155(contractAddress);
        erc1155Contract.safeTransferFrom(address(this), to, tokenTypeId, amount, '');
    }

    function transferERC721(address contractAddress, address to, uint256 tokenId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC721 erc721Contract = IERC721(contractAddress);
        erc721Contract.safeTransferFrom(address(this), to, tokenId);
    }

    function transferERC20(address contractAddress, address to, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20 erc20Contract = IERC20(contractAddress);
        erc20Contract.safeTransfer(to, amount);
    }

}