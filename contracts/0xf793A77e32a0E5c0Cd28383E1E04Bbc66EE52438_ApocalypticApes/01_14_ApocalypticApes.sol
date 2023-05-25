// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ApocalypticApes is ERC721, ERC721Enumerable, Ownable {
    using MerkleProof for bytes32[];
    
    struct SaleDetails {
        bytes1 phase;
        uint8 maxBatch;
        uint8 maxBuy;
        uint8 freeMints;
        uint16 totalCount;
        uint256 totalMinted;
    }
    
    address payable public treasury;

    uint256 public price = 0.07 * 10**18; // 0.07 eth; use "7 * 10**16" in JS
    bytes32 public rootHash;
    string public baseURI;
    
    string name_ = 'Apocalyptic Apes';
    string symbol_ = 'AAPES';
    string baseURI_ = 'ipfs://QmYMscQ1gu5eCaXpjs3XA6154LwhfZxxb9LjQDC9UL155d/';

    SaleDetails public saleDetails = SaleDetails({
        phase: 0,    // 0x00 = not started, 0x01 = whitelist sale, 0x02 = public sale
        maxBatch: 10,
        maxBuy: 25,
        freeMints: 100,
        totalCount: 8_888,
        totalMinted: 0
    });
    

    mapping(uint16 => address) public ownerByToken;
    mapping(address => uint8) public walletBuys;
    mapping(address => bytes1) public manualWhitelist;
    //  0x00 = none, 0x01 = whitelisted, 
    //  0x02 or higher up to max buy = free mints
    //          (turns to whitelist after they mint the free ones)

    event MintApe (address indexed buyer, uint256 startWith, uint256 batch);

    constructor() ERC721(name_, symbol_) {
        baseURI = baseURI_;
        treasury = payable(msg.sender);
      
    }

    function totalSupply() public view virtual override returns (uint256) {
        return saleDetails.totalMinted;
    }

    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function changePrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }    

    function setPhase(bytes1 _phase) public onlyOwner {
        saleDetails.phase = _phase;
    }

    function whitelist(address _user, bytes1 _status) public onlyOwner {
        manualWhitelist[_user] = _status;
    }

    function whitelist(address[] memory _user, bytes1 _status) public onlyOwner {
        for (uint256 i = 0; i < _user.length; i++) {
            manualWhitelist[_user[i]] = _status;
        }
    }

    function mintApe(uint8 _batchCount, uint8 authAmnt, bytes32[] memory proof, bytes32 leaf) payable public {
        require(saleDetails.phase != 0, "Sale has not started");
        require(_batchCount > 0 && _batchCount <= saleDetails.maxBatch, "Batch purchase limit exceeded");
        require(saleDetails.totalMinted + _batchCount <= saleDetails.totalCount - saleDetails.freeMints, "Not enough inventory");
        require(msg.value == _batchCount * price, "Invalid value sent");
        require(walletBuys[msg.sender] + _batchCount <= saleDetails.maxBuy, "Buy limit reached");

        // TODO: Untested verification; need to generate merkle tree with whitelist data
        if (saleDetails.phase != 0x02 && !verify(proof, leaf, msg.sender, authAmnt))
            require(manualWhitelist[msg.sender] > 0,"Not whitelisted!");
 
        emit MintApe(_msgSender(), saleDetails.totalMinted+1, _batchCount);
        for(uint8 i=0; i< _batchCount; i++){
            _mint(_msgSender(), 1 + saleDetails.totalMinted++);
        }
        walletBuys[msg.sender] += _batchCount;
    }
    
    function mintApe() public {
        require(saleDetails.phase != 0, "Sale has not started");
        require(saleDetails.totalMinted + 1 <= saleDetails.totalCount, "Not enough inventory");
        require(manualWhitelist[msg.sender] >= 0x02,"No free mints!");
 
        walletBuys[msg.sender] += 1;
        manualWhitelist[msg.sender] = bytes1(uint8(manualWhitelist[msg.sender]) - 1);
        
        emit MintApe(_msgSender(), saleDetails.totalMinted+1, 1);
        _mint(_msgSender(), 1 + (saleDetails.totalCount - saleDetails.freeMints));

        saleDetails.totalMinted++;
        saleDetails.freeMints--;
    }

    function verify(
        bytes32[] memory proof,
        bytes32 leaf,
        address user,
        uint8 authAmnt
    ) public view returns (bool) {
        bytes32 trueLeaf = keccak256(abi.encodePacked(user,authAmnt));
        return MerkleProof.verify(proof, rootHash, trueLeaf) && trueLeaf == leaf;
    }

    function changeRootHash(bytes32 _rootHash) external onlyOwner {
        rootHash = _rootHash;
    }

    function changeTreasury(address payable _newWallet) external onlyOwner {
        treasury = _newWallet;
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
   * Override isApprovedForAll to auto-approve opensea proxy contract
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

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        require(saleDetails.totalMinted++ <= saleDetails.totalCount, "No more mints available");
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {

        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function distributeFunds() public payable {
        require(payable(treasury).send(address(this).balance), "Distribution reverted");     
    }

}