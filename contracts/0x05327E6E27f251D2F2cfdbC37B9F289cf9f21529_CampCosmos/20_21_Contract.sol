// SPDX-License-Identifier: MIT
/*

     
     
                                       ▓▓▄ 
                                 ▓▓▓▓▓▓▓▄▓▓█▄▓▓▓▓▓▓▓▓▓▌
                            g▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓█▓▓█
                         w,▐▓▓▓▓▓▓▓▓▓▓███████████▓████████████
                      ╓,▐▓▓▓▓▓▓███▓█████████████████████████████
                      ╟▓▓▓▓██▀▀╢╢▒╣╣╢╢╢╢╢╢╢╢╢╢╢╣▒╢▀▀▀▀███████████▄
                       ▓█▀▒╫╢╢╢╣╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢▒╢▀█████████▌
                       ╓▓▓╢╢╢╢╢╢╢╢╣╣╣╣╣╣╢╢╢╢╢╢╣╣╣╣╣╢╢╢╢╢╢╢▓▓▓╣█████▀╣╣@,
                      ]▓▓╣╣╢╢▒▒▄▄▓▓▓▓▓▓██████▓╨╨╜╨╨╩╩╣╢╢╢▓▓▓▓▓▓▓▓█╣╣╢╢╢╢L
                       ▀▓╜"    ▓▓▓▓▓▓▓▓█▓▓▓▓▀░░░░░░░░░▒▒▒▒╢▓▓▓▓▓▓╢█▓╣╢▓╩╩
                      ░░░░░░░▒▓▓▓█▌▓▓█░░░░░░░░░░░░░░░▒▒▒▒╢╢▓▓▓▓▓█▓╖,
                     ░░░░░░░░░░░▒▓▓█░░⌠│░░░░░░░░░░░░░░▒▒▒▒▒╢╢╢▓▓▓▓▓▓▓
                    ╓▄▄▄╗,░░░░░░░░╜░░░░░░░░░░░░░░░░░░lg▄▄▄▄╢╢╢╢▓▓▓▓▓▒
                  ▄███████╫░░░░░░░░░░░░░░░░░░░░▒"▄▓████████████╣▓▓▓▓▓▌
                 ▄██████████▄░░░░░░░░░░▒░░░░░░▒▄█▄███████▒▒▒█████▓▓▓▓▓"
                 ▒░╢╢╢╢██████⌐░░░░░░░░░▒▒░░░▒ ███▀▀▀▀▀▀▀▒▒╢╢██████▓▓▓▓
                ║╢╣╣╣╢╢╢██████░░░░░░░░░░░░▒▒`▐████╢╣╢╣╢╢╣╢╢╢╢▀█████▓▓▓
                ╫╢╢╣╢╢╫╢██████░░░█▌░▐█▒▒░▒▒▒ ██████  ╢╢╢╢╣╫╢╢╣╢╣╢██▓▓▓
               ╓╣╢╢╢╢╢╢╫██████░▒▄▄▄▄▄▄▄█▌▒▒▒░██████▀╢╢╣╣╢╣╢╣╢╣╢╣████▓█
               ╢╢╣╢╢╢╢╢╢█████▌▒▒▒▐▓█▓▓╬█▌▒▒▒▒█████▒╢╢╫╢╣╢╣╢╣╢╣██████▓▓
               ╢╢╢╢╢╢╢╢███████▒▒▒▒▒▓▓▓▒▒▒▒▒▒▒▒▒███▄▒▄▄████╢╣╢╣╢╣█████▓▓
               ╢███████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█████████████╢╣████▓▓▓
                ▓▓████████▓░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▀█████████████▓▓▓▓█
                 `▀▀▀▀▀▀╜▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╢╢▓▓▓██▓▓▀▓▓▓▓▓▀
                       `╢╢▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╢╢╢╢╢╣▓▓▓▓▓▓▓▓▓▓▓▀  
                          ╙╢╢▒▒▒▒▒▒▒▒▒╢╢╢╢╢╢╢╢╢╢╣▓▓▓▓▓▓▓▓▓▓▓▓  
                             `╙╩╣╢╢╢╢╢╢╢╢╢╢╢╣▓▓▓▓▓▓▓▓▓▓▓
                                   `"╙╙╩╩▓╢▓▓▓▓▓`
                             ,╥▄▄▄▄▄▄▄▄▄▄║▀▀▀█▌▄▄▄▄▄▄w╥╖╓╓╓
                           ,██████████▀▀ ╙╣▒▒Ñ" ▀▀▀██▀██████▄
                          ▐███▌╢╢▒▒╫▓▄▓▓▓▓▓∩▒ ▓▓▓▓▓▓█╢╣╣╢╢███▄
                          ████▓▒╢╝▒▒▀▓▓▓▓▓▓▓▓▓▌╖▄▓▓█▀▒╠╫╢▓████
                         ███▓▓▀▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓█▓▌▒▒▒▒▒▒▀████
                         ██▓▓▌▒▒▒▒▒▒▒▒█▓▓▓▓▄▓▓█████▌▒▒▒▒▒▒▒▀███
    


 */
