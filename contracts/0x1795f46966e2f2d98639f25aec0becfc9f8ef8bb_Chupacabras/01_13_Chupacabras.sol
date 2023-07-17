// SPDX-License-Identifier: MIT

/*                                                                                                                        
      # ###      /                                                             /                                       
    /  /###  / #/                                                            #/                                        
   /  /  ###/  ##                                                            ##                                        
  /  ##   ##   ##                                                            ##                                        
 /  ###        ##                                                            ##                                        
##   ##        ##  /##  ##   ####        /###     /###     /###      /###    ## /###   ###  /###     /###      /###    
##   ##        ## / ###  ##    ###  /   / ###  / / ###  / / ###  /  / ###  / ##/ ###  / ###/ #### / / ###  /  / #### / 
##   ##        ##/   ### ##     ###/   /   ###/ /   ###/ /   ###/  /   ###/  ##   ###/   ##   ###/ /   ###/  ##  ###/  
##   ##        ##     ## ##      ##   ##    ## ##    ## ##        ##    ##   ##    ##    ##       ##    ##  ####       
##   ##        ##     ## ##      ##   ##    ## ##    ## ##        ##    ##   ##    ##    ##       ##    ##    ###      
 ##  ##        ##     ## ##      ##   ##    ## ##    ## ##        ##    ##   ##    ##    ##       ##    ##      ###    
  ## #      /  ##     ## ##      ##   ##    ## ##    ## ##        ##    ##   ##    ##    ##       ##    ##        ###  
   ###     /   ##     ## ##      /#   ##    ## ##    /# ###     / ##    /#   ##    /#    ##       ##    /#   /###  ##  
    ######/    ##     ##  ######/ ##  #######   ####/ ## ######/   ####/ ##   ####/      ###       ####/ ## / #### /   
      ###       ##    ##   #####   ## ######     ###   ## #####     ###   ##   ###        ###       ###   ##   ###/    
                      /               ##                                                                               
                     /                ##                                                                               
                    /                 ##                                                                               
                   /                   ##       
Owner: Osos Muertos
Developer: CrankyDev.eth
*/

pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Chupacabras is ERC721A, Ownable {
    using Strings for uint256;

    event ChupacabraClaimedForOsos(uint256 ososId);

    mapping (uint256 => bool) public chupacabraClaimedForOsos;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    uint256 public cost = 0.01 ether;
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmountPerTx = 1000;

    bool public paused = true;
    bool public publicSaleActive = false;

    address public ososAddress;

    address DEV_ADDRESS = 0xB4C55107c5a4650500269D6DD1b2aE0F028Cf15f;

    constructor() ERC721A("Chupacabras", "CHUPACABRA") {
        setHiddenMetadataUri(
            "ipfs://QmWZ1VMJu24SozHYn5W5LXs2TTTyHue3xr5Zx1UhcPWr95/hidden.json"
        );
        setOsosAddress(0x8A198B42ad0966703B927f2d7E396371198479d4);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            _currentIndex + _mintAmount <= maxSupply + 1,
            "Max supply exceeded!"
        );
        _;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
    }

    function holderMint(uint256[] memory ososIds)
        public
    {
        require(!paused, "The contract is paused!");
        require(!publicSaleActive, "OSOS Claim period expired!");
        IERC721 token = IERC721(ososAddress);

        for (uint256 i = 0; i < ososIds.length; i++) {
          uint256 ososId = ososIds[i];
          require(msg.sender == token.ownerOf(ososId), "You don't own one of those OSOS!");
          require(!chupacabraClaimedForOsos[ososId], "Already claimed!");
          chupacabraClaimedForOsos[ososId] = true;
          emit ChupacabraClaimedForOsos(ososId);
        }

        _safeMint(msg.sender, ososIds.length);
    }

    function publicMint(uint256 quantity)
        public
        payable
        mintCompliance(quantity)
    {
        require(!paused, "The contract is paused!");
        require(publicSaleActive, "Public sale not active!");
        require(msg.value >= cost * quantity, "Insufficient funds!");

        _safeMint(msg.sender, quantity);
    }

    function mintForAddress(uint256 quantity, address _receiver)
        public
        mintCompliance(quantity)
        onlyOwner
    {
        _safeMint(_receiver, quantity);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
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

        if (bytes(_baseURI()).length == 0) {
            return hiddenMetadataUri;
        }

        return string(
                    abi.encodePacked(
                        _baseURI(),
                        _tokenId.toString(),
                        uriSuffix
                    ));
    }

    function setOsosAddress(address _newAddress) public onlyOwner {
        ososAddress = _newAddress;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
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

    function setPublicSaleActive(bool _state) public onlyOwner {
        publicSaleActive = _state;
    }

    function setDevAddress(address developer) public {
      require(msg.sender == DEV_ADDRESS, "Not the developer!");
      DEV_ADDRESS = developer;
    }

    function withdraw() public onlyOwner {
        //
        // =============================================================================
        (bool hs, ) = payable(DEV_ADDRESS).call{
            value: (address(this).balance * 20) / 100
        }("");
        require(hs);
        // =============================================================================

        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}