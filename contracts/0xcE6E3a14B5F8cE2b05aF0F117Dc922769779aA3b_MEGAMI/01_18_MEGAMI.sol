// SPDX-License-Identifier: MIT

// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddxxxxddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxdol:;,''....'',;:lodxxxxxxxxxxxxxxxxxxxxxdlc;,''....'',;:codxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxdc;'.                .';ldxxxxxxxxxxxxxxdl;'.                ..;cdxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxdl;.                        .;ldxxxxxxxxxo;.                        .;ldxxxxxxxxxxxxxx
// xxxxxxxxxxxxxl,.                            .,lxxxxxxo;.                            .'ldxxxxxxxxxxxx
// xxxxxxxxxxxo;.                                .,lddo;.                                .;oxxxxxxxxxxx
// xxxxxxxxxxo'                                    ....                                    'lxxxxxxxxxx
// xxxxxxxxxl'                             .                   .                            .lxxxxxxxxx
// xxxxxxxxo,                             'c,.              .,c'                             'oxxxxxxxx
// xxxxxxxxc.                             .lxl,.          .,ldo.                             .:xxxxxxxx
// xxxxxxxd,                              .:xxxl,.      .,ldxxc.                              'oxxxxxxx
// xxxxxxxo'                               ,dxxxxl,.  .,ldxxxd;                               .lxxxxxxx
// xxxxxxxo.                               .oxxxxxxl::ldxxxxxo'                               .lxxxxxxx
// xxxxxxxd,                               .cxxxxxxxxxxxxxxxxl.                               'oxxxxxxx
// xxxxxxxx:.           ..                  ;xxxxxxxxxxxxxxxx:                  ..            ;dxxxxxxx
// xxxxxxxxo'           ''                  'oxxxxxxxxxxxxxxd,                  .'           .lxxxxxxxx
// xxxxxxxxxc.          ;,                  .lxxxxxxxxxxxxxxo.                  ';.         .cxxxxxxxxx
// xxxxxxxxxxc.        .c,                  .:xxxxxxxxxxxxxxc.                  'c.        .cdxxxxxxxxx
// xxxxxxxxxxxl'       'l,       ..          ,dxxxxxxxxxxxxd;          ..       'l,       'lxxxxxxxxxxx
// xxxxxxxxxxxxd:.     ;o,       .'          .oxxxxxxxxxxxxo'          ..       'o:.    .:dxxxxxxxxxxxx
// xxxxxxxxxxxxxxd:.  .cd,       .;.         .cxxxxxxxxxxxxl.         .,'       'ol.  .:oxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxo:.,od,       .:.          ;xxxxxxxxxxxx:          .:'       'oo,.:oxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxdodd,       .l,          'dxxxxxxxxxxd,          'l'       'oxodxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxd;       .l:.         .lxxxxxxxxxxo.          :o'       ,dxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxd:.     .ol.         .:xxxxxxxxxxc.         .co'     .:oxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxd:.   .oo'          ;dxxxxxxxxd;          .oo'   .:oxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxo:. .od;          'oxxxxxxxxo'          ,do' .:oxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxd::oxc.         .cxxxxxxxxl.         .:xd::oxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxl.          ;xxxxxxxx:.         .lxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd;          'dxxxxxxd,          ,dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd:.        .lxxxxxxo.        .:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd:.      .cxxxxxxc.      .:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:.     ;dxxxxd;     .:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd:.   'oxxxxo'   .:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:. .cxxxxl. .:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:'cxxxxc,:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddxxxxddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
//
// MEGAMI https://www.megami.io/

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./rarible/royalties/contracts/LibPart.sol";
import "./rarible/royalties/contracts/LibRoyaltiesV2.sol";
import "./rarible/royalties/contracts/RoyaltiesV2.sol";
import "./interfaces/IMEGAMI.sol";

/**
 * @dev Implementation of the MEGAMI tokens which are ERC721 tokens.
 */
