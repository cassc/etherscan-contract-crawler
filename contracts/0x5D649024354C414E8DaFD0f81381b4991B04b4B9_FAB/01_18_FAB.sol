// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {OperatorFilterer} from "./OperatorFilterer.sol";


// ███████  █████  ██████  
// ██      ██   ██ ██   ██ 
// █████   ███████ ██████  
// ██      ██   ██ ██   ██ 
// ██      ██   ██ ██████                        
contract FAB is
    ERC1155Supply,
    ERC1155Burnable,
    OperatorFilterer,
    ERC2981,
    Ownable
{
    using Address for address;
    using Strings for uint256;

    string public _baseURI =  "https://dapp.foundationfor.art/bent/metadata/"; 
    string public _contractURI = "https://dapp.foundationfor.art/contract_uri.json";

    mapping(uint256 => uint256) public pricePerToken;
    mapping(uint256 => uint256) public maxSupplies;
    mapping(uint256 => bool) public claimable; // for physical claimable NFTs

    //address -> tokenID -> numberOfClaims
    mapping(address => mapping(uint256 => uint256)) public numberClaims;

    bool public operatorFilteringEnabled = true;

    event Claimed(address from, uint256 tokenID);

    constructor() ERC1155(_baseURI) {
        pricePerToken[1] = 0.05 ether;
        pricePerToken[2] = 0.3 ether;
        claimable[1] = false;
        maxSupplies[1] = 99999999;
        maxSupplies[2] = 100;
        claimable[2] = true;
        _registerForOperatorFiltering();        
        _setDefaultRoyalty(0xbeDF910B5cc587eE6633855080CAd1Ed08B8bF8e, 1000);
    }

    /**
	 @dev buying of a token
	  */
    /**	 
	 * @param tokenID - the token ID you want to buy
	 @param qty - how many of them
	  */
    function buyToken(uint256 tokenID, uint256 qty) external payable {
        require(pricePerToken[tokenID] != 0, "price not set");
        require(
            qty * pricePerToken[tokenID] == msg.value,
            "exact amount needed"
        );
        require(qty < 10, "max 10 at once");
        require(totalSupply(tokenID) < maxSupplies[tokenID], "over max supply");

        if (claimable[tokenID]) {
            numberClaims[msg.sender][tokenID] =
                numberClaims[msg.sender][tokenID] +
                qty;
        }

        _mint(msg.sender, tokenID, qty, "");
    }

    /**
     * Physical Claim an NFT (ONLY if it's claimable)
     * @param tokenID - the nft ID
     */
    function claim(uint256 tokenID) external {
        require(balanceOf(msg.sender, tokenID) > 0, "you must own this NFT");
        require(numberClaims[msg.sender][tokenID] > 0, "no claims available");

        numberClaims[msg.sender][tokenID] =
            numberClaims[msg.sender][tokenID] -
            1;

        emit Claimed(msg.sender, tokenID);
    }

    /*///////////////////////////////////////////////////////////////
                    CONTRACT MANAGEMENT OPERATIONS
    //////////////////////////////////////////////////////////////*/
    function setBaseURI(string memory newuri) public onlyOwner {
        _baseURI = newuri;
    }

    function setContractURI(string memory newuri) public onlyOwner {
        _contractURI = newuri;
    }

    /**
	 @dev admin can set the price & max supply per token
	  */
    /**	 
	 @param tokenID - the tokenPriceAndMaxSupply ID
	 @param price - the price per one
	 @param maxSupply - max mint
     @param isClaimable - if it's claimable
	  */
    function setTokenDetails(
        uint256 tokenID,
        uint256 price,
        uint256 maxSupply,
        bool isClaimable
    ) external onlyOwner {
        pricePerToken[tokenID] = price;
        maxSupplies[tokenID] = maxSupply;
        claimable[tokenID] = isClaimable;
    }

    //sets the royalty fee and recipient for the collection.
    function setRoyalty(address receiver, uint96 feeBasisPoints)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    // withdraw the earnings to pay for the artists & devs :)
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * admin can overwrite a claim
     * @param tokenID - the nft ID
     */
    function adminSetClaim(
        address to,
        uint256 tokenID,
        uint256 numberOfClaims
    ) external onlyOwner {
        numberClaims[to][tokenID] = numberOfClaims;
    }

    function reclaimERC20(IERC20 erc20Token) public onlyOwner {
        erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
    }

    function reclaimERC721(IERC721 erc721Token, uint256 id) public onlyOwner {
        erc721Token.safeTransferFrom(address(this), msg.sender, id);
    }

    function reclaimERC1155(
        IERC1155 erc1155Token,
        uint256 id,
        uint256 amount
    ) public onlyOwner {
        erc1155Token.safeTransferFrom(
            address(this),
            msg.sender,
            id,
            amount,
            ""
        );
    }

    /*///////////////////////////////////////////////////////////////
                             OTHER THINGS
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseURI, tokenId.toString(), ".json"));
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return
            ERC1155.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function version2a() internal {}
}