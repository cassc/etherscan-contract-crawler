// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

//                                          %@@@@@@@@@@@@@@@@@@@@&                                                                            
//                                     /@@@@%#############%&&&&&&&@@@@(                                                                       
//                                [email protected]@@@&######%@@@@@@@@@@@@@@@@@@@@@@@@@@                                                                     
//                              %@@#######@@@@%                          @@,                                                                  
//                            @@%##&&&&&&&    ,&&,.,,,,,,,,,,,,,,,,,,,,,,,,%@@@@.                                                             
//                       ../@@##&&&%%,....&&*.,,,,,(#####################%%%##%%&@(..                                                         
//                     ,,&@&%%&&%##,,%%%%%****/%%%%%&&&&&&&&&&&&&&&&&&&%%%%%%%&&%%%&&  ...                                                    
//                     @@&&&&&((///##/*///%%%%%&&&&%(((((((((%%%%%%%#((((((###&&&&#//..*/*                                                    
//      ,//..       *(#&&&&#**(((////##%%%@@@@%////,.........,,*/*,,.......,,,////*..***/*                                                    
//      ...((.....  #@@@@,,/%%**(((##%%&@@,,**,  ...............,..........   .......//(##%%                                                  
//           ##(....#@&  &@#,,&&###&&@@(       .......  ..,**.......**,  .....  ..,**//##%@@                                                  
//    ##*..  ##(....,,,@@,,/%%##%&&@@,..  ..   ....   ..***//**,..**//***  ............%@%                                                    
//      *##..,,*##,.(##,,%&%##&&@@&.....................*//////****//////**,..............                                                    
//         ####(..#####&&&&&&&@@*.....................////*****...,****////,................                                                  
//             ,####%&&&&&&&@@..........................*/***.......,**/*...................                                                  
//                @@&&&&&@@#......./*...................*/*...........,/*...................*/.                                               
//                @@&&&@@,.........//.....//..............,//.........,/*............//,...........                                           
//                @@&&&@@,.........//.....//.....**,......,//.......*/*.......//..,/*..*/*....,///*//,                                        
//                  #@@@@,....//,..////,..//.......,/*.........*/*..*/*....*////..,/*..*/*..//.                 _________      .__                  .__                                       
//                     //.......*/*//.....*/..,//.....////*///////*/..,///*...//..,////,....                   /   _____/ ____ |  |__   ____   ____ |  |                                      
//                     //.....////*//..,////..,////,..****,.........,*,....,**////,..///////                   \_____  \_/ ___\|  |  \ /  _ \ /  _ \|  |                                      
//                  ,/*....,//@@*..////,....*////@@@@@@@/*,.........../@@@@@@&***/,..///////                    _____/  \  \___|   Y  (  <_> |  <_> )  |__                                    
//                  ,/*....,//@@*..//.......*/(@@  (@&  ,*,.........,*.  @@* ,@@//,..////*..//.               /_______  /\___  >___|  /\____/ \____/|____/                                    
//                  ,/*....,//@@*..//.......*/***@@&%#  ,*,.........,*(@@%%, .,**/,../*//*..//.                       \/     \/     \/                                                        
//                */,[email protected]@*..//.......*/*.................................*/,..////*..//.                               ________          __                                            
//                */,....*/*..//%@&//.......*/*.................................*/,..////*....,/*                             \______ \ _____ _/  |______                                     
//                */,..//.....////*//.......*/*.................................*/,..////*....,/*                              |  |  |  \\__  \\   __\__  \                                   
//                */,..//.....////*//.......*/*...................,,.........,@@//,..////*....,/*                              |  |__|   \/ __ \|  |  / __ \_                                 
//                */,..**.....////***.......*/*..............................,&&//,..//***....,/*                             /_______  (____  /__| (____  /                                
//                ,*.....*/*..////*..*/,....*/(@@**,.......,\    /,,.....**#%%////,..//,....,,,*,                                     \/     \/          \/                                 
//                  .,,..,*,,,***/*..*/,....*/(@@##(//.......,,,,,....,//%%///////,..//,..,,,,.                                               
//                  ...,,...,,..***..**,....**(@@*,/((##((/,,.....(((((##*****,,**,..***,***                                                  
//                     ..********/*..*/,....*/(@@*****////(%%#####((((///////*..*/,..,,*/*..                                        .////.    
//                            *///*..*/,....*/(@@*,********////%@&*//////////*..*/,....*/*                            *//////,  ////(##..*//  
//                                 **.......*/(@@**************%@@@@@@%/*  */*..*/,....*/*                          (((#(  ##(((,,(#/  ((,    
//                                 //.......*/(@@*,*******,*******@@&&&@@@@,  //.......*/*                       ,#(,,   ##,,,,,##  .##       
//                              %@&.........*/(@@*****************@@&&%####&@&//.......*/*                     (#*    .,,,,,,/##    .##       
//                         *@@@@%#(.........*/(@@..,*********.......&@&#######//.......*/*                   ##     ,,,,,,,       (#/         
//                       &@&######(.........*/(@@...................&@&#######//.......*//##              *#(                ,####            
//                  #@@@@  ,####,.........*///(&&@@/......*@@@@@@@@@@@@&&#####*/.......*/*  ##,           *#(            ####*                
//                @@@@@@@@@#,,  ..........//%&&&&@@(****&@&#########@@@&&#####//.......*/*  ##,           *#(       ,,,,,                     
//             ,@@##*,,,,,,(@@&&*.........//%&&&&##&@@@@%###########@@@&&#####//.......*/*    *#(       ##,         ,,                        
//             .##     ,,,,,,,@@*.........//%&&&&##&@@&&&&%#########@@@&&#####//.....//.         ##.    ##,         ,,                        
//             .##         .,,,,*/*.......*/%&&&&#####@@&&&&&#######@@@&&#####//.....//.           (#/  ##,         ,,#&%                     
//           (#/                */*.......//,,*&&#######@@@&&#######@@@&&####(.......//.             .#(              #&%                     
//           (#/                */*.......//%&#,,#######@@@&&&&%####@@@&&##.  .......//.           &@@&&..            #&%                     
//           (#/                */*.......//&@@&&     ####%@@&&%##&&@@@&&##.  .......//,,,    (@@@@&&&&&  ........    #&%                     
//           (#/                   .......*/&@@@@&&&&%  #&&&&@@&&&&&@@@&&  #@&......./*,,*@@@@&&&&&&&&&&&&*    .......#&%                     
//           (#/                   //.....//&@@@@@@@@@&&*,/&&@@&&&@@&&&&&,,%@&..*/,..//(##&&&&&&%,,,,/&&@@&&&&&       #&%                     
//           (#/                   //.....//,,/@@@@@@@@@&&#,,&&@@@@@&&#,,@@@@&..*/,..//(##&&,,,,*&&&&&@@@@/....&&&&&&&&&%                     
//             .##                   */,....,,,,,,,#@@@@@@@&&,,%@@@@*,/&&@@@@&..*/***  /#(,,&&&&&@@@@%**@@/[email protected]@,                       
//             .##                 ..##(//..   ,,,,,,,@@@@@@@@@(**..%&&@@@@*..****.    /##&&@@@&&&&*****&&*[email protected]@,                       
//             .##     ...........,@@@@@@@//..        ,,%&&&&@@@@@@@@@@@@,,            /##&&&&(***,**/@@[email protected]@,                       
//           ,*/%%*****&&&&&&&&&&&&#####%%@@.           .....##&@@@@@@&%%              /#/    *##(/**/@@[email protected]@,                       
//           &@@&&&&&&%*******/////(((((((@@.                  #@@@@@@&##..        ..//(#/       //(#((([email protected]@,                       
//           &@%,,,,,,,/////((#####@@@@@@@//,..              ##&@@&&&&&&&%%*......,,,##*,.         ,*/##[email protected]@,                       
//           ..*&&(((((@@@@@@@@@@@@@@/****,,,,,,,,,.       ,,@@@@&&&&&&&&@@/,,,,,,,,,##.              ..%%*[email protected]@,                       
//             ,@@@@@@&**************&&(,,,,,,,,,,,,,,,,,,,,,@@@@&&&&&&&&&&&@&,,,,,,,##.                ..(&%....*&&..                        
//                  #@&***********,**&@#,,,,,,,,,,,,,,,,,,,,,@@@@&&&&&&&&&&@@&,,,,,,,##.                    .&&&&&@&                          
//                     @@............&@#,,,,,,,,,,,,,,,,,,/@@,,,,*&&&&&&&  (&&@@,,,,,##.                                                     

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";
import "closedsea/src/OperatorFilterer.sol";

