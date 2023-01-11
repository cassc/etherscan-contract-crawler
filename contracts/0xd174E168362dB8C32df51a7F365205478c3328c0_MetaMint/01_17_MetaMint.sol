// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// ooo        ooooo               .                  ooo        ooooo  o8o                  .   
// `88.       .888'             .o8                  `88.       .888'  `"'                .o8   
//  888b     d'888   .ooooo.  .o888oo  .oooo.         888b     d'888  oooo  ooo. .oo.   .o888oo 
//  8 Y88. .P  888  d88' `88b   888   `P  )88b        8 Y88. .P  888  `888  `888P"Y88b    888   
//  8  `888'   888  888ooo888   888    .oP"888        8  `888'   888   888   888   888    888   
//  8    Y     888  888    .o   888 . d8(  888        8    Y     888   888   888   888    888 . 
// o8o        o888o `Y8bod8P'   "888" `Y888""8o      o8o        o888o o888o o888o o888o   "888" 
                                                                         // Created by NFsTeve                                                                 
                                                                                             
                                                                                             

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "erc721a/contracts/ERC721A.sol";

contract MetaMint is ERC721A, Ownable{
    using StringsUpgradeable for uint256;

    // Constants
    address public  MM_VAULT = address(0x79b6067682413DfA8AA99552a627E47B4B28c208);
    ERC1155 private  OS_STOREFRONT = ERC1155(0x88B48F654c30e99bc2e4A1559b4Dcf1aD93FA656);
    uint256 private  OS_METAMINT_TOKENID =
        75079589279640323933009448590078242754813563268524912197102354225149476077573;

    // Variables
    bool public claimActive;
    string public baseURI;
    uint256[] private flaggedTokens;
    bool public isRefundingGas;
    uint256 public maxRefundAmount;
    uint256 public refundGasBuffer;

    // Events
    event TokensClaimed(address indexed sender, uint256 amount);
    event KeyFlagged(address indexed sender, uint256 tokenId);
    event KeyUnflagged(address indexed sender, uint256 tokenId);
    event LegacyTokensTransferred(address indexed sender, address to, uint256 quantity);
    event KeyBurned(address indexed sender, uint256 tokenId);
    event ClaimActiveChanged(address indexed sender, bool active);
    event Refunded(address indexed refunded, uint256 amount);

    constructor() ERC721A("Meta Mint", "MM"){
        isRefundingGas = true;
        maxRefundAmount = 0.01 ether;
        refundGasBuffer = 32196;
    }

    function claimTokens() external {
        require(msg.sender == owner() || claimActive, "Claiming is not active!");
        require(OS_STOREFRONT.isApprovedForAll(msg.sender, address(this)), "Approval required!");

        uint256 claimable = OS_STOREFRONT.balanceOf(msg.sender, OS_METAMINT_TOKENID);
        require(claimable > 0, "No claimable tokens!");

        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);

        ids[0] = OS_METAMINT_TOKENID;
        amounts[0] = claimable;

        OS_STOREFRONT.safeTransferFrom(msg.sender, MM_VAULT, OS_METAMINT_TOKENID, claimable, bytes("0x0"));
        _safeMint(msg.sender, claimable);

        emit TokensClaimed(msg.sender, claimable);
    }

    /*
        Admin Functions
    */

    function balanceOfLegacyKeys(address address_) external view returns (uint256) {
        return OS_STOREFRONT.balanceOf(address_, OS_METAMINT_TOKENID);
    }

    function burn(uint256 tokenId_) public onlyOwner {
        _burn(tokenId_, false);
        emit KeyBurned(msg.sender, tokenId_);
    }

    function setOSSF(address _addr) external onlyOwner {
        OS_STOREFRONT = ERC1155(_addr);
    }

    function setOSSFTokenId(uint256 _addr) external onlyOwner {
        OS_METAMINT_TOKENID = _addr;
    }

    function setMMVault(address _addr) external onlyOwner {
        MM_VAULT = _addr;
    }

    function setClaimActive(bool _claimActive) external onlyOwner {
        claimActive = _claimActive;
        emit ClaimActiveChanged(msg.sender, _claimActive);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setIsRefundingGas(bool isRefundingGas_) external onlyOwner {
        isRefundingGas = isRefundingGas_;
    }

    function setMaxRefundAmount(uint256 maxRefundAmount_) external onlyOwner {
        maxRefundAmount = maxRefundAmount_;
    }

    function setRefundGasBuffer(uint256 refundGasBuffer_) external onlyOwner {
        refundGasBuffer = refundGasBuffer_;
    }

    function withdraw() external payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Failed to withdraw eth.");
    }

    /*
        ERC721A Overrides
    */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if (bytes(baseURI).length > 0) {
            return baseURI;
        } else {
            return "";
        }
    }

    /*
        Modifiers
    */
    // modifier isRefunding() {
    //     uint256 initialGas = gasleft() + refundGasBuffer;
    //     _;
    //     if (isRefundingGas && address(this).balance >= maxRefundAmount) {
    //         uint256 gasCost = (initialGas - gasleft()) * tx.gasprice;
    //         payable(msg.sender).transfer(gasCost > maxRefundAmount ? maxRefundAmount : gasCost);
    //         emit Refunded(msg.sender, gasCost);
    //     }
    // }
}