// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./ToStringLib.sol";
import "./ECDSA.sol"; 

/*
 *           =%*+.                      ::                      .+*%+                 
 *            @@@@#:                   [email protected]@-                   .*@@@@.                 
 *            .*@@@@#-         +-     [email protected]@@@=     :+         :#@@@@*.                  
 *              .#@@@@%-       [email protected]@#   [email protected]@@@:   *@@+       -#@@@@#:                    
 *                :%@@@@%= -##= %@@[email protected]@@@[email protected]@% =##= -%@@@@%-                      
 *              .##.-%@@@@@=    :@@@@@@@@@@@@@@@@:    =%@@@@@=.*#.                    
 *              :@:   [email protected]+----:   +%*+=-:..:-=+*#*   :[email protected]+   [email protected]                    
 *              :@:     [email protected]@%#*+=                  =+*#%@@=     [email protected]                    
 *              [email protected]     -.  :.    -*@@*.  [email protected]@*-     :. .-     :@:                    
 *               @+  .+#%@@%-   [email protected]@@@@@@##@@@@@@@*   :#@@%#+.  [email protected]                     
 *               *% :@@@#=:=*  [email protected]#@@@@@@@@@@@@@@#@=  +=:=#@@@- ##                     
 *               :@:[email protected]@--*@@.   .. .=%@@@@@@%=. ..   .%@#-:@@[email protected]                     
 *                ## %=%@@*=:  *@@**=:@@@@@@:=+*@@*  :=*@@%[email protected]*%                      
 *                [email protected] %@@@@#   :@@@@@#@@@@@@#@@@@@:   *@@@@% :@:                      
 *                 [email protected][email protected]@#-  =*  +%[email protected]@%@@@@%@@+%+  ++  -#@@+ @+                       
 *                  #% #-  [email protected]@+   .%@@*:..:*@@@.   [email protected]@+  :* ##                        
 *                   %*   %@@%.#+ [email protected]@@@@[email protected]@@@@+ =#.#@@%   *%                         
 *                    %* :@@@#@@@  +%*--++=-+%*  @@@#@@@- *%.                         
 *                     ## [email protected]@@+#@    [email protected]@@@@@+    %#[email protected]@@= *%                           
 *                      *%.:%: @*    *@@@@@@*    [email protected]%-.##                            
 *                       [email protected]   =% .+   :##-   =: #=   [email protected]+                             
 *                     +#..%*   :::@-        :@-.-   *%: *+                           
 *                 .:.#@%-  =%=    @@++.  .*[email protected]@.   -%+  :%@%.:.                       
 *               %@@@@=::    .*%:  [email protected]@@@::%@@@*  :%#.    ::=%@@@@.                    
 *              [email protected]@@@@@        :%#: -=%@@@@@=- .*%:        @@@@@@*                    
 *              [email protected]@@@@+          -%#:  [email protected]@=  :#%-          =%@@@@=                    
 *                ..               :#%=    -##-               ..                    
 *                                   [email protected]*[email protected]*.                                         
 *                                      -=                                            
 */


contract KingdomWarriors is Ownable, ERC721A, ReentrancyGuard {

    uint256 private maxPhaseTokens = 0;
    uint256 private walletMintLimit = 2;
    mapping (address => mapping(uint256 => uint256)) phaseWalletList;
    address[] private allWallets;
    uint256 private phaseId = 1;
    bool private phaseRestricted = true;
    bool private phaseOpen = false;
    uint256 public phasePrice = 0.08 ether; // 0.08 ETH

    address accessAuthority = 0x840f44e23194c6e1fBb29a9cB802526eaef90bD6;

    constructor() ERC721A("KingdomWarriors", "KW", 100, 8888) {}

    /* Config */
    function getConfig() external view returns(uint256, uint256, uint256, bool, bool, uint256) {
        return (phaseId, maxPhaseTokens, walletMintLimit, phaseRestricted, phaseOpen, phasePrice);
    }

    function getCollectionSize() external view returns(uint256) {
        return collectionSize;
    }

    /* Accessor */
    function isValidAccessMessage(bytes memory signature) private view returns (bool) {
        bytes32 internalHash = keccak256(bytes(interalAccessor()));
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(internalHash);
        return accessAuthority == ECDSA.recover(messageHash, signature);
    }

    function interalAccessor() private view returns(string memory) {
        return string(abi.encodePacked(ToStringLib.toString(address(this)), ToStringLib.toString(msg.sender)));
    }

    /* Mint */
    function warrionMintPrecheck(uint256 numberOfTokens, bool isOwner) private {
        require(numberOfTokens <= walletMintLimit, "Cannot mint more than the max mint limit");
        require(numberOfTokens > 0, "Must mint at least one token");
	    require(totalSupply() + numberOfTokens <= collectionSize, "Not enough tokens left to mint that many");
        require(totalSupply() + numberOfTokens <= maxPhaseTokens, "Not enough phase tokens left to mint that many");
        if(isOwner == false) { require(phasePrice * numberOfTokens == msg.value, "Not enough ETH for mint"); }
    }

    function warriorMint(address to, uint256 numberOfTokens) private {
        _safeMint(to, numberOfTokens);
    }

    /* Phase Mint */
    function preMint(uint256 numberOfTokens, bytes memory signature) external payable nonReentrant {
        require(phaseRestricted, "Minting is not active");
        require(isValidAccessMessage(signature), "Mint access not granted!");
        processMint(numberOfTokens, false);
    }

    function publicMint(uint256 numberOfTokens) external payable nonReentrant {
        require(phaseOpen, "Minting is not active");
        processMint(numberOfTokens, false);
    }

    function ownerMint(uint256 numberOfTokens) external nonReentrant onlyOwner {
        processMint(numberOfTokens, true);
    }

    function processMint(uint256 numberOfTokens, bool isOwner) private {
        require(phaseWalletList[msg.sender][phaseId] + numberOfTokens <= walletMintLimit, "You can't mint over your limit!");
        warrionMintPrecheck(numberOfTokens, isOwner);
        warriorMint(msg.sender, numberOfTokens); 
        phaseWalletList[msg.sender][phaseId] += numberOfTokens;
    }

    function getMintsPerPhase(address owner, uint256 phase) external view returns(uint256) {
        return phaseWalletList[owner][phase];
    }

    /* Metadata */
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /* Owner */
    function setAccessAuthority(address addr) external onlyOwner {
        accessAuthority = addr;
    }

    function setPhase(uint256 id, uint256 maxTokens, uint256 walletLimit, bool restricted, bool open, uint256 price) external onlyOwner {
        if(phaseId != id) { phaseId = id; }
        if(maxPhaseTokens != maxTokens) { maxPhaseTokens = maxTokens; }
        if(walletMintLimit != walletLimit) { walletMintLimit = walletLimit; }
        if(phaseRestricted != restricted) { phaseRestricted = restricted; }
        if(phaseOpen != open) { phaseOpen = open; }
        if(phasePrice != price) { phasePrice = price; }
    }

    function withdrawBalance() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    /* Search */
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 total = totalSupply();
            uint256 resultIndex = 0;
            uint256 id;

            for (id = 0; id < total; id++) {
                if (ownerOf(id) == _owner) {
                    result[resultIndex] = id;
                    resultIndex++;
                }
            }

            return result;
        }
    }

}