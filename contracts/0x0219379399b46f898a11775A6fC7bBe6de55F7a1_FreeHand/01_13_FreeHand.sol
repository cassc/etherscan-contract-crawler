//                                 ............                                   
//                         ..'''''',,,,''''''','''',''.                           
//                     .'''''..                    ..'',','.                      
//                  .,,''.                               .',,,.                   
//                ',,.                                       .,;,.                
//              ';'               .',;,.    ...                 ':,.              
//            .;,          ... .:▀▀▀▀▀▀▀▀▀▀▀███▀:.   .....        ':,             
//           ':.         .▀▀▀▀▀▀▀▀▀▀▀██████████▀▀█:▀▀▀█▀██▀:.      .;:.           
//          ;;.         ,▀▀▀▀▀▀▀▀▀█████████████▀▀▀▀▀███████▀▀.       '▀.          
//         ;;          '▀▀▀▀███████████████████████████████▀▀.        '▀.         
//        ,;           :▀▀▀███████████████████████████████▀▀.          ,:.        
//       ':.           ;▀▀▀████████████████████████████▀▀█;.            :;        
//      .:'            .▀▀▀█████████▀▀▀▀███████████████▀▀:              .:.       
//      ';              ▀█▀▀██████▀▀▀▀▀▀▀█████▀▀▀▀▀███▀▀▀▀              .:'       
//      ;,              :█▀▀▀████▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀.               :,       
//     .:.             .▀▀▀▀▀███▀▀▀▀▀::▀█▀▀▀▀▀▀▀█▀█▀▀▀▀:.                ;'       
//     .;.              :▀▀███▀▀▀▀▀,.....,:▀▀▀▀,...',,:'                .;.       
//     .:.               ,█▀▀▀▀▀█▀,...................:;                .;.       
//     .:.                .;▀▀▀▀:,'.....,;,'.......,,.:;                ,'        
//     .:.                   .▀▀;,......:▀▀█,.....'▀█;▀,               .;.        
//      ;,                   .▀:▀▀,.....▀▀█▀▀.....;▀█▀:.              .;.         
//      ,:                    .▀█▀'.....':▀:'.....';:▀,              .;'          
//      .:.                     ;█:''...............::.             .,'           
//       ,;                      '▀▀;'............':;.             .;.            
//       .;'                      ,▀:,'.'''....';:;.              .,..;.          
//        .:.                     .▀▀,'.':▀:;,,,'.              .,'..:'           
//         ':.             ..     '▀▀,'...                     .,. ':.            
//          .:.         ,:▀▀▀▀▀▀▀▀█▀;,......',;:▀▀:;'.       .,' .;,.             
//           .:'      ;█▀▀██████▀▀█:;'...:▀▀▀▀▀▀▀▀▀▀▀█▀;.  .''..,;.               
//             ,;.   ▀▀▀▀███████▀▀:;;'...;▀▀▀▀▀█████████▀▀;'..;:'                 
//              .,,..█▀▀▀▀█████▀▀▀;;:;'..':█▀▀▀████████:▀▀..;:'                   
//                .,;▀█▀▀▀▀█████▀▀▀:;:,..',▀█▀███████▀▀▀▀▀;,.                     
//                  .,▀▀▀▀▀▀▀████▀▀▀▀▀:,..'▀▀▀██████▀▀▀██▀.                       
//                    .███▀▀▀▀▀████▀▀▀██▀;;█▀█████▀▀▀▀▀▀▀▀█,                      
//                   ,▀▀▀▀▀▀▀▀▀▀▀▀█████▀▀▀██▀████▀▀▀▀▀▀▀▀▀▀▀▀.                    
//                  '▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀██▀▀▀▀█████▀▀████████▀█▀.                   
//                 .█▀▀▀▀▀▀▀███▀▀▀▀▀▀▀▀▀▀██████████████████▀▀█:                   
//                 ;▀▀▀▀▀███████████████████████████████████▀▀▀.                  
// 
//             ____  ____  ____  ____    _   _    __    _  _  ____  
//            ( ___)(  _ \( ___)( ___)  ( )_( )  /__\  ( \( )(  _ \ 
//             )__)  )   / )__)  )__)    ) _ (  /(__)\  )  (  )(_) )
//            (__)  (_)\_)(____)(____)  (_) (_)(__)(__)(_)\_)(____/ 
//                       SPDX-License-Identifier: MIT
//              Inspired by the Wonderpals contract & bueno.art
//                      Written by Buzzy @ buzzybee.eth
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Ticketed.sol";

