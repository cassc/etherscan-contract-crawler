// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

pragma solidity ^0.8.0;

// @author: Array
// dsc: array#0007
// tw: @arraythedev
// Contact me on twitter if you need anything :)


//                                         `.-://+oooooooo++/:-.`                                       
//                                  .:+syddmmmmmmmmmmmmmmmmmmddddhs+/-`                                
//                             .:oyddmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmddho/.                            
//                         `:ohdmmmmmmmmmmmmmmmmmmmmmddmmmmmmmmmmmmmmmmmmmdho:`                        
//                      `:sdmmmmmmmmmmmmmmmmmmmmmmmmmhymmmmmmmmmmmmmmmmmmmmmmmdy/.                     
//                    -odmmmmmmmmmmmmmmmmmmmmmmmmmmmmdsydmmmmmmmmmmmmmmmmmmmmmmmmds:`                  
//                 `:ymmmmmmmmmmmmmmmmmmmmmmmmmmmmmmshds+ymmmmmmmmmmmmmmmmmmmmmmmmmmh/`                
//               `/hmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm+:ddh/odmmmmmmmmmmmmmmmmmmmmmmmmmmh+`              
//              :hmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmddmy:-ssyh:ommmmmmmmmmmmmmmmmmmmmmmmmmmmh/`            
//            .smNNNmmmmmmmmmmmmmmmmmmmmmmmmmmdsohs:--o:sh::ddmmmmmmmmmmmmmmmmmmmmmmmmmmmmh-           
//           /dNNNNNNNmmmmmmmmmmmmmmmmmmmmmmmy::h+-----/y/-:d/hmmmmmmmmmmmmmmmmmmmmmmmmmmmmmo`         
//         `sNNNNNNNNNNNmmmmmmmmmmmmmmmmmmmmd:-oy------:--:so:+mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmh.        
//        .hNNNNNNNNNNNNNNNmmmmmmmmmmmmmmmmmm:-/h:---/---:+/--+mmmmmmmmmNNNNNNNNNNNNNNNNNNNNNNd:       
//       -dNNNNNNNNNNNNNNNNNNNNNNmmmmmmdmmmmms--:+:--h/-------hNNNmmmmNNNNNNNNNNNNNNNNNNNNNNNNNm/      
//      .mNNNNNNNNNNNNNNNNNNNNNNmhNmho/omNNNNms-::--+my---+::hNNNNNdsoymNmdNNNNNNNNNNNNNNNNNNNNNm/     
//     `dNNNNNNNNNNNNNNNNNNNNNNd+/msoymNNNNNNNNdoyssmNNhyhysmNNNNNNNNdyohd/smNNNNNNNNNNNNNNNNNNNNm:    
//     hNNNNNNNNNNNNNNNNNNNNNNm+/dhyymNNmmmmmmmmmmmmmmmmmmmmmmmmmmmmNNdyydh/sNmNNNNNNNNNNNNNNNNNNNm.   
//    +NNNNNNNNNNNNNNNNNNNNNsoNhy++sdNNs////////////////////////////hNNds+oydm+hNNNNNNNNNNNNNNNNNNNh   
//   .NNNNNNNNNNNNNNNNNNNNNh:smhyhNNNNNNNdyyyyyyyyyyyyyyyyyyyyyyyhmNNNNNNmhhdmo/mNNNNNNNNNNNNNNNNNNN/  
//   sNNNNNNNNNNNNNNNNNNNdmh+y//ymNNNNNNNdooooooooooooooooooooooosmNNNNNNNms+oy+mdmNNNNNNNNNNNNNNNNNd  
//  `NNNNNNNNNNNNNNNNNNNm+ommhhmNNNNNNNNNNNNms+++++o+++ooooo+oyNNNNNNNNNNNNNmhdmm+sNNNNNNNNNNNNNNNNNN: 
//  /NNNNNNNNNNNNNNNNNNNm/odo/yNNNNNNNNNNNNNNmds:-smh-:mm+-/ymmNNNNNNNNNNNNNms+ym++NNNNNNNNNNNNNNNNNNy 
//  yNNNNNNNNNNNNNNNNNNdmyyoodNNNNNNNNNNNNNNNNNNs-dNm:+NNs-dNNNNNNNNNNNNNNNNNmhohshdmNNNNNNNNNNNNNNNNm 
//  dNNNNNNNNNNNNNNNNNNoommhsmNNNNNNNNNNNNNNNNNNs-dNm:+NNs-dNNNNNNNNNNNNNNNNNNdydmd+yNNNNNNNNNNNNNNNNN.
//  NNNNNNNNNNNNNNNNNNNs:dy/sNNNNNNNNNNNNNNNNNNNs-dNm:+NNs-dNNNNNNNNNNNNNNNNNNmo+dy/hNNNNNNNNNNNNNNNNN-
//  NNNNNNNNNNNNNNNNNNmmshsymNNNNNNNNNNNNNNNNNNNs-dNm:+NNs-dNNNNNNNNNNNNNNNNNNNmyyyymNNNNNNNNNNNNNNNNN:
//  NNNNNNNNNNNNNNNNNNhomddoyNNNNNNNNNNNNNNNNNNNs-dNm:+NNs-dNNNNNNNNNNNNNNNNNNNsymmh+mNNNNNNNNNNNNNNNN-
//  dNNNNNNNNNNNNNNNNNm/odo:mNNNNNNNNNNNNNNNNNNNs-dNm:+NNs-dNNNNNNNNNNNNNNNNNNNh/yh+oNNNNNNNNNNNNNNNNN.
//  yNNNNNNNNNNNNNNNNNNdshsddNNNNNNNNNNNNNNNNNNNs-dNm:+NNs-dNNNNNNNNNNNNNNNNNNmdhyysmNNNNNNNNNNNNNNNNm 
//  /NNNNNNNNNNNNNNNNNmshdms:mNNNNNNNNNNNNNNNNNNs-dNm:+NNs-dNNNNNNNNNNNNNNNNNNh+ddmyyNNNNNNNNNNNNNNNNs 
//  `mNNNNNNNNNNNNNNNNNh/sd+/NNNNNNNNNNNNNNNNNNNs-dNm:+NNs-dNNNNNNNNNNNNNNNNNNd+yho+dNNNNNNNNNNNNNNNN: 
//   sNNNNNNNNNNNNNNNNNNdshymyhNNNNNNNNNNNNNNNNNs-dNm:+NNs-dNNNNNNNNNNNNNNNNNyddhyymNNNNNNNNNNNNNNNNd  
//   `mNNNNNNNNNNNNNNNNNdyddm+/NNNNNNNNNNNNNNNNNs-dNm:+NNs-dNNNNNNNNNNNNNNNNd/yhmhsmNNNNNNNNNNNNNNNN:  
//    +NNNNNNNNNNNNNNNNNNh/ohs+NdNNNNNNNNNNNNNNNs-dNm:+NNs-dNNNNNNNNNNNNNNmdm+yy++dNNNNNNNNNNNNNNNNy   
//     yNNNNNNNNNNNNNNNNNNNhhddd/sNNNNNNNNNNNNNNs-dNm:+NNs-dNNNNNNNNNNNNNmo+mhdydNNNNNNNNNNNNNNNNNd`   
//     `dNNNNNNNNNNNNNNNNNNdoshdo:NdmNNNNNNNNNNNs-dNm:+NNs-dNNNNNNNNNNNdmh/yhhsomNNNNNNNNNNNNNNNNm-    
//      .dNNNNNNNNNNNNNNNNNNmy+oyyNs/hNNNNNNNNNNs-dNm:+NNs-dNNNNNNNNNNy/ddyyooymNNNNNNNNNNNNNNNNm:     
//       .dNNNNNNNNNNNNNNNNNNNNdhhhho/NNNNNNNNNNs-dNm:+NNs-dNNNNNNNNNh+shhhhdNNNNNNNNNNNNNNNNNNm:      
//        `hNNNNNNNNNNNNNNNNNNNmyo++sydmNNNNNNNNs-dNm:+NNs-dNNNNNNNNdhys++ohNNNNNNNNNNNNNNNNNNd-       
//         `oNNNNNNNNNNNNNNNNNNNNNmmmNmdhddmNNNNs-dNm:+NNs-dNNNNddhhmmNmmmNNNNNNNNNNNNNNNNNNNy.        
//           :dNNNNNNNNNNNNNNNNNNNNNNNNNNNmmNNNNs-dNm:+NNs-dNNNNmmNNNNNNNNNNNNNNNNNNNNNNNNNm+`         
//            .sNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNs-dNm:+NNs-dNNNNNNNNNNNNNNNNNNNNNNNNNNNNNmy-           
//              -yNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNs-dNm:+NNs-dNNNNNNNNNNNNNNNNNNNNNNNNNNNNh:`            
//                :hNNNNNNNNNNNNNNNNNNNNNNNNNNNNdomNm:+NNhomNNNNNNNNNNNNNNNNNNNNNNNNNNh/`              
//                  -ymNNNNNNNNNNNNNNNNNNNNNNNNNNNNNm/+NNNNNNNNNNNNNNNNNNNNNNNNNNNNmh/`                
//                    .+dNNNNNNNNNNNNNNNNNNNNNNNNNNNm/+NNNNNNNNNNNNNNNNNNNNNNNNNmdo-                   
//                       -odNNNNNNNNNNNNNNNNNNNNNNNNNdmNNNNNNNNNNNNNNNNNNNNNNmds:`                     
//                          -+hmNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNmho:`                        
//                             `-+ymNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNmmyo:.                            
//                                  `:/oydmNNNNNNNNNNNNNNNNNNNNmdys+:.                                 
//                                         `.-:/++oooooo++/::-`                                        
// 