pragma solidity ^0.8.12;

import "./lib/ERC721AOpensea.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./lib/IWCNFTErrorCodes.sol";
import "./lib/WCNFTToken.sol";
import "./lib/WCNFTMerkle.sol";

contract CampCosmos is
    ReentrancyGuard,
    WCNFTMerkle,
    WCNFTToken,
    IWCNFTErrorCodes,
    ERC721AOpensea
{
    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public constant MAX_PUBLIC_MINT = 2;
    uint256 public constant PRICE_PER_TOKEN = 0.06 ether;

    string public provenance;
    string private _baseURIextended;
    address payable public immutable shareholderAddress;
    bool public saleActive;

    constructor(address payable shareholderAddress_)
        ERC721A("Camper", "CAMPER")
        ERC721AOpensea()
        WCNFTToken()
    {
        if (shareholderAddress_ == address(0)) revert ZeroAddressProvided();

        // set immutable variables
        shareholderAddress = shareholderAddress_;
    }

    /**
     * @dev checks to see if amount of tokens to be minted would exceed the maximum supply allowed
     * @param numberOfTokens the number of tokens to be minted
     */
    modifier supplyAvailable(uint256 numberOfTokens) {
        if (_totalMinted() + numberOfTokens > MAX_SUPPLY)
            revert ExceedsMaximumSupply();
        _;
    }

    /**
     * @dev checks to see whether saleActive is true
     */
    modifier isPublicSaleActive() {
        if (!saleActive) revert PublicSaleIsNotActive();
        _;
    }

    /***************************************************************************
     * Admin
     */

    /**
     * @dev reserves a number of tokens
     * @param to recipient address
     * @param numberOfTokens the number of tokens to be minted
     */
    function devMint(address to, uint256 numberOfTokens)
        external
        onlyRole(SUPPORT_ROLE)
        supplyAvailable(numberOfTokens)
        nonReentrant
    {
        _safeMint(to, numberOfTokens);
    }

    /**
     * @dev allows public sale minting
     * @param state the state of the public sale
     */
    function setSaleActive(bool state) external onlyRole(SUPPORT_ROLE) {
        saleActive = state;
    }

    /***************************************************************************
     * Tokens
     */

    /**
     * @dev sets the base uri for {_baseURI}
     * @param baseURI_ the base uri
     */
    function setBaseURI(string memory baseURI_)
        external
        onlyRole(SUPPORT_ROLE)
    {
        _baseURIextended = baseURI_;
    }

    /**
     * @dev See {ERC721-_baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    /**
     * @dev sets the provenance hash
     * @param provenance_ the provenance hash
     */
    function setProvenance(string memory provenance_)
        external
        onlyRole(SUPPORT_ROLE)
    {
        provenance = provenance_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     * @param interfaceId the interface id
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AOpensea, WCNFTToken, AccessControl)
        returns (bool)
    {
        return
            ERC721AOpensea.supportsInterface(interfaceId) ||
            WCNFTToken.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     * @param tokenId the token id to burn
     * @param approvalCheck check to see whether msg.sender is approved to burn the token
     */
    function _burn(uint256 tokenId, bool approvalCheck)
        internal
        virtual
        override
    {
        super._burn(tokenId, approvalCheck);
        _resetTokenRoyalty(tokenId);
    }

    /***************************************************************************
     * Public
     */

    /**
     * @dev allow minting if the msg.sender is on the allow list
     */
    function mintAllowList(
        uint256 numberOfTokens,
        uint256 totalTokenAmount,
        uint256 price,
        bytes32[] memory merkleProof
    )
        external
        payable
        isAllowListActive
        ableToClaimC(msg.sender, totalTokenAmount, price, merkleProof)
        tokensAvailable(msg.sender, numberOfTokens, totalTokenAmount)
        supplyAvailable(numberOfTokens)
        nonReentrant
    {
        if ((numberOfTokens * price) != msg.value) revert WrongETHValueSent();

        _setAllowListMinted(msg.sender, numberOfTokens);
        _safeMint(msg.sender, numberOfTokens);
    }

    /**
     * @dev allow public minting
     * @param numberOfTokens the number of tokens to be minted
     */
    function mint(uint256 numberOfTokens)
        external
        payable
        isPublicSaleActive
        supplyAvailable(numberOfTokens)
        nonReentrant
    {
        if (numberOfTokens > MAX_PUBLIC_MINT)
            revert ExceedsMaximumTokensPerTransaction();
        if (numberOfTokens * PRICE_PER_TOKEN != msg.value)
            revert WrongETHValueSent();

        _safeMint(msg.sender, numberOfTokens);
    }

    /***************************************************************************
     * Withdraw
     */

    /**
     * @dev withdraws ether from the contract to the shareholder address
     */
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = shareholderAddress.call{
            value: address(this).balance
        }("");
        if (!success) revert WithdrawFailed();
    }
}