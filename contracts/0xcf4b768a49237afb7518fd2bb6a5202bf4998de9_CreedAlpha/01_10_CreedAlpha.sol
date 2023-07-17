// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**                                                                               
                                                                                
                                                                                
                                                                                
                                      #5B&                                      
                                    &577GB#&                                    
                                  &P?!!7BBBB#&                                  
                                &P?7!!!!B##BBB#&                                
                              &P?77!!!~!B####BBB#&                              
                            &5?777!!~~~7B######BBBB&                            
                           #J7777!!~~75#&#######BBBB&                           
                           Y7777!~!JG&@@@@&######BBB#                           
                          [email protected]@@@@&@@@&######BB#                          
                         B?77!?P#@@@@&#P#&&&@@&&####BB&                         
                        #?77YG&@@@@&G5?J###&&&@@@&##BBB&                        
                       #??5#@@@@&BPY??PBGB###&&&&@@&#BBB&                       
                      &PP&@@@@&BPJ?JP#&#PPBB####&&&&@@&BB                       
                      &#@@@@@@&&&#B#&&##55PGGBB####&@@@@##                      
                      &#@@@@@@&&&&&####B55PPGGBB##&@@@@@##                      
                      &#@@&&@@@@&&#####BY55PPGB#&@@@&&&@B#                      
                      ##&&&#B#&@@&&####BYY55G#&@@@&#####B#                      
                      &G5PGBBGB#&&&&&##B5PB#&@@&&######B#&                      
                        #5YPGBBBB#&&&&&&&&@@@&#######BG#                        
                         @B55GBBB###&@@@@@@&#######BP5#                         
                          @&G5PB######&@@&#######BGYJ&                          
                           @##GPG##############BG5J~G                           
                           &####BGB#&#######&BGP5J7:P                           
                            &##&&#BB#&&#####GPYJJ?7Y                            
                              &&#&&#BB#&&BP5J77?J5#                             
                                &&####BBPP57!7?5#                               
                                  &#####G#B?7JB                                 
                                   &##&####J5&                                  
                                    &#&####B                                    
                                     &&&##&                                     
                                      &&#&                                      
                                                                                
                                                                                
                                                                                
                                                                                
*/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/**
 * @title Creed Alpha Group Token Contract
 * @author @0xdrnoid
 * @notice Facilitates a staged mint for Creed Alpha passes
 * @custom:website https://creedalpha.com
 */
contract CreedAlpha is ERC721A, DefaultOperatorFilterer, Ownable {
    uint256 public constant TEAM_RESERVE = 12;
    uint256 public maxTokens = 111;
    uint256 public mintPrice = 0.15 ether;
    string public constant BASE_URI = "https://creedalpha.com/token/";

    bytes32 public mintlistMerkleRoot;

    enum SaleStage {
        Closed,
        Minting
    }

    SaleStage public saleStage = SaleStage.Closed;

    error SaleClosed();
    error MerkleTreeNotSet();
    error NotOnMintlist();
    error UnauthorizedMint();
    error SupplyFull();
    error CallerNotEOA();

    modifier callerIsEOA() {
        if (tx.origin != msg.sender) revert CallerNotEOA();
        _;
    }

    constructor() ERC721A("CreedAlpha", "CREED") {}

    function acquireCreedPass(
        bytes32[] calldata _merkleProof
    ) external payable callerIsEOA {
        if (saleStage == SaleStage.Closed) revert SaleClosed();

        unchecked {
            if (_numberMinted(msg.sender) > 0) revert UnauthorizedMint();
            if (msg.value < mintPrice) revert UnauthorizedMint();
            if (_totalMinted() + 1 > maxTokens - TEAM_RESERVE)
                revert SupplyFull();
        }

        if (!onMintlist(_merkleProof, msg.sender)) revert NotOnMintlist();
        _mint(msg.sender, 1);
    }

    function onMintlist(
        bytes32[] calldata _merkleProof,
        address _address
    ) public view returns (bool) {
        if (mintlistMerkleRoot == 0) revert MerkleTreeNotSet();

        bytes32 leaf = keccak256(abi.encodePacked(_address));

        return
            MerkleProof.verifyCalldata(_merkleProof, mintlistMerkleRoot, leaf);
    }

    function setMintlistRoot(bytes32 _merkleRoot) external onlyOwner {
        mintlistMerkleRoot = _merkleRoot;
    }

    function setSaleStage(SaleStage _stage) public onlyOwner {
        saleStage = _stage;
    }

    function setMaxSupply(uint256 _new) external onlyOwner {
        maxTokens = _new;
    }

    function setPrice(uint256 _new) external onlyOwner {
        mintPrice = _new;
    }

    function creedTeamMint(uint256 _amount) external onlyOwner {
        if (_totalMinted() + _amount > maxTokens) revert SupplyFull();
        _mint(msg.sender, _amount);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return string(abi.encodePacked(BASE_URI, _toString(tokenId), ".json"));
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
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
}