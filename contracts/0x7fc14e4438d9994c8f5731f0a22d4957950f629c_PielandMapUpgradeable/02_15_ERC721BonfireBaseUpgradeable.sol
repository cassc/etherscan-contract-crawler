// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ERC721 gives us all the basics, including balance tracking, tokenURI() (though you need to override _baseURI() or else it always return "")
// ERC721Enumerable give us totalSupply(), balanceOf() and automatic tracking of ownership, which getTokensOfOwner() takes advantage of.
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

/*
  ________________ _____ ___ __
   ___            ____        
  / _ )___  ___  / _(_)______ 
 / _  / _ \/ _ \/ _/ / __/ -_)
/____/\___/_//_/_//_/_/  \__/ 

     [email protected]
________________ _____ ___ __
*/

// Base class for Bonfire-powered NFT smart contacts
//   * inherit directly from this contract if you're doing a standard drop without an on-chain whitelisted pre-sale
//   * uses require()/revert() and the 0xfd opcode to refund as much as possible the unused gas on failed transactions.
//   * disallows contract-to-contract scripted minting
//   * two ways for a token to be minted
//     * user calls mint() and sends eth in msg and pays gas
//     * contract owner (admin) calls mintAndSend() and admin pays gas
//   * can set MAX_* to 0 to make infinite
contract ERC721BonfireBaseUpgradeable is ERC721EnumerableUpgradeable, OwnableUpgradeable {
    using StringsUpgradeable for uint256;

    // type of contract
    string public contractType;

    // constructor params (you will override these defaults in your subclass's constructor)
    string internal baseURI;
    uint256 public MAX_TOTAL_SUPPLY;
    uint256 public MAX_PER_TX;
    uint256 public MAX_TOTAL_PER_WALLET;
    uint256 public MINT_PRICE;

    // drop status
    bool public mainSaleOngoing;

    // mappings
    mapping(address => uint256) public mainSaleMintedAmounts;

    // transparency to help users see mint events in real-time
    event Mint(address indexed to, uint256 numberOfTokens, uint256 value, uint256 totalSupply);
    bool internal constant EMIT_EVENTS = true;

    function init(string memory name, string memory symbol, string memory bURI, uint256 maxTotalSupply, uint256 maxPerTx, uint256 maxPerWallet, uint256 mintPrice ) initializer public {
        __ERC721_init(name, symbol);
        __ERC721Enumerable_init();
        __Ownable_init();
        contractType = 'Base';
        mainSaleOngoing = false;
        baseURI = bURI;
        MAX_TOTAL_SUPPLY = maxTotalSupply;
        MAX_PER_TX = maxPerTx;
        MAX_TOTAL_PER_WALLET = maxPerWallet;
        MINT_PRICE = mintPrice;
    }
    
    /** MODIFIERS */

    modifier whenMainSaleOngoing() {
        require(mainSaleOngoing, "Main sale is not active");
        _;
    }

    /** PUBLIC */

    function mint(uint256 numberOfTokens) public payable virtual whenMainSaleOngoing {
        require(MAX_PER_TX == 0 || numberOfTokens > 0 && numberOfTokens < (MAX_PER_TX + 1), "Cannot mint that many at once");
        require(MAX_TOTAL_SUPPLY == 0 || totalSupply() + numberOfTokens < (MAX_TOTAL_SUPPLY + 1), "Purchase would exceed max supply");
        require(MAX_TOTAL_PER_WALLET == 0 || mainSaleMintedAmounts[msg.sender] + numberOfTokens < (MAX_TOTAL_PER_WALLET + 1), "Exceeds max per wallet");
        require(MINT_PRICE * numberOfTokens <= msg.value, "Insufficient ether sent");
        require(tx.origin == msg.sender, "You cannot mint from another contract.");     // tx.origin is original external account that started the tx, and msg. sender refers to the immediate account which can be a contract or external account

        // do the mint
        _mint(msg.sender, numberOfTokens, msg.value);

        // increment mainSaleMintedAmounts for this user
        mainSaleMintedAmounts[msg.sender] = mainSaleMintedAmounts[msg.sender] + numberOfTokens;
    }

    // copied from ERC721Burnable.sol
    // function burn(uint256 tokenId) public virtual {
    //     //solhint-disable-next-line max-line-length
    //     require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
    //     _burn(tokenId);
    // }

    /** INTERNAL */

    function _mint(address to, uint256 numberOfTokens, uint256 value) internal virtual {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            if (totalSupply() < MAX_TOTAL_SUPPLY || MAX_TOTAL_SUPPLY == 0) {
                _safeMint(to, totalSupply());         // start tokenIds at index 0
            }
        }

        // Emit
        if (EMIT_EVENTS && value > 0) emit Mint(to, numberOfTokens, value, totalSupply());
    }

    /** GETTERS **/

    // we override ERC721's default or else baseURI would be ignored
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function getTokensOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    /** ADMIN MINTING */

    function mintAndSend(address _to, uint256 numberOfTokens) external onlyOwner {
        require(MAX_TOTAL_SUPPLY == 0 || totalSupply() + numberOfTokens < (MAX_TOTAL_SUPPLY + 1), "Exceeds max supply");
        _mint(_to, numberOfTokens, 0);
    }

    /** ADMIN **/

    function setBaseURI(string memory _u) external onlyOwner {
        baseURI = _u;
    }
    function flipMainSaleState() external onlyOwner {
        mainSaleOngoing = !mainSaleOngoing;
    }
    function setMaxSupply(uint256 _s) external onlyOwner {
        MAX_TOTAL_SUPPLY = _s;
    }
    // common to call to change per tx limitation when going from pre-sale to main sale
    function setMaxPerTx(uint256 _p) external onlyOwner {
        MAX_PER_TX = _p;
    }
    // common to call to change per wallet limitation when going from pre-sale to main sale
    function setMaxPerWallet(uint256 _p) external onlyOwner {
        MAX_TOTAL_PER_WALLET = _p;
    }
    function setMintPrice(uint256 _p) external onlyOwner {
        MINT_PRICE = _p;
    }
    function withdraw() public onlyOwner {
      payable(msg.sender).transfer(address(this).balance);
    }

}