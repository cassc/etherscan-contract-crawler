// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;


//  ███╗   ██╗███████╗████████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗     ██████╗██╗████████╗██╗███████╗███████╗███╗   ██╗
//  ████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝    ██╔════╝██║╚══██╔══╝██║╚══███╔╝██╔════╝████╗  ██║
//  ██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██║   ██║██████╔╝█████╔╝     ██║     ██║   ██║   ██║  ███╔╝ █████╗  ██╔██╗ ██║
//  ██║╚██╗██║██╔══╝     ██║   ██║███╗██║██║   ██║██╔══██╗██╔═██╗     ██║     ██║   ██║   ██║ ███╔╝  ██╔══╝  ██║╚██╗██║
//  ██║ ╚████║███████╗   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗    ╚██████╗██║   ██║   ██║███████╗███████╗██║ ╚████║
//  ╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝     ╚═════╝╚═╝   ╚═╝   ╚═╝╚══════╝╚══════╝╚═╝  ╚═══╝
//                                                                                                                                                                                                                                           
//                                                                                                                                    
//                                                                                                                                  
//                                                                                                                                  
//                                                         .-=+++++*+++==-:.                                                        
//                                                    :=*%@@@@@@@@@@@@@@@@@@@%#=:                                                   
//                                                 -#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+.                                                
//                                              :*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%-                                              
//                                            -%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%-                                            
//                                          .#@@@@@#=%%+*@%+=#@@@@@%*%@@@@@%@@%[email protected]@@@@#.                                          
//                                         [email protected]@@@@*:    =*:  %@@#=:[email protected]@@#+: ::.      :#@@@@+                                         
//                                        #@@@@+.           --    =+=:                .*@@@%-                                       
//                                      .#@@@*.                                         [email protected]@@@*                                      
//                                     [email protected]@@@*                                            .%@@@=                                     
//                                    *@@@@.                                             [email protected]@@@.                                    
//                                     @@@@@                                              [email protected]@@@=                                    
//                                     %@@@@                                              [email protected]@@@-                                    
//                                     [email protected]@@@       .-=====-:.            .:-=====-:       [email protected]@@%.                                    
//                                      #@@@.   :*@@@@@@@@@@@@+        =%@@@@@@@@@@@#-    [email protected]@@:                                     
//                                      .%@@:  [email protected]@%*+=----=++#%#      *%#*+==---==*#@@+   [email protected]@+                                      
//                                   ..:.:%@+  -.  .:------:.             :------:.  .-   #@+.::..                                  
//                               .=*+=----=#+   ---:        :==.  .-   ==-.       :---    **=----+**-                               
//                              **:        --  +:              -  :=  -              .+.  +         -*=                             
//                            .#:          -- .:         =%%:     :=     .#@+          :  +...        =*                            
//                            %=:.   ......-=....        =#+.  ...-=...   +#+        .....*......   .::**                           
//                           +=  .:-==-....:+.......         .....=+.....         ........*....:-=--:.  #:                          
//                           @.    ..:-==:.:*.....................=+.....................:*..-+=:..     =*                          
//                           @     .....:=+-*.....................=*.....................-+-+-.....     -#                          
//                           *=     ......:+#:.................-. =* :+:.................=*=:.....      #-                          
//                           .*-      ......+:...............   -=++==:    ..............=-......      +=                           
//                             :+-          ::  ..........-::.          ..::-.........   =..        .==.                            
//                               :=+=-:     .=               .:::::::::::.               +     .:-++=.                              
//                                   .-=+++++*                                          .#+++++=-.                                  
//                                           +:                                         +:                                          
//                                            :==-                                  .===.                                           
//                                               .-=-:.                         .:---                                               
//                                                  #..:::::.             .:::::.#                                                  
//                                                  *-      .::-::-:---:::      -*                                                  
//                                                  *-                          -*                                                  
//                                                  #-                          -#                                                  
//                                                 :%                            %:                                                 
//                                                =*                              *=                                                
//                                             :[email protected]@@#=.                        .=#@@@+:                                             
//                                          :+%@@@@@@@@@*=.                .=*@@@@@@@@@%+:                                          
//                                      .=#@@@@@@@@@@@@@@@@@%#*+======+*#%@@@@@@@@@@@@@@@@@#=.                                      
//                                   -+%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%+-                                   
//                                =#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#-                                
//                            .=#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#=.                            
//                         -+%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%+-                         
//                     :+#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#+:                     
//                 :+#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#+:                 
//            :=*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*=:            
//        .-*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*-.        
//      =#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#=      
//    .%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%.    
//    %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%    
//   [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@-   
//   #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#   
//   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   
//   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   


import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract NetworkCitizen is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxNoOfApplicationsPerTx;
  uint256 public maxLimitPerWallet = 3;
  

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxNoOfApplicationsPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxNoOfApplicationsPerTx(_maxNoOfApplicationsPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _NoOfApplications) {
    require(_NoOfApplications > 0 && _NoOfApplications <= maxNoOfApplicationsPerTx, 'Invalid mint amount!');
    require(totalSupply() + _NoOfApplications <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _NoOfApplications) {
    require(msg.value >= cost * _NoOfApplications, 'Insufficient funds!');
    _;
  }

  function whitelistMint(uint256 _NoOfApplications, bytes32[] calldata _merkleProof) public payable mintCompliance(_NoOfApplications) mintPriceCompliance(_NoOfApplications) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _NoOfApplications);
  }

  function ApplyForCitizenship(uint256 _NoOfApplications) public payable mintCompliance(_NoOfApplications) mintPriceCompliance(_NoOfApplications) {
    require(!paused, 'The contract is paused!');
    require(balanceOf(msg.sender) + _NoOfApplications <= maxLimitPerWallet, 'Not eligible for more applications!');
    _safeMint(_msgSender(), _NoOfApplications);
  }
  
  function mintForAddress(uint256 _NoOfApplications, address _receiver) public mintCompliance(_NoOfApplications) onlyOwner {
    _safeMint(_receiver, _NoOfApplications);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxNoOfApplicationsPerTx(uint256 _maxNoOfApplicationsPerTx) public onlyOwner {
    maxNoOfApplicationsPerTx = _maxNoOfApplicationsPerTx;
  }

  function setmaxLimitPerWallet(uint256 _maxLimitPerWallet) public onlyOwner {
  maxLimitPerWallet = _maxLimitPerWallet;
  }  

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}