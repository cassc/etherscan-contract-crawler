// SPDX-License-Identifier: MIT
/*                                                                                                                                                                 
                                                                                                                                                                                                                                                                                                                               
                                    .'.                                                                                                                         
                                  .;:c:;,,,;;,,;:c:'.                                                                                                           
                                .,cc:::cclloooddxkkko:.                                                                                                         
                             .':cc:;;;:lloodddxxkkkOOOxc.                                                                                                       
                            'cc:;;;;;;:cooodxkkkkkOOO000Odll,                                                                                                   
                          .:c:;,,,,,,,lxdlccokOOOO000KKK00KK0o.                                                                                                 
                         .,;,,,,,,,,,,lxoc:coO00000KKKKKKKKKKKo.                                                                                                
                        .,,,,,,,,,;;,,:loodxO000000KKKKKKKKKKKk'                                                                                                
                        ,;,,,,,,,,;::::coxkkOOO0O00KKKKKXXKKKKl                                                                                                 
                       'c;,,,,,,,;:lcclc;;cdkkOOO0OdloOKXXXKKKl.                                                                                                
                      .;:;,,,,,,,;:cccl;,c;:xkkkkOo:oolOXKKKKKk'                                                                                                
                      .;;,,,,,,,,,;::cclloddoddddddk0000KKKK0Kx.                                                                                                
                       ':;,,,,,,,,,;::cclodl......;k0000KK0000l.                                                                                                
                       .;;,,,,,,,,,;;;:cccoo:.  .'oOO00000000k,                                                                                                 
                        ';,,,,,,,,,,,;::,;codolcoxOOOOOO000OOl.                                                                                                 
                        .,,,,,,,,,,,,;:;,;cloodxkkO000Okkkkkl.                                                                                                  
                         ',',',,',,,,;:;,;:cccldxxddxkOkxxd:.                                                                                                   
                          .'',,,,,,,,,;;;;;;;,:llc;;;cdxdc'                                                                                                     
                           ..',,,;,,,,:c:;,,,,,coolccloc'                                                                                                       
                               ..,;::;;::,,,,,;coddoc,.                                                                                                         
                                   ..''',,,;;;;;,,..                                                                                                            
                                                                                                                                                                
                  .......                  ......               ....                                                     ......               ....              
              .:dkOOOOOOOko:.          'cdkOOkOOOOdc'         ,d0000Od,       .:o'               .:.     .od'        'cxOOOOOOOkd:.        .:x0000Oo,           
            ,xKKxc,.....,cdKKd'      ,xK0d:'....':o0Xk;...   cNKc..':OXl      'OMO'             .xK;     '0K,      ;kKOo;'....,:d0Kd'     .oNO:..'l0K:          
          .oXKc.           .cx;    .oX0:.          .:ONXK0x'.xWl     .'.      :XMWO'           .xWWl     'OK,    .xXk;           .c0Xl.   'ON:     .'.          
         .oWO'                    .dNx.              .OMMMK, cX0:             oNX0KO'         .xX0Nx.    '0K,   .xNo.  .'.    '.   .ONo   .oNO,                 
         ;KX;                     ;X0,            .;lkXMMk.   ;kXOc.         .kKx;:KO'       .xXl,O0'    '0K,   cNk.   lNo   :Xx.   ;KK,    :OKk:.              
         :NO.                     oWx.       .':okKNXkd0Mo      ,dKKx;       ,Kk:. :KO'     .xXl..xNc    '0K,   dMo    'l'   .c,    .ON:     .;dKKd,            
         ;X0'                   .dXMO. .';cdkKNNKkl;. .kWl        .cOXk,     lWd.   :KO'   .dXl   cWd    '0K,   oWx.                '0X;        .l0Xx.          
         .kNo.                 .xMMMN00XNNXOxo:'.     cX0'          .oNK,   .xN:     :KO' .dXl    ,KO.   '0K,   ,KX:               .oNx.          .dNO.         
          'ONd.             .,. 'lddKWXd;'.         .lX0;   .,.      .OWl   '00'      :KO;dXo     .kX;   '0K,    :KKc.            .xXk.   ''       ,0N:         
           .oXKo;.       .;o0K:     .oK0o,.      .,l0Kd.   .oXk,    .oXK,   ;Xx.       :KNXo.      oWl   '0K,     'xXOc'.      .;oKXo.   .xXd'    .dNO.         
             .ck00kxdddxk00xc.        .ck0Okxddxk00kl.      .:kKOddx0Kx'    lNl         :0o.       :Xx.  .OK,       'lk0Okxddxk00kKXl.    .cOKkddkK0o.          
                .';:ccc:;'.              .';cccc:,.            .;cc:,.      .'.          .          ..    ..           .,:ccc:;'. .d0d.      ':cc:,.            
                                                                                                                                    ...                         
                                                                                                                                                                
*/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract COSMIQS is ERC721A, Ownable, PaymentSplitter  {
   
    using Strings for uint256;

    //Settings

    string private baseURI;
    string private URIextension = ".json";
    uint256 public constant maxSupply = 8888;  //First 4 will be auctioned off for charity. Dev mint 36 will be minted for giveaways and partnerships. 
    uint256 public mintPrice = 0.15 ether;
    uint256 public whitelistMaxMint = 2;
    uint256 public incubatorMaxMint = 1;
    uint256 private maxMintperTxn = 2;    
    bool public paused = true;
    bool private activeWhitelist = true;
    mapping(address => uint256) private amountMinted;
    bytes32 private incubatorMerkleRoot;
    bytes32 private whitelistMerkleRoot;

    event URIChanged(string _newBaseURI);
    event WhitelistStateChanged(bool _wlactive);


    //Equity
    address[] payees = [0xE8F8eD5E4E07bb87330780269f4147B6113b8a8B,    // Cosmiqs Admin Wallet
        0xa35fa69E715975128c659e04B0D5f6FE26422f28,
        0x65BeF03EB4B6690ECbE18Fd715621e79e99737d5,
        0x69192A30Bb363396A0E8750C95E35f12183f5509,
        0x66aED5F269137dcE8073046A8dd910190543b40C,
        0x4E988d6d347D22258A6649205Fe51c92A7D8297b,
        0x3156B8C7FaFF01334e22E31BecDE257975c480C1,
        0x9B14D932FEf3aff01b3f600c8BB639CFb51cd871,
        0x4cB2d0A4428B5D827885E5b0AD2C97DCaf3F6BAb];
    uint256[] shares_ = [185,
        100,
        20,
        100,
        65,
        130,
        80,
        160,
        160];


    constructor(
        string memory _initBaseURI
    ) ERC721A("COSMIQS", "CSMQ") PaymentSplitter(payees, shares_) {
        setURI(_initBaseURI);
    }
    
    //Minting functionality
    function mintCosmiq(uint256 _tokenAmount, bytes32[] calldata proof) external payable {
        uint256 supply = totalSupply();

        require(msg.sender == tx.origin, "No transaction from smart contracts");
        require(_tokenAmount > 0, "Can't mint zero!");      
        require(supply + _tokenAmount <= maxSupply, "Can't mint that many!");      
        
        if (msg.sender != owner()) {
            require(_tokenAmount <= maxMintperTxn, "Max mint per transaction exceeded!");
            require(paused == false, "Sale is not active!");
            if(activeWhitelist == true) {
                require(MerkleProof.verify(proof, whitelistMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Not on Whitelist!");
                require(amountMinted[msg.sender] + _tokenAmount <= whitelistMaxMint, "Can't mint that many!");
            } 
            require(msg.value == mintPrice * _tokenAmount, "Wrong ETH amount!");
        }

        amountMinted[msg.sender] += _tokenAmount;
        _safeMint(msg.sender, _tokenAmount);

    }

    function mintIncubator(uint256 _tokenAmount, bytes32[] calldata proof) external payable {
        uint256 supply = totalSupply();

        require(msg.sender == tx.origin, "No transaction from smart contracts");
        require(_tokenAmount > 0, "Can't mint zero!");
        require(supply + _tokenAmount <= maxSupply, "Can't mint that many!");

        require(_tokenAmount <= maxMintperTxn, "Max mint per transaction exceeded!");
        require(paused == false, "Sale is not active");
        require(activeWhitelist == true, "Incubatorlist sale is not active!");
        require(amountMinted[msg.sender] + _tokenAmount <= incubatorMaxMint, "Can't mint that many!");
        require(MerkleProof.verify(proof, incubatorMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Not on Incubatorlist");
        require(msg.value == mintPrice * _tokenAmount, "Wrong ETH amount!");

        amountMinted[msg.sender] += _tokenAmount;
        _safeMint(msg.sender, _tokenAmount);
    }


    //WL+PreSale setting
    function setIncubatorlistMerkleRoot(bytes32 incubatorlistRoot) external onlyOwner {
        incubatorMerkleRoot = incubatorlistRoot;
    }

    function setWhitelistMerkleRoot(bytes32 whitelistRoot) external onlyOwner {
        whitelistMerkleRoot = whitelistRoot;
    }

    //Metadata
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token query!");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), URIextension)) : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    function setURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
        
        emit URIChanged(_newBaseURI);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }


    //Sale State
    //If true, WL is active, if false public sale is active.
    function setWhitelistActive(bool _wlactive) public onlyOwner {
        activeWhitelist = _wlactive;

        emit WhitelistStateChanged(_wlactive);
    }
    
    function isPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }
}