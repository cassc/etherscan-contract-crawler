//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Whitelist is Ownable {
    event WhitelistAdd(address indexed account);
    event WhitelistRemove(address indexed account);

    mapping(address => bool) private _whitelists;

    modifier onlyWhitelist() {
        require(isWhitelist(_msgSender()), "Caller is not whitelist");
        _;
    } 

    function isWhitelist(address account) public view returns (bool) {
        return _whitelists[account] || account == owner();
    }

    function addWhitelist(address account) external onlyOwner {
        _addWhitelist(account);
    }

    function removeWhitelist(address account) external onlyOwner {
        _removeWhitelist(account);
    }

    function renounceWhitelist() external {
        _removeWhitelist(_msgSender());
    }

    function _addWhitelist(address account) internal {
        _whitelists[account] = true;
        emit WhitelistAdd(account);
    }

    function _removeWhitelist(address account) internal {
        delete _whitelists[account];
        emit WhitelistRemove(account);
    }
}

contract Smoke is Ownable, ERC721AQueryable, ReentrancyGuard,ERC2981,DefaultOperatorFilterer,Whitelist {
    using SafeMath for uint256;
   
    uint256 public constant maxSupply = 3000;
    uint256 public PRICE1 = 0 ether;
    uint256 public PRICE2 = 0.01 ether;
    uint256 public MINTED1;
    uint256 public MINTED2;
    uint256 public AMOUNT1 = 500;
    uint256 public AMOUNT2 = 2500;
    uint256 public LIMIT1 = 1;
    uint256 public LIMIT2 = 5;

    

    uint256 _step = 0;

    mapping(address => uint256) public WALLET1_CAP;
    mapping(address => uint256) public WALLET2_CAP;


    address public _burner;
    address recipient = 0xf5D310Efa2030C1188bCF693FF4d885c1AA33Ac9;
    uint96 fee = 750;
    string public BASE_URI="https://data.smokeweed.wtf/metadata/";
    bool isBlack = false;

   struct Info {
        uint256 all_amount;
        uint256 minted;
        uint256 price;
        uint256 start_time;
        uint256 numberMinted;
        uint256 step;
        uint256 limit;
        uint256 step_minted;
        uint256 step_amount;
    }


    constructor() ERC721A("SmokeWeedEveryday", "smokeweedeveryday") {
        _safeMint(msg.sender, 1);
        MINTED1 = MINTED1.add(1);
        _setDefaultRoyalty(recipient, fee);
    }  
    
    function info(address user) public view returns (Info memory) {
        if(_step == 1){
             return  Info(maxSupply,totalSupply(),PRICE1,0,WALLET1_CAP[user],_step,LIMIT1,MINTED1,AMOUNT1);
        }else if(_step == 2){
             return  Info(maxSupply,totalSupply(),PRICE2,0,WALLET2_CAP[user],_step,LIMIT2,MINTED2,AMOUNT2);
        }
    }


    function freemint(uint256 amount) external {
        require(msg.sender == tx.origin, "Cannot mint from contract");
        require(_step == 1, "must be active to mint tokens");
        require(amount > 0, "amount must be greater than 0");

        require(WALLET1_CAP[msg.sender].add(amount) <= LIMIT1, "max mint per wallet would be exceeded");
        require(MINTED1.add(amount) <= AMOUNT1,"Max supply for freemint reached!");
        require(totalSupply().add(amount) <= maxSupply, "max supply would be exceeded");

        if (MINTED1.add(amount) == AMOUNT1){
            _step = 2;
        }

        MINTED1 = MINTED1.add(amount);

        WALLET1_CAP[msg.sender] = WALLET1_CAP[msg.sender].add(amount);
        
        _safeMint(msg.sender, amount);
    }

    function mintpublic(uint256 amount) external payable {
        require(msg.sender == tx.origin, "Cannot mint from contract");
        require(_step == 2, "must be active to mint tokens");
        require(amount > 0, "amount must be greater than 0");

        require(WALLET2_CAP[msg.sender].add(amount) <= LIMIT2, "max mint per wallet would be exceeded");
        require(MINTED2.add(amount) <= AMOUNT2,"Max supply for mintpublic reached!");
        require(totalSupply().add(amount) <= maxSupply, "max supply would be exceeded");

        require(msg.value >= PRICE2 * amount, "value not met");

        MINTED2 = MINTED2.add(amount);

        WALLET2_CAP[msg.sender] = WALLET2_CAP[msg.sender].add(amount);
        
        _safeMint(msg.sender, amount);
    }


   function withdraw() public onlyOwner nonReentrant {
        (bool succ, ) = payable(owner()).call{value: address(this).balance}('');
        require(succ, "transfer failed");
   }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        BASE_URI = _baseURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(IERC721A, ERC721A)
        returns (string memory)
    {
        return string(abi.encodePacked(BASE_URI, Strings.toString(_tokenId), ".json"));
    }

     function flipStep(uint256 step) external onlyOwner {
        _step = step;
    }


     function setPrice2(uint256 price) public onlyOwner
    {
        PRICE2 = price;
    }


    function burn(uint256 tokenId) public {
        require(msg.sender == _burner, "Permission denied for burn");
        _burn(tokenId);
    }

    function setBurner(address burner) external onlyOwner {
        _burner = burner;
    }

    function setIsBlack(bool _isBlack) external onlyOwner {
        isBlack = _isBlack;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC721A, ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }


     //  ===============================================================
    //                    Operator Filtering
    //===============================================================

    function setApprovalForAll(address operator, bool approved)
        public
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
         if(isBlack){
            require(!isWhitelist(operator), "Permission denied");
        }
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
         if(isBlack){
            require(!isWhitelist(operator), "Permission denied");
        }
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }




    //===============================================================
    //                  ERC2981 Implementation
    //===============================================================

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }


    


}