contract MEGAMI is IMEGAMI, ERC721, Ownable, ReentrancyGuard, RoyaltiesV2 {
    using Strings for uint256;

    /**
     * @dev Minimum token ID of MEGAMI.
     */ 
    uint256 private constant START_TOKEN_ID = 1;

    /**
     * @dev Maxium number of MEGAMI tokens can be minted.
     */ 
    uint256 private constant MAX_SUPPLY = 10000;

    /**
     * @notice Total number of the MEGAMI tokens minted so far.
     */ 
    uint256 public totalSupply = 0;

    /**
     * @dev The base URI of metadata 
     */ 
    string private baseTokenURI = "ipfs://QmQMdt64iGaCFR1RCN9yRL2eFbWeizPwEdVKbfH9aSayFt/";

    /**
     * @dev Address of the royalty recipient 
     */
    address payable private defaultRoyaltiesReceipientAddress;

    /**
     * @dev Percentage basis points of the royalty
     */ 
    uint96 private defaultPercentageBasisPoints = 300;  // 3%

    /**
     * @dev Address of sales contract
     */ 
    address private salesContractAddr;

    /**
     * @dev Address of the fund manager contract
     */
    address private fundManager;

    /**
     * @dev 100% in bases point
     */
    uint256 private constant HUNDRED_PERCENT_IN_BASIS_POINTS = 10000;

    /**
     * @dev Max royalty this contract allows to set. It's 15% in the basis points.
     */
    uint256 private constant MAX_ROYALTY_BASIS_POINTS = 1500;

    /**
     * @dev Constractor of MEGAMI contract. Setting the fund manager and royalty recipient.
     * @param fundManagerContractAddress Address of the contract managing funds.
     */
    constructor (address fundManagerContractAddress)
    ERC721("MEGAMI", "MEGAMI")
    {
        fundManager = fundManagerContractAddress;
        defaultRoyaltiesReceipientAddress = payable(fundManager);
    }

    /**
     * @dev For receiving fund in case someone try to send it.
     */
    receive() external payable {}

    /**
     * @dev The modifier allowing the function access only for owner and sales contract.
     */
    modifier onlyOwnerORSalesContract()
    {
        require(salesContractAddr == _msgSender() || owner() == _msgSender(), "Ownable: caller is not the Owner or SalesContract");
        _;
    }

    /**
     * @dev Sets the address of the sales contract.
     * @param newSalesContractAddr Address of the contract selling MEGAMI tokens.
     */
    function setSalesContract(address newSalesContractAddr)
        external
        onlyOwner
    {
        salesContractAddr = newSalesContractAddr;
    }

    /**
     * @dev Returns the address of the sales contract.
     */
    function getSalesContract() external view returns (address) {
        return salesContractAddr;
    }

    /**
     * @dev Set baseTokenURI.
     * @param newBaseTokenURI The value being set to baseTokenURI.
     */
    function setBaseTokenURI(string calldata newBaseTokenURI) external onlyOwner {
        baseTokenURI = newBaseTokenURI;
    }

    /**
     * @dev Mint the specified MEGAMI token and transfer it to the specified address.
     * @param _tokenId The token ID being minted.
     * @param _address Receiver's address of the minted token.
     */
    function mint(uint256 _tokenId, address _address) 
        external 
        override 
        onlyOwnerORSalesContract nonReentrant 
    { 
        require(_tokenId >= START_TOKEN_ID && _tokenId < START_TOKEN_ID + MAX_SUPPLY, "invalid token id");
        
        unchecked { ++totalSupply; }

        _safeMint(_address, _tokenId);
    }

    /**
     * @dev Set the royalty recipient.
     * @param newDefaultRoyaltiesReceipientAddress The address of the new royalty receipient.
     */
    function setDefaultRoyaltiesReceipientAddress(address payable newDefaultRoyaltiesReceipientAddress) external onlyOwner {
        require(newDefaultRoyaltiesReceipientAddress != address(0), "invalid address");
        defaultRoyaltiesReceipientAddress = newDefaultRoyaltiesReceipientAddress;
    }

    /**
     * @dev Set the percentage basis points of the loyalty.
     * @param newDefaultPercentageBasisPoints The new percentagy basis points of the loyalty.
     */
    function setDefaultPercentageBasisPoints(uint96 newDefaultPercentageBasisPoints) external onlyOwner {
        require(newDefaultPercentageBasisPoints <= MAX_ROYALTY_BASIS_POINTS, "must be less than or equal to 15%");
        defaultPercentageBasisPoints = newDefaultPercentageBasisPoints;
    }

    /**
     * @dev Return royality information for Rarible.
     */
    function getRaribleV2Royalties(uint256) external view override returns (LibPart.Part[] memory) {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = defaultPercentageBasisPoints;
        _royalties[0].account = defaultRoyaltiesReceipientAddress;
        return _royalties;
    }

    /**
     * @dev Return royality information in EIP-2981 standard.
     * @param _salePrice The sale price of the token that royality is being calculated.
     */
    function royaltyInfo(uint256, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        return (defaultRoyaltiesReceipientAddress, (_salePrice * defaultPercentageBasisPoints) / HUNDRED_PERCENT_IN_BASIS_POINTS);
    }
     
    /**
     * @dev Set the address of the fund manager contract.
     * @param contractAddr Address of the contract managing funds.
     */
    function setFundManagerContract(address contractAddr)
        external
        onlyOwner
    {
        require(contractAddr != address(0), "invalid address");
        fundManager = contractAddr;
    } 

    /**
     * @dev Return the address of the fund manager contarct.
     */
    function getFundManagerContract() external view returns (address) {
        return fundManager;
    }

    /**
     * @dev Allow owner to send funds directly to recipient. This is for emergency purpose and use moveFundToManager for regular withdraw.
     * @param recipient The address of the recipinet.
     */
    function emergencyWithdraw(address recipient) external onlyOwner {
        require(recipient != address(0), "recipient shouldn't be 0");

        (bool sent, ) = recipient.call{value: address(this).balance}("");
        require(sent, "failed to withdraw");
    }

    /**
     * @dev Move all of funds to the fund manager contract.
     */
    function moveFundToManager() external onlyOwner {
        require(fundManager != address(0), "fundManager shouldn't be 0");

        (bool sent, ) = fundManager.call{value: address(this).balance}("");
        require(sent, "failed to move fund to FundManager contract");
    }

    /**
     * @dev Return tokenURI for the specified token ID.
     * @param tokenId The token ID the token URI is returned for.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseTokenURI, tokenId.toString(), ".json"));
    }

    /**
     * @dev ERC20s should not be sent to this contract, but if someone does, it's nice to be able to recover them.
     *      Copied from ForgottenRunesWarriorsGuild. Thank you dotta ;)
     * @param token IERC20 the token address
     * @param amount uint256 the amount to send
     */
    function forwardERC20s(IERC20 token, uint256 amount) public onlyOwner {
        token.transfer(msg.sender, amount);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(IERC165, ERC721) 
        returns (bool) 
    {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if (interfaceId == type(IERC2981).interfaceId) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
    
    /**
     * @dev Do nothing for disable renouncing ownership.
     */ 
    function renounceOwnership() public override onlyOwner {}     
}