contract SchoolData is ERC721A, ERC2981, OperatorFilterer, Ownable {
    string public baseURI;

    uint256 public constant price = 0.049 ether;

    uint256 public constant totalTokens = 5555;
    uint256 public constant freeTotalTokens = 455;
    uint256 public constant paidTotalTokens = 5100;
    uint256 public constant treasury = 2222;
    uint256 public constant maxFreeState = 2;
    uint256 public constant maxPaidState = 3;
    uint256 public mintedFree = 0;
    uint256 public mintedPaid = 0;
    uint256 public mintedTreasury = 0;

    bytes32 private freeRoot;
    bytes32 private paidRoot;

    enum SaleState {
        Closed,
        Free,
        Paid,
        Public
    }
    SaleState public saleState = SaleState.Closed;

    mapping(address => uint256) public freeMinted;
    mapping(address => uint256) public paidMinted;
    mapping(address => uint256) public publicMinted;
    mapping(address => uint256) public treasuryMinted;

    bool public operatorFilteringEnabled = true;

    constructor(
        string memory _initURI,
        bytes32 root1,
        bytes32 root2
    ) ERC721A("SchoolData", "JK") { 
        setBaseURI(_initURI);
        setMerkleRoot(root1, root2);
        _setDefaultRoyalty(msg.sender, 750);
        _registerForOperatorFiltering();
    }

    function mintFree(uint256 _amount, uint256 _maxAmount, bytes32[] calldata merkleProof) external
        callerIsUser
        isValidSaleState(SaleState.Free) {
        require(freeMinted[msg.sender] + _amount <= _maxAmount, "Exceeding max eligible amount.");
        require(mintedFree + _amount <= freeTotalTokens, "Exceeding max supply of free tokens.");
        require(freeMinted[msg.sender] + _amount <= maxFreeState, "Exceeding max tokens of Phase 1.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _maxAmount));
        require(MerkleProof.verify(merkleProof, freeRoot, leaf), "Proof does not match.");

        freeMinted[msg.sender] += _amount;
        mintedFree += _amount;
        _mint(msg.sender, _amount);
    }

    function mintPaid(uint256 _amount, uint256 _maxAmount, bytes32[] calldata merkleProof) external payable 
        callerIsUser
        isValidSaleState(SaleState.Paid) {
        require(paidMinted[msg.sender] + _amount <= _maxAmount, "Exceeding max eligible amount.");
        require(mintedPaid + _amount <= paidTotalTokens, "Exceeding max supply of paid tokens.");
        require(msg.value == price * _amount, "Incorrect Ether value.");
        require(paidMinted[msg.sender] + _amount <= maxPaidState, "Exceeding max tokens of Phase 2.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _maxAmount));
        require(MerkleProof.verify(merkleProof, paidRoot, leaf), "Proof does not match.");

        paidMinted[msg.sender] += _amount;
        mintedPaid += _amount;
        _mint(msg.sender, _amount);
    }

    function mintPublic(uint256 _amount) external payable isValidSaleState(SaleState.Public){
        require(publicMinted[msg.sender] + _amount <= maxPaidState, "Exceeding max tokens of Public sale");
        require(totalSupply() + _amount <= totalTokens, "Exceeding max supply of total tokens.");
        require(msg.value == price * _amount, "Incorrect Ether value.");

        publicMinted[msg.sender] += _amount;
        mintedPaid += _amount;
        _mint(msg.sender, _amount);
    }

    //Functions

    modifier isValidSaleState(SaleState requiredState) {
        require(saleState == requiredState, "wrong sale state");
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "contract not allowed");
        _;
    }

    function setMerkleRoot(bytes32 _root1, bytes32 _root2) public onlyOwner {
        freeRoot = _root1;
        paidRoot = _root2;
    }

    function setBaseURI(string memory newbaseURI) public onlyOwner {
        baseURI = newbaseURI;
    }

    function setSaleState(SaleState _saleState) external onlyOwner {
        saleState = _saleState;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Failed to withdraw payment");
    }

    function airdrop(address to, uint256 _amount) external onlyOwner{
        require(mintedTreasury + _amount <= treasury, "Mint failed: exceeding treasury amount.");

        _mint(to, _amount);
        treasuryMinted[to] += _amount;
    }

    function airdrop(address[] memory to) external onlyOwner{
        require(mintedTreasury + to.length <= treasury, "Mint failed: exceeding treasury amount.");
        
        for(uint i = 0; i < to.length;){
            _mint(to[i], 1);
            treasuryMinted[to[i]] += 1;
            unchecked{ i++; }
        }
    }

    // IERC2981

    function setRoyaltyInfo(address payable receiver, uint96 numerator) public onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }

    // OperatorFilterer

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function toggleOperatorFilteringEnabled() external onlyOwner {
        operatorFilteringEnabled = !operatorFilteringEnabled;
    }

    function _operatorFilteringEnabled() internal view virtual override returns (bool) {
        return operatorFilteringEnabled;
    }

    // ERC165

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}