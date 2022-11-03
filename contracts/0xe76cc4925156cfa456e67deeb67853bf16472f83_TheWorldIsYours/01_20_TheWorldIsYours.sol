// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/*
             @@@@@   @@   @@@@@                             
            @@    /  @@  @    @@                            
            @@  @@/  @@  @@@  @@                            
           &@@  @@/  @@  @@@  @@/                           
       @@@@@    @@/  @@  @@@    @@@@@                       
    @@@@    @@@@@    @@    @@@@@    @@@,                    
    @@@  @@@@        @@        @@@/  @@,                    
    @@@  @@@  @@            @@  @@/  @@,                    
     @@   @@  @@@          @@@  @@   @@                     
     @@@  @@@  @@@#      /@@@  @@%  @@@                     
      @@@   @@@   @@@@@@@@   @@@   @@@                      
       %@@@   @@@@,      /@@@@   @@@                        
         @@@@     @@@@@@@@    (@@@/                         
            @@@@@@%      &@@@@@/                            
                  #@@@@@@#                                                                                                            
*/

import "@divergencetech/ethier/contracts/erc721/BaseTokenURI.sol";
import "@divergencetech/ethier/contracts/erc721/ERC721ACommon.sol";
import "@divergencetech/ethier/contracts/sales/LinearDutchAuction.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*
 * @title TheWorldIsYours
 * @notice ERC-721 Smart Contract for Mistah Isaac's new single called "The World Is Yours" 
 * @author wakokungo.com
 */
contract TheWorldIsYours is ERC721ACommon, LinearDutchAuction, BaseTokenURI {
    using Strings for uint256;

    string _contractURI;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        string memory contractURI_,
        address payable beneficiary,
        uint96 royaltyBasisPoints
    )
        ERC721ACommon(name, symbol, beneficiary, royaltyBasisPoints)
        BaseTokenURI(baseTokenURI)
        LinearDutchAuction(
            LinearDutchAuction.DutchAuctionConfig({
                startPoint: 1667379600, // 2022-10-02 9 PM UTC
                startPrice: 2 ether,
                unit: AuctionIntervalUnit.Time,
                decreaseInterval: 600, // 10 mins
                decreaseSize: 0.1 ether,
                numDecreases: 18
            }),
            0.2 ether,
            Seller.SellerConfig({
                totalInventory: 36,
                lockTotalInventory: true,
                maxPerAddress: 3,
                maxPerTx: 0,
                freeQuota: 0,
                lockFreeQuota: true,
                reserveFreeQuota: true
            }),
            beneficiary
        )
    {
        setContractURI(contractURI_);
    }

    function mint(address to, uint256 quantity) external payable {
        Seller._purchase(to, quantity);
    }

    function _startTokenId() internal pure override(ERC721A) returns (uint256) {
        return 1;
    }

    function _handlePurchase(
        address to,
        uint256 quantity,
        bool
    ) internal override {
        _safeMint(to, quantity);
    }

    function setContractURI(string memory contractURI_) public onlyOwner {
        _contractURI = contractURI_;
    }

    function _baseURI()
        internal
        view
        override(BaseTokenURI, ERC721A)
        returns (string memory)
    {
        return BaseTokenURI._baseURI();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId)))
                : "";
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
}