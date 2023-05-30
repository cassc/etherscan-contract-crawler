// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/*
#     # ####### ####### #     # ######  #     # #     # #     # #     # 
##   ## #     # #     # ##    # #     # #     # ##    # ##    #  #   #  
# # # # #     # #     # # #   # #     # #     # # #   # # #   #   # #   
#  #  # #     # #     # #  #  # ######  #     # #  #  # #  #  #    #    
#     # #     # #     # #   # # #     # #     # #   # # #   # #    #    
#     # #     # #     # #    ## #     # #     # #    ## #    ##    #    
#     # ####### ####### #     # ######   #####  #     # #     #    #    

                                                                                                    
                                                                                                    
                                              .lOOOOOOk,                                            
                                .,,.        .lxxOXMMMMW0d;                                          
                                 ',.      .:xNWKOXWMWK000xc;.             .'.                       
                                        ';dKXXXWMMMMXxoooOWXo,.         ..lOo'.                     
                     .......           .OW0dooxXMMMMNOxxx0WMWWl         ,ckNOl;.                    
                    'x00000k, ..       .OW0dddxXMMMMMWWWWWWWWWl           ;o:.                      
                  ,kx;.....,d000l.     'OMWNNNNWMMMMMMMMMXxkXWl            .     .c,                
                :dl:'       ':::cdo.    ,:kWNOONMMMMMMMMMNKOo;.                   ..                
               .kMd    .'','    .:lll,    'ldkOO0XMMMMMMM0o:.                                       
    ...        .kMd    ,oodl,..    ;dl:'    .lxxOXMMMMW0d;    .;:::::::::;.                         
    'c'        .l0o'.  'cccclo,.     ,kx;..   .l000000k,    ..l0000000000Oc..                       
                 .;Ox'.... .;lll;.     'x0c.    ......     .o0c. .........l0o.                      
                   .;x0O0o.  .,olc:.    ..l0l.           ,kk:..           ..:kx'                    
         ';.         ',,,cdo.  .,loc;.    lWk.         :ko;'.               .';ox,                  
        .o0:             .;clo'  .'coc;.  .:coc.       dMd  .,:o;             .kWl                  
    ..';l0Wk:,'.            :dl:'  .;:ol,.. ,KK,       dMd  :dkKkc,.          .kWl                  
    .:ok0NMXOxc;.             lWk.   .looo' ,KK,       dMd  ;ooodkx:'''''''''';dk;                  
        .xNl                  :Kx'.  .looo' 'kO;.......oKl  ;ooo:..xWX00000000x'                    
         :d,        .;c.       .;O0, .looo'  .'dKKKKKK0:.   ;ooo; .kMx.........         .c;.        
         ..          ..         ,KN:  ....     .,,,,,,,.    ..... .kMd                  ;0x.        
              ''              'oxOk,                               ,clo:.           ';coOWXxoc,.    
           ..:kk:'.         ,cd0x;'.                                 .loc:.         ';coOWXkoc;.    
           .;l00l;.      .':kKd;'                                      .lxc,.           ,0x.        
             .::.       .:0Xdc.                                           lKd'.         .c;.        
                       lKOxo'                                              .;Ok'                    
                       dMXxc.               .;:::.            .:::;.        ,KK,                    
                    .cxkOo,.                 ....              ....         .,:od,      .,'         
                    'OWOo;             .,cccccccc.              .;ccccccc:.   .kWl      .,'         
                    'OWOo;           .,:dxxkkkkxxl;;'         .,cdkkkkkxkxc;. .kWl                  
                   .:OXdc,           :XO' .'.    lNWO.        lWk. .'.    dMk..o0l'.                
                  ;KKko'             :NO. cXx.   lNWO'        lWk..dNd.   dMk.  .lXd.               
                  :NXxl.             :NO. lWNKx' lNWO'        lWk..kMN0d. dMk.   lWk.               
                  :NXxl.             :NKl;kWMMNo;kWWO'        lW0cc0MMMKl:OMk.   lWk.               
                  :NXxl.             :NXxox000Oxo0WWO.   .''',xWXdok000OddKMk.   lWk.               
                  :NXxl.             'oxkOOOOOOOOkdxc.   ,kOOO0K0OOOOOOOOOxd:    lWk.               
                  :NXxl.      ........ .d00000000:     ..oNMMMKxkO0000000O,  ....dWk.               
                  ;KKxo'      ;O00000c   ........      c0KXXXXXKd.........  'x000XMk.               
                   .:OXdc,    ........                 ..........            .'.'dWk.               
         ';.        'OWOo;    ,xkkkkk:                                      .okkkl;.                
      .,,''',.      .,cx0x:'  .:ccccc'                                      .;oKWl                  
      .,;'.';.         ;dxkkl;,..                                         .::::od,                  
         ':.     .       .dOOOkko,'''.                             .''''',oOOOd.         ..         
                ,c'           :000000o...                        .'d00000O;             .:;.        
                               ......c0Ooc.                     'kO;......            'c,..;c.      
                                   :kkOd,.                      .';ok:                 .';;..       
                                .cdxOo,.             ',,,,,,,,.    ,clo:.                ..         
                                ,KWOo,         .'''',loooooooo:'.    :NO.                           
                                ,KWOo,         ;dooooooooooooood;    :NO.                           
