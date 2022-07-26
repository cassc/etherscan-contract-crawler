// SPDX-License-Identifier: MIT
// ERC721AirdropTarget Contracts v4.0.0
// Creator: Chance Santana-Wees

pragma solidity ^0.8.11;

import './ERC721A.sol';
import './ERC721AirdropTarget.sol';
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract Luftballons is ERC721AirdropTarget, ERC2981, ERC721A {
    IERC721 constant gmDAO = IERC721(0x36F4D96Fe0D4Eb33cdC2dC6C0bCA15b9Cdd0d648);
    mapping(uint256 => bool) private gmTokenMinted;
    uint256 private reservedMinted = 0;

    string private baseURI = "https://luftballons.mypinata.cloud/ipfs/QmXXo2pCyi5GF2fFrbZVUzRHRmDkhR4WQKFwALEmiFrYqB/";
    string private _contractURI = "https://luftballons.mypinata.cloud/ipfs/QmdQ71dZRdSdfiwx5tbuH2HKJBd7PEyfkSqzxWRr4fFUNg";

    ERC20Spendable public LuftToken;
    mapping(address => uint256) public customLuftPricePerNFT;
    mapping(uint256 => uint256) public claimedLuft;

    uint256 startBlock;
    uint256 spentLuft;

    event LuftClaimed(uint256[] tokenIDs, address claimant, uint256 quantityHarvested);
    event LuftSpent(address collection, address spender, uint256 nftID, uint256 luft, uint256 nftQuantity);

    constructor()
        ERC721AirdropTarget()
        ERC721A("9999 Luftballons", "LUFTBALLONS")
    {
        _setDefaultRoyalty(owner(), 1000);
        _safeMint(owner(), 25);
        startBlock = block.number;
        LuftToken = new ERC20Spendable("Luft", "LUFT");
    }

    function _claimableLuft() internal view returns (uint256) {
        return (block.number - startBlock) * TokensPerblock;
    }

    function setCustomNFTPrice(address collection, uint256 tokenPrice) external {
        require(Ownable(collection).owner() == _msgSender(), "Not Detectable as Collection Owner");
        customLuftPricePerNFT[collection] = tokenPrice;
    }

    function _beforeHarvestERC721(address collection, uint256 tokenID) internal override {
        uint256 luftSpent = LuftPerNFT(collection);
        LuftToken.spend(_msgSender(), luftSpent);
        emit LuftSpent(collection, _msgSender(), tokenID, luftSpent, 1);
    }

    function _beforeHarvestERC1155(address collection, uint256 tokenID, uint256 quantity) internal override { 
        uint256 luftSpent = LuftPerNFT(collection) * quantity;
        LuftToken.spend(_msgSender(), luftSpent);
        emit LuftSpent(collection, _msgSender(), tokenID, luftSpent, 1);
    }

    function LuftPerNFT(address collection) public view returns (uint256) {
        if(customLuftPricePerNFT[collection] > 0) 
            return customLuftPricePerNFT[collection];

        uint benchmarkBlock = (100*(block.number/100));
        if(benchmarkBlock < startBlock) 
            benchmarkBlock = startBlock;

        uint benchmarkTotal = (benchmarkBlock - startBlock) * TokensPerblock;
        uint availableTokens = benchmarkTotal - spentLuft;

        if(availableTokens < 1000 ether)
            return 1 ether;
        else if(availableTokens > 100_000 ether)
            return 100 ether;
        else
            return availableTokens / 1000;
    }

    function claimableLuft(uint256[] memory tokenIDs) public view returns (uint256) {
        uint256 claimable = _claimableLuft();
        uint256 claimed = 0;
        for(uint i = 0; i < tokenIDs.length; i++) {
            claimed += claimable - claimedLuft[tokenIDs[i]];
        }
        return claimed;
    }

    function claimLuft(uint256[] memory tokenIDs) public {
        uint256 claimable = _claimableLuft();
        uint256 claimed = 0;
        for(uint i = 0; i < tokenIDs.length; i++) {
            require(ownerOf(tokenIDs[i]) == _msgSender(), "Not owner of TokenID");
            claimed += claimable - claimedLuft[tokenIDs[i]];
            claimedLuft[tokenIDs[i]] = claimable;
        }
        emit LuftClaimed(tokenIDs, _msgSender(), claimed);
        LuftToken.mint(_msgSender(), claimed);
    }

    function mint(address to, uint256 quantity) external {
        require(_numberMinted(_msgSenderERC721A()) + quantity < 3, "Don't be greedy.");
        require(totalSupply() + quantity < 9000, "Exceeds Unreserved Supply");
        require(totalSupply() + quantity < 10000, "Exceeds Max Supply");
        _safeMint(to,quantity);
    }
    
    function mint3_gmdao(uint256 gm_tokenID) external {
        require(!gmTokenMinted[gm_tokenID], "Allocation Minted");
        require(reservedMinted < 999, "No more reserved");
        require(totalSupply() + 3 < 10000, "Exceeds Max Supply");
        address to = gmDAO.ownerOf(gm_tokenID);
        gmTokenMinted[gm_tokenID] = true;
        reservedMinted += 3;
        _safeMint(to,3);
    }

    function setContractURI(string memory uri) external onlyOwner {
        _contractURI = uri;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setDefaultRoyalty(uint96 basisPoints) external onlyOwner {
        _setDefaultRoyalty(owner(), basisPoints);
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override(ERC721A, ERC721AirdropTarget) returns (address) {
        return super.ownerOf(tokenId);
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see `_totalMinted`.
     */
    function maxSupply() public pure override(ERC721AirdropTarget) returns (uint256) {
        return 9999;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721AirdropTarget, ERC2981, ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId); 
    }
}