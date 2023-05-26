// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       /@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@                 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       @@@@@            (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@                       @@@@@@@@@@         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@                          @@@@@@@@@               @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@               @@@@@@@@@@@@@@@@@@@@@@    @@    @@     @@@@@@@@@   @@@@@@@@@    @@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@     @@@@      @@@@@@@@@@@@@@  @@@@@    ,@%    @       @@@@@/    @@@@@@@@@@      @@@@@@@@,      @@@@@@@@@@@     #@@@@@@@@@@@@@@@@@@@@@@@//           @@@@@@@@@
@@@@@@@@@@@@      @@      @@@@    @@@@@     @@@   @@@     @@@@     @@@@@@@@@@@@@*     @@@@@@       @@@@@@@@.      @@@@@@   #@@@@@@@@@                  @@@@@@@@@@
@@@@@@@@@@@@@             @@@     @@@@@@     @           @@@@     @@@@@      @@@@@    %@@@@@       @@@@@@@      @@@@&         @@@@@@           @@@@@@@@@@@@@@@@@@
@@@@@@@@@@@            @@@@@@     #@@@@@@@             @@@@@,     @@@@        @@@@     @@@@@      @@@@@@@      @@@            @@@@@@@@@                @@@@@@@@@@
@@@@@@@@*           @@@@@@@@@      @@@@@@@@@@&     @@@@@@@@@      @@@    @    @@@@#    @@@@@      @@@@@@.     @@       &,     @@@@@@@..   [email protected]@@           @@@@@@@
@@@@@@@@@@@@@@@      @@@@@@@@/     *@@@@@@@@@@@@@@@@@@@@@@@@      @@@         @@@@     @@@@.      @@@@@@@             @       @@@@                 @@      @@@@@@
@@@@@@@@@@@@@@@@      @@@@@@@@      /@@     @@@@@@@@@@@@@@@@      @@@@       @@@@      @@@@@      @@@@@@@                    @@@@         (@@@@/ @@(       @@@@@@
@@@@@@@@@@@@@@@@@      @@@@@@@%            @@@@@@@@@@@@@@@@@@      @@@       @@@      @@@@@@      @@@@@@@@,                @@@@@@@                        @@@@@@@
@@@@@@@@@@@@@@@@@@@     @@@@@@@         @@@@@@@@@@@@@@@@@@@@@@                       @@@@@@@     @@@@@@@@@@@         [email protected]@@@@@@@@@@@@@@                  @@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       @@         @@@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/
contract Flowtys is ERC721, ERC721Enumerable, Ownable {
    using Math for uint256;
    using Strings for string;
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    enum Age { Fresh, Scratched, Dusty, Vintage }
    uint256 public constant MAX_FLOWTYS = 10000;
    // threshold in number of blocks between age steps
    // corresponds to rougly 3 months, assuing 15s between blocks
    uint256 public constant ageBlocksThreshold = 518400;
    uint256 public maxFlowtysPurchase = 16;
    uint256 public flowtyPrice = 0.08 ether;
    bool public saleIsActive = false;
    string public _baseFlowtyURI;
    string public provenance;

    mapping(uint256 => uint256) private _ages;

    event FLowtyMinted(uint256 tokenId);

    constructor(string memory baseURI) ERC721("Flowtys", "FLOWTY") {
        _baseFlowtyURI = baseURI;
    }

    /**
     * Set some Flowtys aside
     */
    function reserveFlowtys(uint256 reservedAmount) public onlyOwner {        
        for (uint256 i = 1; i <= reservedAmount; i++) {
            createCollectible(msg.sender);
        }
    }

    /*
    * Withdraw funds to pay the team, dev, artists
    */
    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");

        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }

    function withdrawForGiveaway(uint256 amount, address payable to) public onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");

        Address.sendValue(to, amount);
    }

    //---------------------------------------------------------------------------------
    /*
    * < ageBlocksThreshold => Age.Fresh
    * > 1x ageBlocksThreshold => Age.Scratched
    * > 2x ageBlocksThreshold => Age.Dusty
    * > 3x ageBlocksThreshold => Age.Vintage
    */
    function getAge(uint256 tokenId) public view returns (Age) {
        require(_exists(tokenId), "getAge query for nonexistent token");
        uint256 currentAge = uint((block.number - _ages[tokenId]) / ageBlocksThreshold);
        return Age(currentAge.min(3));
    }

    function getAgeStaringBlock(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "getAge query for nonexistent token");
        return _ages[tokenId];
    }

    //---------------------------------------------------------------------------------

    function setBaseURI(string memory newuri) public onlyOwner {
        _baseFlowtyURI = newuri;
    }

    function setMaxFlowtysPurchase(uint256 newMax) public onlyOwner {
        maxFlowtysPurchase = newMax;
    }

    function setMintCost(uint256 newCost) public onlyOwner {
        require(newCost > 0, "flowtyPrice must be greater than zero");
        flowtyPrice = newCost;
    }

    /*
    * Pause sale if active, make active if paused
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
    * Mints Flowtys
    */
    function mintFlowty(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Flowty");
        require(numberOfTokens <= maxFlowtysPurchase, "# of new NFTs is limited per single transaction");
        require((totalSupply() + numberOfTokens) <= MAX_FLOWTYS, "Purchase would exceed max supply of Flowtys");
        require((flowtyPrice * numberOfTokens) <= msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            if (totalSupply() < MAX_FLOWTYS) {
                createCollectible(msg.sender);
            }
        }
    }

    /*     
    * Set provenance once it's calculated.
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        provenance = provenanceHash;
    }

    /// Internal
    function createCollectible(address mintAddress) private {
      uint256 mintIndex = _tokenIdCounter.current();
      if (mintIndex < MAX_FLOWTYS) {
          _safeMint(mintAddress, mintIndex);
          _tokenIdCounter.increment();
          _ages[mintIndex] = block.number;
          // fire event in logs
          emit FLowtyMinted(mintIndex);
      }
    }

    /*
    * The aging calculation is simple, we save the initial block number once Flowty is minted
    * if at the transaction time on a given Flowty block number suppressed ageBlocksThreshold
    * we threat it as aged level crossed and only revert to this level
    * In case if it's still level 0 we just store current block number as a new base
    */
    function updateAge(uint256 tokenId) private {
        uint256 currentAge = uint((block.number - 1 - _ages[tokenId]) / ageBlocksThreshold);
        uint256 currentBlockAge = block.number - _ages[tokenId];
        if (currentBlockAge < ageBlocksThreshold) {
            _ages[tokenId] = block.number;
        } else if (currentBlockAge < ageBlocksThreshold * 3) {
            _ages[tokenId] = _ages[tokenId] + (block.number - (_ages[tokenId] + ageBlocksThreshold * currentAge));
        }
    }

    /// ERC721 related
    /**
     * @dev See {ERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        super.transferFrom(from, to, tokenId);
        updateAge(tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        super.safeTransferFrom(from, to, tokenId, _data);
        updateAge(tokenId);
    }

    /**
     * @dev See {ERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string memory baseURI = super.tokenURI(tokenId);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(abi.encodePacked(baseURI, "/"), uint256(getAge(tokenId)).toString())) : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseFlowtyURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}