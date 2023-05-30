// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FuckLootV2 is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {

    event GetFucked (address indexed buyer, uint256 startWith, uint256 batch);

    address payable public mainWallet;
    address payable public faucetWallet;

    uint256 public totalMinted;
    uint256 public burnCount;
    uint256 public totalCount = 10000;
    uint256 public maxBatch = 50;
    uint256 public price = 1 * 10 ** 18;
    uint256 public initialReserve = 21;
    uint256 private nftsReserved;
    string public baseURI;
    bool private started;

    string name_ = 'FUCKLOOT';
    string symbol_ = 'FLOOT';
    string baseURI_ = 'ipfs://QmQfwVxi1rFSxrXNW7VGVFJ1AXDmb6TRmgbdvu7De3G7AU/';

    constructor() ERC721(name_, symbol_) {
        baseURI = baseURI_;
        mainWallet = payable(msg.sender);
        faucetWallet = payable(msg.sender);
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function changePrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }

    function setStart(bool _start) public onlyOwner {
        started = _start;
    }

    function distributeFunds() public payable onlyOwner{
        uint256 contract_balance = address(this).balance;
        require(payable(mainWallet).send( (contract_balance * 500) / 1000));
        (bool sent, ) = payable(faucetWallet).call{value: ((contract_balance * 500) / 1000)}("");
        require(sent);
    }

    function mintReservedNFTs(address[] memory to) public onlyOwner { //Check this to make sure its how we want to reserve some of the initial supply
        require(nftsReserved <= initialReserve, "Exceeds reserve supply");
        require(to.length == initialReserve);
        for (uint256 i = 0; i < initialReserve; i++) {
            nftsReserved++;
            totalMinted++;
            _safeMint(to[i], totalMinted);
        }  
    }

    function changeMainWallet(address payable _newWallet) external onlyOwner { 
        mainWallet = _newWallet;
    }

    function changeFaucetWallet(address payable _newWallet) external onlyOwner { 
        faucetWallet = _newWallet;

    }

    function distroDust() public onlyOwner {
        uint256 contract_balance = address(this).balance;
        require(payable(mainWallet).send(contract_balance));
    }

    function getFucked(uint256 _batchCount) payable public {
        require(started, "Sale has not started");
        require(_batchCount > 0 && _batchCount <= maxBatch, "Batch purchase limit exceeded");
        require(totalMinted + _batchCount + burnCount <= totalCount, "Not enough inventory");
        require(msg.value == _batchCount * price, "Invalid value sent");
 
        emit GetFucked(_msgSender(), totalMinted, _batchCount);
        for(uint256 i=0; i < _batchCount; i++){
            totalMinted++;
            _safeMint(_msgSender(), totalMinted);
        }
        
        uint256 contract_balance = address(this).balance;
        require(payable(mainWallet).send( (contract_balance * 500) / 1000));
        (bool sent, ) = payable(faucetWallet).call{value: ((contract_balance * 500) / 1000)}("");
        require(sent);
    }

    function walletInventory(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0xa5409ec958C83C3f309868babACA7c86DCB077c1  )) {     // OpenSea approval
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function burn(uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
        burnCount++;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}