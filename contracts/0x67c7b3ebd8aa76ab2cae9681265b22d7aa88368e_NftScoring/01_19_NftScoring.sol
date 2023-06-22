// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./TokenPaymentSplitter.sol";



contract NftScoring is ERC721, ERC721Enumerable, ERC721Burnable, Pausable, Ownable, ReentrancyGuard, TokenPaymentSplitter {
    using Counters for Counters.Counter;

    event Listing(uint256 projectIdentifier);
    event Advertisement(uint256 projectIdentifier, uint256 time, uint256 slot);

    Counters.Counter private _premiumTokenIdCounter;
    Counters.Counter private _investTokenIdCounter;
    Counters.Counter private _nonce;

    uint256 public maxSupply = 1000;
    uint256 public maxInvestSupply = 100;
    
    // 0.2 ETH
    uint256 public price = 200000000000000000;

    bool public saleOpen = false;
    
    string public investBaseURI; // = "https://gateway.pinata.cloud/ipfs/QmcQ8htaR9rfC9pVj5EiPH33F55UcgmB4AK19DxHmgUTsj/";
    string public premiumBaseURI; // = "https://gateway.pinata.cloud/ipfs/QmQNN86a6FGTGvR6EbQwbFx5CavpRmMyZafDZfpgV3nTp4/";
    string private _contractUri; // = "https://gateway.pinata.cloud/ipfs/QmdRcny7zU6K3uNw5snuGbVKUePgQqRRVwCQMLGcj8vF3n";
    
    mapping (address => uint256) public Whitelist;

    receive() external payable {}

    // The payments are split between main wallet and the investers share in ratio 570:100 ~ 15% to investors.
    constructor() ERC721('NFT Scoring', 'SCO') TokenPaymentSplitter(570, 100) {
        for (uint256 i=0; i < 20; i++) _mintInvestment(msg.sender);
    }

    function whitelistAddresses(address[] calldata addresses, uint256 amount) external onlyOwner {
        for (uint256 i=0; i < addresses.length; i++) Whitelist[addresses[i]] = amount;
    }

    function pause() public onlyOwner {
        _pause();
    }
    
    function unpause() public onlyOwner {
        _unpause();
    }

    function toggleSale() public onlyOwner {
        saleOpen = !saleOpen;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function getInvestorsCount() public view returns (uint256) {
        return _investTokenIdCounter.current();
    }

    function mint(uint256 amount) external payable nonReentrant {
        require(saleOpen, 'sale was not yet open');
        require(!Address.isContract(msg.sender), 'can not mint from a contract');
        require(amount <= 10, 'at most 10 per transaction allowed');

        if (msg.value > 0){
            require(msg.value >= price * amount, 'not enough was paid');
        }
        else {
            uint256 whitelistAmount = Whitelist[msg.sender];
            require(amount <= whitelistAmount, 'requesting more tokens than whitelisted for this address');
            Whitelist[msg.sender] = whitelistAmount - amount;
        }
        
        for (uint256 i = 0; i < amount; i++) internalMint(msg.sender);
    }

    function internalMint(address to) internal {
        if (_investTokenIdCounter.current() < maxInvestSupply){

          uint256 rand = getRandom();
          bool winner = isWinner(rand);
          if (winner){
            _mintInvestment(to);
          }
          else{
            _mintPremium(to);
          }
        }
        else{
            _mintPremium(to);
        }
    }

    function getRandom() private returns(uint256)
    {
        uint256 seed = uint256(keccak256(abi.encodePacked( block.timestamp + block.difficulty + ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) + block.gaslimit +  ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) + block.number)));

        seed = uint256(keccak256(abi.encodePacked(seed + _nonce.current())));
        _nonce.increment();

        return (seed % maxSupply);
    }

    function isWinner(uint256 rand) private view returns(bool){
          return rand < ((maxInvestSupply - _investTokenIdCounter.current()) * maxSupply / (maxSupply - totalSupply())) ;
    }

    function _mintPremium(address to) internal {
        require(totalSupply() < maxSupply, 'supply depleted');

        _safeMint(to, maxInvestSupply + _premiumTokenIdCounter.current());
        _premiumTokenIdCounter.increment();
    }

    function _mintInvestment(address to) internal {
        require(totalSupply() < maxSupply, 'supply depleted');
        require(_investTokenIdCounter.current() < maxInvestSupply, 'supply of investments depleted');

        _safeMint(to, _investTokenIdCounter.current());
        _investTokenIdCounter.increment();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // ---------------------------------------------------------
    // -----             URI                              ------
    // ---------------------------------------------------------

    function _baseURI() internal view override returns (string memory) {
        return premiumBaseURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function setContractURI(string calldata newBaseURI) external onlyOwner {
        _contractUri = newBaseURI;
    }
    
    function setInvestBaseURI(string calldata newBaseURI) external onlyOwner {
        investBaseURI = newBaseURI;
    }

    function setPremiumBaseURI(string calldata newBaseURI) external onlyOwner {
        premiumBaseURI = newBaseURI;
    }

    // ---------------------------------------------------------
    // -----             LISTING                          ------
    // ---------------------------------------------------------

    mapping(uint256 => bool) public listing;

    // 0.05 ETH - can change
    uint256 public listingPrice = 50000000000000000;

    function buyListing(uint256 projectIdentifier) external payable {
        require(msg.value >= listingPrice, 'not enough was paid');

        listing[projectIdentifier] = true;
        emit Listing(projectIdentifier);
    }

    function setListingPrice(uint256 newPrice) external onlyOwner {
        listingPrice = newPrice;
    }

    // ---------------------------------------------------------
    // -----             ADVERTISEMENT                    ------
    // ---------------------------------------------------------

    mapping(uint256 => mapping(uint256 => uint256)) public advertising;
    mapping(uint256 => uint256) public advertisingPrice;
    uint256 public numAdSlots = 0;
    
    function buyAdvertisement(uint256 time_identifier, uint256 slot, uint256 project_identifier, uint256 duration) external payable {
        require(msg.value >= advertisingPrice[slot] * duration, 'not enough was paid');
        require(slot < numAdSlots, 'specified slot is not defined');

        for (uint256 i = 0; i < duration; i++) {
            require(advertising[time_identifier + i][slot] == 0, 'time slot is alredy occupied');

            advertising[time_identifier + i][slot] = project_identifier;

            emit Advertisement(project_identifier, time_identifier + i, slot);
        }
    }

    function setAdvertisingPrice(uint256[] calldata newPrice) external onlyOwner {
        numAdSlots = newPrice.length;
        for (uint256 i = 0; i < newPrice.length; i++) {
            advertisingPrice[i] = newPrice[i];
        }
    }

    function advertisementOn(uint256 time_identifier, uint256 slot) public view returns (uint256) {
        return advertising[time_identifier][slot];
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = (tokenId < maxInvestSupply) ? investBaseURI : premiumBaseURI;
        
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId))) : "";
    }


    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function ownerOf(uint256 tokenId) public view override(ERC721, TokenPaymentSplitter) returns (address) {
        return super.ownerOf(tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view override(ERC721, TokenPaymentSplitter) returns (bool){
        return super._isApprovedOrOwner(spender, tokenId);
    }

    function owner() public view override(Ownable, TokenPaymentSplitter) returns (address) {
        return super.owner();
    }
}