error SaleInactive();
error SoldOut();
error InvalidPrice();
error InvalidQuantity();
error WithdrawFailed();

contract FreeHand is ERC721, Ownable, Ticketed {
    uint256 public nextTokenId = 1;
    uint256 public price = 0.0550 ether;

    // tokenIds will range from 1-2882
    uint256 public constant SUPPLY = 2882;

    string public _baseTokenURI;

    bool public saleActive = false;

    bool public publicSaleActive = false;

    // dev address - buzzybee.eth
    address private buzz = 0x816ae721F90d9cd5190d0385E7224C6798DaD52B;

    // cm address - moodymarv.eth
    address private marv = 0x8fD8Cc0F855Ade5470C8Af71ad2b0dF98B94E596;

    // artist address - mlted.eth
    address private melt = 0x511F548cad64382945A9EBa04eeA6003992CadE4;

    // community
    address private comm = 0xCd99178Fd3bD04411b9E0C03023f5Ca2D2fcF35A;

    constructor(string memory baseURI) ERC721("Free Hand", "FREEHAND") {
        _baseTokenURI = baseURI;
    }

    function mintOne(bytes calldata _signature, uint256 spotId)
        external
        payable
    {
        uint256 _nextTokenId = nextTokenId;
        if (!saleActive) revert SaleInactive();
        if (_nextTokenId > SUPPLY) revert SoldOut();
        if (msg.value != price) revert InvalidPrice();

        // invalidate the spotId passed in
        _claimAllowlistSpot(_signature, spotId);
        _mint(msg.sender, _nextTokenId);

        unchecked {
            _nextTokenId++;
        }

        nextTokenId = _nextTokenId;
    }

    function mintOnePublic()
        external
        payable
    {
        uint256 _nextTokenId = nextTokenId;
        if (!saleActive) revert SaleInactive();
        if (!publicSaleActive) revert SaleInactive();
        if (_nextTokenId > SUPPLY) revert SoldOut();
        if (msg.value != price) revert InvalidPrice();

        _mint(msg.sender, _nextTokenId);

        unchecked {
            _nextTokenId++;
        }

        nextTokenId = _nextTokenId;
    }

    function devMint(address receiver, uint256 qty) external onlyOwner {
        uint256 _nextTokenId = nextTokenId;
        if (_nextTokenId + (qty - 1) > SUPPLY) revert InvalidQuantity();

        for (uint256 i = 0; i < qty; i++) {
            _mint(receiver, _nextTokenId);

            unchecked {
                _nextTokenId++;
            }
        }
        nextTokenId = _nextTokenId;
    }

    function totalSupply() public view virtual returns (uint256) {
        return nextTokenId - 1;
    }

    function setSaleState(bool active) external onlyOwner {
        saleActive = active;
    }

    function setPublicSaleState(bool active) external onlyOwner {
        publicSaleActive = active;
    }

    function setClaimGroups(uint256 num) external onlyOwner {
        _setClaimGroups(num);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() external onlyOwner {
        // 10% of total
        (bool s1, ) = buzz.call{value: (address(this).balance * 10) / 100}("");

        // 10% of total, we currently have 90% left
        (bool s2, ) = marv.call{value: (address(this).balance * 10) / 90}("");

        // 30% of the total, we currently have 80% left
        (bool s3, ) = melt.call{value: (address(this).balance * 30) / 80}("");
        (bool s4, ) = comm.call{value: (address(this).balance)}("");

        if (!s1 || !s2 || !s3 || !s4) revert WithdrawFailed();
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setSigner(address _signer) external onlyOwner {
        _setClaimSigner(_signer);
    }

    function tokensOf(address wallet) public view returns (uint256[] memory) {
        uint256 supply = totalSupply();
        uint256[] memory tokenIds = new uint256[](balanceOf(wallet));

        uint256 currIndex = 0;
        for (uint256 i = 1; i <= supply; i++) {
            if (wallet == ownerOf(i)) tokenIds[currIndex++] = i;
        }

        return tokenIds;
    }
}