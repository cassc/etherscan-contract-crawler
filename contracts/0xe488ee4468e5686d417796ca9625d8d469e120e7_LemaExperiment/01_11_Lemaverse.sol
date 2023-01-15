// SPDX-License-Identifier: MIT

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

pragma solidity ^0.8.17;
    
contract LemaExperiment is ERC721A, DefaultOperatorFilterer, Ownable {

    /*

    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BGGGGGGGGGGGGGGGG&@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@&GGGG5YYYYYYYYYYYP&&&&@@@@@@@@@@@@@@@@@@@@@@@@@&&&&PYYYYYYYYYYY5GGGG&@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@GGGG?~!!!!!!!!!!!PGGG&@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@&GGGP77777777!!!!7YYY5#########################5YYY7!!!!77777777PGGG&@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@&GGGP????????7!!!!!!~7GGGGGGGGGGGGGGGGGGGGGGGGG7~!!!!!!7????????PGGG&@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@&GGGP????????777777777YYYYYYYYYYYYYYYYYYYYYYYYY777777777????????PGGG&@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@&PPGP?????????????????!!!!!!!!!!!!!!!!!!!!!!!!!?????????????????PGPP&@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@###B5YYYJ???777777777!!!!!!!!!!!!!!!!!!!!!!!!!777777777???JYYY5B###@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@&&&&PYY5?!!!!!!!!!!!!????7!!!!!!!7????!!!!!!!!!!!!?5YYP&&&&@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@&&&&GY555555555557!!!!!!!!!!!!!!!755555555GBBB#&&&&@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@#GGGGGGGGGGGG7!!!!!!!!!!!!!!!7GGGGGGGG&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&P555555555555555P&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

    THIS IS THE LEMA EXPERIMENT.

    */

    using Strings for uint256;

    string private uriPrefix ;
    string private uriSuffix = ".json";
    string public hiddenURL;

    uint256 public cost;
    uint16 public maxSupply;
    uint8 public maxMintAmountPerTx;
    uint8 public maxMintPerWallet;
    uint8 public maxFreeMintAmountPerWallet = 1;
 
    bool public paused = true;
    bool public reveal = false;

    mapping (address => uint8) public NFTPerPublicAddress;

    constructor(
        uint256 _cost,
        uint16 _supply,
        uint8 _maxPerWallet,
        uint8 _maxPerTx,
        string memory _hiddenURL

    ) ERC721A("Lema Experiment", "LEMA") {
        cost = _cost;
        maxSupply = _supply;
        maxMintAmountPerTx = _maxPerTx;
        hiddenURL = _hiddenURL;
        maxMintPerWallet = _maxPerWallet;

        _safeMint(msg.sender, 2);
    }


    function mint(uint8 _mintAmount) external payable  {
        uint16 totalSupply = uint16(totalSupply());
        uint8 nft = NFTPerPublicAddress[msg.sender];
        require(totalSupply + _mintAmount <= maxSupply, "Exceeds max supply.");
        require(_mintAmount <= maxMintAmountPerTx, "Exceeds max per transaction.");
        require(_mintAmount + nft <= maxMintPerWallet, "Exceeds max per transaction.");

        require(!paused, "Contract paused!");
        
        if(nft >= maxFreeMintAmountPerWallet){
            require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        } else {
            uint8 costAmount = _mintAmount + nft;
            if(costAmount > maxFreeMintAmountPerWallet) {
                costAmount = costAmount - maxFreeMintAmountPerWallet;
                require(msg.value >= cost * costAmount, "Insufficient funds!");
            }
        }

        _safeMint(msg.sender , _mintAmount);
        NFTPerPublicAddress[msg.sender] = _mintAmount + nft;
        delete totalSupply;
        delete _mintAmount;
    }
  
    function Reserve(uint16 _mintAmount, address _receiver) external onlyOwner {
        uint16 totalSupply = uint16(totalSupply());
        require(totalSupply + _mintAmount <= maxSupply, "Exceeds max supply.");
        _safeMint(_receiver , _mintAmount);
        delete _mintAmount;
        delete _receiver;
        delete totalSupply;
    }

    function  Airdrop(uint8 _amountPerAddress, address[] calldata addresses) external onlyOwner {
        uint16 totalSupply = uint16(totalSupply());
        uint totalAmount =   _amountPerAddress * addresses.length;
        require(totalSupply + totalAmount <= maxSupply, "Exceeds max supply.");
        for (uint256 i = 0; i < addresses.length; i++) {
                _safeMint(addresses[i], _amountPerAddress);
            }

        delete _amountPerAddress;
        delete totalSupply;
    }

    function setMintPerWallet (uint8 _val) external onlyOwner {
        maxMintPerWallet = _val;
    }

    function setMaxSupply(uint16 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }
   
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
    
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
    
        if ( reveal == false){
            return hiddenURL;
        }
            
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString() ,uriSuffix))
            : "";
    }

    function setFreeMaxLimitPerAddress(uint8 _limit) external onlyOwner{
        maxFreeMintAmountPerWallet = _limit;
        delete _limit;
    }

    function setUriPrefix(string memory _uriPrefix) external onlyOwner {
        uriPrefix = _uriPrefix;
    }
    function setHiddenUri(string memory _uriPrefix) external onlyOwner {
        hiddenURL = _uriPrefix;
    }


    function togglePause() external onlyOwner {
        paused = !paused;
    }

    function setCost(uint _cost) external onlyOwner{
        cost = _cost;
    }

    function toggleRevealed() external onlyOwner{
        reveal = !reveal;
    }

    function setMaxMintAmountPerTx(uint8 _maxtx) external onlyOwner{
        maxMintAmountPerTx = _maxtx;
    }

    function withdraw() external onlyOwner {
    uint _balance = address(this).balance;
        payable(msg.sender).transfer(_balance ); 
        
    }

    function _baseURI() internal view  override returns (string memory) {
        return uriPrefix;
    }

        function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public payable
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
    }