*/

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract Moonbunny is ERC721A, Ownable {
    using Address for address payable;
    using Strings for uint256;

    string private _baseTokenURI;
    bool private _saleStatus = false;
    uint256 private _salePrice = 0.005 ether;
    uint256 private _teamSupply = 88;
    uint256 private _reservedSupply;

    uint256 public MAX_SUPPLY = 8888;
    uint256 public FREE_PER_WALLET = 2;
    uint256 public MAX_MINTS_PER_TX = 5;
    uint256 public MAX_PER_WALLET = 5;

    constructor() ERC721A("Moonbunny", "Moonbunny") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function setMaxMintPerTx(uint256 maxMint) external onlyOwner {
        MAX_MINTS_PER_TX = maxMint;
    }

    function setSalePrice(uint256 price) external onlyOwner {
        _salePrice = price;
    }

    function toggleSaleStatus() external onlyOwner {
        _saleStatus = !_saleStatus;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), ".json"));
    }
    
    function trackUserMinted(address minter) external view returns (uint32 userMinted) {
        return uint32(_numberMinted(minter));
    }        

    function mint(uint256 quantity)
        external
        payable
        callerIsUser
    {
        uint256 userMintCount = uint256(_numberMinted(msg.sender));
        uint256 freeQuantity = 0;

        if (userMintCount < FREE_PER_WALLET) {
            uint256 freeLeft = FREE_PER_WALLET - userMintCount;
            freeQuantity += freeLeft > quantity ? quantity : freeLeft;
        }

        uint256 totalPrice = (quantity - freeQuantity) * _salePrice;

        if (totalPrice > msg.value)
            revert("Moonbunny: Insufficient fund");

        if (!isSaleActive()) revert("Moonbunny: Sale not started");
        
        if (quantity > MAX_MINTS_PER_TX)
            revert("Moonbunny: Amount exceeds transaction limit");
        if (quantity + userMintCount > MAX_PER_WALLET)
            revert("Moonbunny: Amount exceeds wallet limit");
        if (totalSupply() + quantity > (MAX_SUPPLY))
            revert("Moonbunny: Amount exceeds supply");

        _safeMint(msg.sender, quantity);
        if (msg.value > totalPrice) {
            payable(msg.sender).sendValue(msg.value - totalPrice);
        }              
    }

    function adminMint(uint256 quantity) external onlyOwner {
        require(_reservedSupply + quantity <= _teamSupply, "Moonbunny: Reserved amount is exceeded");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Moonbunny: Amount exceeds supply");

        _safeMint(msg.sender, quantity);
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 1;
        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= totalSupply()
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    function mintToAddress(address to, uint256 quantity) external onlyOwner {
        if (totalSupply() + quantity > MAX_SUPPLY)
            revert("Moonbunny: Amount exceeds supply");

        _safeMint(to, quantity);
    }

    function isSaleActive() public view returns (bool) {
        return _saleStatus;
    }

    function getSalePrice() public view returns (uint256) {
        return _salePrice;
    }

}