contract DivineAssembly is ERC721Enumerable, Ownable, PaymentSplitter, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;
    using Address for address payable;
    using ECDSA for bytes32;

    address private signerAddress = 0xDC90586e77086E3A236ad5145df7B4bd7F628067;

    address[] private _team = [
        0x0c90B7622b4eb910fc8B79eD247D8D425ef7dA7c,
        0x05814703bF4f3a142178eF9204547c6b410586bA,
        0x61497f1843eb5D5b19788A494EB310932Ad10112,
        0xCFDa68452Ac0778C3c74b079A2629061E42930c3,
        0xCE89AFC3ffa79BAacD4B59Dc91DF7C9fd5671220,
        0xe2fe6d312138417Cdab7184D70D03B74f2Ce698C,
        0x2bDA83f718262c0031415E7d2f16d007fcC8DAE7,
        0xfa80F8dF4f3fca053a28eFAfAd832F76Ea8be319,
        0x27aD0c508F77Dce925F114BAd1a95eCDC6a3a474,
        0x01B2D1345c2F04f5F9DCddc14ead6ca07706E477,
        0x6865Ad01393FFF4e651EbD513CA2d71312A4cC21,
        0xc2df218dA745f0fbFD0A2b03b3bC8438387d9dBc,
        0xE4a419F374BD594Fde6Af0bA666275EaeB1B09CB,
        0xEcb2703B964614D64c461789B21Ee4E70D1D42EE,
        0xCAbf81e9F7b1Bc13b9977D1CEb1B08fFcC67fCB0,
        0xF3fe50C433FD211AfF2fbA8f153CEe7bC2369AA1
    ];

    uint256[] private _teamShares = [10000, 19475, 24475, 5000, 20000, 6000, 5000, 2000, 2000, 750, 750, 1300, 1100, 1000, 650, 500];

    uint256 public constant MAX_SUPPLY = 7890;

    string public baseURI;

    bool public whitelistSaleActivated;
    bool public publicSaleActivated;
    uint256 public publicSupply = 5890;
    uint256 public totalPublicSaleClaimable = 2;
    uint256 public totalPublicSaleClaimed;
    uint256 public salePrice = 0.19 ether;

    bool public givewayClaimActivated;

    mapping(address => uint256) public whitelistClaimed;
    mapping(address => uint256) public publicSaleClaimed;
    mapping(address => uint256) public givewaysClaimed;

    Counters.Counter private _tokenIds;
    bool internal revealed = false;

    uint256 public firstWithdrawRemaining = 100 ether;
    address private firstWithdrawWallet = 0xCE89AFC3ffa79BAacD4B59Dc91DF7C9fd5671220;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) PaymentSplitter(_team, _teamShares) {
    }

    // ADMIN
    function firstWithdraw() external onlyOwner {
        uint256 _currentBalance = address(this).balance;
        uint256 _amountToTransfer = Math.min(firstWithdrawRemaining, _currentBalance);
        require(_amountToTransfer > 0, "DA: No more amount to transfer for the first withdraw.");
        payable(firstWithdrawWallet).sendValue(_amountToTransfer);
        firstWithdrawRemaining -= _amountToTransfer;
    }

    function withdrawAll() external onlyOwner {
        require(firstWithdrawRemaining == 0, "DA: First withdraw amount need to be executed first.");
        for (uint256 i = 0; i < _team.length; i++) {
            address payable wallet = payable(_team[i]);
            release(wallet);
        }
    }
    function setFirstWithdrawRemaining(uint256 _nb) external onlyOwner {
        firstWithdrawRemaining = _nb;
    }

    function _setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setSignerAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "DA: The void is not your friend.");
        signerAddress = _newAddress;
    }

    // Setters
    function setTotalPublicSaleClaimable(uint256 _nb) external onlyOwner {
        totalPublicSaleClaimable = _nb;
    }

    function setSalePrice(uint256 _nb) external onlyOwner {
        salePrice = _nb;
    }

    function setPublicSupply(uint256 _nb) external onlyOwner {
        publicSupply = _nb;
    }

    function flipWhitelistSale() external onlyOwner {
        whitelistSaleActivated = !whitelistSaleActivated;
    }

    function flipGivewayClaim() external onlyOwner {
        givewayClaimActivated = !givewayClaimActivated;
    }

    function flipPublicSale() external onlyOwner {
        publicSaleActivated = !publicSaleActivated;
    }

    function flipRevealed() external onlyOwner {
        revealed = !revealed;
    }

    function deactivatePublicSale() external onlyOwner {
        publicSaleActivated = false;
    }

    // VIEW
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory base = _baseURI();
        if (!revealed) {
            return bytes(base).length > 0 ? string(abi.encodePacked(base)) : "";
        }
        return bytes(base).length > 0 ? string(abi.encodePacked(base, tokenId.toString())) : "";
    }

    // MINT

    function airdrop(address _to, uint256 _nb) external onlyOwner {
        require(totalSupply() + _nb <= MAX_SUPPLY, "DA: Not enough tokens left.");

        for (uint32 i = 0; i < _nb; i++) {
            _mint(_to);
        }
    }

    function whitelistMint(
        uint256 _nb,
        uint256 _alloc,
        bytes calldata _signature
    ) external payable nonReentrant {
        require(whitelistSaleActivated, "DA: Whitelisted sale is not active.");
        require(totalSupply() + _nb <= MAX_SUPPLY, "DA: Not enough tokens left.");
        require(whitelistClaimed[msg.sender] + _nb <= _alloc, "DA: Allocation exceeded.");
        require(msg.value >= salePrice * _nb, "DA: Insufficient amount.");

        bytes32 _messageHash = hashMessage(abi.encode("wl", address(this), msg.sender, _alloc));
        require(verifyAddressSigner(_messageHash, _signature), "DA: Invalid signature.");

        for (uint32 i = 0; i < _nb; i++) {
            _mint(msg.sender);
        }
        whitelistClaimed[msg.sender] += _nb;
    }

    function givewayMint(
        uint256 _nb,
        uint256 _alloc,
        bytes calldata _signature
    ) external nonReentrant {
        require(givewayClaimActivated, "DA: Giveway is not active.");
        require(totalSupply() + _nb <= MAX_SUPPLY, "DA: Not enough tokens left.");
        require(givewaysClaimed[msg.sender] + _nb <= _alloc, "DA: Allocation exceeded.");

        bytes32 _messageHash = hashMessage(abi.encode("gw", address(this), msg.sender, _alloc));
        require(verifyAddressSigner(_messageHash, _signature), "DA: Invalid signature.");

        for (uint32 i = 0; i < _nb; i++) {
            _mint(msg.sender);
        }
        givewaysClaimed[msg.sender] += _nb;
    }

    function publicMint(uint256 _nb) external payable {
        require(publicSaleActivated, "DA: Public sale is not active.");
        require(totalSupply() + _nb <= MAX_SUPPLY, "DA: Not enough tokens left.");
        require(totalPublicSaleClaimed + _nb <= publicSupply, "DA: Not enough supply.");
        require(publicSaleClaimed[msg.sender] + _nb <= totalPublicSaleClaimable, "DA: Allocation exceeded.");
        require(msg.value >= salePrice * _nb, "DA: Insufficient amount.");

        for (uint32 i = 0; i < _nb; i++) {
            _mint(msg.sender);
        }
        totalPublicSaleClaimed += _nb;
        publicSaleClaimed[msg.sender] += _nb;
    }

    // INTERNAL
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _mint(address _to) internal returns (uint256) {
        _tokenIds.increment();
        uint256 _tokenId = _tokenIds.current();
        _safeMint(_to, _tokenId);
        return _tokenId;
    }

    // PRIVATE
    function verifyAddressSigner(bytes32 _messageHash, bytes memory _signature) private view returns (bool) {
        return signerAddress == _messageHash.toEthSignedMessageHash().recover(_signature);
    }

    function hashMessage(bytes memory _msg) private pure returns (bytes32) {
        return keccak256(_msg);
    }

    /// Necessary overrides
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}